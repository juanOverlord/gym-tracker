import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/rutina.dart';
import '../models/sesion.dart';
import 'almacen.dart';
import 'notificaciones.dart';

class SesionController extends ChangeNotifier {
  SesionController._();
  static final SesionController instancia = SesionController._();

  final Almacen _almacen = Almacen();

  Rutina? rutina;
  DateTime? inicio;
  Duration transcurrido = Duration.zero;
  List<EjercicioSesion> ejercicios = [];
  Map<String, EjercicioSesion> anteriores = {};
  List<Sesion> _historial = [];

  int? descansoIndice;
  int descansoRestante = 0;
  int descansoTotal = 0;
  DateTime? _descansoFin;

  Timer? _timer;
  bool _iniciando = false;

  bool get activa => rutina != null;

  int get seriesTotales =>
      ejercicios.fold(0, (suma, e) => suma + e.series.length);

  int get seriesCompletadas => ejercicios.fold(
      0, (suma, e) => suma + e.series.where((s) => s.completada).length);

  EjercicioSesion? _buscarPrevio(String ejercicioId) {
    for (final s in _historial.reversed) {
      for (final x in s.ejercicios) {
        if (x.ejercicio.id == ejercicioId) return x;
      }
    }
    return null;
  }

  EjercicioSesion _nuevoEjercicioSesion(Ejercicio e) {
    final previo = _buscarPrevio(e.id);
    if (previo != null) anteriores[e.id] = previo;
    return EjercicioSesion(
      ejercicio: e,
      series: List.generate(3, (_) => Serie()),
      descansoSegundos: previo?.descansoSegundos ?? 90,
    );
  }

  Future<void> iniciar(Rutina r) async {
    if (activa || _iniciando) return;
    _iniciando = true;

    _historial = await _almacen.cargarSesiones();

    anteriores = {};
    rutina = r;
    inicio = DateTime.now();
    transcurrido = Duration.zero;
    _detenerDescanso();
    ejercicios = r.ejercicios.map(_nuevoEjercicioSesion).toList();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _iniciando = false;
    notifyListeners();
  }

  void _tick() {
    final ahora = DateTime.now();
    transcurrido = ahora.difference(inicio!);

    if (descansoIndice != null && _descansoFin != null) {
      final msRestantes = _descansoFin!.difference(ahora).inMilliseconds;
      if (msRestantes <= 0) {
        // El aviso del sistema se encarga; si no se pudo programar, avisamos aquí.
        _detenerDescanso(cancelarNotificaciones: false);
        if (!Notificaciones.instancia.finProgramado) _alertar();
        Notificaciones.instancia.finProgramado = false;
      } else {
        descansoRestante = (msRestantes / 1000).ceil();
      }
    }
    notifyListeners();
  }

  Future<void> _alertar() async {
    try {
      await HapticFeedback.vibrate();
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  void _detenerDescanso({bool cancelarNotificaciones = true}) {
    descansoIndice = null;
    descansoRestante = 0;
    descansoTotal = 0;
    _descansoFin = null;
    if (cancelarNotificaciones) {
      Notificaciones.instancia.cancelarDescanso();
    }
  }
  void _notificarDescanso() {
    debugPrint('Sesion: _notificarDescanso (indice=$descansoIndice)');
    if (descansoIndice == null || _descansoFin == null) return;
    final restante = _descansoFin!.difference(DateTime.now());
    if (restante.isNegative) return;
    Notificaciones.instancia.iniciarDescanso(
      ejercicio: ejercicios[descansoIndice!].ejercicio.nombre,
      duracion: restante,
    );
  }

  void cambiarSerieCompletada(int indiceEjercicio, bool completada) {
    final e = ejercicios[indiceEjercicio];
    if (completada && e.descansoSegundos > 0) {
      descansoIndice = indiceEjercicio;
      descansoRestante = e.descansoSegundos;
      descansoTotal = e.descansoSegundos;
      _descansoFin = DateTime.now().add(Duration(seconds: e.descansoSegundos));
      _notificarDescanso();
    } else if (!completada && descansoIndice == indiceEjercicio) {
      _detenerDescanso();
    }
    notifyListeners();
  }

  void omitirDescanso() {
    _detenerDescanso();
    notifyListeners();
  }

  void agregarTiempoDescanso(int segundos) {
    if (_descansoFin == null) return;
    _descansoFin = _descansoFin!.add(Duration(seconds: segundos));
    descansoTotal += segundos;
    descansoRestante += segundos;
    _notificarDescanso();
    notifyListeners();
  }

  void cambiarDescanso(int indiceEjercicio, int segundos) {
    ejercicios[indiceEjercicio].descansoSegundos = segundos;
    notifyListeners();
  }

  void agregarSerie(int indiceEjercicio) {
    ejercicios[indiceEjercicio].series.add(Serie());
    notifyListeners();
  }

  void eliminarSerie(int indiceEjercicio, int indiceSerie) {
    ejercicios[indiceEjercicio].series.removeAt(indiceSerie);
    notifyListeners();
  }

  /// Agrega un ejercicio solo a la sesión en curso (no cambia la rutina guardada).
  void agregarEjercicio(Ejercicio e) {
    ejercicios.add(_nuevoEjercicioSesion(e));
    notifyListeners();
  }

    /// Sube (delta = -1) o baja (delta = 1) un ejercicio dentro de la sesión.
  void moverEjercicio(int indice, int delta) {
    final nuevo = indice + delta;
    if (nuevo < 0 || nuevo >= ejercicios.length) return;
    final e = ejercicios.removeAt(indice);
    ejercicios.insert(nuevo, e);

    // Mantener bien ubicado el descanso en curso
    if (descansoIndice == indice) {
      descansoIndice = nuevo;
    } else if (descansoIndice == nuevo) {
      descansoIndice = indice;
    }
    notifyListeners();
  }

    /// Quita un ejercicio de la sesión en curso (no cambia la rutina guardada).
  void eliminarEjercicio(int indice) {
    if (indice < 0 || indice >= ejercicios.length) return;
    ejercicios.removeAt(indice);

    // Mantener bien ubicado el descanso en curso
    if (descansoIndice != null) {
      if (descansoIndice == indice) {
        _detenerDescanso();
      } else if (descansoIndice! > indice) {
        descansoIndice = descansoIndice! - 1;
      }
    }
    notifyListeners();
  }

  /// Guarda la sesión y la cierra. Devuelve true si se guardó algo.
    /// Guarda la sesión y la cierra. Devuelve la sesión guardada,
  /// o null si no había series completadas.
  Future<Sesion?> terminar() async {
    final aGuardar = ejercicios
        .map((e) => EjercicioSesion(
              ejercicio: e.ejercicio,
              series: e.series.where((s) => s.completada).toList(),
              nota: e.nota,
              descansoSegundos: e.descansoSegundos,
            ))
        .where((e) => e.series.isNotEmpty)
        .toList();

    Sesion? guardada;
    if (aGuardar.isNotEmpty) {
      final sesiones = await _almacen.cargarSesiones();
      guardada = Sesion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rutinaNombre: rutina!.nombre,
        inicio: inicio!,
        duracionSegundos: DateTime.now().difference(inicio!).inSeconds,
        ejercicios: aGuardar,
      );
      sesiones.add(guardada);
      await _almacen.guardarSesiones(sesiones);
    }
    _limpiar();
    return guardada;
  }

  void descartar() => _limpiar();

  void _limpiar() {
    _timer?.cancel();
    _timer = null;
    rutina = null;
    inicio = null;
    transcurrido = Duration.zero;
    ejercicios = [];
    anteriores = {};
    _historial = [];
    _detenerDescanso();
    notifyListeners();
  }
}