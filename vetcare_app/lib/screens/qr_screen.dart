import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/qr_service.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  bool _showScanner = false;
  Map<String, dynamic>? _scannedData;

  void _toggleScanner() {
    setState(() {
      _showScanner = !_showScanner;
      if (_showScanner) _scannedData = null;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _showScanner = false);

    try {
      final auth = context.read<AuthProvider>();
      final service = QRService(auth.api);
      final data = await service.searchByQR(code);
      setState(() => _scannedData = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showScanner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Escanear QR'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleScanner,
          ),
        ),
        body: MobileScanner(
          onDetect: _onDetect,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Código QR')),
      body: _scannedData != null ? _buildScannedResult() : _buildQRGenerator(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear QR'),
      ),
    );
  }

  Widget _buildQRGenerator() {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Center(child: Text('Sin sesión'));

    final qrData = 'VETCARE:${user.id}:${user.email}';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tu código QR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Chip(label: Text(user.role, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedResult() {
    final data = _scannedData!;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _scannedData = null),
                ),
                const Expanded(child: Text('Resultado del escaneo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.containsKey('nombre'))
                      Text(data['nombre'], style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (data.containsKey('email'))
                      _InfoRow(Icons.email, data['email']),
                    if (data.containsKey('telefono'))
                      _InfoRow(Icons.phone, data['telefono']),
                    if (data.containsKey('direccion'))
                      _InfoRow(Icons.location_on, data['direccion']),
                    if (data.containsKey('especie'))
                      _InfoRow(Icons.pets, data['especie']),
                    if (data.containsKey('raza'))
                      _InfoRow(Icons.category, data['raza']),
                    const SizedBox(height: 16),
                    if (data.containsKey('historial_medico') && data['historial_medico'] is List) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Historial Médico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...((data['historial_medico'] as List).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• ${e.toString()}'),
                      ))),
                    ],
                    if (data.containsKey('servicios_recientes') && data['servicios_recientes'] is List) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Servicios Recientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...((data['servicios_recientes'] as List).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• ${e.toString()}'),
                      ))),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

