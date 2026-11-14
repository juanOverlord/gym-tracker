import 'rutina.dart';

class Serie {
  double peso;
  int reps;
  bool completada;

  Serie({this.peso = 0, this.reps = 0, this.completada = false});

  Map<String, dynamic> toJson() => {
        'peso': peso,
        'reps': reps,
        'completada': completada,
      };

  factory Serie.fromJson(Map<String, dynamic> j) => Serie(
        peso: (j['peso'] as num).toDouble(),
        reps: j['reps'] as int,
        completada: j['completada'] as bool,
      );
}

class EjercicioSesion {
  final Ejercicio ejercicio;
  final List<Serie> series;
  String nota;
  int descansoSegundos;

  EjercicioSesion({
    required this.ejercicio,
    required this.series,
    this.nota = '',
    this.descansoSegundos = 90,
  });

  Map<String, dynamic> toJson() => {
        'ejercicio': ejercicio.toJson(),
        'series': series.map((s) => s.toJson()).toList(),
        'nota': nota,
        'descansoSegundos': descansoSegundos,
      };

  factory EjercicioSesion.fromJson(Map<String, dynamic> j) => EjercicioSesion(
        ejercicio: Ejercicio.fromJson(j['ejercicio'] as Map<String, dynamic>),
        series: (j['series'] as List)
            .map((s) => Serie.fromJson(s as Map<String, dynamic>))
            .toList(),
        nota: j['nota'] as String? ?? '',
        descansoSegundos: j['descansoSegundos'] as int? ?? 90,
      );
}

class Sesion {
  final String id;
  final String rutinaNombre;
  final DateTime inicio;
  final int duracionSegundos;
  final List<EjercicioSesion> ejercicios;

  Sesion({
    required this.id,
    required this.rutinaNombre,
    required this.inicio,
    required this.duracionSegundos,
    required this.ejercicios,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'rutinaNombre': rutinaNombre,
        'inicio': inicio.toIso8601String(),
        'duracionSegundos': duracionSegundos,
        'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
      };

  factory Sesion.fromJson(Map<String, dynamic> j) => Sesion(
        id: j['id'] as String,
        rutinaNombre: j['rutinaNombre'] as String,
        inicio: DateTime.parse(j['inicio'] as String),
        duracionSegundos: j['duracionSegundos'] as int,
        ejercicios: (j['ejercicios'] as List)
            .map((e) => EjercicioSesion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}