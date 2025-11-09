import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:vetcare_app/services/client_service.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'manage_clients_screen.dart';
import 'manage_appointments_screen.dart';
import 'manage_invoices_screen.dart';
import 'perfil_screen.dart';
import 'notificaciones_screen.dart';
import 'quick_register_screen.dart';
import 'create_user_screen.dart';
import 'qr_screen.dart';
import 'all_patients_screen.dart';

class ReceptionistHomeScreen extends StatefulWidget {
  const ReceptionistHomeScreen({super.key});

  @override
  State<ReceptionistHomeScreen> createState() => _ReceptionistHomeScreenState();
}

class _ReceptionistHomeScreenState extends State<ReceptionistHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _ReceptionistDashboard(),
    ManageClientsScreen(),
    ManageAppointmentsScreen(),
    AllPatientsScreen(), // Todas las mascotas
    QRScreen(), // Scanner QR
    ManageInvoicesScreen(),
    PerfilScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Clientes',
    'Citas',
    'Mascotas',
    'Scanner QR',
    'Facturas',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Menú de acciones rápidas
          PopupMenuButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: 'Acciones Rápidas',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'quick_register',
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 22),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Registro Rápido', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Cliente walk-in sin cuenta', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'create_user',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppTheme.secondaryColor, size: 22),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Crear Usuario', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Con acceso a la app', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_appointment',
                child: Row(
                  children: [
                    Icon(Icons.event_available, color: Colors.orange, size: 22),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nueva Cita', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Agendar cita', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_invoice',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppTheme.accentColor, size: 22),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nueva Factura', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Generar factura', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'divider',
                enabled: false,
                child: Divider(),
              ),
              const PopupMenuItem(
                value: 'appointments_today',
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20),
                    SizedBox(width: 12),
                    Text('Ver Citas de Hoy'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'quick_register') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuickRegisterScreen(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Cliente walk-in registrado exitosamente'),
                        ],
                      ),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } else if (value == 'create_user') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateUserScreen(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              } else if (value == 'new_appointment') {
                setState(() {
                  _currentIndex = 2; // Índice de citas
                });
              } else if (value == 'new_invoice') {
                setState(() {
                  _currentIndex = 5; // Índice de facturas (ajustado)
                });
              } else if (value == 'appointments_today') {
                setState(() {
                  _currentIndex = 2;
                });
              }
            },
          ),
          // Notificaciones
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                _buildNavItem(1, Icons.people, 'Clientes'),
                _buildNavItem(2, Icons.calendar_today, 'Citas'),
                _buildNavItem(3, Icons.pets, 'Mascotas'),
                _buildNavItem(4, Icons.qr_code_scanner, 'QR'),
                _buildNavItem(5, Icons.receipt_long, 'Facturas'),
                _buildNavItem(6, Icons.person_outline, 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? AppTheme.primaryColor
                    : (isDark ? AppTheme.textSecondary : AppTheme.textLight),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? AppTheme.primaryColor
                      : (isDark ? AppTheme.textSecondary : AppTheme.textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceptionistDashboard extends StatefulWidget {
  const _ReceptionistDashboard();

  @override
  State<_ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<_ReceptionistDashboard> {
  int _totalClients = 0;
  int _walkInClients = 0;
  int _todayAppointments = 0;
  int _pendingInvoices = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final auth = context.read<AuthProvider>();
      final clientService = ClientService(auth.api);
      final appointmentService = AppointmentService(auth.api);

      final clients = await clientService.getClients();
      final appointments = await appointmentService.getAppointments();

      // Calcular estadísticas
      final now = DateTime.now();
      final todayAppointments = appointments.where((a) {
        final appointmentDate = a.date; // usar 'date' (nullable)
        if (appointmentDate == null) return false;
        return appointmentDate.year == now.year &&
            appointmentDate.month == now.month &&
            appointmentDate.day == now.day;
      }).length;

      final walkInCount = clients.where((c) => c.isWalkIn).length;

      if (mounted) {
        setState(() {
          _totalClients = clients.length;
          _walkInClients = walkInCount;
          _todayAppointments = todayAppointments;
          _pendingInvoices = 0; // TODO: Implementar cuando esté el servicio de facturas
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = context.watch<AuthProvider>().user?.name ?? 'Recepcionista';

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo personalizado
            Text(
              '¡Hola, $userName! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona tu día de trabajo',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),

            // Estadísticas del día
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.calendar_today,
                    title: 'Citas Hoy',
                    value: '$_todayAppointments',
                    color: Colors.orange,
                  ),
                  _StatCard(
                    icon: Icons.people,
                    title: 'Total Clientes',
                    value: '$_totalClients',
                    color: AppTheme.secondaryColor,
                  ),
                  _StatCard(
                    icon: Icons.flash_on,
                    title: 'Walk-in',
                    value: '$_walkInClients',
                    color: AppTheme.primaryColor,
                  ),
                  _StatCard(
                    icon: Icons.receipt_long,
                    title: 'Facturas',
                    value: '$_pendingInvoices',
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Tarjetas de acceso rápido
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _QuickActionCard(
                  icon: Icons.flash_on,
                  title: 'Registro\nRápido',
                  subtitle: 'Cliente walk-in',
                  color: AppTheme.primaryColor,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuickRegisterScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadStats();
                    }
                  },
                ),
                _QuickActionCard(
                  icon: Icons.person_add,
                  title: 'Nuevo\nUsuario',
                  subtitle: 'Con cuenta',
                  color: AppTheme.secondaryColor,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateUserScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadStats();
                    }
                  },
                ),
                _QuickActionCard(
                  icon: Icons.receipt_long,
                  title: 'Nueva\nFactura',
                  subtitle: 'Generar',
                  color: AppTheme.accentColor,
                  onTap: () {
                    // TODO: Navegar a crear factura
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función en desarrollo'),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.event_available,
                  title: 'Nueva\nCita',
                  subtitle: 'Agendar',
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Navegar a crear cita
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función en desarrollo'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Información sobre tipos de registro
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tipos de Registro',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.flash_on,
                    title: 'Registro Rápido (Walk-in)',
                    description: 'Para clientes que NO necesitan acceso a la app. '
                        'Solo se registra nombre, teléfono y mascota. Ideal para clientes ocasionales.',
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person_add,
                    title: 'Crear Usuario (Con Cuenta)',
                    description: 'Para usuarios que SÍ tendrán acceso a la app móvil. '
                        'Puedes elegir el rol: cliente, veterinario, recepcionista o admin. '
                        'Requiere email y contraseña.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para las estadísticas
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
