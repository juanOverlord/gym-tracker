import 'package:flutter/material.dart';
import '../models/rutina.dart';
import '../services/almacen.dart';
import '../services/sesion_controller.dart';
import 'rutina_form_screen.dart';
import 'sesion_activa_screen.dart';

class EntrenarScreen extends StatefulWidget {
  const EntrenarScreen({super.key});

  @override
  State<EntrenarScreen> createState() => _EntrenarScreenState();
}

class _EntrenarScreenState extends State<EntrenarScreen> {
  final _almacen = Almacen();
  List<Rutina> _rutinas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    Almacen.cambiosRutinas.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    Almacen.cambiosRutinas.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final rutinas = await _almacen.cargarRutinas();
    if (!mounted) return;
    setState(() {
      _rutinas = rutinas;
      _cargando = false;
    });
  }

  Future<void> _abrirFormulario([Rutina? rutina]) async {
    final resultado = await Navigator.of(context).push<Rutina>(
      MaterialPageRoute(builder: (_) => RutinaFormScreen(rutina: rutina)),
    );
    if (resultado == null) return;
    final indice = _rutinas.indexWhere((r) => r.id == resultado.id);
    setState(() {
      if (indice >= 0) {
        _rutinas[indice] = resultado;
      } else {
        _rutinas.add(resultado);
      }
    });
    await _almacen.guardarRutinas(_rutinas);
  }

  Future<void> _eliminar(Rutina rutina) async {
    setState(() => _rutinas.removeWhere((r) => r.id == rutina.id));
    await _almacen.guardarRutinas(_rutinas);
  }

  Future<void> _comenzar(Rutina rutina) async {
    final ctrl = SesionController.instancia;

    if (ctrl.activa) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ya tienes un entrenamiento en curso'),
          action: SnackBarAction(
            label: 'Continuar',
            onPressed: () => abrirSesionActiva(context),
          ),
        ),
      );
      return;
    }

    await ctrl.iniciar(rutina);
    if (!mounted) return;
    await abrirSesionActiva(context);
  }

  Future<void> _iniciar(Rutina rutina) async {
    if (rutina.ejercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega ejercicios a la rutina primero')),
      );
      return;
    }
    await _comenzar(rutina);
  }

  Future<void> _iniciarVacio() {
    return _comenzar(
      Rutina(id: 'libre', nombre: 'Entrenamiento libre', ejercicios: []),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _iniciarVacio,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar entrenamiento vacío'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Mis rutinas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: _rutinas.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Aún no tienes rutinas.\nToca el botón + para crear la primera.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                          itemCount: _rutinas.length,
                          itemBuilder: (context, i) {
                            final rutina = _rutinas[i];
                            return Card(
                              child: ListTile(
                                title: Text(rutina.nombre),
                                subtitle: Text(
                                    '${rutina.ejercicios.length} ejercicios'),
                                onTap: () => _abrirFormulario(rutina),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: () => _iniciar(rutina),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _eliminar(rutina),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}