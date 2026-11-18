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

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function isTotoras(properties: Record<string, unknown>): boolean {
  const values = [
    properties.label,
    properties.name,
    properties.locality,
    properties.locality_a,
    properties.localadmin,
    properties.borough,
    properties.county,
    properties.region,
  ];

  const text = values
    .filter((value) => value !== null && value !== undefined)
    .join(" ")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();

  return text.includes("totoras");
}

async function geocodeAddress(
  address: string,
  apiKey: string,
  stage: string,
) {
  // Separar calle y altura de localidad, provincia y país.
  const streetAddress = address.split(",")[0].trim();

  if (!streetAddress) {
    throw new Error(stage + ": falta la calle y altura.");
  }

  const numberMatch = streetAddress.match(/\b(\d+[A-Za-z]?)\b/);
  const requestedNumber = numberMatch?.[1] ?? null;

  // Búsqueda estructurada para evitar confundir calles homónimas.
  const url = new URL(
    "https://api.heigit.org/pelias/v1/search/structured",
  );

  url.searchParams.set("address", streetAddress);
  url.searchParams.set("locality", "Totoras");
  url.searchParams.set("region", "Santa Fe");
  url.searchParams.set("country", "Argentina");
  url.searchParams.set("boundary.country", "ARG");
  url.searchParams.set("size", "10");

  const result = await fetch(url.toString(), {
    headers: {
      Authorization: apiKey,
      Accept: "application/geo+json, application/json",
    },
  });

  if (!result.ok) {
    const detail = await result.text();
    throw new Error(
      stage + ": error de geocodificacion HTTP " +
      result.status + ": " + detail.slice(0, 250),
    );
  }

  const data = await result.json();
  const features = Array.isArray(data.features) ? data.features : [];

  const townFeatures = features.filter(
    (item: { properties?: Record<string, unknown> }) =>
      isTotoras(item.properties ?? {}),
  );

  // No aceptar otra provincia ni una altura diferente.
  const feature = townFeatures.find(
    (item: {
      properties?: Record<string, unknown>;
      geometry?: { coordinates?: unknown };
    }) => {
      const properties = item.properties ?? {};

      if (!requestedNumber) {
        return true;
      }

      const returnedNumber = String(
        properties.housenumber ?? properties.number ?? "",
      ).trim();

      const label = String(properties.label ?? "");
      const escapedNumber = requestedNumber.replace(
        /[.*+?^${}()|[\]\\]/g,
        "\\$&",
      );

      const numberInLabel = new RegExp(
        "(^|\\D)" + escapedNumber + "(\\D|$)",
      ).test(label);

      return returnedNumber === requestedNumber || numberInLabel;
    },
  );

  if (!feature) {
    const samples = features.slice(0, 10).map(
      (item: {
        properties?: Record<string, unknown>;
        geometry?: { coordinates?: number[] };
      }) => {
        const p = item.properties ?? {};
        const coordinates = item.geometry?.coordinates ?? [];

        return {
          label: p.label ?? null,
          name: p.name ?? null,
          housenumber: p.housenumber ?? null,
          locality: p.locality ?? null,
          localadmin: p.localadmin ?? null,
          county: p.county ?? null,
          region: p.region ?? null,
          country_a: p.country_a ?? null,
          layer: p.layer ?? null,
          coordinates: coordinates,
        };
      },
    );

    throw new Error(
      stage + ": no encontramos una coincidencia segura para " +
      streetAddress + " en Totoras. Resultados: " +
      features.length + "; resultados identificados en Totoras: " +
      townFeatures.length + ". Muestras: " + JSON.stringify(samples),
    );
  }

  const coordinates = feature.geometry?.coordinates;

  if (
    !Array.isArray(coordinates) ||
    coordinates.length < 2 ||
    !Number.isFinite(Number(coordinates[0])) ||
    !Number.isFinite(Number(coordinates[1]))
  ) {
    throw new Error(stage + ": el resultado no tiene coordenadas validas.");
  }

  return {
    longitude: Number(coordinates[0]),
    latitude: Number(coordinates[1]),
  };
}
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return response({ error: "Método no permitido." }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const orsKey = Deno.env.get("OPENROUTESERVICE_API_KEY");

    if (!supabaseUrl || !serviceRoleKey || !orsKey) {
      throw new Error(
        "Falta configurar una variable secreta en Supabase.",
      );
    }

    const body = await request.json();
    const storeId = String(body.store_id ?? "");
    const destinationAddress = String(
      body.destination_address ?? "",
    ).trim();

    if (storeId !== ALLOWED_STORE_ID) {
      return response(
        { error: "Este comercio todavía no está habilitado para calcular envíos." },
        403,
      );
    }

    if (
      destinationAddress.length < 5 ||
      destinationAddress.length > 250
    ) {
      return response(
        { error: "Ingresá una dirección de entrega válida." },
        400,
      );
    }

    // Consultar el comercio en Supabase.
    const merchantResponse = await fetch(
      `${supabaseUrl}/rest/v1/merchants?id=eq.${ALLOWED_STORE_ID}&select=id,name,address,city,latitude,longitude`,
      {
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
        },
      },
    );

    if (!merchantResponse.ok) {
      throw new Error("No se pudo consultar el comercio en Supabase.");
    }

    const merchants = await merchantResponse.json();
    const merchant = merchants[0];

    if (!merchant) {
      throw new Error("No encontramos el comercio.");
    }

    if (
      !String(merchant.city ?? "").toLowerCase().includes("totoras")
    ) {
      throw new Error("El comercio no está habilitado en Totoras.");
    }

    if (!merchant.address) {
      throw new Error("El comercio no tiene una dirección configurada.");
    }

    // Usar coordenadas guardadas o geocodificar el comercio.
    let origin;

    const hasCoordinates =
      merchant.latitude !== null &&
      merchant.longitude !== null &&
      String(merchant.latitude).trim() !== "" &&
      String(merchant.longitude).trim() !== "" &&
      Number.isFinite(Number(merchant.latitude)) &&
      Number.isFinite(Number(merchant.longitude));

    if (hasCoordinates) {
      origin = {
        latitude: Number(merchant.latitude),
        longitude: Number(merchant.longitude),
      };
    } else {
      origin = await geocodeAddress(merchant.address, orsKey, "comercio Banana Loca");

      // Guardar las coordenadas del comercio para próximos pedidos.
      const updateResponse = await fetch(
        `${supabaseUrl}/rest/v1/merchants?id=eq.${ALLOWED_STORE_ID}`,
        {
          method: "PATCH",
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
            "Content-Type": "application/json",
            Prefer: "return=minimal",
          },
          body: JSON.stringify({
            latitude: origin.latitude,
            longitude: origin.longitude,
          }),
        },
      );

      if (!updateResponse.ok) {
        throw new Error("No se pudieron guardar las coordenadas del comercio.");
      }
    }

    // Buscar la dirección de entrega, limitada a Totoras.
    const rawDestinationLatitude = body.destination_latitude;
const rawDestinationLongitude = body.destination_longitude;

const destinationLatitude = Number(rawDestinationLatitude);
const destinationLongitude = Number(rawDestinationLongitude);

if (
  rawDestinationLatitude === null ||
  rawDestinationLatitude === undefined ||
  rawDestinationLongitude === null ||
  rawDestinationLongitude === undefined ||
  !Number.isFinite(destinationLatitude) ||
  !Number.isFinite(destinationLongitude) ||
  destinationLatitude < -90 ||
  destinationLatitude > 90 ||
  destinationLongitude < -180 ||
  destinationLongitude > 180
) {
  throw new Error("Las coordenadas de entrega no son validas.");
}

const destination = {
  latitude: destinationLatitude,
  longitude: destinationLongitude,
};
// Calcular el recorrido real por calles.
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
            [origin.longitude, origin.latitude],
            [destination.longitude, destination.latitude],
          ],
          instructions: false,
        }),
      },
    );

    if (!routeResponse.ok) {
      const detail = await routeResponse.text();
      throw new Error(
        `Error al calcular el recorrido (${routeResponse.status}): ${detail.slice(0, 200)}`,
      );
    }

    const routeData = await routeResponse.json();
    const summary = routeData.features?.[0]?.properties?.summary;

    if (
      !summary ||
      !Number.isFinite(Number(summary.distance)) ||
      !Number.isFinite(Number(summary.duration)) ||
      Number(summary.distance) <= 0
    ) {
      throw new Error("No se pudo obtener una ruta válida.");
    }

    const distanceMeters = Number(summary.distance);
    const rawKm = distanceMeters / 1000;

    const deliveryKm = Number(rawKm.toFixed(2));
    const deliveryFee = Math.max(
      MIN_DELIVERY_FEE,
      Math.round(rawKm * PRICE_PER_KM),
    );

    return response({
      ok: true,
      delivery_km: deliveryKm,
      delivery_fee: deliveryFee,
      service_fee: SERVICE_FEE,
      estimated_duration_minutes: Math.ceil(
        Number(summary.duration) / 60,
      ),
      currency: "ARS",
    });
  } catch (error) {
    console.error("calculate-delivery-route:", error);

    return response(
      {
        error: error instanceof Error
          ? error.message
          : "No se pudo calcular el recorrido.",
      },
      500,
    );
  }
});