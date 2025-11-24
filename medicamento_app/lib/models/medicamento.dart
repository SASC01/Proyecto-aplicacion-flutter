class Medicamento {
  String id;
  String nombre;
  List<int> diasSemana; // 1=Lunes, 2=Martes, ... 7=Domingo
  int intervaloHoras;
  int intervaloMinutos;
  String horaInicio; // Formato "HH:mm"
  bool activo;

  Medicamento({
    required this.id,
    required this.nombre,
    required this.diasSemana,
    required this.intervaloHoras,
    required this.intervaloMinutos,
    required this.horaInicio,
    this.activo = true,
  });

  // Convertir a JSON para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'diasSemana': diasSemana,
      'intervaloHoras': intervaloHoras,
      'intervaloMinutos': intervaloMinutos,
      'horaInicio': horaInicio,
      'activo': activo,
    };
  }

  // Crear desde JSON
  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      id: json['id'],
      nombre: json['nombre'],
      diasSemana: List<int>.from(json['diasSemana']),
      intervaloHoras: json['intervaloHoras'],
      intervaloMinutos: json['intervaloMinutos'],
      horaInicio: json['horaInicio'],
      activo: json['activo'] ?? true,
    );
  }

  // Obtener nombre del día
  static String getNombreDia(int dia) {
    const dias = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      7: 'Domingo',
    };
    return dias[dia] ?? '';
  }

  // Obtener string con los días seleccionados
  String getDiasTexto() {
    if (diasSemana.length == 7) {
      return 'Todos los días';
    }
    return diasSemana.map((d) => getNombreDia(d)).join(', ');
  }

  // Obtener intervalo en texto
  String getIntervaloTexto() {
    if (intervaloHoras > 0 && intervaloMinutos > 0) {
      return '$intervaloHoras hrs y $intervaloMinutos min';
    } else if (intervaloHoras > 0) {
      return '$intervaloHoras hrs';
    } else {
      return '$intervaloMinutos min';
    }
  }

  // Calcular la próxima dosis
  DateTime? calcularProximaDosis() {
    final now = DateTime.now();
    final hoyDiaSemana = now.weekday; // 1=Lunes, 7=Domingo

    // Si hoy está en los días seleccionados
    if (diasSemana.contains(hoyDiaSemana)) {
      final horaInicioParts = horaInicio.split(':');
      final horaInicial = int.parse(horaInicioParts[0]);
      final minutoInicial = int.parse(horaInicioParts[1]);

      // Crear la primera dosis de hoy
      var proximaDosis = DateTime(
        now.year,
        now.month,
        now.day,
        horaInicial,
        minutoInicial,
      );

      // Si la primera dosis ya pasó, calcular la siguiente según el intervalo
      while (proximaDosis.isBefore(now)) {
        proximaDosis = proximaDosis.add(Duration(
          hours: intervaloHoras,
          minutes: intervaloMinutos,
        ));
        
        // Si pasamos al día siguiente, buscar el próximo día válido
        if (proximaDosis.day != now.day) {
          return _buscarProximoDiaValido(now);
        }
      }

      return proximaDosis;
    } else {
      // Buscar el próximo día válido
      return _buscarProximoDiaValido(now);
    }
  }

  // Buscar el próximo día válido de medicación
  DateTime? _buscarProximoDiaValido(DateTime desde) {
    for (int i = 1; i <= 7; i++) {
      final proximaFecha = desde.add(Duration(days: i));
      final proximoDiaSemana = proximaFecha.weekday;

      if (diasSemana.contains(proximoDiaSemana)) {
        final horaInicioParts = horaInicio.split(':');
        final horaInicial = int.parse(horaInicioParts[0]);
        final minutoInicial = int.parse(horaInicioParts[1]);

        return DateTime(
          proximaFecha.year,
          proximaFecha.month,
          proximaFecha.day,
          horaInicial,
          minutoInicial,
        );
      }
    }
    return null;
  }

  // Obtener texto de próxima dosis
  String getProximaDosisTexto() {
    final proxima = calcularProximaDosis();
    if (proxima == null) return 'No programada';

    final now = DateTime.now();
    final diferencia = proxima.difference(now);

    // Si es hoy
    if (proxima.year == now.year &&
        proxima.month == now.month &&
        proxima.day == now.day) {
      final hora = proxima.hour.toString().padLeft(2, '0');
      final minuto = proxima.minute.toString().padLeft(2, '0');
      
      if (diferencia.inMinutes < 60) {
        return 'Hoy a las $hora:$minuto (en ${diferencia.inMinutes} min)';
      } else {
        return 'Hoy a las $hora:$minuto';
      }
    }

    // Si es mañana
    final manana = now.add(const Duration(days: 1));
    if (proxima.year == manana.year &&
        proxima.month == manana.month &&
        proxima.day == manana.day) {
      final hora = proxima.hour.toString().padLeft(2, '0');
      final minuto = proxima.minute.toString().padLeft(2, '0');
      return 'Mañana a las $hora:$minuto';
    }

    // Otro día
    final diasNombres = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final hora = proxima.hour.toString().padLeft(2, '0');
    final minuto = proxima.minute.toString().padLeft(2, '0');
    return '${diasNombres[proxima.weekday]} a las $hora:$minuto';
  }
}