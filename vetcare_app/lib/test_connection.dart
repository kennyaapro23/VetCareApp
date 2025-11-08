import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ConnectionTestApp());
}

class ConnectionTestApp extends StatelessWidget {
  const ConnectionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test de Conexión',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ConnectionTestScreen(),
    );
  }
}

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  String _status = 'Presiona el botón para probar';
  bool _isLoading = false;
  Color _statusColor = Colors.grey;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Probando conexión...';
      _statusColor = Colors.orange;
    });

    try {
      // Test 1: Health check - USAR 127.0.0.1 con adb reverse
      print('🔍 Probando: http://127.0.0.1:8000/api/health');
      final healthResponse = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📨 Health Response: ${healthResponse.statusCode}');
      print('📨 Body: ${healthResponse.body}');

      if (healthResponse.statusCode == 200) {
        setState(() {
          _status = '✅ CONEXIÓN EXITOSA\n\n'
              'Backend Laravel: OK\n'
              'Status Code: ${healthResponse.statusCode}\n'
              'Response: ${healthResponse.body}';
          _statusColor = Colors.green;
          _isLoading = false;
        });

        // Test 2: Probar login
        await Future.delayed(const Duration(seconds: 1));
        await _testLogin();
      } else {
        setState(() {
          _status = '⚠️ RESPUESTA INESPERADA\n\n'
              'Status Code: ${healthResponse.statusCode}\n'
              'Body: ${healthResponse.body}';
          _statusColor = Colors.orange;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _status = '❌ ERROR DE CONEXIÓN\n\n'
            'No se pudo conectar al backend Laravel.\n\n'
            'Error: $e\n\n'
            'Verifica que:\n'
            '1. Laravel esté corriendo en 0.0.0.0:8000\n'
            '2. Tu PC y emulador estén en la misma red WiFi\n'
            '3. El firewall permita conexiones al puerto 8000';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    try {
      print('🔍 Probando login: http://127.0.0.1:8000/api/auth/login');

      final loginResponse = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': 'cliente@veterinaria.com',
          'password': 'password123',
        }),
      ).timeout(const Duration(seconds: 10));

      print('📨 Login Response: ${loginResponse.statusCode}');
      print('📨 Body: ${loginResponse.body}');

      if (loginResponse.statusCode == 200) {
        final data = jsonDecode(loginResponse.body);
        setState(() {
          _status = '✅ CONEXIÓN Y LOGIN EXITOSOS\n\n'
              'Backend Laravel: OK ✓\n'
              'Ruta /health: OK ✓\n'
              'Ruta /auth/login: OK ✓\n\n'
              'Usuario: ${data['user']?['nombre'] ?? data['user']?['email']}\n'
              'Token recibido: ${data['token'] != null ? "SÍ" : "NO"}\n\n'
              '🎉 TODO FUNCIONA CORRECTAMENTE';
          _statusColor = Colors.green;
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = '⚠️ LOGIN FALLÓ\n\n'
              'Health Check: OK ✓\n'
              'Login: FALLÓ ✗\n\n'
              'Status: ${loginResponse.statusCode}\n'
              'Response: ${loginResponse.body}';
          _statusColor = Colors.orange;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error en login: $e');
      setState(() {
        _status = '⚠️ LOGIN ERROR\n\n'
            'Health Check: OK ✓\n'
            'Login: ERROR ✗\n\n'
            'Error: $e';
        _statusColor = Colors.orange;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Conexión Backend'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _isLoading
                  ? Icons.sync
                  : _statusColor == Colors.green
                      ? Icons.check_circle
                      : _statusColor == Colors.red
                          ? Icons.error
                          : Icons.info,
              size: 64,
              color: _statusColor,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _statusColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Probando...' : 'Probar Conexión'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'URL Backend: http://127.0.0.1:8000/api/\n(Requiere: adb reverse tcp:8000 tcp:8000)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
