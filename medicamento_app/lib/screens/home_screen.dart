import 'package:flutter/material.dart';
import '../models/medicamento.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'editar_medicamento_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  List<Medicamento> _medicamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    // Inicializar notificaciones y solicitar permisos
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    
    // Cargar medicamentos
    await _cargarMedicamentos();
  }

  Future<void> _cargarMedicamentos() async {
    setState(() => _isLoading = true);
    final medicamentos = await _storageService.obtenerMedicamentos();
    setState(() {
      _medicamentos = medicamentos;
      _isLoading = false;
    });
  }

  Future<void> _eliminarMedicamento(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar medicamento?',
          style: TextStyle(fontSize: 24),
        ),
        content: const Text(
          'Se eliminarán también todas las alarmas programadas.',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(fontSize: 20, color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Cancelar notificaciones primero
      await _notificationService.cancelarNotificaciones(id);
      
      // Luego eliminar de storage
      await _storageService.eliminarMedicamento(id);
      
      _cargarMedicamentos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicamento y alarmas eliminadas', style: TextStyle(fontSize: 18)),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mis Medicamentos',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, size: 32),
            tooltip: 'Probar notificación',
            onPressed: () async {
              try {
                await _notificationService.mostrarNotificacionPrueba();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '🔔 Notificación de prueba enviada',
                        style: TextStyle(fontSize: 18),
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print('Error al mostrar notificación: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: $e',
                        style: const TextStyle(fontSize: 16),
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 5),
            )
          : _medicamentos.isEmpty
              ? _buildEmptyState()
              : _buildMedicamentosList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/agregar');
          _cargarMedicamentos();
        },
        icon: const Icon(Icons.add, size: 32),
        label: const Text(
          'Agregar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 30),
            Text(
              'No hay medicamentos registrados',
              style: TextStyle(
                fontSize: 26,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'Presiona el botón "Agregar" para registrar tu primer medicamento',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicamentosList() {
    return RefreshIndicator(
      onRefresh: _cargarMedicamentos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicamentos.length,
        itemBuilder: (context, index) {
          final medicamento = _medicamentos[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () {
                // Aquí se puede navegar al detalle
                _mostrarDetalle(medicamento);
              },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medication,
                            size: 36,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            medicamento.nombre,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 32),
                          color: Colors.orange,
                          tooltip: 'Editar',
                          onPressed: () async {
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditarMedicamentoScreen(
                                  medicamento: medicamento,
                                ),
                              ),
                            );
                            // Si se editó, recargar la lista
                            if (resultado == true) {
                              _cargarMedicamentos();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 32),
                          color: Colors.red,
                          onPressed: () => _eliminarMedicamento(medicamento.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.calendar_today,
                      medicamento.getDiasTexto(),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.access_time,
                      'Cada ${medicamento.getIntervaloTexto()}',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.schedule,
                      'Inicio: ${medicamento.horaInicio}',
                    ),
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 10),
                    // Próxima dosis
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.alarm,
                            size: 28,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Próxima dosis:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  medicamento.getProximaDosisTexto(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarDetalle(Medicamento medicamento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          medicamento.nombre,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalleItem('Días:', medicamento.getDiasTexto()),
            const SizedBox(height: 12),
            _buildDetalleItem('Intervalo:', medicamento.getIntervaloTexto()),
            const SizedBox(height: 12),
            _buildDetalleItem('Hora de inicio:', medicamento.horaInicio),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}