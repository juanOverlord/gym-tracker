import 'package:flutter/material.dart';
import '../models/rutina.dart';
import 'selector_ejercicio.dart';

class RutinaFormScreen extends StatefulWidget {
  final Rutina? rutina;

  const RutinaFormScreen({super.key, this.rutina});

  @override
  State<RutinaFormScreen> createState() => _RutinaFormScreenState();
}

class _RutinaFormScreenState extends State<RutinaFormScreen> {
  late final TextEditingController _nombre;
  late List<Ejercicio> _ejercicios;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.rutina?.nombre ?? '');
    _ejercicios = List.of(widget.rutina?.ejercicios ?? []);
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

    Future<void> _agregarEjercicio() async {
    final elegidos = await showModalBottomSheet<List<Ejercicio>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SelectorEjercicio(),
    );
    if (elegidos != null && elegidos.isNotEmpty) {
      setState(() => _ejercicios.addAll(elegidos));
    }
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la rutina')),
      );
      return;
    }
    Navigator.of(context).pop(
      Rutina(
        id: widget.rutina?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: nombre,
        ejercicios: _ejercicios,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rutina == null ? 'Nueva rutina' : 'Editar rutina'),
        actions: [
          TextButton(onPressed: _guardar, child: const Text('Guardar')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre de la rutina',
                hintText: 'Ej. Push, Pierna, Torso...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _ejercicios.isEmpty
                  ? const Center(child: Text('Aún no hay ejercicios'))
                  : ListView.builder(
                      itemCount: _ejercicios.length,
                      itemBuilder: (context, i) {
                        final e = _ejercicios[i];
                        return Card(
                          child: ListTile(
                            title: Text(e.nombre),
                            subtitle: Text(e.musculos),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _ejercicios.removeAt(i)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _agregarEjercicio,
                icon: const Icon(Icons.add),
                label: const Text('Agregar ejercicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}