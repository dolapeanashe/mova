import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String result;
  bool success = false;

  try {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      publishableKey: const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
    );

    final rows = await Supabase.instance.client
        .from('merchants')
        .select('id')
        .limit(1);

    success = true;
    result =
        'MOVA_SUPABASE_OK\n'
        'Conexión y consulta correctas.\n'
        'Filas recibidas: ${rows.length}';
  } catch (error) {
    result = 'MOVA_SUPABASE_ERROR\n$error';
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFAF6F2),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      success ? Icons.check_circle : Icons.error,
                      size: 55,
                      color: success ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'PRUEBA DE SUPABASE - MOVA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SelectableText(
                      result,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}