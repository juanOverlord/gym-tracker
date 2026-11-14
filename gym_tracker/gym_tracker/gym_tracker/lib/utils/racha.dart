import '../models/sesion.dart';

DateTime inicioSemana(DateTime fecha) {
  return DateTime(fecha.year, fecha.month, fecha.day - (fecha.weekday - 1));
}

DateTime _semanaAnterior(DateTime inicio) {
  return DateTime(inicio.year, inicio.month, inicio.day - 7);
}

/// Semanas seguidas (lunes a domingo) con al menos un entrenamiento.
int rachaSemanas(List<Sesion> sesiones, DateTime hoy) {
  final semanas = sesiones.map((s) => inicioSemana(s.inicio)).toSet();
  var semana = inicioSemana(hoy);
  // Si esta semana aún no tiene entrenamientos, la racha cuenta desde la anterior.
  if (!semanas.contains(semana)) semana = _semanaAnterior(semana);
  var racha = 0;
  while (semanas.contains(semana)) {
    racha++;
    semana = _semanaAnterior(semana);
  }
  return racha;
}

/// Días de la semana actual (1 = lunes ... 7 = domingo) con entrenamiento.
Set<int> diasEntrenadosSemana(List<Sesion> sesiones, DateTime hoy) {
  final semana = inicioSemana(hoy);
  return sesiones
      .where((s) => inicioSemana(s.inicio) == semana)
      .map((s) => s.inicio.weekday)
      .toSet();
}