import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/medicamento.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inicializar timezones
      tz.initializeTimeZones();
      
      // Intentar obtener la zona horaria local, con fallback
      try {
        tz.setLocalLocation(tz.getLocation('America/Merida'));
      } catch (e) {
        print('Error al establecer zona horaria Mérida, usando local del sistema');
        final String timeZoneName = DateTime.now().timeZoneName;
        try {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
        } catch (e2) {
          print('Usando UTC como fallback');
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }

      // Configuración de Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración de iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      print('NotificationService inicializado correctamente');
    } catch (e) {
      print('Error al inicializar NotificationService: $e');
      rethrow;
    }
  }

  // Manejar cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    print('Notificación tocada: ${response.payload}');
    // Aquí puedes navegar a una pantalla específica si lo deseas
  }

  // Solicitar permisos (especialmente importante en iOS y Android 13+)
  Future<bool> requestPermissions() async {
    // Android
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // iOS
    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return true;
  }

  // Programar notificaciones para un medicamento
  Future<void> programarNotificaciones(Medicamento medicamento) async {
    try {
      await initialize();

      print('Programando notificaciones para: ${medicamento.nombre}');

      // Cancelar notificaciones previas de este medicamento
      await cancelarNotificaciones(medicamento.id);

      // Obtener la hora de inicio
      final horaInicioParts = medicamento.horaInicio.split(':');
      final horaInicial = int.parse(horaInicioParts[0]);
      final minutoInicial = int.parse(horaInicioParts[1]);

      // Programar notificaciones para cada día seleccionado
      for (int dia in medicamento.diasSemana) {
        await _programarNotificacionesDia(
          medicamento,
          dia,
          horaInicial,
          minutoInicial,
        );
      }
      
      print('Notificaciones programadas exitosamente');
    } catch (e) {
      print('Error en programarNotificaciones: $e');
      rethrow;
    }
  }

  // Programar notificaciones para un día específico
  Future<void> _programarNotificacionesDia(
    Medicamento medicamento,
    int diaSemana,
    int horaInicial,
    int minutoInicial,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    
    // Calcular el próximo día que coincida
    int diasHastaProximoDia = (diaSemana - now.weekday) % 7;
    if (diasHastaProximoDia == 0 && 
        (now.hour > horaInicial || 
         (now.hour == horaInicial && now.minute >= minutoInicial))) {
      diasHastaProximoDia = 7;
    }

    var proximaFecha = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + diasHastaProximoDia,
      horaInicial,
      minutoInicial,
    );

    // Programar múltiples notificaciones a lo largo del día según el intervalo
    int notificacionIndex = 0;
    const maxNotificacionesPorDia = 10; // Máximo 10 tomas por día

    while (notificacionIndex < maxNotificacionesPorDia) {
      final notificationId = _generarNotificationId(
        medicamento.id,
        diaSemana,
        notificacionIndex,
      );

      await _notifications.zonedSchedule(
        notificationId,
        '💊 Hora de tu medicamento',
        '${medicamento.nombre} - Es hora de tomar tu dosis',
        proximaFecha,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      // Calcular la siguiente toma
      proximaFecha = proximaFecha.add(Duration(
        hours: medicamento.intervaloHoras,
        minutes: medicamento.intervaloMinutos,
      ));

      // Si la siguiente toma es al día siguiente, detenemos
      if (proximaFecha.day != proximaFecha.subtract(Duration(
        hours: medicamento.intervaloHoras,
        minutes: medicamento.intervaloMinutos,
      )).day) {
        break;
      }

      notificacionIndex++;
    }
  }

  // Generar ID único para cada notificación
  int _generarNotificationId(String medicamentoId, int dia, int index) {
    // Usamos los últimos dígitos del ID del medicamento + día + índice
    final idNum = int.tryParse(medicamentoId.substring(
      medicamentoId.length > 8 ? medicamentoId.length - 8 : 0,
    )) ?? 0;
    return (idNum % 1000) * 100 + dia * 10 + index;
  }

  // Configuración de la notificación
  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medicamento_channel',
      'Recordatorios de Medicamentos',
      channelDescription: 'Notificaciones para recordar tomar medicamentos',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      // Removemos el sonido personalizado y usamos el predeterminado
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Cancelar todas las notificaciones de un medicamento
  Future<void> cancelarNotificaciones(String medicamentoId) async {
    // Cancelar todas las posibles notificaciones de este medicamento
    for (int dia = 1; dia <= 7; dia++) {
      for (int index = 0; index < 10; index++) {
        final notificationId = _generarNotificationId(medicamentoId, dia, index);
        await _notifications.cancel(notificationId);
      }
    }
  }

  // Cancelar todas las notificaciones
  Future<void> cancelarTodasLasNotificaciones() async {
    await _notifications.cancelAll();
  }

  // Mostrar notificación inmediata (para testing)
  Future<void> mostrarNotificacionPrueba() async {
    try {
      await initialize();
      
      print('Mostrando notificación de prueba...');
      
      await _notifications.show(
        999,
        '💊 Notificación de prueba',
        'Las notificaciones están funcionando correctamente',
        _notificationDetails(),
      );
      
      print('Notificación de prueba enviada');
    } catch (e) {
      print('Error al mostrar notificación de prueba: $e');
      rethrow;
    }
  }

  // Obtener notificaciones pendientes
  Future<List<PendingNotificationRequest>> obtenerNotificacionesPendientes() async {
    return await _notifications.pendingNotificationRequests();
  }
}