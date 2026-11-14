import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class Notificaciones {
  Notificaciones._();
  static final Notificaciones instancia = Notificaciones._();

  static const int _idCuenta = 1;
  static const int _idFin = 2;
  static const String _icono = 'ic_stat_timer';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _iniciado = false;

  /// true si las notificaciones están permitidas.
  bool habilitado = false;

  /// true si el aviso de fin de descanso quedó programado en el sistema.
  bool finProgramado = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> iniciar() async {
    if (_iniciado) return;
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings(_icono),
        ),
      );
      _iniciado = true;
      debugPrint('Notificaciones: plugin inicializado');
      final concedido = await _android?.requestNotificationsPermission();
      debugPrint('Notificaciones: permiso solicitado -> $concedido');
    } catch (e) {
      debugPrint('Notificaciones: error al iniciar -> $e');
    }
  }

  Future<bool> _permitido() async {
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (e) {
      debugPrint('Notificaciones: error al revisar permiso -> $e');
      return false;
    }
  }

  /// Muestra la cuenta regresiva y programa el aviso de fin.
  /// Si ya había un descanso, lo reemplaza (sirve también para el +10 s).
  Future<void> iniciarDescanso({
    required String ejercicio,
    required Duration duracion,
  }) async {
    finProgramado = false;
    if (!_iniciado) await iniciar();
    if (!_iniciado) {
      debugPrint('Notificaciones: sigue sin inicializarse, se omite');
      return;
    }

    habilitado = await _permitido();
    debugPrint('Notificaciones: permitidas=$habilitado');
    if (!habilitado) return;

    try {
      final fin = DateTime.now().add(duracion);
      await _plugin.cancel(_idFin);
      await _plugin.show(
        _idCuenta,
        'Descanso · $ejercicio',
        'Termina cuando el contador llegue a cero',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'descanso_cuenta',
            'Cuenta regresiva del descanso',
            channelDescription: 'Muestra el tiempo que falta de descanso',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            playSound: false,
            enableVibration: false,
            showWhen: true,
            when: fin.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            timeoutAfter: duracion.inMilliseconds,
            visibility: NotificationVisibility.public,
            icon: _icono,
          ),
        ),
      );
      debugPrint('Notificaciones: cuenta mostrada (${duracion.inSeconds}s)');
    } catch (e) {
      debugPrint('Notificaciones: error al mostrar la cuenta -> $e');
    }

    try {
      await _programarFin(duracion);
      finProgramado = true;
      debugPrint('Notificaciones: aviso de fin programado');
    } catch (e) {
      finProgramado = false;
      debugPrint('Notificaciones: error al programar el fin -> $e');
    }
  }

  Future<void> _programarFin(Duration duracion) async {
    final fecha = tz.TZDateTime.now(tz.UTC).add(duracion);
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'descanso_fin',
        'Fin del descanso',
        channelDescription: 'Aviso cuando termina el descanso entre series',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        icon: _icono,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        _idFin,
        '¡Descanso terminado!',
        'Es hora de la siguiente serie',
        fecha,
        detalles,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Notificaciones: alarma exacta no disponible ($e), uso aproximada');
      await _plugin.zonedSchedule(
        _idFin,
        '¡Descanso terminado!',
        'Es hora de la siguiente serie',
        fecha,
        detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Quita la cuenta regresiva y cancela el aviso de fin.
  Future<void> cancelarDescanso() async {
    finProgramado = false;
    if (!_iniciado) return;
    try {
      await _plugin.cancel(_idCuenta);
      await _plugin.cancel(_idFin);
    } catch (e) {
      debugPrint('Notificaciones: error al cancelar -> $e');
    }
  }
}