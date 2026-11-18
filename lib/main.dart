import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'widgets/delivery_location_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  runApp(const MovaApp());
}

const Color wine = Color(0xFF651F35);
const Color darkWine = Color(0xFF401321);
const Color cream = Color(0xFFFAF6F2);
const Color rose = Color(0xFFEAD9DC);
const Color softRose = Color(0xFFF4E9E9);

class MovaApp extends StatelessWidget {
  const MovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOVA',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: wine,
          primary: wine,
          surface: cream,
        ),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: rose),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: wine, width: 1.5),
          ),
        ),
      ),
      home: const MovaSessionGate(),
    );
  }
}

// MODELOS DE DATOS

class Product {
  final String? id;
  final String name;
  final String description;
  final double price;
  final String emoji;
  final bool isAvailable;
  final String? imageBase64;
  final String? imagePath;
  final String? imageExtension;

  const Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    this.isAvailable = true,
    this.imageBase64,
    this.imagePath,
    this.imageExtension,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? emoji,
    bool? isAvailable,
    String? imageBase64,
    String? imagePath,
    String? imageExtension,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      emoji: emoji ?? this.emoji,
      isAvailable: isAvailable ?? this.isAvailable,
      imageBase64: imageBase64 ?? this.imageBase64,
      imagePath: imagePath ?? this.imagePath,
      imageExtension: imageExtension ?? this.imageExtension,
    );
  }
}

Map<String, dynamic> movaProductToJson(Product product) {
  return {
    'name': product.name,
    'description': product.description,
    'price': product.price,
    'id': product.id,
    'emoji': product.emoji,
    'isAvailable': product.isAvailable,
    'imageBase64': product.imageBase64,
    'imagePath': product.imagePath,
    'imageExtension': product.imageExtension,
  };
}

Product movaProductFromJson(Map<String, dynamic> json) {
  return Product(
    id: json['id'] as String?,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    price: (json['price'] as num).toDouble(),
    emoji: json['emoji'] as String? ?? '📦',
    isAvailable: json['isAvailable'] as bool? ?? true,
    imageBase64: json['imageBase64'] as String?,
    imagePath: json['imagePath'] as String?,
    imageExtension: json['imageExtension'] as String?,
  );
}

Widget productThumbnail(
  Product product, {
  double size = 56,
  double emojiSize = 30,
}) {
  Widget fallback() {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(product.emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }

  final imagePath = product.imagePath;

  if (imagePath != null && imagePath.isNotEmpty) {
    final imageUrl = Supabase.instance.client.storage
        .from('product-images')
        .getPublicUrl(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        ),
      ),
    );
  }

  final image = product.imageBase64;

  if (image == null || image.isEmpty) {
    return fallback();
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: size,
      height: size,
      child: Image.memory(
        base64Decode(image),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      ),
    ),
  );
}

class Store {
  final String? id;
  final String name;
  final String category;
  final String emoji;
  final String description;
  final String city;
  final String? imagePath;
  final List<Product> products;

  const Store({
    this.id,
    this.city = '',
    this.imagePath,
    required this.name,
    required this.category,
    required this.emoji,
    required this.description,
    required this.products,
  });
}

Widget storeCoverImage(
  Store store, {
  double width = 65,
  double height = 65,
  double emojiSize = 34,
}) {
  Widget fallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: softRose,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(store.emoji, style: TextStyle(fontSize: emojiSize)),
    );
  }

  final imagePath = store.imagePath;

  if (imagePath == null || imagePath.isEmpty) {
    return fallback();
  }

  final imageUrl = Supabase.instance.client.storage
      .from('product-images')
      .getPublicUrl(imagePath);

  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: width,
      height: height,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      ),
    ),
  );
}

const List<String> movaOrderStatuses = [
  'Pendiente',
  'Aceptado',
  'Preparando',
  'En camino',
  'Entregado',
];

class MovaOrder {
  final String id;
  final String? databaseId;
  final String? storeId;
  final String storeName;
  final List<Product> products;
  final double total;
  final String address;
  final String notes;
  final DateTime createdAt;
  String status;
  String? driverId;

  MovaOrder({
    required this.id,
    this.databaseId,
    this.storeId,
    required this.storeName,
    required this.products,
    required this.total,
    required this.address,
    required this.notes,
    required this.createdAt,
    required this.status,
    this.driverId,
  });
}

Map<String, dynamic> movaOrderToJson(MovaOrder order) {
  return {
    'id': order.id,
    'databaseId': order.databaseId,
    'storeId': order.storeId,
    'storeName': order.storeName,
    'products': order.products
        .map(
          (product) => {
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'emoji': product.emoji,
            'isAvailable': product.isAvailable,
          },
        )
        .toList(),
    'total': order.total,
    'address': order.address,
    'notes': order.notes,
    'createdAt': order.createdAt.toIso8601String(),
    'status': order.status,
    'driverId': order.driverId,
  };
}

MovaOrder movaOrderFromJson(Map<String, dynamic> json) {
  final savedProducts = json['products'] as List<dynamic>;

  return MovaOrder(
    id: json['id'] as String,
    databaseId: json['databaseId'] as String?,
    storeId: json['storeId'] as String?,
    storeName: json['storeName'] as String? ?? 'Comercio no identificado',
    products: savedProducts.map((item) {
      final product = Map<String, dynamic>.from(item as Map);

      return Product(
        name: product['name'] as String,
        description: product['description'] as String,
        price: (product['price'] as num).toDouble(),
        emoji: product['emoji'] as String,
        isAvailable: product['isAvailable'] as bool? ?? true,
      );
    }).toList(),
    total: (json['total'] as num).toDouble(),
    address: json['address'] as String,
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    status: json['status'] as String? ?? 'Pendiente',
    driverId: json['driverId'] as String?,
  );
}

final List<Store> stores = [
  Store(
    name: 'Burger House',
    category: 'Hamburguesas',
    emoji: '🍔',
    description: 'Hamburguesas y comidas rápidas',
    products: [
      Product(
        name: 'Hamburguesa clásica',
        description: 'Carne, queso, lechuga y tomate',
        price: 6500,
        emoji: '🍔',
      ),
      Product(
        name: 'Hamburguesa completa',
        description: 'Carne, queso, huevo y panceta',
        price: 8500,
        emoji: '🍔',
      ),
      Product(
        name: 'Papas fritas',
        description: 'Porción de papas',
        price: 3500,
        emoji: '🍟',
      ),
    ],
  ),
  Store(
    name: 'Pizza Club',
    category: 'Pizzerías',
    emoji: '🍕',
    description: 'Pizzas para compartir',
    products: [
      Product(
        name: 'Pizza muzzarella',
        description: 'Salsa, muzzarella y aceitunas',
        price: 9000,
        emoji: '🍕',
      ),
      Product(
        name: 'Pizza especial',
        description: 'Jamón, morrones y muzzarella',
        price: 11000,
        emoji: '🍕',
      ),
    ],
  ),
  Store(
    name: 'Heladería Central',
    category: 'Heladerías',
    emoji: '🍦',
    description: 'Helados y postres',
    products: [
      Product(
        name: 'Cuarto kilo',
        description: 'Elegí tus sabores',
        price: 5000,
        emoji: '🍦',
      ),
      Product(
        name: 'Medio kilo',
        description: 'Elegí tus sabores',
        price: 8500,
        emoji: '🍨',
      ),
    ],
  ),
  Store(
    name: 'Almacén Don Pedro',
    category: 'Almacenes',
    emoji: '🛒',
    description: 'Almacén y productos diarios',
    products: [
      Product(
        name: 'Leche',
        description: 'Leche larga vida',
        price: 1800,
        emoji: '🥛',
      ),
      Product(
        name: 'Yerba',
        description: 'Paquete de 1 kg',
        price: 4500,
        emoji: '🧉',
      ),
    ],
  ),
  Store(
    name: 'Verdulería Verde',
    category: 'Verdulerías',
    emoji: '🥑',
    description: 'Frutas y verduras frescas',
    products: [
      Product(
        name: 'Manzanas',
        description: 'Por kilo',
        price: 2500,
        emoji: '🍎',
      ),
      Product(
        name: 'Bananas',
        description: 'Por kilo',
        price: 2200,
        emoji: '🍌',
      ),
    ],
  ),
  Store(
    name: 'Farmacia Central',
    category: 'Farmacias',
    emoji: '💊',
    description: 'Farmacia y perfumería',
    products: [
      Product(
        name: 'Alcohol en gel',
        description: 'Envase de 250 ml',
        price: 2500,
        emoji: '🧴',
      ),
      Product(
        name: 'Apósitos',
        description: 'Paquete',
        price: 1500,
        emoji: '🩹',
      ),
    ],
  ),
];

class MovaSessionGate extends StatelessWidget {
  const MovaSessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const WelcomeScreen();
    }

    final accountType = session.user.userMetadata?['account_type']?.toString();

    if (accountType == 'customer') {
      return const CustomerHome();
    }

    if (accountType == 'merchant') {
      return const MerchantOwnerGate();
    }

    return const WelcomeScreen();
  }
}

// PANTALLA DE BIENVENIDA

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkWine, wine, Color(0xFF8D4057)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text(
                    'MOVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Todo lo que querés,\na un pedido de distancia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cream,
                      foregroundColor: wine,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RoleScreen()),
                      );
                    },
                    child: const Text(
                      'COMENZAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MovaAuthScreen extends StatefulWidget {
  final String accountType;
  final WidgetBuilder destinationBuilder;

  const MovaAuthScreen({
    super.key,
    required this.accountType,
    required this.destinationBuilder,
  });

  @override
  State<MovaAuthScreen> createState() => _MovaAuthScreenState();
}

class _MovaAuthScreenState extends State<MovaAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegistering = true;
  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String get accountLabel => widget.accountType == 'merchant'
      ? 'comerciante'
      : widget.accountType == 'driver'
      ? 'repartidor'
      : 'cliente';

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      if (isRegistering) {
        final response = await client.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          data: {
            'full_name': nameController.text.trim(),
            'account_type': widget.accountType == 'driver'
                ? 'customer'
                : widget.accountType,
          },
        );

        if (response.session == null || response.user == null) {
          showMessage(
            'Cuenta creada. Revisá tu correo para confirmar el registro. '
            'Después podrás iniciar sesión.',
          );
          return;
        }

        await client.from('profiles').upsert({
          'user_id': response.user!.id,
          'full_name': nameController.text.trim(),
        });
      } else {
        final response = await client.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        final user = response.user;

        if (user == null) {
          throw Exception('No se pudo recuperar la cuenta.');
        }

        final savedRole = user.userMetadata?['account_type']?.toString();

        if (widget.accountType != 'driver' &&
            savedRole != null &&
            savedRole != widget.accountType) {
          await client.auth.signOut();

          showMessage(
            'Esta cuenta corresponde a otro tipo de usuario. '
            'Elegí el acceso correcto.',
          );
          return;
        }

        final metadataName = user.userMetadata?['full_name']?.toString() ?? '';

        final profile = <String, dynamic>{'user_id': user.id};

        if (metadataName.isNotEmpty) {
          profile['full_name'] = metadataName;
        }

        await client.from('profiles').upsert(profile);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: widget.destinationBuilder),
      );
    } on AuthException catch (error) {
      showMessage('Error de acceso: ${error.message}');
    } catch (error) {
      showMessage('No se pudo completar la operación: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'MOVA',
          style: TextStyle(
            color: wine,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_pin_circle_outlined,
                    color: wine,
                    size: 65,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isRegistering
                        ? 'Creá tu cuenta de $accountLabel'
                        : 'Bienvenido nuevamente',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: darkWine,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isRegistering
                        ? 'Sumate a la comunidad MOVA.'
                        : 'Ingresá tus datos para continuar.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  if (isRegistering) ...[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline, color: wine),
                      ),
                      validator: (value) {
                        if (isRegistering &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Ingresá tu nombre.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined, color: wine),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Ingresá un correo válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, color: wine),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Usá al menos 8 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: wine,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isRegistering ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              isRegistering = !isRegistering;
                            });
                          },
                    child: Text(
                      isRegistering
                          ? '¿Ya tenés cuenta? Iniciá sesión'
                          : '¿Todavía no tenés cuenta? Registrate',
                      style: const TextStyle(color: wine),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ELECCIÓN DE TIPO DE USUARIO

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'MOVA',
          style: TextStyle(
            color: wine,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            const Text(
              '¿Qué querés hacer?',
              style: TextStyle(
                color: darkWine,
                fontSize: 29,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Elegí cómo querés formar parte de MOVA.',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 30),
            RoleCard(
              emoji: '🛍️',
              title: 'QUIERO HACER UN PEDIDO',
              description: 'Descubrí comercios y productos de tu zona.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovaAuthScreen(
                      accountType: 'customer',
                      destinationBuilder: (_) => const CustomerHome(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 17),
            RoleCard(
              emoji: '🏪',
              title: 'TENGO UN COMERCIO',
              description: 'Sumá tu negocio y ofrecé tus productos en MOVA.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovaAuthScreen(
                      accountType: 'merchant',
                      destinationBuilder: (_) => const MerchantOwnerGate(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 17),
            RoleCard(
              emoji: '🛵',
              title: 'QUIERO TRABAJAR EN MOVA',
              description: 'Dejanos tus datos para postularte como repartidor.',
              onTap: () {
                final currentUser = Supabase.instance.client.auth.currentUser;

                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RegistrationScreen(isBusiness: false),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovaAuthScreen(
                        accountType: 'driver',
                        destinationBuilder: (_) =>
                            const RegistrationScreen(isBusiness: false),
                      ),
                    ),
                  );
                }
              },
            ),
            const Spacer(),
            Center(
              child: Text(
                'MOVA · Tu ciudad, más conectada.',
                style: TextStyle(color: wine.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: rose),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: wine,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: wine, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

// REGISTRO DE COMERCIOS Y REPARTIDORES

class RegistrationScreen extends StatefulWidget {
  final bool isBusiness;

  const RegistrationScreen({super.key, required this.isBusiness});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final detailController = TextEditingController();

  String? selectedBusinessCategory;
  String? selectedVehicleType;
  bool isSubmitting = false;

  PlatformFile? selectedPdf;
  PlatformFile? selectedVideo;

  @override
  void initState() {
    super.initState();

    if (!widget.isBusiness) {
      emailController.text =
          Supabase.instance.client.auth.currentUser?.email ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cityController.dispose();
    detailController.dispose();
    super.dispose();
  }

  Future<void> pickPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (!mounted) return;

    if (files.isNotEmpty) {
      setState(() {
        selectedPdf = files.first;
      });
    }
  }

  Future<void> pickVideo() async {
    final files = await FilePicker.pickFiles(type: FileType.video);

    if (!mounted) return;

    if (files.isNotEmpty) {
      setState(() {
        selectedVideo = files.first;
      });
    }
  }

  Future<void> submitDriverApplication() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciá sesión para enviar tu postulación.'),
        ),
      );
      return;
    }

    if (selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná tu tipo de vehículo.')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final existing = await client
          .from('delivery_drivers')
          .select('status')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        final status = existing['status']?.toString();

        final statusText = switch (status) {
          'approved' => 'aprobada',
          'rejected' => 'rechazada',
          'suspended' => 'suspendida',
          _ => 'pendiente de revisión',
        };

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya tenés una solicitud registrada: $statusText.'),
          ),
        );
        return;
      }

      // Guardar los datos personales en el perfil de la cuenta.
      await client.from('profiles').upsert({
        'user_id': user.id,
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      });

      // Crear la solicitud. Supabase asigna el estado "pending".
      await client.from('delivery_drivers').insert({
        'user_id': user.id,
        'vehicle_type': selectedVehicleType,
        'city': cityController.text.trim().isEmpty
            ? null
            : cityController.text.trim(),
        'description': detailController.text.trim().isEmpty
            ? null
            : detailController.text.trim(),
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '¡Solicitud enviada!',
            style: TextStyle(color: wine, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Recibimos tu postulación para trabajar como repartidor. '
            'Tu solicitud quedó pendiente de aprobación. '
            'Te avisaremos cuando sea revisada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ENTENDIDO', style: TextStyle(color: wine)),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error enviando solicitud de repartidor: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo enviar la solicitud. Revisá tu conexión e intentá nuevamente. ($error)',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!widget.isBusiness) {
      await submitDriverApplication();
      return;
    }
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciá sesión para enviar tu solicitud.'),
        ),
      );
      return;
    }

    final category = selectedBusinessCategory;

    if (category == null) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      await client.from('merchant_applications').insert({
        'contact_name': nameController.text.trim(),
        'business_name': detailController.text.trim(),
        'category': category,
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'city': cityController.text.trim(),
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '¡Solicitud enviada!',
            style: TextStyle(color: wine, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Recibimos los datos de tu comercio. '
            'Nuestro equipo revisará la solicitud. '
            'Te avisaremos cuando sea aprobada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ENTENDIDO', style: TextStyle(color: wine)),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error enviando solicitud de comercio: $error');

      if (!mounted) return;

      final message =
          error.toString().contains('idx_merchant_applications_pending')
          ? 'Ya tenés una solicitud pendiente de revisión.'
          : 'No se pudo enviar la solicitud. Revisá tu conexión e intentá nuevamente.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = widget.isBusiness;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: Text(
          isBusiness ? 'Sumá tu comercio' : 'Trabajá con MOVA',
          style: const TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(23),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  isBusiness ? '🏪' : '🛵',
                  style: const TextStyle(fontSize: 55),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                isBusiness
                    ? 'Hacé crecer tu negocio.'
                    : 'Sumate al equipo MOVA.',
                style: const TextStyle(
                  color: darkWine,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isBusiness
                    ? 'Completá tus datos y contanos sobre tu comercio. '
                          'Nos pondremos en contacto para conocer tu propuesta.'
                    : 'Completá tus datos para postularte como repartidor. '
                          'Te contactaremos cuando MOVA tenga incorporaciones disponibles.',
                style: const TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 27),
              buildLabel(
                isBusiness ? 'Nombre del responsable' : 'Nombre completo',
              ),
              buildField(
                controller: nameController,
                hint: isBusiness ? 'Nombre y apellido' : 'Tu nombre',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 17),
              buildLabel(
                isBusiness ? 'Nombre del comercio' : 'Teléfono de contacto',
              ),
              if (isBusiness)
                buildField(
                  controller: detailController,
                  hint: 'Nombre de tu negocio',
                  icon: Icons.storefront_outlined,
                )
              else
                buildField(
                  controller: phoneController,
                  hint: 'Tu número de teléfono',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              if (!isBusiness) ...[
                const SizedBox(height: 17),
                buildLabel('Tipo de vehículo'),
                DropdownButtonFormField<String>(
                  initialValue: selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Seleccioná tu vehículo',
                    prefixIcon: Icon(Icons.delivery_dining, color: wine),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Bicicleta',
                      child: Text('Bicicleta'),
                    ),
                    DropdownMenuItem(value: 'Moto', child: Text('Moto')),
                    DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedVehicleType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Seleccioná un vehículo.';
                    }
                    return null;
                  },
                ),
              ],
              if (isBusiness) ...[
                const SizedBox(height: 17),
                buildLabel('Categoría del comercio'),
                DropdownButtonFormField<String>(
                  initialValue: selectedBusinessCategory,
                  decoration: const InputDecoration(
                    labelText: 'Seleccioná una categoría',
                    prefixIcon: Icon(Icons.category_outlined, color: wine),
                  ),
                  items:
                      const [
                        'Hamburguesas',
                        'Pizzerías',
                        'Heladerías',
                        'Almacenes',
                        'Verdulerías',
                        'Farmacias',
                        'Otros comercios',
                      ].map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBusinessCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Seleccioná una categoría.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 17),
              buildLabel(
                isBusiness ? 'Teléfono de contacto' : 'Correo electrónico',
              ),
              if (isBusiness)
                buildField(
                  controller: phoneController,
                  hint: 'Teléfono del comercio',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                )
              else
                TextFormField(
                  controller: emailController,
                  readOnly: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo de tu cuenta',
                    prefixIcon: Icon(Icons.email_outlined, color: wine),
                  ),
                ),
              const SizedBox(height: 17),
              buildLabel(isBusiness ? 'Correo electrónico' : 'Localidad'),
              if (isBusiness)
                buildField(
                  controller: emailController,
                  hint: 'correo@ejemplo.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                )
              else
                buildField(
                  controller: cityController,
                  hint: '¿En qué localidad vivís?',
                  icon: Icons.location_on_outlined,
                ),
              const SizedBox(height: 17),
              buildLabel(
                isBusiness
                    ? 'Localidad del comercio'
                    : 'Contanos algo más (opcional)',
              ),
              buildField(
                controller: isBusiness ? cityController : detailController,
                hint: isBusiness
                    ? '¿En qué localidad está tu negocio?'
                    : 'Experiencia, disponibilidad, etc.',
                icon: Icons.edit_note,
                requiredField: isBusiness,
                maxLines: 3,
              ),
              if (!isBusiness) ...[
                const SizedBox(height: 25),

                buildLabel('DOCUMENTACIÓN Y PRESENTACIÓN'),

                const Text(
                  'Podés adjuntar tu documentación y un video de presentación (ambos opcionales).',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),

                const SizedBox(height: 15),

                OutlinedButton.icon(
                  onPressed: pickPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(
                    selectedPdf == null ? 'ADJUNTAR PDF' : 'CAMBIAR PDF',
                  ),
                ),

                if (selectedPdf != null)
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: wine),
                    title: Text(selectedPdf!.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => selectedPdf = null),
                    ),
                  ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: pickVideo,
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(
                    selectedVideo == null ? 'ADJUNTAR VIDEO' : 'CAMBIAR VIDEO',
                  ),
                ),

                if (selectedVideo != null)
                  ListTile(
                    leading: const Icon(Icons.video_file_outlined, color: wine),
                    title: Text(selectedVideo!.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => selectedVideo = null),
                    ),
                  ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isBusiness
                              ? 'ENVIAR MI COMERCIO'
                              : 'ENVIAR SOLICITUD',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: darkWine, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (requiredField && (value == null || value.trim().isEmpty)) {
          return 'Completá este campo';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: wine),
      ),
    );
  }
}

// INTERFAZ PARA CLIENTES

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int selectedTab = 0;
  String selectedCategory = 'Todos';
  String searchText = '';

  final List<Product> cart = [];
  String? selectedStoreName;
  final List<MovaOrder> orders = [];
  int nextOrderNumber = 1;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool _loadingOrders = true;
  bool _refreshingOrders = false;
  Timer? _ordersRefreshTimer;
  bool _loadingCatalog = true;

  late final Future<bool> _adminAccessFuture = _checkAdminAccess();

  final List<String> categories = [
    'Todos',
    'Hamburguesas',
    'Pizzerías',
    'Heladerías',
    'Almacenes',
    'Verdulerías',
    'Farmacias',
    'Otros comercios',
  ];

  double get total {
    return cart.fold(0, (sum, product) => sum + product.price);
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadCatalog();
    _ordersRefreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) unawaited(_loadOrders());
    });
  }

  Future<bool> _checkAdminAccess() async {
    try {
      final result = await Supabase.instance.client.rpc('mova_is_admin');
      return result == true;
    } catch (error) {
      debugPrint('No se pudo comprobar el acceso de administrador: $error');
      return false;
    }
  }

  Future<void> _loadOrders() async {
    if (_refreshingOrders) return;
    _refreshingOrders = true;

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() => _loadingOrders = false);
        }
        return;
      }

      final orderRows = await client
          .from('orders')
          .select(
            'id,order_number,store_id,status,total,delivery_address,delivery_notes,driver_id,created_at,order_items(product_name,quantity,unit_price,emoji)',
          )
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      final previousOrders = <String, MovaOrder>{
        for (final order in orders)
          if (order.databaseId != null) order.databaseId!: order,
      };

      final loadedOrders = <MovaOrder>[];

      for (final item in orderRows) {
        final row = Map<String, dynamic>.from(item);
        final databaseId = row['id']?.toString();
        final storeId = row['store_id']?.toString();

        if (databaseId == null || storeId == null) continue;

        final rawItems = row['order_items'];
        final products = <Product>[];

        if (rawItems is List) {
          for (final rawItem in rawItems) {
            final itemRow = Map<String, dynamic>.from(rawItem as Map);
            final quantity = (itemRow['quantity'] as num?)?.toInt() ?? 1;
            final price = itemRow['unit_price'];

            if (price is! num || quantity < 1) continue;

            final product = Product(
              name: itemRow['product_name']?.toString() ?? 'Producto',
              description: '',
              price: price.toDouble(),
              emoji: itemRow['emoji']?.toString() ?? '📦',
            );

            for (var i = 0; i < quantity; i++) {
              products.add(product);
            }
          }
        }

        final previous = previousOrders[databaseId];

        loadedOrders.add(
          MovaOrder(
            id: row['order_number']?.toString() ?? databaseId,
            databaseId: databaseId,
            storeId: storeId,
            storeName: previous?.storeName ?? 'Comercio',
            products: products,
            total: (row['total'] as num?)?.toDouble() ?? 0,
            address: row['delivery_address']?.toString() ?? '',
            notes: row['delivery_notes']?.toString() ?? '',
            createdAt:
                DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                DateTime.now(),
            status: row['status']?.toString() ?? 'Pendiente',
            driverId: row['driver_id']?.toString(),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        orders
          ..clear()
          ..addAll(loadedOrders);
        _loadingOrders = false;
      });
    } catch (error) {
      debugPrint('Error sincronizando pedidos del cliente: $error');

      if (mounted) {
        setState(() => _loadingOrders = false);
      }
    } finally {
      _refreshingOrders = false;
    }
  }

  Future<void> _saveOrders() async {
    final ordersJson = jsonEncode(orders.map(movaOrderToJson).toList());

    await _preferences.setString('mova_orders_v1', ordersJson);

    await _preferences.setInt('mova_next_order_number_v1', nextOrderNumber);
  }

  Future<void> _loadCatalog() async {
    try {
      final savedJson = await _preferences.getString('mova_catalog_v1');

      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson);

        if (decoded is Map) {
          final catalog = Map<String, dynamic>.from(decoded);

          for (final store in stores) {
            final savedProducts = catalog[store.name];

            if (savedProducts is List) {
              store.products
                ..clear()
                ..addAll(
                  savedProducts.map((item) {
                    return movaProductFromJson(
                      Map<String, dynamic>.from(item as Map),
                    );
                  }),
                );
            }
          }
        }
      }

      // Cargar también los comercios aprobados desde Supabase.
      await _loadCloudStores();
    } catch (error) {
      debugPrint('Error recuperando el catalogo: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingCatalog = false;
        });
      }
    }
  }

  Future<void> _loadCloudStores() async {
    try {
      final client = Supabase.instance.client;

      // Consultar comercios activos.
      final merchantRows = await client
          .from('merchants')
          .select('id,name,category,emoji,description,city,image_path')
          .eq('is_active', true)
          .order('name');

      // Consultar productos disponibles.
      List<dynamic> productRows = [];

      try {
        productRows = await client
            .from('products')
            .select(
              'id,store_id,name,description,price,emoji,is_available,image_path',
            )
            .eq('is_available', true);
      } catch (error) {
        debugPrint('No se pudieron cargar los productos online: $error');
      }

      // Agrupar productos por comercio.
      final productsByStore = <String, List<Product>>{};

      for (final item in productRows) {
        final row = Map<String, dynamic>.from(item as Map);
        final storeId = row['store_id']?.toString();
        final price = row['price'];

        if (storeId == null || price is! num) continue;

        final product = Product(
          id: row['id']?.toString(),
          name: row['name'] as String,
          description: row['description'] as String? ?? '',
          price: price.toDouble(),
          emoji: row['emoji'] as String? ?? '📦',
          isAvailable: row['is_available'] as bool? ?? true,
          imagePath: row['image_path'] as String?,
        );

        productsByStore.putIfAbsent(storeId, () => <Product>[]).add(product);
      }

      // Evitar duplicar comercios online al volver a cargar.
      stores.removeWhere((store) => store.id != null);

      // Incorporar los comercios activos al catálogo.
      for (final item in merchantRows) {
        final row = Map<String, dynamic>.from(item as Map);

        final storeId = row['id']?.toString();
        final name = row['name'] as String? ?? '';

        if (storeId == null || name.trim().isEmpty) continue;

        final remoteProducts = productsByStore[storeId] ?? <Product>[];

        stores.add(
          Store(
            id: storeId,
            name: name,
            category: row['category'] as String? ?? 'Otros comercios',
            emoji: row['emoji'] as String? ?? '🏪',
            description: row['description'] as String? ?? '',
            city: row['city'] as String? ?? '',
            imagePath: row['image_path'] as String?,
            products: remoteProducts,
          ),
        );
      }

      debugPrint('Comercios online cargados: ${merchantRows.length}');
    } catch (error) {
      debugPrint('Error cargando comercios desde Supabase: $error');
    }
  }

  Future<String> registerOrder({
    required List<Product> products,
    required String storeName,
    required String address,
    required String notes,
    required String paymentMethod,
  }) async {
    final client = Supabase.instance.client;

    if (client.auth.currentUser == null) {
      throw Exception('Tu sesión venció. Iniciá sesión nuevamente.');
    }

    if (products.isEmpty) {
      throw Exception('El carrito está vacío.');
    }

    Store? selectedStore;

    for (final store in stores) {
      if (store.name == storeName && store.id != null) {
        selectedStore = store;
        break;
      }
    }

    final store = selectedStore;

    if (store == null) {
      throw Exception(
        'Este comercio todavía no está conectado a MOVA. '
        'Probá con un comercio adherido.',
      );
    }

    final storeId = store.id!;
    final quantities = <String, int>{};

    for (final product in products) {
      final productId = product.id;

      if (productId == null ||
          !store.products.any((item) => item.id == productId)) {
        throw Exception(
          'Uno de los productos ya no está disponible. '
          'Actualizá el catálogo e intentá nuevamente.',
        );
      }

      quantities[productId] = (quantities[productId] ?? 0) + 1;
    }

    final items = quantities.entries.map((entry) {
      return {'product_id': entry.key, 'quantity': entry.value};
    }).toList();

    final response = await client.rpc(
      'mova_create_order',
      params: {
        'p_store_id': storeId,
        'p_items': items,
        'p_delivery_address': address.trim(),
        'p_delivery_notes': notes.trim(),
        'p_payment_method': paymentMethod,
      },
    );

    if (response is! Map) {
      throw Exception('Supabase devolvió una respuesta inesperada.');
    }

    final result = Map<String, dynamic>.from(response);
    final databaseId = result['id'] as String?;
    final orderNumber = result['order_number'] as String?;

    if (databaseId == null || orderNumber == null) {
      throw Exception('No se recibió la confirmación del pedido.');
    }

    final order = MovaOrder(
      id: orderNumber,
      databaseId: databaseId,
      storeId: storeId,
      storeName: storeName,
      products: List<Product>.unmodifiable(products),
      total: (result['total'] as num).toDouble(),
      address: address.trim(),
      notes: notes.trim(),
      createdAt: DateTime.now(),
      status: result['status'] as String? ?? 'Pendiente',
    );

    if (!mounted) {
      throw Exception('La pantalla se cerró antes de completar el pedido.');
    }

    setState(() {
      orders.insert(0, order);
      nextOrderNumber++;
      cart.clear();
      selectedStoreName = null;
      selectedTab = 3;
    });

    unawaited(_saveOrders());

    return orderNumber;
  }

  void addToCart(Product product, String storeName) {
    if (cart.isNotEmpty && selectedStoreName != storeName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tu carrito contiene productos de $selectedStoreName.'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VACIAR Y AGREGAR',
            onPressed: () {
              if (!mounted) return;

              setState(() {
                cart
                  ..clear()
                  ..add(product);
                selectedStoreName = storeName;
              });
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      selectedStoreName = storeName;
      cart.add(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al carrito'),
        duration: const Duration(seconds: 1),
        backgroundColor: wine,
      ),
    );
  }

  @override
  void dispose() {
    _ordersRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingOrders || _loadingCatalog) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      buildHome(),
      buildExplore(),
      buildCart(),
      buildOrders(),
      buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'MOVA',
          style: TextStyle(
            color: wine,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => selectedTab = 2),
            icon: Badge(
              isLabelVisible: cart.isNotEmpty,
              label: Text('${cart.length}'),
              child: const Icon(Icons.shopping_bag_outlined, color: wine),
            ),
          ),
        ],
      ),
      body: pages[selectedTab],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: rose,
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: wine),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: wine),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cart.isNotEmpty,
              label: Text('${cart.length}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart, color: wine),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: wine),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: wine),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Hola! 👋',
            style: TextStyle(
              color: darkWine,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '¿Qué necesitás hoy?',
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) {
              setState(() => searchText = value);
            },
            decoration: const InputDecoration(
              hintText: 'Buscá comercios o productos...',
              prefixIcon: Icon(Icons.search, color: wine),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Categorías',
            style: TextStyle(
              color: darkWine,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((category) {
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedCategory = category);
                  },
                  child: Container(
                    width: 85,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selectedCategory == category ? wine : Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: rose),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          categoryEmoji(category),
                          style: const TextStyle(fontSize: 27),
                        ),
                        const SizedBox(height: 7),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            category,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: selectedCategory == category
                                  ? Colors.white
                                  : wine,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [wine, Color(0xFF96546A)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODO CERCA TUYO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Los comercios de tu ciudad, en un solo lugar.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Comercios disponibles',
            style: TextStyle(
              color: darkWine,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...filteredStores().map(
            (store) => StoreCard(store: store, onTap: () => openStore(store)),
          ),
        ],
      ),
    );
  }

  Widget buildExplore() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explorar',
            style: TextStyle(
              color: darkWine,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Encontrá lo que buscás en tu ciudad.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) {
              setState(() => searchText = value);
            },
            decoration: const InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: Icon(Icons.search, color: wine),
            ),
          ),
          const SizedBox(height: 20),
          ...filteredStores().map(
            (store) => StoreCard(store: store, onTap: () => openStore(store)),
          ),
        ],
      ),
    );
  }

  List<Store> filteredStores() {
    return stores.where((store) {
      final matchesCategory =
          selectedCategory == 'Todos' || store.category == selectedCategory;

      final query = searchText.toLowerCase();

      final matchesSearch =
          store.name.toLowerCase().contains(query) ||
          store.category.toLowerCase().contains(query) ||
          store.city.toLowerCase().contains(query) ||
          store.products.any(
            (product) =>
                product.isAvailable &&
                product.name.toLowerCase().contains(query),
          );

      final hasAvailableProducts = store.products.any(
        (product) => product.isAvailable,
      );

      // Los comercios online aprobados también pueden mostrarse
      // aunque todavía no hayan cargado productos.
      final isOnlineStore = store.id != null;

      return (hasAvailableProducts || isOnlineStore) &&
          matchesCategory &&
          matchesSearch;
    }).toList();
  }

  Widget buildCart() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mi carrito',
            style: TextStyle(
              color: darkWine,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (cart.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🛍️', style: TextStyle(fontSize: 55)),
                    SizedBox(height: 12),
                    Text(
                      'Tu carrito está vacío',
                      style: TextStyle(
                        color: wine,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Agregá productos para comenzar.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final product = cart[index];
                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: productThumbnail(
                        product,
                        size: 56,
                        emojiSize: 28,
                      ),
                      title: Text(product.name),
                      subtitle: Text(formatPrice(product.price)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: wine),
                        onPressed: () {
                          setState(() {
                            cart.removeAt(index);
                            if (cart.isEmpty) {
                              selectedStoreName = null;
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                    color: wine,
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 53,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: wine,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        products: List<Product>.from(cart),
                        total: total,
                        storeName:
                            selectedStoreName ?? 'Comercio no identificado',
                        onConfirm: (address, notes, paymentMethod) =>
                            registerOrder(
                              products: List<Product>.from(cart),
                              storeName:
                                  selectedStoreName ??
                                  'Comercio no identificado',
                              address: address,
                              notes: notes,
                              paymentMethod: paymentMethod,
                            ),
                      ),
                    ),
                  );
                },
                child: const Text('CONTINUAR'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildOrders() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis pedidos',
            style: TextStyle(
              color: darkWine,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (orders.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🛍️', style: TextStyle(fontSize: 55)),
                    SizedBox(height: 12),
                    Text(
                      'Todavia no tenes pedidos',
                      style: TextStyle(
                        color: wine,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tus compras apareceran aqui.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final orderStatusIndex = movaOrderStatuses.indexOf(
                    order.status,
                  );

                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: rose),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.id,
                                style: const TextStyle(
                                  color: darkWine,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: rose,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.status,
                                  style: const TextStyle(
                                    color: wine,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value:
                                  (orderStatusIndex + 1) /
                                  movaOrderStatuses.length,
                              minHeight: 7,
                              backgroundColor: rose,
                              color: wine,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Etapa ${orderStatusIndex + 1} de ${movaOrderStatuses.length}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            order.storeName,
                            style: const TextStyle(
                              color: wine,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.products
                                .map(
                                  (product) =>
                                      '${product.emoji} ${product.name}',
                                )
                                .join('\n'),
                            style: const TextStyle(height: 1.7),
                          ),
                          const Divider(height: 24),
                          Text(
                            'Entrega: ${order.address}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (order.notes.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text('Indicaciones: ${order.notes}'),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: ${formatPrice(order.total)}',
                                style: const TextStyle(
                                  color: wine,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatOrderDate(order.createdAt),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget buildProfile() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mi perfil',
            style: TextStyle(
              color: darkWine,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          const CircleAvatar(
            radius: 38,
            backgroundColor: rose,
            child: Icon(Icons.person, color: wine, size: 40),
          ),
          const SizedBox(height: 15),
          const Text(
            'Bienvenido a MOVA',
            style: TextStyle(
              color: wine,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Muy pronto vas a poder crear tu cuenta, guardar tus '
            'direcciones y consultar tus pedidos.',
            style: TextStyle(color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 25),
          FutureBuilder<bool>(
            future: _adminAccessFuture,
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }

              return ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: wine,
                ),
                title: const Text('Panel de administración'),
                subtitle: const Text('Gestionar MOVA y sus repartidores'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MovaAdminDashboardScreen(),
                    ),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined, color: wine),
            title: const Text('Mi comercio'),
            subtitle: const Text('Acceder a tu negocio'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MerchantOwnerGate()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined, color: wine),
            title: const Text('Tengo un comercio'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegistrationScreen(isBusiness: true),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_ind_outlined, color: wine),
            title: const Text('Mi cuenta de repartidor'),
            subtitle: const Text('Consultar tu postulación y tus entregas'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverAccountScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delivery_dining, color: wine),
            title: const Text('Quiero trabajar en MOVA'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegistrationScreen(isBusiness: false),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void openStore(Store store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailScreen(store: store, onAdd: addToCart),
      ),
    );
  }
}

class DriverAccountScreen extends StatefulWidget {
  const DriverAccountScreen({super.key});

  @override
  State<DriverAccountScreen> createState() => _DriverAccountScreenState();
}

class _DriverAccountScreenState extends State<DriverAccountScreen> {
  Map<String, dynamic>? _driver;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Iniciá sesión para consultar tu cuenta.');
      }

      final result = await client
          .from('delivery_drivers')
          .select('status, vehicle_type, city, description, created_at')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _driver = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _driver?['status']?.toString() ?? '';
    final vehicle = _driver?['vehicle_type']?.toString() ?? '';
    final city = _driver?['city']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Mi cuenta de repartidor',
          style: TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadApplication,
            icon: const Icon(Icons.refresh, color: wine),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _error != null
          ? _buildMessage(
              Icons.error_outline,
              'No pudimos consultar tu cuenta',
              _error!,
              buttonText: 'REINTENTAR',
              onPressed: _loadApplication,
            )
          : _driver == null
          ? _buildMessage(
              Icons.delivery_dining,
              'Todavía no tenés una postulación',
              'Completá el formulario para solicitar trabajar como repartidor de MOVA.',
              buttonText: 'COMPLETAR POSTULACIÓN',
              onPressed: _openRegistration,
            )
          : status == 'approved'
          ? _buildMessage(
              Icons.verified,
              '¡Tu cuenta está aprobada!',
              'Vehículo: $vehicle\nLocalidad: ${city.isEmpty ? 'No especificada' : city}\n\nYa podés consultar tus entregas.',
              buttonText: 'VER MIS ENTREGAS',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverDashboardScreen(),
                  ),
                );
              },
            )
          : status == 'pending'
          ? _buildMessage(
              Icons.hourglass_top,
              'Postulación pendiente',
              'Recibimos tu solicitud. Nuestro equipo todavía debe revisarla.\n\nTe avisaremos cuando sea aprobada.',
            )
          : status == 'rejected'
          ? _buildMessage(
              Icons.info_outline,
              'Postulación no aprobada',
              'Tu solicitud no fue aprobada. Contactá al equipo de MOVA para consultar los próximos pasos.',
            )
          : _buildMessage(
              Icons.pause_circle_outline,
              'Cuenta suspendida',
              'Por el momento tu cuenta de repartidor está suspendida. Contactá al equipo de MOVA.',
            ),
    );
  }

  Widget _buildMessage(
    IconData icon,
    String title,
    String description, {
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: rose,
              child: Icon(icon, color: wine, size: 43),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkWine,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.6),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openRegistration() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrationScreen(isBusiness: false),
      ),
    );

    if (!mounted) return;
    await _loadApplication();
  }
}

// =====================================================
// 3. CREAR PANEL DE ENTREGAS
// =====================================================
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  String? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Tu sesión venció. Iniciá sesión nuevamente.');
      }

      final response = await client
          .from('orders')
          .select(
            'id, order_number, status, total, delivery_address, delivery_notes, created_at',
          )
          .eq('driver_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (showLoading && mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateOrder(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString();

    if (orderId == null || _busyOrderId != null) return;

    final currentStatus = order['status']?.toString() ?? '';

    final nextStatus = currentStatus == 'Preparando'
        ? 'En camino'
        : currentStatus == 'En camino'
        ? 'Entregado'
        : null;

    if (nextStatus == null) return;

    setState(() {
      _busyOrderId = orderId;
    });

    try {
      await Supabase.instance.client.rpc(
        'mova_update_order_status',
        params: {'p_order_id': orderId, 'p_new_status': nextStatus},
      );

      if (!mounted) return;

      await _loadOrders(showLoading: false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido actualizado: $nextStatus'),
          backgroundColor: wine,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el pedido: $error'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyOrderId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Mis entregas',
          style: TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadOrders,
            icon: const Icon(Icons.refresh, color: wine),
            tooltip: 'Actualizar pedidos',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: wine, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'No pudimos cargar tus entregas.',
                      style: TextStyle(
                        color: darkWine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadOrders,
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: wine,
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 170),
                        Icon(Icons.delivery_dining, size: 60, color: wine),
                        SizedBox(height: 15),
                        Center(
                          child: Text(
                            'Todavía no tenés pedidos asignados.',
                            style: TextStyle(
                              color: darkWine,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Cuando un comercio te asigne un pedido, aparecerá aquí.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(17),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final orderId = order['id']?.toString();
                        final orderStatus = order['status']?.toString() ?? '';
                        final orderNumber =
                            order['order_number']?.toString() ?? '';
                        final address =
                            order['delivery_address']?.toString() ?? '';
                        final notes = order['delivery_notes']?.toString() ?? '';
                        final total = (order['total'] as num?)?.toDouble() ?? 0;

                        final nextStatus = orderStatus == 'Preparando'
                            ? 'En camino'
                            : orderStatus == 'En camino'
                            ? 'Entregado'
                            : null;

                        final isBusy = _busyOrderId == orderId;

                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: rose),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(17),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        orderNumber,
                                        style: const TextStyle(
                                          color: darkWine,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: rose,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        orderStatus,
                                        style: const TextStyle(
                                          color: wine,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  'DIRECCIÓN DE ENTREGA',
                                  style: TextStyle(
                                    color: wine,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: wine,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(child: Text(address)),
                                  ],
                                ),
                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'INDICACIONES',
                                    style: TextStyle(
                                      color: wine,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(notes),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  'Total del pedido: ${formatPrice(total)}',
                                  style: const TextStyle(
                                    color: darkWine,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (nextStatus != null) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isBusy
                                          ? null
                                          : () => _updateOrder(order),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: wine,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                        ),
                                      ),
                                      child: isBusy
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              nextStatus == 'En camino'
                                                  ? 'MARCAR EN CAMINO'
                                                  : 'MARCAR ENTREGADO',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class MovaAdminDashboardScreen extends StatefulWidget {
  const MovaAdminDashboardScreen({super.key});

  @override
  State<MovaAdminDashboardScreen> createState() =>
      _MovaAdminDashboardScreenState();
}

class _MovaAdminDashboardScreenState extends State<MovaAdminDashboardScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String? _error;
  String? _busyDriverId;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final client = Supabase.instance.client;

      final driverRows = await client
          .from('delivery_drivers')
          .select(
            'user_id,status,vehicle_type,city,description,created_at,reviewed_at',
          )
          .order('created_at', ascending: false);

      final driverIds = driverRows
          .map((row) => row['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final profilesById = <String, Map<String, dynamic>>{};

      if (driverIds.isNotEmpty) {
        final profileRows = await client
            .from('profiles')
            .select('user_id,full_name,phone')
            .inFilter('user_id', driverIds);

        for (final item in profileRows) {
          final profile = Map<String, dynamic>.from(item);
          final id = profile['user_id']?.toString();

          if (id != null) {
            profilesById[id] = profile;
          }
        }
      }

      final loadedDrivers = <Map<String, dynamic>>[];

      for (final raw in driverRows) {
        final driver = Map<String, dynamic>.from(raw);
        final id = driver['user_id'].toString();
        final profile = profilesById[id] ?? {};

        loadedDrivers.add({
          ...driver,
          'full_name': profile['full_name'] ?? 'Sin nombre',
          'phone': profile['phone'] ?? 'Sin teléfono',
        });
      }

      if (!mounted) return;

      setState(() {
        _drivers = loadedDrivers;
        _error = null;
      });
    } catch (error) {
      debugPrint('Error cargando postulaciones: $error');

      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _reviewDriver(
    Map<String, dynamic> driver,
    String newStatus,
  ) async {
    final driverId = driver['user_id']?.toString();

    if (driverId == null || _busyDriverId != null) return;

    setState(() {
      _busyDriverId = driverId;
    });

    try {
      await Supabase.instance.client.rpc(
        'mova_review_driver',
        params: {'p_driver_id': driverId, 'p_new_status': newStatus},
      );

      if (!mounted) return;

      await _loadDrivers(showLoading: false);

      if (!mounted) return;

      final message = switch (newStatus) {
        'approved' => 'Repartidor aprobado correctamente.',
        'rejected' => 'Postulación rechazada.',
        'suspended' => 'Repartidor suspendido.',
        _ => 'Estado actualizado.',
      };

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: wine));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la solicitud: $error'),
          duration: const Duration(seconds: 6),
          backgroundColor: wine,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyDriverId = null;
        });
      }
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Pendiente',
      'approved' => 'Aprobado',
      'rejected' => 'Rechazado',
      'suspended' => 'Suspendido',
      _ => status,
    };
  }

  Widget _reviewButton({
    required Map<String, dynamic> driver,
    required String label,
    required String newStatus,
    bool primary = false,
  }) {
    final isBusy = _busyDriverId == driver['user_id'].toString();

    final buttonStyle = primary
        ? ElevatedButton.styleFrom(
            backgroundColor: wine,
            foregroundColor: Colors.white,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: wine,
            side: const BorderSide(color: wine),
          );

    final VoidCallback? onPressed = _busyDriverId != null
        ? null
        : () => _reviewDriver(driver, newStatus);

    if (primary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: isBusy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(label),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final status = driver['status']?.toString() ?? '';
    final name = driver['full_name']?.toString() ?? 'Sin nombre';
    final phone = driver['phone']?.toString() ?? 'Sin teléfono';
    final vehicle = driver['vehicle_type']?.toString() ?? 'No indicado';
    final city = driver['city']?.toString() ?? 'No indicada';
    final description = driver['description']?.toString() ?? '';

    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: rose),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: rose,
                  child: Icon(Icons.delivery_dining, color: wine),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: darkWine,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: rose,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: const TextStyle(
                      color: wine,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text('Teléfono: $phone'),
            const SizedBox(height: 5),
            Text('Vehículo: $vehicle'),
            const SizedBox(height: 5),
            Text('Localidad: $city'),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Presentación:',
                style: TextStyle(color: wine, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(description),
            ],
            const SizedBox(height: 16),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: _reviewButton(
                      driver: driver,
                      label: 'RECHAZAR',
                      newStatus: 'rejected',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _reviewButton(
                      driver: driver,
                      label: 'APROBAR',
                      newStatus: 'approved',
                      primary: true,
                    ),
                  ),
                ],
              )
            else if (status == 'approved')
              SizedBox(
                width: double.infinity,
                child: _reviewButton(
                  driver: driver,
                  label: 'SUSPENDER REPARTIDOR',
                  newStatus: 'suspended',
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: _reviewButton(
                  driver: driver,
                  label: status == 'suspended'
                      ? 'REACTIVAR REPARTIDOR'
                      : 'APROBAR REPARTIDOR',
                  newStatus: 'approved',
                  primary: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleDrivers = _filter == 'all'
        ? _drivers
        : _drivers.where((driver) {
            return driver['status'] == _filter;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Administración MOVA',
          style: TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined, color: wine),
            tooltip: 'Supervisión de pedidos',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MerchantApplicationsAdminScreen(),
                ),
              );
            },
            icon: const Icon(Icons.storefront_outlined, color: wine),
            tooltip: 'Solicitudes de comercios',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MovaAdminStatsScreen()),
              );
            },
            icon: const Icon(Icons.analytics_outlined, color: wine),
            tooltip: 'Estadísticas de MOVA',
          ),
          IconButton(
            onPressed: _loading ? null : _loadDrivers,
            icon: const Icon(Icons.refresh, color: wine),
            tooltip: 'Actualizar postulaciones',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: wine, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'No pudimos cargar las postulaciones.',
                      style: TextStyle(
                        color: darkWine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDrivers,
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Postulaciones de repartidores',
                        style: TextStyle(
                          color: darkWine,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_drivers.length} postulaciones registradas',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: _filter,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar solicitudes',
                          prefixIcon: Icon(Icons.filter_list, color: wine),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pendientes'),
                          ),
                          DropdownMenuItem(
                            value: 'approved',
                            child: Text('Aprobados'),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text('Rechazados'),
                          ),
                          DropdownMenuItem(
                            value: 'suspended',
                            child: Text('Suspendidos'),
                          ),
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filter = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visibleDrivers.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 70),
                            Icon(Icons.inbox_outlined, color: wine, size: 55),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No hay postulaciones en esta categoría.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        )
                      : RefreshIndicator(
                          color: wine,
                          onRefresh: _loadDrivers,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(18),
                            itemCount: visibleDrivers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildDriverCard(visibleDrivers[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class MerchantApplicationsAdminScreen extends StatefulWidget {
  const MerchantApplicationsAdminScreen({super.key});

  @override
  State<MerchantApplicationsAdminScreen> createState() =>
      _MerchantApplicationsAdminScreenState();
}

class _MerchantApplicationsAdminScreenState
    extends State<MerchantApplicationsAdminScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String? _error;
  String? _busyApplicationId;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('merchant_applications')
          .select(
            'id,owner_id,contact_name,business_name,category,phone,email,city,description,status,merchant_id,created_at,reviewed_at',
          )
          .order('created_at', ascending: false);

      final loaded = response
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;

      setState(() {
        _applications = loaded;
        _error = null;
      });
    } catch (error) {
      debugPrint('Error cargando solicitudes comerciales: $error');

      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _reviewApplication(
    Map<String, dynamic> application,
    String newStatus,
  ) async {
    final applicationId = application['id']?.toString();

    if (applicationId == null || _busyApplicationId != null) return;

    setState(() {
      _busyApplicationId = applicationId;
    });

    try {
      final response = await Supabase.instance.client.rpc(
        'mova_review_merchant_application',
        params: {'p_application_id': applicationId, 'p_new_status': newStatus},
      );

      if (response is! Map || response['success'] != true) {
        throw Exception('Supabase no confirmó la operación.');
      }

      if (!mounted) return;

      await _loadApplications(showLoading: false);

      if (!mounted) return;

      final message = newStatus == 'approved'
          ? 'Comercio aprobado y creado correctamente en MOVA.'
          : 'Solicitud comercial rechazada.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: wine,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo revisar la solicitud: $error'),
          backgroundColor: wine,
          duration: const Duration(seconds: 7),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyApplicationId = null;
        });
      }
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Pendiente',
      'approved' => 'Aprobado',
      'rejected' => 'Rechazado',
      _ => status,
    };
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final id = application['id']?.toString() ?? '';
    final name = application['business_name']?.toString() ?? 'Sin nombre';
    final contact = application['contact_name']?.toString() ?? '';
    final category = application['category']?.toString() ?? '';
    final phone = application['phone']?.toString() ?? '';
    final email = application['email']?.toString() ?? '';
    final city = application['city']?.toString() ?? '';
    final description = application['description']?.toString() ?? '';
    final status = application['status']?.toString() ?? '';
    final merchantId = application['merchant_id']?.toString();

    final isBusy = _busyApplicationId == id;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: rose),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: rose,
                  child: Icon(Icons.storefront_outlined, color: wine),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: darkWine,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: rose,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: const TextStyle(
                      color: wine,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text('Responsable: $contact'),
            const SizedBox(height: 5),
            Text('Categoría: $category'),
            const SizedBox(height: 5),
            Text('Teléfono: $phone'),
            const SizedBox(height: 5),
            Text('Correo: $email'),
            const SizedBox(height: 5),
            Text('Localidad: $city'),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Descripción del comercio:',
                style: TextStyle(color: wine, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(description),
            ],
            if (status == 'approved' && merchantId != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                'Comercio creado y vinculado correctamente.',
                style: TextStyle(color: wine, fontWeight: FontWeight.bold),
              ),
              SelectableText(
                'ID: $merchantId',
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busyApplicationId != null
                          ? null
                          : () => _reviewApplication(application, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: wine,
                        side: const BorderSide(color: wine),
                      ),
                      child: const Text('RECHAZAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busyApplicationId != null
                          ? null
                          : () => _reviewApplication(application, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: wine,
                        foregroundColor: Colors.white,
                      ),
                      child: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('APROBAR'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleApplications = _filter == 'all'
        ? _applications
        : _applications.where((application) {
            return application['status'] == _filter;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Solicitudes de comercios',
          style: TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadApplications,
            icon: const Icon(Icons.refresh, color: wine),
            tooltip: 'Actualizar solicitudes',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: wine, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'No pudimos cargar las solicitudes comerciales.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkWine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadApplications,
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestión de comercios',
                        style: TextStyle(
                          color: darkWine,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_applications.length} solicitudes registradas',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: _filter,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar solicitudes',
                          prefixIcon: Icon(Icons.filter_list, color: wine),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pendientes'),
                          ),
                          DropdownMenuItem(
                            value: 'approved',
                            child: Text('Aprobados'),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text('Rechazados'),
                          ),
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filter = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visibleApplications.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 75),
                            Icon(Icons.inbox_outlined, color: wine, size: 55),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No hay solicitudes en esta categoría.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        )
                      : RefreshIndicator(
                          color: wine,
                          onRefresh: _loadApplications,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(18),
                            itemCount: visibleApplications.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildApplicationCard(
                                visibleApplications[index],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  Map<String, String> _merchantNames = {};
  Map<String, Map<String, dynamic>> _profiles = {};

  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _search = '';
  String _statusFilter = 'all';
  String _storeFilter = 'all';
  String _driverFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final client = Supabase.instance.client;

      final isAdmin = await client.rpc('mova_is_admin');

      if (isAdmin != true) {
        throw Exception('No tenés permisos para consultar los pedidos.');
      }

      final response = await client
          .from('orders')
          .select(
            'id,order_number,store_id,customer_id,driver_id,status,total,delivery_address,delivery_notes,created_at,order_items(product_name,quantity,unit_price,emoji)',
          )
          .order('created_at', ascending: false);

      final loadedOrders = response
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final storeIds = loadedOrders
          .map((order) => order['store_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final userIds = <String>{
        for (final order in loadedOrders)
          if (order['customer_id'] != null) order['customer_id'].toString(),
        for (final order in loadedOrders)
          if (order['driver_id'] != null) order['driver_id'].toString(),
      };

      final merchantNames = <String, String>{};

      if (storeIds.isNotEmpty) {
        final merchantRows = await client
            .from('merchants')
            .select('id,name')
            .inFilter('id', storeIds);

        for (final item in merchantRows) {
          final merchant = Map<String, dynamic>.from(item);
          final id = merchant['id']?.toString();

          if (id != null) {
            merchantNames[id] = merchant['name']?.toString() ?? 'Comercio';
          }
        }
      }

      final profiles = <String, Map<String, dynamic>>{};

      if (userIds.isNotEmpty) {
        final profileRows = await client
            .from('profiles')
            .select('user_id,full_name')
            .inFilter('user_id', userIds.toList());

        for (final item in profileRows) {
          final profile = Map<String, dynamic>.from(item);
          final id = profile['user_id']?.toString();

          if (id != null) {
            profiles[id] = profile;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _orders = loadedOrders;
        _merchantNames = merchantNames;
        _profiles = profiles;
        _error = null;
      });
    } catch (error) {
      debugPrint('Error en supervisión de pedidos: $error');

      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _profileName(String? userId, String fallback) {
    if (userId == null || userId.isEmpty) return fallback;

    return _profiles[userId]?['full_name']?.toString() ?? fallback;
  }

  String _itemsSummary(Map<String, dynamic> order) {
    final items = order['order_items'];

    if (items is! List || items.isEmpty) {
      return 'Sin detalle de productos';
    }

    return items
        .map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
          final name = item['product_name']?.toString() ?? 'Producto';
          return '$quantity × $name';
        })
        .join(', ');
  }

  bool _matchesSearch(Map<String, dynamic> order) {
    if (_search.trim().isEmpty) return true;

    final query = _search.trim().toLowerCase();
    final orderNumber = order['order_number']?.toString() ?? '';
    final storeId = order['store_id']?.toString();
    final customerId = order['customer_id']?.toString();
    final driverId = order['driver_id']?.toString();

    final searchable = [
      orderNumber,
      order['delivery_address']?.toString() ?? '',
      _merchantNames[storeId] ?? '',
      _profileName(customerId, ''),
      _profileName(driverId, ''),
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderNumber =
        order['order_number']?.toString() ?? 'Pedido sin número';
    final status = order['status']?.toString() ?? 'Sin estado';
    final storeId = order['store_id']?.toString();
    final customerId = order['customer_id']?.toString();
    final driverId = order['driver_id']?.toString();
    final address = order['delivery_address']?.toString() ?? '';
    final notes = order['delivery_notes']?.toString() ?? '';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final createdAt =
        DateTime.tryParse(order['created_at']?.toString() ?? '') ??
        DateTime.now();

    final merchantName = _merchantNames[storeId] ?? 'Comercio no identificado';
    final customerName = _profileName(customerId, 'Cliente no identificado');
    final driverName = _profileName(driverId, 'Repartidor asignado');
    final items = _itemsSummary(order);

    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: rose),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    orderNumber,
                    style: const TextStyle(
                      color: darkWine,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: rose,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: wine,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _detailRow(Icons.storefront_outlined, 'Comercio', merchantName),
            _detailRow(Icons.person_outline, 'Cliente', customerName),
            _detailRow(
              Icons.delivery_dining,
              'Repartidor',
              driverId == null ? 'Sin asignar' : driverName,
            ),
            _detailRow(Icons.location_on_outlined, 'Entrega', address),
            _detailRow(Icons.shopping_bag_outlined, 'Productos', items),
            if (notes.isNotEmpty)
              _detailRow(Icons.notes, 'Indicaciones', notes),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                    color: wine,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatOrderDate(createdAt),
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: wine, size: 19),
          const SizedBox(width: 9),
          SizedBox(
            width: 88,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: darkWine)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses =
        _orders
            .map((order) => order['status']?.toString() ?? '')
            .where((status) => status.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final storeIds =
        _orders
            .map((order) => order['store_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort(
            (a, b) =>
                (_merchantNames[a] ?? a).compareTo(_merchantNames[b] ?? b),
          );

    final driverIds =
        _orders
            .map((order) => order['driver_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => _profileName(a, a).compareTo(_profileName(b, b)));

    final visibleOrders = _orders.where((order) {
      final status = order['status']?.toString() ?? '';
      final storeId = order['store_id']?.toString() ?? '';
      final driverId = order['driver_id']?.toString() ?? '';

      return (_statusFilter == 'all' || status == _statusFilter) &&
          (_storeFilter == 'all' || storeId == _storeFilter) &&
          (_driverFilter == 'all' || driverId == _driverFilter) &&
          _matchesSearch(order);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Supervisión de pedidos',
          style: TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadOrders,
            icon: const Icon(Icons.refresh, color: wine),
            tooltip: 'Actualizar pedidos',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: wine, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'No pudimos cargar los pedidos.',
                      style: TextStyle(
                        color: darkWine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadOrders,
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${visibleOrders.length} de ${_orders.length} pedidos',
                        style: const TextStyle(
                          color: darkWine,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar pedido, cliente o dirección',
                          prefixIcon: const Icon(Icons.search, color: wine),
                          suffixIcon: _search.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _search = '';
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _search = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: statuses.contains(_statusFilter)
                            ? _statusFilter
                            : 'all',
                        decoration: const InputDecoration(
                          labelText: 'Estado del pedido',
                          prefixIcon: Icon(Icons.filter_list, color: wine),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Todos los estados'),
                          ),
                          ...statuses.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _statusFilter = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 235,
                            child: DropdownButtonFormField<String>(
                              initialValue: storeIds.contains(_storeFilter)
                                  ? _storeFilter
                                  : 'all',
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Comercio',
                                prefixIcon: Icon(Icons.store, color: wine),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Todos los comercios'),
                                ),
                                ...storeIds.map(
                                  (id) => DropdownMenuItem(
                                    value: id,
                                    child: Text(
                                      _merchantNames[id] ?? id,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _storeFilter = value ?? 'all';
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 235,
                            child: DropdownButtonFormField<String>(
                              initialValue: driverIds.contains(_driverFilter)
                                  ? _driverFilter
                                  : 'all',
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Repartidor',
                                prefixIcon: Icon(
                                  Icons.delivery_dining,
                                  color: wine,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Todos los repartidores'),
                                ),
                                ...driverIds.map(
                                  (id) => DropdownMenuItem(
                                    value: id,
                                    child: Text(
                                      _profileName(id, id),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _driverFilter = value ?? 'all';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visibleOrders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 65),
                            Icon(Icons.inbox_outlined, color: wine, size: 55),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No hay pedidos que coincidan con los filtros.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        )
                      : RefreshIndicator(
                          color: wine,
                          onRefresh: _loadOrders,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visibleOrders.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildOrderCard(visibleOrders[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class ProductManagementScreen extends StatefulWidget {
  final Store store;
  final Future<void> Function() onCatalogChanged;

  const ProductManagementScreen({
    super.key,
    required this.store,
    required this.onCatalogChanged,
  });

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  Future<void> _showProductDialog({Product? product, int? index}) async {
    final nameController = TextEditingController(text: product?.name ?? '');

    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );

    final priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(0),
    );

    final emojiController = TextEditingController(text: product?.emoji ?? '🍔');

    final result = await showDialog<Product>(
      context: context,
      builder: (dialogContext) {
        String? errorMessage;
        String? imageBase64 = product?.imageBase64;
        String? imagePath = product?.imagePath;
        String? imageExtension;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                product == null ? 'Agregar producto' : 'Editar producto',
                style: const TextStyle(
                  color: wine,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final files = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                          );

                          if (files.isEmpty) return;

                          final extension = files.first.extension
                              ?.toLowerCase();

                          if (extension == null ||
                              ![
                                'jpg',
                                'jpeg',
                                'png',
                                'webp',
                              ].contains(extension)) {
                            setDialogState(() {
                              errorMessage = 'Formato de imagen no permitido.';
                            });
                            return;
                          }

                          final bytes = await files.first.readAsBytes();

                          if (!dialogContext.mounted) return;

                          if (bytes.length > 5 * 1024 * 1024) {
                            setDialogState(() {
                              errorMessage =
                                  'La foto debe pesar como máximo 5 MB.';
                            });
                            return;
                          }

                          setDialogState(() {
                            imageBase64 = base64Encode(bytes);
                            imagePath = null;
                            imageExtension = extension;
                            errorMessage = null;
                          });
                        } catch (error) {
                          if (!dialogContext.mounted) return;

                          setDialogState(() {
                            errorMessage = 'No se pudo cargar la imagen.';
                          });
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('SELECCIONAR FOTO'),
                      style: OutlinedButton.styleFrom(foregroundColor: wine),
                    ),
                    if (imageBase64 != null || imagePath != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: imageBase64 != null
                              ? Image.memory(
                                  base64Decode(imageBase64!),
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  Supabase.instance.client.storage
                                      .from('product-images')
                                      .getPublicUrl(imagePath!),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            imageBase64 = null;
                            imagePath = null;
                            imageExtension = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Quitar foto'),
                        style: TextButton.styleFrom(foregroundColor: wine),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: emojiController,
                      decoration: const InputDecoration(
                        labelText: 'Emoji del producto (alternativo)',
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('CANCELAR', style: TextStyle(color: wine)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final parsedPrice = double.tryParse(
                      priceController.text.trim().replaceAll(',', '.'),
                    );

                    if (nameController.text.trim().isEmpty ||
                        parsedPrice == null ||
                        !parsedPrice.isFinite ||
                        parsedPrice <= 0) {
                      setDialogState(() {
                        errorMessage = 'Ingresá un nombre y un precio válido.';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      Product(
                        id: product?.id,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        price: parsedPrice,
                        emoji: emojiController.text.trim().isEmpty
                            ? '📦'
                            : emojiController.text.trim(),
                        isAvailable: product?.isAvailable ?? true,
                        imageBase64: imageBase64,
                        imagePath: imagePath,
                        imageExtension: imageExtension,
                      ),
                    );
                  },
                  child: const Text('GUARDAR'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    emojiController.dispose();

    if (result == null || !mounted) return;

    if (widget.store.id != null) {
      try {
        final savedProduct = await _saveCloudProduct(result, previous: product);

        if (!mounted) return;

        setState(() {
          if (index == null) {
            widget.store.products.add(savedProduct);
          } else {
            widget.store.products[index] = savedProduct;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado en MOVA online.')),
        );
      } catch (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el producto: $error')),
        );
      }

      return;
    }

    setState(() {
      if (index == null) {
        widget.store.products.add(result);
      } else {
        widget.store.products[index] = result;
      }
    });

    await widget.onCatalogChanged();
  }

  Future<Product> _saveCloudProduct(Product draft, {Product? previous}) async {
    final client = Supabase.instance.client;
    final storeId = widget.store.id!;

    String? imagePath = draft.imagePath;
    String? uploadedPath;

    try {
      if (draft.imageBase64 != null && draft.imageBase64!.isNotEmpty) {
        final extension = draft.imageExtension?.toLowerCase();

        const mimeTypes = {
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'webp': 'image/webp',
        };

        final mimeType = mimeTypes[extension];

        if (extension == null || mimeType == null) {
          throw Exception('Formato de fotografía no permitido.');
        }

        final bytes = base64Decode(draft.imageBase64!);

        final path =
            '$storeId/${DateTime.now().microsecondsSinceEpoch}.$extension';

        uploadedPath = path;

        await client.storage
            .from('product-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: mimeType,
                cacheControl: '3600',
                upsert: false,
              ),
            );

        imagePath = path;
      }

      final payload = {
        'store_id': storeId,
        'name': draft.name,
        'description': draft.description,
        'price': draft.price,
        'emoji': draft.emoji,
        'is_available': draft.isAvailable,
        'image_path': imagePath,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      late String savedId;

      if (draft.id == null) {
        final inserted = await client
            .from('products')
            .insert(payload)
            .select('id')
            .single();

        savedId = inserted['id'].toString();
      } else {
        final updated = await client
            .from('products')
            .update(payload)
            .eq('id', draft.id!)
            .eq('store_id', storeId)
            .select('id')
            .maybeSingle();

        if (updated == null) {
          throw Exception('No se encontró el producto para actualizar.');
        }

        savedId = updated['id'].toString();
      }

      final oldPath = previous?.imagePath;

      if (oldPath != null && oldPath != imagePath) {
        try {
          await client.storage.from('product-images').remove([oldPath]);
        } catch (error) {
          debugPrint('No se pudo eliminar la foto anterior: $error');
        }
      }

      return Product(
        id: savedId,
        name: draft.name,
        description: draft.description,
        price: draft.price,
        emoji: draft.emoji,
        isAvailable: draft.isAvailable,
        imageBase64: null,
        imagePath: imagePath,
        imageExtension: draft.imageExtension,
      );
    } catch (error) {
      if (uploadedPath != null) {
        try {
          await client.storage.from('product-images').remove([uploadedPath]);
        } catch (cleanupError) {
          debugPrint('No se pudo limpiar la foto temporal: $cleanupError');
        }
      }

      rethrow;
    }
  }

  Future<void> _toggleProduct(int index) async {
    final current = widget.store.products[index];

    if (widget.store.id != null) {
      if (current.id == null) return;

      try {
        final updated = await Supabase.instance.client
            .from('products')
            .update({
              'is_available': !current.isAvailable,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', current.id!)
            .eq('store_id', widget.store.id!)
            .select('id')
            .maybeSingle();

        if (updated == null) {
          throw Exception('No se encontró el producto.');
        }
      } catch (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      widget.store.products[index] = current.copyWith(
        isAvailable: !current.isAvailable,
      );
    });

    if (widget.store.id == null) {
      await widget.onCatalogChanged();
    }
  }

  Future<void> _deleteProduct(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Seguro que querés eliminar este producto del catálogo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final current = widget.store.products[index];

    if (widget.store.id != null) {
      if (current.id == null) return;

      try {
        final deleted = await Supabase.instance.client
            .from('products')
            .delete()
            .eq('id', current.id!)
            .eq('store_id', widget.store.id!)
            .select('id')
            .maybeSingle();

        if (deleted == null) {
          throw Exception('No se encontró el producto.');
        }
      } catch (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
        return;
      }

      if (current.imagePath != null) {
        try {
          await Supabase.instance.client.storage.from('product-images').remove([
            current.imagePath!,
          ]);
        } catch (error) {
          debugPrint('No se pudo eliminar la fotografía: $error');
        }
      }
    }

    if (!mounted) return;

    setState(() {
      widget.store.products.removeAt(index);
    });

    if (widget.store.id == null) {
      await widget.onCatalogChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: Text(
          'Productos · ${widget.store.name}',
          style: const TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: wine,
        foregroundColor: Colors.white,
        onPressed: () {
          unawaited(_showProductDialog());
        },
        icon: const Icon(Icons.add),
        label: const Text('AGREGAR PRODUCTO'),
      ),
      body: widget.store.products.isEmpty
          ? const Center(
              child: Text(
                'Todavía no hay productos.\nAgregá el primero.',
                textAlign: TextAlign.center,
                style: TextStyle(color: wine, fontSize: 17),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
              itemCount: widget.store.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = widget.store.products[index];

                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: rose),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: productThumbnail(product, size: 56, emojiSize: 30),
                    title: Text(
                      product.name,
                      style: const TextStyle(
                        color: darkWine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${product.description}\n'
                      '${formatPrice(product.price)} · '
                      '${product.isAvailable ? 'Disponible' : 'Pausado'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          unawaited(
                            _showProductDialog(product: product, index: index),
                          );
                        } else if (action == 'toggle') {
                          unawaited(_toggleProduct(index));
                        } else if (action == 'delete') {
                          unawaited(_deleteProduct(index));
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            product.isAvailable
                                ? 'Pausar producto'
                                : 'Activar producto',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class MerchantOwnerGate extends StatefulWidget {
  const MerchantOwnerGate({super.key});

  @override
  State<MerchantOwnerGate> createState() => _MerchantOwnerGateState();
}

class _MerchantOwnerGateState extends State<MerchantOwnerGate> {
  bool _loading = true;
  String? _error;
  String? _applicationStatus;
  String? _applicationName;

  List<Store> _ownedStores = [];
  List<MovaOrder> _ownedOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOwnedStores();
  }

  Future<void> _loadOwnedStores() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('No hay una sesión iniciada.');
      }

      // Consultar exclusivamente los comercios del propietario.
      final merchantRows = await client
          .from('merchants')
          .select('id,name,category,emoji,description,city,image_path')
          .eq('owner_id', user.id)
          .order('name');

      final storeIds = merchantRows.map((row) => row['id'].toString()).toList();

      final productsByStore = <String, List<Product>>{};

      if (storeIds.isNotEmpty) {
        final productRows = await client
            .from('products')
            .select(
              'id,store_id,name,description,price,emoji,is_available,image_path',
            )
            .inFilter('store_id', storeIds);

        for (final item in productRows) {
          final row = Map<String, dynamic>.from(item);
          final storeId = row['store_id']?.toString();
          final price = row['price'];

          if (storeId == null || price is! num) continue;

          final product = Product(
            id: row['id']?.toString(),
            name: row['name'] as String,
            description: row['description'] as String? ?? '',
            price: price.toDouble(),
            emoji: row['emoji'] as String? ?? '📦',
            isAvailable: row['is_available'] as bool? ?? true,
            imagePath: row['image_path'] as String?,
          );

          productsByStore.putIfAbsent(storeId, () => <Product>[]).add(product);
        }
      }

      final loadedStores = <Store>[];

      for (final item in merchantRows) {
        final row = Map<String, dynamic>.from(item);
        final id = row['id'].toString();

        loadedStores.add(
          Store(
            id: id,
            name: row['name'] as String,
            category: row['category'] as String? ?? 'Otros comercios',
            emoji: row['emoji'] as String? ?? '🏪',
            description: row['description'] as String? ?? '',
            city: row['city'] as String? ?? '',
            imagePath: row['image_path'] as String?,
            products: productsByStore[id] ?? <Product>[],
          ),
        );
      }

      // Descargar los pedidos de los comercios del propietario.
      final loadedOrders = <MovaOrder>[];

      if (storeIds.isNotEmpty) {
        final orderRows = await client
            .from('orders')
            .select(
              'id,order_number,store_id,status,total,delivery_address,delivery_notes,driver_id,created_at,order_items(product_name,quantity,unit_price,emoji)',
            )
            .inFilter('store_id', storeIds)
            .order('created_at', ascending: false);

        final storeNames = <String, String>{
          for (final store in loadedStores)
            if (store.id != null) store.id!: store.name,
        };

        for (final item in orderRows) {
          final row = Map<String, dynamic>.from(item);
          final rawItems = row['order_items'];
          final products = <Product>[];

          if (rawItems is List) {
            for (final rawItem in rawItems) {
              final itemRow = Map<String, dynamic>.from(rawItem as Map);
              final quantity = (itemRow['quantity'] as num?)?.toInt() ?? 1;
              final price = itemRow['unit_price'];

              if (price is! num || quantity < 1) continue;

              final product = Product(
                name: itemRow['product_name']?.toString() ?? 'Producto',
                description: '',
                price: price.toDouble(),
                emoji: itemRow['emoji']?.toString() ?? '📦',
              );

              for (var i = 0; i < quantity; i++) {
                products.add(product);
              }
            }
          }

          final storeId = row['store_id']?.toString();
          final databaseId = row['id']?.toString();
          final orderNumber = row['order_number']?.toString();

          if (databaseId == null || storeId == null) continue;

          loadedOrders.add(
            MovaOrder(
              id: orderNumber ?? databaseId,
              databaseId: databaseId,
              storeId: storeId,
              storeName: storeNames[storeId] ?? 'Comercio',
              products: products,
              total: (row['total'] as num?)?.toDouble() ?? 0,
              address: row['delivery_address']?.toString() ?? '',
              notes: row['delivery_notes']?.toString() ?? '',
              createdAt:
                  DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              status: row['status']?.toString() ?? 'Pendiente',
              driverId: row['driver_id']?.toString(),
            ),
          );
        }
      }

      String? applicationStatus;
      String? applicationName;

      if (loadedStores.isEmpty) {
        final applications = await client
            .from('merchant_applications')
            .select('business_name,status')
            .eq('owner_id', user.id)
            .order('created_at', ascending: false)
            .limit(1);

        if (applications.isNotEmpty) {
          applicationStatus = applications.first['status']?.toString();

          applicationName = applications.first['business_name']?.toString();
        }
      }

      if (!mounted) return;

      setState(() {
        _ownedStores = loadedStores;
        _ownedOrders = loadedOrders;
        _applicationStatus = applicationStatus;
        _applicationName = applicationName;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeOwnedOrderStatus(MovaOrder order, String status) async {
    final databaseId = order.databaseId;

    if (databaseId == null) {
      throw Exception('Este pedido no tiene un identificador de Supabase.');
    }

    final client = Supabase.instance.client;

    await client.rpc(
      'mova_update_order_status',
      params: {'p_order_id': databaseId, 'p_new_status': status},
    );

    if (!mounted) return;

    setState(() {
      final index = _ownedOrders.indexWhere(
        (item) => item.databaseId == databaseId,
      );

      if (index != -1) {
        _ownedOrders[index].status = status;
      }
    });
  }

  Future<void> _openRegistration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrationScreen(isBusiness: true),
      ),
    );

    if (mounted) {
      await _loadOwnedStores();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: cream,
          title: const Text('Mi comercio'),
        ),
        body: const Center(child: CircularProgressIndicator(color: wine)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: cream,
          title: const Text('Mi comercio'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: wine, size: 45),
                const SizedBox(height: 15),
                const Text(
                  'No pudimos cargar tu comercio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: darkWine,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadOwnedStores,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('REINTENTAR'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_ownedStores.isEmpty) {
      final status = _applicationStatus?.toLowerCase();

      String message;

      if (status == 'pending') {
        message =
            'Tu solicitud de ${_applicationName ?? 'comercio'} '
            'está pendiente de revisión. Te avisaremos cuando sea aprobada.';
      } else if (status == 'rejected') {
        message =
            'Tu solicitud fue rechazada. Comunicate con MOVA '
            'para conocer los detalles.';
      } else {
        message =
            'Todavía no encontramos un comercio aprobado vinculado '
            'a tu cuenta.';
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: cream,
          title: const Text('Mi comercio', style: TextStyle(color: wine)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.hourglass_top
                      : Icons.storefront_outlined,
                  color: wine,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  status == 'pending'
                      ? 'Solicitud en revisión'
                      : 'Tu negocio en MOVA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: darkWine,
                    fontWeight: FontWeight.bold,
                    fontSize: 23,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.5),
                ),
                if (status == null || status == 'rejected') ...[
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _openRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: wine,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('REGISTRAR MI COMERCIO'),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadOwnedStores,
                  child: const Text(
                    'ACTUALIZAR ESTADO',
                    style: TextStyle(color: wine),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MerchantDashboardScreen(
      stores: _ownedStores,
      orders: _ownedOrders,
      onChangeStatus: _changeOwnedOrderStatus,
      onCatalogChanged: _loadOwnedStores,
      productsOnlineEnabled: true,
    );
  }
}

class MerchantDashboardScreen extends StatefulWidget {
  final List<Store> stores;
  final List<MovaOrder> orders;
  final Future<void> Function(MovaOrder, String) onChangeStatus;
  final Future<void> Function() onCatalogChanged;
  final bool productsOnlineEnabled;

  const MerchantDashboardScreen({
    super.key,
    required this.stores,
    required this.orders,
    required this.onChangeStatus,
    required this.onCatalogChanged,
    this.productsOnlineEnabled = true,
  });

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  late String selectedStoreName;
  bool _savingCover = false;
  bool _loadingDrivers = false;
  String? _driverLoadError;
  String? _assigningOrderId;
  List<Map<String, dynamic>> _approvedDrivers = [];

  @override
  void initState() {
    super.initState();
    selectedStoreName = widget.stores.isNotEmpty
        ? widget.stores.first.name
        : '';

    unawaited(_loadApprovedDrivers());
  }

  List<MovaOrder> get storeOrders {
    return widget.orders
        .where((order) => order.storeName == selectedStoreName)
        .toList();
  }

  Future<void> _loadApprovedDrivers() async {
    if (mounted) {
      setState(() {
        _loadingDrivers = true;
        _driverLoadError = null;
      });
    }

    try {
      final client = Supabase.instance.client;

      final driverRows = await client
          .from('delivery_drivers')
          .select('user_id,vehicle_type,city,created_at')
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      final driverIds = driverRows
          .map((row) => row['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final nameById = <String, String>{};

      if (driverIds.isNotEmpty) {
        final profileRows = await client
            .from('profiles')
            .select('user_id,full_name')
            .inFilter('user_id', driverIds);

        for (final item in profileRows) {
          final profile = Map<String, dynamic>.from(item);
          final id = profile['user_id']?.toString();

          if (id != null) {
            nameById[id] = profile['full_name']?.toString() ?? 'Repartidor';
          }
        }
      }

      final drivers = driverRows.map((raw) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['user_id'].toString();

        return <String, dynamic>{
          ...row,
          'full_name': nameById[id] ?? 'Repartidor',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _approvedDrivers = drivers;
        _driverLoadError = null;
      });
    } catch (error) {
      debugPrint('Error cargando repartidores aprobados: $error');

      if (!mounted) return;

      setState(() {
        _approvedDrivers = [];
        _driverLoadError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingDrivers = false;
        });
      }
    }
  }

  String _driverName(String? driverId) {
    if (driverId == null) return '';

    for (final driver in _approvedDrivers) {
      if (driver['user_id']?.toString() == driverId) {
        return driver['full_name']?.toString() ?? 'Repartidor';
      }
    }

    return 'Repartidor asignado';
  }

  Future<void> _assignDriver(MovaOrder order) async {
    final orderId = order.databaseId;

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El pedido no tiene un identificador válido.'),
        ),
      );
      return;
    }

    if (order.status != 'Preparando') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El pedido debe estar en preparación para asignar un repartidor.',
          ),
        ),
      );
      return;
    }

    if (_assigningOrderId != null) return;

    setState(() {
      _assigningOrderId = orderId;
    });

    try {
      // Actualizar la lista antes de mostrar el selector.
      await _loadApprovedDrivers();

      if (!mounted) return;

      if (_approvedDrivers.isEmpty) {
        throw Exception(
          _driverLoadError ??
              'Todavía no hay repartidores aprobados disponibles.',
        );
      }

      final selectedDriver = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Elegir repartidor',
            style: TextStyle(color: wine, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: ListView.separated(
              itemCount: _approvedDrivers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final driver = _approvedDrivers[index];
                final name = driver['full_name']?.toString() ?? 'Repartidor';
                final vehicle = driver['vehicle_type']?.toString() ?? '';
                final city = driver['city']?.toString() ?? '';

                final details = [
                  vehicle,
                  city,
                ].where((value) => value.isNotEmpty).join(' · ');

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: rose,
                    child: Icon(Icons.delivery_dining, color: wine),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: darkWine,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    details.isEmpty ? 'Repartidor aprobado' : details,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color: wine,
                  ),
                  onTap: () => Navigator.pop(dialogContext, driver),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR', style: TextStyle(color: wine)),
            ),
          ],
        ),
      );

      if (selectedDriver == null) return;
      if (!mounted) return;

      final driverId = selectedDriver['user_id'].toString();

      await Supabase.instance.client.rpc(
        'mova_assign_driver',
        params: {'p_order_id': orderId, 'p_driver_id': driverId},
      );

      if (!mounted) return;

      setState(() {
        order.driverId = driverId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido asignado a ${selectedDriver['full_name']}.'),
          backgroundColor: wine,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo asignar el repartidor: $error'),
          duration: const Duration(seconds: 6),
          backgroundColor: wine,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _assigningOrderId = null;
        });
      }
    }
  }

  Future<void> _changeStoreCover() async {
    final matchingStores = widget.stores.where(
      (store) => store.name == selectedStoreName,
    );

    if (matchingStores.isEmpty) return;

    final store = matchingStores.first;
    final storeId = store.id;

    if (storeId == null) return;

    String? uploadedPath;
    bool savedToDatabase = false;

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (files.isEmpty) return;

      final extension = files.first.extension?.toLowerCase();

      const mimeTypes = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
      };

      final mimeType = extension == null ? null : mimeTypes[extension];

      if (mimeType == null) {
        throw Exception('Formato de fotografía no permitido.');
      }

      final bytes = await files.first.readAsBytes();

      if (!mounted) return;

      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('La fotografía debe pesar como máximo 5 MB.');
      }

      setState(() => _savingCover = true);

      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('No hay una sesión iniciada.');
      }

      uploadedPath =
          '$storeId/portada_${DateTime.now().microsecondsSinceEpoch}.$extension';

      await client.storage
          .from('product-images')
          .uploadBinary(
            uploadedPath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              cacheControl: '3600',
            ),
          );

      final updated = await client
          .from('merchants')
          .update({'image_path': uploadedPath})
          .eq('id', storeId)
          .eq('owner_id', user.id)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        throw Exception(
          'No se pudo actualizar el comercio. Revisá los permisos de Supabase.',
        );
      }

      savedToDatabase = true;

      final oldPath = store.imagePath;

      if (oldPath != null && oldPath != uploadedPath) {
        try {
          await client.storage.from('product-images').remove([oldPath]);
        } catch (error) {
          debugPrint('No se pudo eliminar la portada anterior: $error');
        }
      }

      try {
        await widget.onCatalogChanged();
      } catch (error) {
        debugPrint('No se pudo actualizar el catálogo: $error');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La portada de ${store.name} se actualizó correctamente.',
          ),
          backgroundColor: wine,
        ),
      );
    } catch (error) {
      if (uploadedPath != null && !savedToDatabase) {
        try {
          await Supabase.instance.client.storage.from('product-images').remove([
            uploadedPath,
          ]);
        } catch (_) {}
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la portada: $error'),
          backgroundColor: wine,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingCover = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = storeOrders
        .where((order) => order.status == 'Pendiente')
        .length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Panel de comercios',
          style: TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Administrá tu negocio',
              style: TextStyle(
                color: darkWine,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consultá las compras y actualizá su estado.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),

            DropdownButtonFormField<String>(
              initialValue: selectedStoreName.isEmpty
                  ? null
                  : selectedStoreName,
              decoration: const InputDecoration(
                labelText: 'Seleccionar comercio',
                prefixIcon: Icon(Icons.storefront_outlined, color: wine),
              ),
              items: widget.stores.map((store) {
                return DropdownMenuItem<String>(
                  value: store.name,
                  child: Text(store.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStoreName = value;
                  });
                }
              },
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    selectedStoreName.isEmpty || !widget.productsOnlineEnabled
                    ? null
                    : () {
                        final selectedStore = widget.stores.firstWhere(
                          (store) => store.name == selectedStoreName,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductManagementScreen(
                              store: selectedStore,
                              onCatalogChanged: widget.onCatalogChanged,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  widget.productsOnlineEnabled
                      ? 'ADMINISTRAR PRODUCTOS'
                      : 'PRODUCTOS ONLINE EN PREPARACIÓN',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: wine,
                  side: const BorderSide(color: wine),
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: selectedStoreName.isEmpty || _savingCover
                    ? null
                    : _changeStoreCover,
                icon: _savingCover
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _savingCover
                      ? 'GUARDANDO PORTADA...'
                      : 'CAMBIAR FOTO DEL COMERCIO',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: wine,
                  side: const BorderSide(color: wine),
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pedidos recibidos',
                  style: TextStyle(
                    color: darkWine,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${storeOrders.length} pedidos · $pendingCount pendientes',
                  style: const TextStyle(
                    color: wine,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: storeOrders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: wine,
                            size: 55,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Todavía no hay pedidos',
                            style: TextStyle(
                              color: wine,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Cuando recibas compras aparecerán aquí.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: storeOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = storeOrders[index];

                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: rose),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      order.id,
                                      style: const TextStyle(
                                        color: darkWine,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Actualizar estado',
                                      onSelected: (status) async {
                                        try {
                                          await widget.onChangeStatus(
                                            order,
                                            status,
                                          );
                                          if (!context.mounted) return;
                                          setState(() {});
                                        } catch (error) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'No se pudo actualizar el pedido: $error',
                                              ),
                                              backgroundColor: wine,
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) {
                                        return movaOrderStatuses.map((status) {
                                          return PopupMenuItem<String>(
                                            value: status,
                                            child: Text(status),
                                          );
                                        }).toList();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: rose,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              order.status,
                                              style: const TextStyle(
                                                color: wine,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_drop_down,
                                              color: wine,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 22),
                                ...order.products.map(
                                  (product) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      '${product.emoji} ${product.name}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: wine,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        order.address,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.notes.isNotEmpty) ...[
                                  const SizedBox(height: 7),
                                  Text(
                                    'Indicaciones: ${order.notes}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (order.driverId != null) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.delivery_dining,
                                        color: wine,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          'Repartidor asignado: ${_driverName(order.driverId)}',
                                          style: const TextStyle(
                                            color: wine,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (order.status == 'Preparando') ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          (_assigningOrderId ==
                                                  order.databaseId ||
                                              _loadingDrivers)
                                          ? null
                                          : () => _assignDriver(order),
                                      icon:
                                          _assigningOrderId == order.databaseId
                                          ? const SizedBox(
                                              width: 17,
                                              height: 17,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.delivery_dining),
                                      label: Text(
                                        _assigningOrderId == order.databaseId
                                            ? 'ASIGNANDO...'
                                            : order.driverId == null
                                            ? 'ASIGNAR REPARTIDOR'
                                            : 'CAMBIAR REPARTIDOR',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: wine,
                                        side: const BorderSide(color: wine),
                                        padding: const EdgeInsets.all(14),
                                      ),
                                    ),
                                  ),
                                ],
                                const Divider(height: 22),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total del pedido',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      formatPrice(order.total),
                                      style: const TextStyle(
                                        color: wine,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatOrderDate(order.createdAt),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final List<Product> products;
  final double total;
  final String storeName;
  final Future<String> Function(
    String address,
    String notes,
    String paymentMethod,
  )
  onConfirm;

  const CheckoutScreen({
    super.key,
    required this.products,
    required this.total,
    required this.storeName,
    required this.onConfirm,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String _paymentMethod = 'cash';
  LatLng? _deliveryPoint;

  @override
  void dispose() {
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Finalizar pedido',
          style: TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Dónde te lo llevamos?',
                style: TextStyle(
                  color: darkWine,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ingresá la dirección donde querés recibir tu pedido.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 25),
              const Text(
                'Dirección de entrega',
                style: TextStyle(color: darkWine, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  hintText: 'Calle, número y barrio',
                  prefixIcon: Icon(Icons.location_on_outlined, color: wine),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresá una dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Ubicación de entrega',
                style: TextStyle(
                  color: darkWine,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tocá el mapa para marcar exactamente dónde querés recibir tu pedido.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              DeliveryLocationPicker(
                pickupPoint: const LatLng(
                  -32.582811210089886,
                  -61.16969691753774,
                ),
                selectedPoint: _deliveryPoint,
                onPointSelected: (point) {
                  setState(() {
                    _deliveryPoint = point;
                  });
                },
              ),
              const SizedBox(height: 10),
              if (_deliveryPoint == null)
                const Text(
                  'Todavía no seleccionaste el punto de entrega.',
                  style: TextStyle(color: Colors.black54),
                )
              else
                Text(
                  'Ubicación elegida: '
                  '${_deliveryPoint!.latitude.toStringAsFixed(6)}, '
                  '${_deliveryPoint!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: wine,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Indicaciones adicionales',
                style: TextStyle(color: darkWine, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Referencias, casa, departamento, etc.',
                  prefixIcon: Icon(Icons.edit_note, color: wine),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Método de pago',
                style: TextStyle(
                  color: darkWine,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: rose),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      activeColor: wine,
                      value: 'cash',
                      groupValue: _paymentMethod,
                      title: const Text('Efectivo'),
                      subtitle: const Text('Pagás al recibir tu pedido.'),
                      secondary: const Icon(
                        Icons.payments_outlined,
                        color: wine,
                      ),
                      onChanged: _submitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _paymentMethod = value);
                              }
                            },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      activeColor: wine,
                      value: 'transfer',
                      groupValue: _paymentMethod,
                      title: const Text('Transferencia'),
                      subtitle: const Text(
                        'El pago quedará pendiente de verificación.',
                      ),
                      secondary: const Icon(
                        Icons.account_balance_outlined,
                        color: wine,
                      ),
                      onChanged: _submitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _paymentMethod = value);
                              }
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Resumen de tu pedido',
                style: TextStyle(
                  color: darkWine,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comercio: ${widget.storeName}',
                style: const TextStyle(
                  color: wine,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.products.map(
                (product) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: productThumbnail(product, size: 56, emojiSize: 25),
                  title: Text(product.name),
                  subtitle: Text(formatPrice(product.price)),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    formatPrice(widget.total),
                    style: const TextStyle(
                      color: wine,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setState(() => _submitting = true);

                          try {
                            final orderId = await widget.onConfirm(
                              addressController.text.trim(),
                              notesController.text.trim(),
                              _paymentMethod,
                            );

                            if (!context.mounted) return;

                            await showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('¡Pedido registrado!'),
                                content: Text(
                                  'Tu número de pedido es $orderId.\n\n'
                                  'Dirección: ${addressController.text}\n'
                                  'Total: ${formatPrice(widget.total)}\n\n'
                                  'El pedido fue registrado correctamente.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'VER MIS PEDIDOS',
                                      style: TextStyle(color: wine),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No se pudo registrar el pedido: $error',
                                ),
                                duration: const Duration(seconds: 6),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _submitting = false);
                            }
                          }
                        },
                  child: Text(
                    _submitting ? 'ENVIANDO...' : 'CONFIRMAR PEDIDO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TARJETA DE COMERCIO

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreCard({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: rose),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: softRose,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: storeCoverImage(
                  store,
                  width: 65,
                  height: 65,
                  emojiSize: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        color: darkWine,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      store.description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      store.category,
                      style: const TextStyle(
                        color: wine,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: wine, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

// DETALLE DEL COMERCIO

class StoreDetailScreen extends StatelessWidget {
  final Store store;
  final Function(Product, String) onAdd;

  const StoreDetailScreen({
    super.key,
    required this.store,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: Text(
          store.name,
          style: const TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: softRose,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  storeCoverImage(
                    store,
                    width: double.infinity,
                    height: 150,
                    emojiSize: 65,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    store.name,
                    style: const TextStyle(
                      color: darkWine,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    store.description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Productos',
              style: TextStyle(
                color: darkWine,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 13),
            if (store.products.where((product) => product.isAvailable).isEmpty)
              const Text(
                'No hay productos disponibles por el momento.',
                style: TextStyle(color: Colors.black54),
              )
            else
              ...store.products
                  .where((product) => product.isAvailable)
                  .map(
                    (product) => Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: productThumbnail(
                          product,
                          size: 64,
                          emojiSize: 32,
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkWine,
                          ),
                        ),
                        subtitle: Text(
                          '${product.description}\n${formatPrice(product.price)}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          onPressed: () => onAdd(product, store.name),
                          icon: const Icon(
                            Icons.add_circle,
                            color: wine,
                            size: 29,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// FUNCIONES AUXILIARES

String categoryEmoji(String category) {
  switch (category) {
    case 'Hamburguesas':
      return '🍔';
    case 'Pizzerías':
      return '🍕';
    case 'Heladerías':
      return '🍦';
    case 'Almacenes':
      return '🛒';
    case 'Verdulerías':
      return '🥑';
    case 'Farmacias':
      return '💊';
    default:
      return '✨';
  }
}

String formatOrderDate(DateTime date) {
  final value = date.toLocal();

  String twoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

String formatPrice(double price) {
  return '\$${price.toStringAsFixed(0)}';
}

// ============================================================
// PANEL DE ESTADISTICAS DE MOVA
// ============================================================

class MovaAdminStatsScreen extends StatefulWidget {
  const MovaAdminStatsScreen({super.key});

  @override
  State<MovaAdminStatsScreen> createState() => _MovaAdminStatsScreenState();
}

class _MovaAdminStatsScreenState extends State<MovaAdminStatsScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return formatPrice(_number(value));
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'mova_admin_dashboard_stats',
      );

      final result = Map<String, dynamic>.from(response as Map);

      if (!mounted) return;

      setState(() {
        _stats = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      width: 225,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rose),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: wine, size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: darkWine,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: wine),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: darkWine,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyChart() {
    final days = (_stats['last_7_days'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final maxOrders = days.fold<double>(0, (maximum, day) {
      final value = _number(day['orders']);
      return value > maximum ? value : maximum;
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rose),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pedidos por día',
            style: TextStyle(color: darkWine, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 165,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final orders = _number(day['orders']);
                final height = maxOrders == 0
                    ? 5.0
                    : (orders / maxOrders * 105).clamp(5.0, 105.0);

                final date = day['date']?.toString() ?? '';
                final label = date.length >= 10 ? date.substring(8, 10) : date;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          orders.toInt().toString(),
                          style: const TextStyle(
                            color: wine,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: wine,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Cantidad de pedidos registrados en cada día.',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _topMerchants() {
    final merchants = (_stats['top_merchants'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (merchants.isEmpty) {
      return const Text(
        'Todavía no hay datos de comercios.',
        style: TextStyle(color: Colors.black54),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rose),
      ),
      child: Column(
        children: List.generate(merchants.length, (index) {
          final merchant = merchants[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: softRose,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: wine,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              merchant['name']?.toString() ?? 'Comercio',
              style: const TextStyle(
                color: darkWine,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('${_number(merchant['orders']).toInt()} pedidos'),
            trailing: Text(
              _money(merchant['gross_total']),
              style: const TextStyle(color: wine, fontWeight: FontWeight.bold),
            ),
          );
        }),
      ),
    );
  }

  Widget _statusSummary() {
    final statuses = Map<String, dynamic>.from(
      _stats['by_status'] as Map? ?? {},
    );

    if (statuses.isEmpty) {
      return const Text(
        'Todavía no hay estados registrados.',
        style: TextStyle(color: Colors.black54),
      );
    }

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: statuses.entries.map((entry) {
        return Chip(
          backgroundColor: softRose,
          label: Text(
            '${entry.key}: ${_number(entry.value).toInt()}',
            style: const TextStyle(
              color: darkWine,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Estadísticas MOVA',
          style: TextStyle(color: wine, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadStats,
            icon: const Icon(Icons.refresh, color: wine),
            tooltip: 'Actualizar estadísticas',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: wine, size: 45),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudieron cargar las estadísticas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkWine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _loadStats,
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: wine,
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Resumen general',
                    style: TextStyle(
                      color: darkWine,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Actividad y rendimiento de la plataforma',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statCard(
                        title: 'Pedidos totales',
                        value: _number(_stats['total_orders'])
                            .toInt()
                            .toString(),
                        icon: Icons.receipt_long,
                      ),
                      _statCard(
                        title: 'Facturación bruta',
                        value: _money(_stats['gross_total']),
                        icon: Icons.payments_outlined,
                        subtitle: 'Importe de todos los pedidos',
                      ),
                      _statCard(
                        title: 'Pedidos de hoy',
                        value: _number(_stats['today_orders'])
                            .toInt()
                            .toString(),
                        icon: Icons.today,
                      ),
                      _statCard(
                        title: 'Últimos 7 días',
                        value: _number(_stats['week_orders'])
                            .toInt()
                            .toString(),
                        icon: Icons.date_range,
                      ),
                      _statCard(
                        title: 'Pedidos entregados',
                        value: _number(_stats['delivered_orders'])
                            .toInt()
                            .toString(),
                        icon: Icons.check_circle_outline,
                      ),
                      _statCard(
                        title: 'Total entregado',
                        value: _money(_stats['delivered_total']),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _statCard(
                        title: 'Comercios activos',
                        value: _number(_stats['active_merchants'])
                            .toInt()
                            .toString(),
                        icon: Icons.storefront,
                      ),
                      _statCard(
                        title: 'Repartidores aprobados',
                        value: _number(_stats['approved_drivers'])
                            .toInt()
                            .toString(),
                        icon: Icons.delivery_dining,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Actividad semanal', Icons.bar_chart),
                  _weeklyChart(),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    'Comercios destacados',
                    Icons.emoji_events_outlined,
                  ),
                  _topMerchants(),
                  const SizedBox(height: 28),
                  _sectionTitle('Pedidos por estado', Icons.donut_large),
                  _statusSummary(),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'MOVA · Panel de administración',
                      style: TextStyle(color: Colors.black38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
