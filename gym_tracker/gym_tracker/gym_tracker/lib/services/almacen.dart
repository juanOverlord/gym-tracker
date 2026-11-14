import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rutina.dart';
import '../models/sesion.dart';
import 'package:flutter/foundation.dart';

class Almacen {
  static final ValueNotifier<int> cambiosRutinas = ValueNotifier<int>(0);
  static const _claveRutinas = 'rutinas';
  static const _claveEjerciciosPropios = 'ejercicios_propios';
  static const _claveSesiones = 'sesiones';

  static const List<String> grupos = [
    'Pecho',
    'Espalda',
    'Hombro',
    'Bíceps',
    'Tríceps',
    'Pierna',
    'Glúteo',
    'Core',
    'Cardio',
  ];

    static const List<Ejercicio> catalogoBase = [
    Ejercicio(id: 'base_1', nombre: 'Press de banca', grupo: 'Pecho', secundarios: ['Tríceps', 'Hombro']),
    Ejercicio(id: 'base_2', nombre: 'Press inclinado con mancuernas', grupo: 'Pecho', secundarios: ['Hombro', 'Tríceps']),
    Ejercicio(id: 'base_3', nombre: 'Aperturas con mancuernas', grupo: 'Pecho', secundarios: ['Hombro']),
    Ejercicio(id: 'base_4', nombre: 'Dominadas', grupo: 'Espalda', secundarios: ['Bíceps', 'Core']),
    Ejercicio(id: 'base_5', nombre: 'Remo con barra', grupo: 'Espalda', secundarios: ['Bíceps', 'Hombro']),
    Ejercicio(id: 'base_6', nombre: 'Jalón al pecho', grupo: 'Espalda', secundarios: ['Bíceps']),
    Ejercicio(id: 'base_7', nombre: 'Press militar', grupo: 'Hombro', secundarios: ['Tríceps']),
    Ejercicio(id: 'base_8', nombre: 'Elevaciones laterales', grupo: 'Hombro'),
    Ejercicio(id: 'base_9', nombre: 'Curl con barra', grupo: 'Bíceps'),
    Ejercicio(id: 'base_10', nombre: 'Curl martillo', grupo: 'Bíceps'),
    Ejercicio(id: 'base_11', nombre: 'Extensión de tríceps en polea', grupo: 'Tríceps'),
    Ejercicio(id: 'base_12', nombre: 'Fondos', grupo: 'Tríceps', secundarios: ['Pecho', 'Hombro']),
    Ejercicio(id: 'base_13', nombre: 'Sentadilla', grupo: 'Pierna', secundarios: ['Glúteo', 'Core']),
    Ejercicio(id: 'base_14', nombre: 'Peso muerto rumano', grupo: 'Pierna', secundarios: ['Glúteo', 'Espalda']),
    Ejercicio(id: 'base_15', nombre: 'Prensa de pierna', grupo: 'Pierna', secundarios: ['Glúteo']),
    Ejercicio(id: 'base_16', nombre: 'Hip thrust', grupo: 'Glúteo', secundarios: ['Pierna']),
    Ejercicio(id: 'base_17', nombre: 'Plancha', grupo: 'Core', secundarios: ['Hombro']),
    Ejercicio(id: 'base_18', nombre: 'Caminadora', grupo: 'Cardio', secundarios: ['Pierna']),
  ];

  /// Si el ejercicio es del catálogo base, devuelve su versión actual
  /// (así las rutinas viejas también reciben los músculos secundarios).
  static Ejercicio actualizado(Ejercicio e) {
    for (final base in catalogoBase) {
      if (base.id == e.id) return base;
    }
    return e;
  }

    Future<List<Rutina>> cargarRutinas() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveRutinas);
    if (texto == null) return [];
    final lista = jsonDecode(texto) as List;
    return lista.map((e) {
      final r = Rutina.fromJson(e as Map<String, dynamic>);
      return Rutina(
        id: r.id,
        nombre: r.nombre,
        ejercicios: r.ejercicios.map(actualizado).toList(),
      );
    }).toList();
  }

    Future<void> guardarRutinas(List<Rutina> rutinas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _claveRutinas,
      jsonEncode(rutinas.map((r) => r.toJson()).toList()),
    );
    cambiosRutinas.value++;
  }

  Future<List<Ejercicio>> cargarEjerciciosPropios() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveEjerciciosPropios);
    if (texto == null) return [];
    final lista = jsonDecode(texto) as List;
    return lista
        .map((e) => Ejercicio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> guardarEjerciciosPropios(List<Ejercicio> ejercicios) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _claveEjerciciosPropios,
      jsonEncode(ejercicios.map((e) => e.toJson()).toList()),
    );
  }

    Future<List<Sesion>> cargarSesiones() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveSesiones);
    if (texto == null) return [];
    final lista = jsonDecode(texto) as List;
    return lista
        .map((e) => Sesion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> guardarSesiones(List<Sesion> sesiones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _claveSesiones,
      jsonEncode(sesiones.map((s) => s.toJson()).toList()),
    );
  }

}