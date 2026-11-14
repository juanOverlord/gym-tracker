import 'package:flutter/material.dart';
import '../models/rutina.dart';
import '../services/almacen.dart';

class SelectorEjercicio extends StatefulWidget {
  const SelectorEjercicio({super.key});

  @override
  State<SelectorEjercicio> createState() => _SelectorEjercicioState();
}

class _SelectorEjercicioState extends State<SelectorEjercicio> {
  final _almacen = Almacen();
  List<Ejercicio> _todos = [];
  final List<Ejercicio> _seleccion = [];
  String _busqueda = '';
  String? _grupoFiltro; // null = todos

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final propios = await _almacen.cargarEjerciciosPropios();
    if (!mounted) return;
    setState(() => _todos = [...Almacen.catalogoBase, ...propios]);
  }

  bool _estaSeleccionado(Ejercicio e) => _seleccion.any((x) => x.id == e.id);

  void _alternar(Ejercicio e) {
    setState(() {
      if (_estaSeleccionado(e)) {
        _seleccion.removeWhere((x) => x.id == e.id);
      } else {
        _seleccion.add(e);
      }
    });
  }

  Future<void> _crearNuevo() async {
    final nuevo = await showDialog<Ejercicio>(
      context: context,
      builder: (_) => const _DialogoNuevoEjercicio(),
    );
    if (nuevo == null) return;
    final propios = await _almacen.cargarEjerciciosPropios();
    propios.add(nuevo);
    await _almacen.guardarEjerciciosPropios(propios);
    if (!mounted) return;
    setState(() {
      _todos = [..._todos, nuevo];
      _seleccion.add(nuevo);
    });
  }

  bool _coincide(Ejercicio e) {
    if (_grupoFiltro != null && e.grupo != _grupoFiltro) return false;
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.nombre.toLowerCase().contains(q) ||
        e.grupo.toLowerCase().contains(q) ||
        e.secundarios.any((s) => s.toLowerCase().contains(q));
  }

  List<Widget> _lista() {
    final filtrados = _todos.where(_coincide).toList();
    final widgets = <Widget>[];

    for (final grupo in Almacen.grupos) {
      final delGrupo = filtrados.where((e) => e.grupo == grupo).toList();
      if (delGrupo.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            grupo,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      );
      for (final e in delGrupo) {
        widgets.add(
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.trailing,
            value: _estaSeleccionado(e),
            onChanged: (_) => _alternar(e),
            title: Text(e.nombre),
            subtitle: e.secundarios.isEmpty
                ? null
                : Text('Secundario: ${e.secundarios.join(', ')}'),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      widgets.add(const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No se encontraron ejercicios')),
      ));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final n = _seleccion.length;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar ejercicio o músculo',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _busqueda = v),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: _grupoFiltro == null,
                      onSelected: (_) => setState(() => _grupoFiltro = null),
                    ),
                  ),
                  for (final g in Almacen.grupos)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: _grupoFiltro == g,
                        onSelected: (_) => setState(() => _grupoFiltro = g),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Crear ejercicio nuevo'),
              onTap: _crearNuevo,
            ),
            const Divider(height: 1),
            Expanded(child: ListView(children: _lista())),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: n == 0
                        ? null
                        : () => Navigator.of(context)
                            .pop(List<Ejercicio>.from(_seleccion)),
                    child: Text(
                      n == 0
                          ? 'Selecciona ejercicios'
                          : 'Agregar $n ejercicio${n == 1 ? '' : 's'}',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogoNuevoEjercicio extends StatefulWidget {
  const _DialogoNuevoEjercicio();

  @override
  State<_DialogoNuevoEjercicio> createState() => _DialogoNuevoEjercicioState();
}

class _DialogoNuevoEjercicioState extends State<_DialogoNuevoEjercicio> {
  final _nombre = TextEditingController();
  String _grupo = Almacen.grupos.first;
  final Set<String> _secundarios = {};

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo ejercicio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _grupo,
              decoration: const InputDecoration(labelText: 'Músculo principal'),
              items: Almacen.grupos
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() {
                _grupo = v ?? _grupo;
                _secundarios.remove(_grupo);
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Músculos secundarios (opcional)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final g in Almacen.grupos.where((g) => g != _grupo))
                  FilterChip(
                    label: Text(g),
                    selected: _secundarios.contains(g),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _secundarios.add(g);
                      } else {
                        _secundarios.remove(g);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final nombre = _nombre.text.trim();
            if (nombre.isEmpty) return;
            Navigator.of(context).pop(
              Ejercicio(
                id: 'propio_${DateTime.now().millisecondsSinceEpoch}',
                nombre: nombre,
                grupo: _grupo,
                secundarios: _secundarios.toList(),
              ),
            );
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}