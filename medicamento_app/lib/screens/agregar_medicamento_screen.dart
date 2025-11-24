import 'package:flutter/material.dart';
import '../models/medicamento.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AgregarMedicamentoScreen extends StatefulWidget {
  const AgregarMedicamentoScreen({Key? key}) : super(key: key);

  @override
  State<AgregarMedicamentoScreen> createState() =>
      _AgregarMedicamentoScreenState();
}

class _AgregarMedicamentoScreenState extends State<AgregarMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _storageService = StorageService();
  final _notificationService = NotificationService();

  // Días de la semana seleccionados
  final Map<int, bool> _diasSeleccionados = {
    1: false, // Lunes
    2: false, // Martes
    3: false, // Miércoles
    4: false, // Jueves
    5: false, // Viernes
    6: false, // Sábado
    7: false, // Domingo
  };

  int _horasIntervalo = 0;
  int _minutosIntervalo = 0;
  TimeOfDay _horaInicio = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    // No establecer valores por defecto, dejar en 0
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarHoraInicio() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.3),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _horaInicio = picked;
      });
    }
  }

  void _guardarMedicamento() async {
    // Validaciones del formulario
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor completa el nombre del medicamento',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Valida que el nombre no esté vacío después de trim
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El nombre del medicamento no puede estar vacío',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Valida que al menos un día esté seleccionado
    final diasSeleccionados = _diasSeleccionados.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar al menos un día',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Valida que el intervalo sea mayor a 0
    if (_horasIntervalo == 0 && _minutosIntervalo == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El intervalo debe ser mayor a 0',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Muestra indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(strokeWidth: 5),
      ),
    );

    // Debug: Imprimir valores
    print('Guardando - Horas: $_horasIntervalo, Minutos: $_minutosIntervalo');

    // Crear el medicamento
    final medicamento = Medicamento(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombreController.text.trim(),
      diasSemana: diasSeleccionados,
      intervaloHoras: _horasIntervalo,
      intervaloMinutos: _minutosIntervalo,
      horaInicio:
          '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}',
    );

    // Guardar en storage
    final guardado = await _storageService.agregarMedicamento(medicamento);

    if (guardado) {
      // Programar notificaciones con manejo de errores
      try {
        await _notificationService.programarNotificaciones(medicamento);
        print('Notificaciones programadas correctamente');
      } catch (e) {
        print('Error al programar notificaciones: $e');
        // Continuar aunque falle la programación de notificaciones
      }
      
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Medicamento guardado con alarmas programadas',
              style: TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context); // Volver a home
      }
    } else {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al guardar el medicamento',
              style: TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.red,
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
          'Agregar Medicamento',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Campo de nombre
            _buildSeccionTitulo('Nombre del medicamento'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nombreController,
              style: const TextStyle(fontSize: 22),
              decoration: InputDecoration(
                hintText: 'Ej: Paracetamol',
                hintStyle: TextStyle(fontSize: 20, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.medication, size: 32),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre del medicamento';
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            // Selección de días
            _buildSeccionTitulo('Días de la semana'),
            const SizedBox(height: 10),
            _buildSelectorDias(),

            const SizedBox(height: 30),

            // Intervalo
            _buildSeccionTitulo('Intervalo entre dosis'),
            const SizedBox(height: 10),
            _buildSelectorIntervalo(),

            const SizedBox(height: 30),

            // Hora de inicio
            _buildSeccionTitulo('Hora de primera dosis'),
            const SizedBox(height: 10),
            _buildSelectorHoraInicio(),

            const SizedBox(height: 40),

            // Botón guardar
            ElevatedButton(
              onPressed: _guardarMedicamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              child: const Text(
                'GUARDAR MEDICAMENTO',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSelectorDias() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildDiaCheckbox(1, 'Lunes'),
          _buildDiaCheckbox(2, 'Martes'),
          _buildDiaCheckbox(3, 'Miércoles'),
          _buildDiaCheckbox(4, 'Jueves'),
          _buildDiaCheckbox(5, 'Viernes'),
          _buildDiaCheckbox(6, 'Sábado'),
          _buildDiaCheckbox(7, 'Domingo'),
        ],
      ),
    );
  }

  Widget _buildDiaCheckbox(int dia, String nombre) {
    return CheckboxListTile(
      title: Text(
        nombre,
        style: const TextStyle(fontSize: 20),
      ),
      value: _diasSeleccionados[dia],
      onChanged: (value) {
        setState(() {
          _diasSeleccionados[dia] = value ?? false;
        });
      },
      activeColor: Colors.blue,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSelectorIntervalo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Horas
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Horas:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 36),
                color: Colors.red,
                onPressed: () {
                  if (_horasIntervalo > 0) {
                    setState(() => _horasIntervalo--);
                  }
                },
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_horasIntervalo',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 36),
                color: Colors.green,
                onPressed: () {
                  setState(() => _horasIntervalo++);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 15),
          
          // Minutos - Título
          const Text(
            'Minutos:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
          
          // Botones predefinidos
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildBotonMinuto(1),
              _buildBotonMinuto(5),
              _buildBotonMinuto(15),
              _buildBotonMinuto(30),
              _buildBotonMinuto(45),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Mostrar minutos seleccionados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.blue),
                const SizedBox(width: 10),
                Text(
                  '$_minutosIntervalo minutos',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonMinuto(int minutos) {
    final bool seleccionado = _minutosIntervalo == minutos;
    
    return ElevatedButton(
      onPressed: () {
        setState(() => _minutosIntervalo = minutos);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: seleccionado ? Colors.blue : Colors.grey[200],
        foregroundColor: seleccionado ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: seleccionado ? 5 : 1,
      ),
      child: Text(
        '$minutos min',
        style: TextStyle(
          fontSize: 18,
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSelectorHoraInicio() {
    return InkWell(
      onTap: _seleccionarHoraInicio,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 36, color: Colors.blue),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hora seleccionada:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _horaInicio.format(context),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 28, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}