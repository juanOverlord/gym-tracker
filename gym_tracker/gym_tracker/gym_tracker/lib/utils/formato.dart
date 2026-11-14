String formatoTiempo(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

String formatoNumero(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

String formatoDescanso(int segundos) {
  if (segundos == 0) return 'Sin descanso';
  final m = segundos ~/ 60;
  final s = segundos % 60;
  if (m == 0) return '$s s';
  if (s == 0) return '$m min';
  return '$m min $s s';
}