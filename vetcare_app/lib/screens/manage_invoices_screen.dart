import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/models/factura.dart';
import 'package:vetcare_app/models/client_model.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/factura_service.dart';
import 'package:vetcare_app/services/client_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ManageInvoicesScreen extends StatefulWidget {
  const ManageInvoicesScreen({super.key});

  @override
  State<ManageInvoicesScreen> createState() => _ManageInvoicesScreenState();
}

class _ManageInvoicesScreenState extends State<ManageInvoicesScreen> {
  List<Factura> _facturas = [];
  List<Factura> _filteredFacturas = [];
  bool _isLoading = true;
  String _filterStatus = 'todas';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic> _estadisticas = {
    'total': 0.0,
    'pagadas': 0,
    'pendientes': 0,
    'anuladas': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadFacturas();
    _loadEstadisticas();
  }

  Future<void> _loadFacturas() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final facturaService = FacturaService(apiService);
      final facturas = await facturaService.getFacturas();
      setState(() {
        _facturas = facturas;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar facturas: $e')),
        );
      }
    }
  }

  Future<void> _loadEstadisticas() async {
    try {
      final apiService = context.read<ApiService>();
      final facturaService = FacturaService(apiService);
      final stats = await facturaService.getEstadisticas();
      setState(() => _estadisticas = stats);
    } catch (e) {
      // Error silencioso
    }
  }

  void _applyFilters() {
    var filtered = _facturas;

    // Filtrar por estado
    if (_filterStatus != 'todas') {
      filtered = filtered.where((f) => f.estado == _filterStatus).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((f) {
        final id = f.id?.toString() ?? '';
        final clienteId = f.clienteId.toString();
        final total = f.total.toString();
        final searchLower = _searchQuery.toLowerCase();
        return id.contains(searchLower) ||
            clienteId.contains(searchLower) ||
            total.contains(searchLower);
      }).toList();
    }

    // Ordenar por fecha (más reciente primero)
    filtered.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    setState(() => _filteredFacturas = filtered);
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
      _applyFilters();
    });
  }

  void _searchFacturas(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  Future<void> _deleteFactura(Factura factura) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar la factura #${factura.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = context.read<ApiService>();
        final facturaService = FacturaService(apiService);
        await facturaService.eliminarFactura(factura.id.toString());
        _loadFacturas();
        _loadEstadisticas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Factura eliminada exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar factura: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Estadísticas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Pagadas',
                        value: _estadisticas['pagadas']?.toString() ?? '0',
                        icon: Icons.check_circle,
                        color: AppTheme.successColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Pendientes',
                        value: _estadisticas['pendientes']?.toString() ?? '0',
                        icon: Icons.pending,
                        color: AppTheme.warningColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Recaudado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'S/. ${(_estadisticas['total'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                // Búsqueda
                TextField(
                  controller: _searchController,
                  onChanged: _searchFacturas,
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID o cliente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchFacturas('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkBackground
                        : AppTheme.lightBackground,
                  ),
                ),
                const SizedBox(height: 12),
                // Filtros de estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todas',
                        isSelected: _filterStatus == 'todas',
                        onTap: () => _filterByStatus('todas'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pagadas',
                        isSelected: _filterStatus == 'pagado',
                        onTap: () => _filterByStatus('pagado'),
                        color: AppTheme.successColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pendientes',
                        isSelected: _filterStatus == 'pendiente',
                        onTap: () => _filterByStatus('pendiente'),
                        color: AppTheme.warningColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Anuladas',
                        isSelected: _filterStatus == 'anulado',
                        onTap: () => _filterByStatus('anulado'),
                        color: AppTheme.errorColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de facturas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFacturas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty && _filterStatus == 'todas'
                                  ? 'No hay facturas registradas'
                                  : 'No se encontraron facturas',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadFacturas();
                          await _loadEstadisticas();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFacturas.length,
                          itemBuilder: (context, index) {
                            final factura = _filteredFacturas[index];
                            return _FacturaCard(
                              factura: factura,
                              isDark: isDark,
                              onTap: () => _showFacturaDetails(factura),
                              onEdit: () => _showFacturaForm(factura: factura),
                              onDelete: () => _deleteFactura(factura),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFacturaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Factura'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showFacturaDetails(Factura factura) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FacturaDetailsSheet(factura: factura),
    );
  }

  void _showFacturaForm({Factura? factura}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FacturaFormScreen(factura: factura),
      ),
    );
    if (result == true) {
      _loadFacturas();
      _loadEstadisticas();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor
              : (isDark ? AppTheme.darkBackground : AppTheme.lightBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.textPrimary : AppTheme.textDark),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FacturaCard extends StatelessWidget {
  final Factura factura;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FacturaCard({
    required this.factura,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: factura.estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: factura.estadoColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Factura #${factura.id ?? "N/A"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: factura.estadoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              factura.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: factura.estadoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        factura.totalFormateado,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cliente ID: ${factura.clienteId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      if (factura.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(factura.createdAt!),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Acciones
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                          SizedBox(width: 12),
                          Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FacturaDetailsSheet extends StatelessWidget {
  final Factura factura;

  const _FacturaDetailsSheet({required this.factura});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Factura #${factura.id ?? "N/A"}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: factura.estadoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              factura.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: factura.estadoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Total
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        factura.totalFormateado,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Detalles
                Text(
                  'Detalles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.person,
                  label: 'Cliente ID',
                  value: factura.clienteId.toString(),
                  isDark: isDark,
                ),
                if (factura.citaId != null)
                  _DetailRow(
                    icon: Icons.event,
                    label: 'Cita ID',
                    value: factura.citaId.toString(),
                    isDark: isDark,
                  ),
                if (factura.metodoPago != null)
                  _DetailRow(
                    icon: Icons.payment,
                    label: 'Método de Pago',
                    value: factura.metodoPago!,
                    isDark: isDark,
                  ),
                if (factura.createdAt != null)
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha de Creación',
                    value: dateFormat.format(factura.createdAt!),
                    isDark: isDark,
                  ),
                if (factura.updatedAt != null)
                  _DetailRow(
                    icon: Icons.update,
                    label: 'Última Actualización',
                    value: dateFormat.format(factura.updatedAt!),
                    isDark: isDark,
                  ),
                // Detalles adicionales
                if (factura.detalles != null && factura.detalles!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Información Adicional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: factura.detalles!.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.textSecondary
                                      : AppTheme.textLight,
                                ),
                              ),
                              Text(
                                entry.value.toString(),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Formulario de Factura
class _FacturaFormScreen extends StatefulWidget {
  final Factura? factura;

  const _FacturaFormScreen({this.factura});

  @override
  State<_FacturaFormScreen> createState() => _FacturaFormScreenState();
}

class _FacturaFormScreenState extends State<_FacturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _totalController;
  String? _selectedClientId;
  String _selectedEstado = 'pendiente';
  String? _selectedMetodoPago;
  List<ClientModel> _clients = [];
  bool _isLoading = false;
  bool _isLoadingData = true;

  final List<String> _estados = ['pendiente', 'pagado', 'anulado'];
  final List<String> _metodosPago = ['efectivo', 'tarjeta', 'transferencia', 'yape', 'plin'];

  @override
  void initState() {
    super.initState();
    _totalController = TextEditingController(
      text: widget.factura?.total.toStringAsFixed(2) ?? '',
    );
    _selectedEstado = widget.factura?.estado ?? 'pendiente';
    _selectedMetodoPago = widget.factura?.metodoPago;
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final apiService = context.read<ApiService>();
      final clientService = ClientService(apiService);
      final clients = await clientService.getClients();
      setState(() {
        _clients = clients;
        if (widget.factura != null) {
          _selectedClientId = widget.factura!.clienteId.toString();
        }
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
    }
  }

  Future<void> _saveFactura() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();
      final facturaService = FacturaService(apiService);

      final data = {
        'cliente_id': int.parse(_selectedClientId!),
        'total': double.parse(_totalController.text.trim()),
        'estado': _selectedEstado,
        if (_selectedMetodoPago != null) 'metodo_pago': _selectedMetodoPago,
      };

      if (widget.factura == null) {
        await facturaService.crearFactura(data);
      } else {
        await facturaService.actualizarFactura(
          widget.factura!.id.toString(),
          data,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.factura == null
                  ? 'Factura creada exitosamente'
                  : 'Factura actualizada exitosamente',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.factura == null ? 'Nueva Factura' : 'Editar Factura'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Cliente
                  DropdownButtonFormField<String>(
                    value: _selectedClientId,
                    decoration: InputDecoration(
                      labelText: 'Cliente *',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _clients.map((client) {
                      return DropdownMenuItem(
                        value: client.id,
                        child: Text(client.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedClientId = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Selecciona un cliente';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Total
                  TextFormField(
                    controller: _totalController,
                    decoration: InputDecoration(
                      labelText: 'Total *',
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: 'S/. ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El total es requerido';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Ingresa un número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Estado
                  DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    decoration: InputDecoration(
                      labelText: 'Estado *',
                      prefixIcon: const Icon(Icons.info),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _estados.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(estado.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedEstado = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Método de pago
                  DropdownButtonFormField<String>(
                    value: _selectedMetodoPago,
                    decoration: InputDecoration(
                      labelText: 'Método de Pago',
                      prefixIcon: const Icon(Icons.payment),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _metodosPago.map((metodo) {
                      return DropdownMenuItem(
                        value: metodo,
                        child: Text(metodo.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMetodoPago = value);
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveFactura,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.factura == null
                                  ? 'Crear Factura'
                                  : 'Guardar Cambios',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }
}

