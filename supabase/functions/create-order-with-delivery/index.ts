const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const ALLOWED_STORE_ID = "cff9aa92-707c-4146-ab24-76819bf0958a";
const SERVICE_FEE = 1000;
const PRICE_PER_KM = 700;
const MIN_DELIVERY_FEE = 1500;
const MAX_STRAIGHT_DISTANCE_KM = 10;

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function haversineKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const rad = (degrees: number) => degrees * Math.PI / 180;
  const dLat = rad(lat2 - lat1);
  const dLon = rad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) *
      Math.cos(rad(lat2)) *
      Math.sin(dLon / 2) ** 2;

  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Método no permitido." }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const orsKey = Deno.env.get("OPENROUTESERVICE_API_KEY");

    if (!supabaseUrl || !serviceRoleKey || !orsKey) {
      throw new Error("Falta configurar una variable secreta en Supabase.");
    }

    // Comprobar la sesión del usuario.
    const authorization = request.headers.get("Authorization");

    if (!authorization?.toLowerCase().startsWith("bearer ")) {
      return jsonResponse({ error: "Debés iniciar sesión." }, 401);
    }

    const userResponse = await fetch(
      `${supabaseUrl}/auth/v1/user`,
      {
        headers: {
          apikey: serviceRoleKey,
          Authorization: authorization,
        },
      },
    );

    if (!userResponse.ok) {
      return jsonResponse({ error: "La sesión no es válida o venció." }, 401);
    }

    const user = await userResponse.json();

    if (!user?.id) {
      return jsonResponse({ error: "No se pudo identificar al cliente." }, 401);
    }

    const body = await request.json();

    const storeId = String(body.store_id ?? "");
    const address = String(body.delivery_address ?? "").trim();
    const notes = String(body.delivery_notes ?? "");
    const paymentMethod = String(body.payment_method ?? "");

    const latitude = Number(body.destination_latitude);
    const longitude = Number(body.destination_longitude);

    const items = body.items;

    if (storeId !== ALLOWED_STORE_ID) {
      return jsonResponse(
        { error: "Este comercio todavía no está habilitado para pedidos con cálculo automático." },
        403,
      );
    }

    if (address.length < 5 || address.length > 500) {
      return jsonResponse({ error: "Ingresá una dirección válida." }, 400);
    }

    if (notes.length > 1000) {
      return jsonResponse({ error: "Las indicaciones son demasiado extensas." }, 400);
    }

    if (!["cash", "transfer"].includes(paymentMethod)) {
      return jsonResponse({ error: "El método de pago no es válido." }, 400);
    }

    if (
      body.destination_latitude === null ||
      body.destination_latitude === undefined ||
      body.destination_longitude === null ||
      body.destination_longitude === undefined ||
      !Number.isFinite(latitude) ||
      !Number.isFinite(longitude) ||
      latitude < -90 || latitude > 90 ||
      longitude < -180 || longitude > 180
    ) {
      return jsonResponse({ error: "Seleccioná un punto de entrega válido en el mapa." }, 400);
    }

    if (
      !Array.isArray(items) ||
      items.length < 1 ||
      items.length > 50
    ) {
      return jsonResponse({ error: "El carrito no es válido." }, 400);
    }

    // Obtener el punto de retiro del comercio.
    const merchantResponse = await fetch(
      `${supabaseUrl}/rest/v1/merchants?id=eq.${ALLOWED_STORE_ID}&select=id,name,is_active,latitude,longitude`,
      {
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
        },
      },
    );

    if (!merchantResponse.ok) {
      throw new Error("No se pudo consultar el punto de retiro.");
    }

    const merchants = await merchantResponse.json();
    const merchant = merchants[0];

    if (!merchant || merchant.is_active !== true) {
      throw new Error("El comercio no está disponible.");
    }

    const originLatitude = Number(merchant.latitude);
    const originLongitude = Number(merchant.longitude);

    if (
      !Number.isFinite(originLatitude) ||
      !Number.isFinite(originLongitude)
    ) {
      throw new Error("El comercio todavía no tiene un punto de retiro configurado.");
    }

    // Limitar provisionalmente el área de entrega.
    const straightDistance = haversineKm(
      originLatitude,
      originLongitude,
      latitude,
      longitude,
    );

    if (straightDistance > MAX_STRAIGHT_DISTANCE_KM) {
      return jsonResponse(
        { error: "Por ahora, la entrega está limitada a 10 km en línea recta desde el punto de retiro." },
        400,
      );
    }

    // Calcular el recorrido por calles.
    const routeResponse = await fetch(
      "https://api.heigit.org/openrouteservice/v2/directions/driving-car/geojson",
      {
        method: "POST",
        headers: {
          Authorization: orsKey,
          "Content-Type": "application/json",
          Accept: "application/geo+json, application/json",
        },
        body: JSON.stringify({
          coordinates: [
            [originLongitude, originLatitude],
            [longitude, latitude],
          ],
          instructions: false,
        }),
      },
    );

    if (!routeResponse.ok) {
      const detail = await routeResponse.text();
      throw new Error(
        `No se pudo calcular el recorrido (${routeResponse.status}): ${detail.slice(0, 200)}`,
      );
    }

    const routeData = await routeResponse.json();
    const summary = routeData.features?.[0]?.properties?.summary;

    if (
      !summary ||
      !Number.isFinite(Number(summary.distance)) ||
      Number(summary.distance) <= 0
    ) {
      throw new Error("No se encontró un recorrido válido por calles.");
    }

    const rawKm = Number(summary.distance) / 1000;
    const deliveryKm = Number(rawKm.toFixed(2));

    // Calcular sobre los mismos kilómetros redondeados que se guardarán.
    const deliveryFee = Math.max(
      MIN_DELIVERY_FEE,
      Math.round(deliveryKm * PRICE_PER_KM),
    );

    // Crear el pedido usando la función SQL protegida.
    const rpcResponse = await fetch(
      `${supabaseUrl}/rest/v1/rpc/mova_create_order_with_delivery`,
      {
        method: "POST",
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          p_customer_id: user.id,
          p_store_id: storeId,
          p_items: items,
          p_delivery_address: address,
          p_delivery_notes: notes,
          p_payment_method: paymentMethod,
          p_delivery_latitude: latitude,
          p_delivery_longitude: longitude,
          p_delivery_km: deliveryKm,
          p_delivery_fee: deliveryFee,
        }),
      },
    );

    const rpcText = await rpcResponse.text();

    if (!rpcResponse.ok) {
      console.error("Error al crear pedido:", rpcText);
      throw new Error("Supabase no pudo registrar el pedido. Revisá el carrito y los datos.");
    }

    let orderResult: unknown;

    try {
      orderResult = JSON.parse(rpcText);
    } catch {
      throw new Error("Supabase devolvió una respuesta inesperada al crear el pedido.");
    }

    return jsonResponse({
      ...(orderResult as Record<string, unknown>),
      delivery_km: deliveryKm,
      delivery_fee: deliveryFee,
      service_fee: SERVICE_FEE,
      estimated_duration_minutes: Math.ceil(Number(summary.duration) / 60),
      currency: "ARS",
    });

  } catch (error) {
    console.error("create-order-with-delivery:", error);

    return jsonResponse(
      {
        error: error instanceof Error
          ? error.message
          : "No se pudo crear el pedido.",
      },
      400,
    );
  }
});