class Ejercicio {
  final String id;
  final String nombre;
  final String grupo; // músculo principal
  final List<String> secundarios;

  const Ejercicio({
    required this.id,
    required this.nombre,
    required this.grupo,
    this.secundarios = const [],
  });

  String get musculos => secundarios.isEmpty
      ? grupo
      : '$grupo · Secundario: ${secundarios.join(', ')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'grupo': grupo,
        'secundarios': secundarios,
      };

  factory Ejercicio.fromJson(Map<String, dynamic> j) => Ejercicio(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        grupo: j['grupo'] as String,
        secundarios: (j['secundarios'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}

class Rutina {
  final String id;
  final String nombre;
  final List<Ejercicio> ejercicios;

  Rutina({
    required this.id,
    required this.nombre,
    required this.ejercicios,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
      };

  factory Rutina.fromJson(Map<String, dynamic> j) => Rutina(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        ejercicios: (j['ejercicios'] as List)
            .map((e) => Ejercicio.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}