import 'package:flutter/material.dart';
import '../models/medicamento.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class EditarMedicamentoScreen extends StatefulWidget {
  final Medicamento medicamento;

  const EditarMedicamentoScreen({Key? key, required this.medicamento})
      : super(key: key);

  @override
  State<EditarMedicamentoScreen> createState() =>
      _EditarMedicamentoScreenState();
}

class _EditarMedicamentoScreenState extends State<EditarMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  final _storageService = StorageService();
  final _notificationService = NotificationService();

  late Map<int, bool> _diasSeleccionados;
  late int _horasIntervalo;
  late int _minutosIntervalo;
  late TimeOfDay _horaInicio;

  @override
  void initState() {
    super.initState();
    // Cargar datos existentes del medicamento
    _nombreController = TextEditingController(text: widget.medicamento.nombre);
    
    _diasSeleccionados = {
      1: widget.medicamento.diasSemana.contains(1),
      2: widget.medicamento.diasSemana.contains(2),
      3: widget.medicamento.diasSemana.contains(3),
      4: widget.medicamento.diasSemana.contains(4),
      5: widget.medicamento.diasSemana.contains(5),
      6: widget.medicamento.diasSemana.contains(6),
      7: widget.medicamento.diasSemana.contains(7),
    };
    
    _horasIntervalo = widget.medicamento.intervaloHoras;
    _minutosIntervalo = widget.medicamento.intervaloMinutos;
    
    final horaInicioParts = widget.medicamento.horaInicio.split(':');
    _horaInicio = TimeOfDay(
      hour: int.parse(horaInicioParts[0]),
      minute: int.parse(horaInicioParts[1]),
    );
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

  void _actualizarMedicamento() async {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(strokeWidth: 5),
      ),
    );

    // Crear medicamento actualizado con el mismo ID
    final medicamentoActualizado = Medicamento(
      id: widget.medicamento.id, // Mantener el mismo ID
      nombre: _nombreController.text.trim(),
      diasSemana: diasSeleccionados,
      intervaloHoras: _horasIntervalo,
      intervaloMinutos: _minutosIntervalo,
      horaInicio:
          '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}',
    );

    final actualizado =
        await _storageService.actualizarMedicamento(medicamentoActualizado);

    if (actualizado) {
      // Cancelar notificaciones anteriores y programar nuevas
      try {
        await _notificationService.cancelarNotificaciones(widget.medicamento.id);
        await _notificationService.programarNotificaciones(medicamentoActualizado);
        print('Notificaciones actualizadas correctamente');
      } catch (e) {
        print('Error al actualizar notificaciones: $e');
      }

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Medicamento actualizado correctamente',
              style: TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Volver a home con resultado
      }
    } else {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al actualizar el medicamento',
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
          'Editar Medicamento',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
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
            _buildSeccionTitulo('Días de la semana'),
            const SizedBox(height: 10),
            _buildSelectorDias(),
            const SizedBox(height: 30),
            _buildSeccionTitulo('Intervalo entre dosis'),
            const SizedBox(height: 10),
            _buildSelectorIntervalo(),
            const SizedBox(height: 30),
            _buildSeccionTitulo('Hora de primera dosis'),
            const SizedBox(height: 10),
            _buildSelectorHoraInicio(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _actualizarMedicamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              child: const Text(
                'ACTUALIZAR MEDICAMENTO',
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
      activeColor: Colors.orange,
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
                  color: Colors.orange.shade50,
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
          const Text(
            'Minutos:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.orange),
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
        backgroundColor: seleccionado ? Colors.orange : Colors.grey[200],
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
            const Icon(Icons.access_time, size: 36, color: Colors.orange),
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