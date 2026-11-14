import 'package:flutter/material.dart';
import '../models/rutina.dart';
import '../models/sesion.dart';
import '../services/sesion_controller.dart';
import '../utils/formato.dart';
import 'selector_ejercicio.dart';
import '../services/almacen.dart';
import 'entrenamiento_guardado_screen.dart';
/// Abre la sesión que está en curso y avisa si se guardó al volver.
Future<void> abrirSesionActiva(BuildContext context) async {
  final mensaje = await Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const SesionActivaScreen()),
  );
  if (mensaje != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}

class SesionActivaScreen extends StatelessWidget {
  const SesionActivaScreen({super.key});

      Future<void> _terminar(BuildContext context) async {
    final ctrl = SesionController.instancia;
    final resultado = await showDialog<_ResultadoTerminar>(
      context: context,
      builder: (_) => _DialogoTerminar(ctrl: ctrl),
    );
    if (resultado == null) return;

    final ejerciciosRutina = ctrl.ejercicios.map((e) => e.ejercicio).toList();
    final sesionGuardada = await ctrl.terminar();

    if (resultado.guardarRutina) {
      final almacen = Almacen();
      final rutinas = await almacen.cargarRutinas();
      rutinas.add(Rutina(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: resultado.nombre,
        ejercicios: ejerciciosRutina,
      ));
      await almacen.guardarRutinas(rutinas);
    }

    if (!context.mounted) return;

    if (sesionGuardada != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EntrenamientoGuardadoScreen(
            sesion: sesionGuardada,
            rutinaGuardada: resultado.guardarRutina ? resultado.nombre : null,
          ),
        ),
      );
    } else {
      Navigator.of(context)
          .pop(resultado.guardarRutina ? 'Rutina guardada' : null);
    }
  }

  Future<void> _descartar(BuildContext context) async {
    final ctrl = SesionController.instancia;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar entrenamiento?'),
        content: const Text('Se perderá todo lo que registraste en esta sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      ctrl.descartar();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

    Future<void> _agregarEjercicio(BuildContext context) async {
    final elegidos = await showModalBottomSheet<List<Ejercicio>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SelectorEjercicio(),
    );
    if (elegidos == null) return;
    for (final e in elegidos) {
      SesionController.instancia.agregarEjercicio(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = SesionController.instancia;
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        if (!ctrl.activa) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(ctrl.rutina!.nombre),
            actions: [
              TextButton(
                onPressed: () => _terminar(context),
                child: const Text('Terminar'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _Resumen(ctrl: ctrl),
              const SizedBox(height: 12),
              for (int i = 0; i < ctrl.ejercicios.length; i++)
                _TarjetaEjercicio(
                  key: ObjectKey(ctrl.ejercicios[i]),
                  ctrl: ctrl,
                  indice: i,
                ),
                if (ctrl.ejercicios.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aún no hay ejercicios.\nAgrega el primero para empezar.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              FilledButton.tonalIcon(
                onPressed: () => _agregarEjercicio(context),
                icon: const Icon(Icons.add),
                label: const Text('Agregar ejercicio'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _descartar(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Descartar entrenamiento'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          bottomNavigationBar:
              ctrl.descansoIndice != null ? _BarraDescanso(ctrl: ctrl) : null,
        );
      },
    );
  }
}

class _BarraDescanso extends StatelessWidget {
  final SesionController ctrl;

  const _BarraDescanso({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final colorTexto = colores.onSecondaryContainer;
    final total = ctrl.descansoTotal == 0 ? 1 : ctrl.descansoTotal;
    final progreso = ((total - ctrl.descansoRestante) / total).clamp(0.0, 1.0);
    final nombre = ctrl.ejercicios[ctrl.descansoIndice!].ejercicio.nombre;

    return Material(
      color: colores.secondaryContainer,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: colorTexto),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descanso',
                          style: TextStyle(color: colorTexto, fontSize: 12),
                        ),
                        Text(
                          nombre,
                          style: TextStyle(color: colorTexto),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatoTiempo(Duration(seconds: ctrl.descansoRestante)),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorTexto,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progreso),
                duration: const Duration(seconds: 1),
                builder: (context, valor, _) => LinearProgressIndicator(
                  value: valor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ctrl.agregarTiempoDescanso(10),
                      child: const Text('+10 s'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: ctrl.omitirDescanso,
                      child: const Text('Omitir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final SesionController ctrl;

  const _Resumen({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _Dato(
                titulo: 'Tiempo',
                valor: formatoTiempo(ctrl.transcurrido),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(
              child: _Dato(
                titulo: 'Series completadas',
                valor: '${ctrl.seriesCompletadas}/${ctrl.seriesTotales}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Dato({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(titulo, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(valor, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

const _opcionesDescanso = [0, 30, 45, 60, 90, 120, 180, 300];

class _TarjetaEjercicio extends StatelessWidget {
  final SesionController ctrl;
  final int indice;

  const _TarjetaEjercicio({
    super.key,
    required this.ctrl,
    required this.indice,
  });

  EjercicioSesion get _e => ctrl.ejercicios[indice];

  Future<void> _elegirDescanso(BuildContext context) async {
    final elegido = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Descanso entre series',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final seg in _opcionesDescanso)
                ListTile(
                  title: Text(formatoDescanso(seg)),
                  trailing:
                      seg == _e.descansoSegundos ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(sheetContext).pop(seg),
                ),
            ],
          ),
        ),
      ),
    );
    if (elegido != null) ctrl.cambiarDescanso(indice, elegido);
  }

    Future<void> _eliminar(BuildContext context) async {
    final tieneSeries = _e.series.any((s) => s.completada);
    if (tieneSeries) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Eliminar ejercicio?'),
          content: Text(
            'Se perderán las series que ya completaste en "${_e.ejercicio.nombre}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    ctrl.eliminarEjercicio(indice);
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
    final anteriores = ctrl.anteriores[e.ejercicio.id]?.series;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.ejercicio.nombre,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(e.ejercicio.musculos,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Subir',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: indice > 0
                      ? () => ctrl.moverEjercicio(indice, -1)
                      : null,
                ),
                IconButton(
                  tooltip: 'Bajar',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: indice < ctrl.ejercicios.length - 1
                      ? () => ctrl.moverEjercicio(indice, 1)
                      : null,
                ),
                 PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (valor) {
                    if (valor == 'eliminar') _eliminar(context);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 12),
                          Text('Eliminar ejercicio'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _NotaEjercicio(ejercicio: e),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _elegirDescanso(context),
              icon: const Icon(Icons.timer_outlined),
              label: Text('Descanso: ${formatoDescanso(e.descansoSegundos)}'),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  SizedBox(width: 36, child: Text('Serie')),
                  Expanded(child: Center(child: Text('Anterior'))),
                  SizedBox(width: 70, child: Center(child: Text('Kg'))),
                  SizedBox(width: 8),
                  SizedBox(width: 70, child: Center(child: Text('Reps'))),
                  SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 4),
            for (int j = 0; j < e.series.length; j++)
              Dismissible(
                key: ObjectKey(e.series[j]),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red.shade700,
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) => ctrl.eliminarSerie(indice, j),
                child: _SerieFila(
                  numero: j + 1,
                  serie: e.series[j],
                  anterior: (anteriores != null && j < anteriores.length)
                      ? anteriores[j]
                      : null,
                  onCompletadaCambiada: (v) =>
                      ctrl.cambiarSerieCompletada(indice, v),
                ),
              ),
            TextButton.icon(
              onPressed: () => ctrl.agregarSerie(indice),
              icon: const Icon(Icons.add),
              label: const Text('Agregar serie'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotaEjercicio extends StatefulWidget {
  final EjercicioSesion ejercicio;

  const _NotaEjercicio({required this.ejercicio});

  @override
  State<_NotaEjercicio> createState() => _NotaEjercicioState();
}

class _NotaEjercicioState extends State<_NotaEjercicio> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.ejercicio.nota);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.edit_note),
        hintText: 'Agregar nota sobre el ejercicio',
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => widget.ejercicio.nota = v,
    );
  }
}

class _SerieFila extends StatefulWidget {
  final int numero;
  final Serie serie;
  final Serie? anterior;
  final ValueChanged<bool> onCompletadaCambiada;

  const _SerieFila({
    required this.numero,
    required this.serie,
    required this.anterior,
    required this.onCompletadaCambiada,
  });

  @override
  State<_SerieFila> createState() => _SerieFilaState();
}

class _SerieFilaState extends State<_SerieFila> {
  late final TextEditingController _peso;
  late final TextEditingController _reps;

  @override
  void initState() {
    super.initState();
    _peso = TextEditingController(
        text: widget.serie.peso > 0 ? formatoNumero(widget.serie.peso) : '');
    _reps = TextEditingController(
        text: widget.serie.reps > 0 ? widget.serie.reps.toString() : '');
  }

  @override
  void dispose() {
    _peso.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _alMarcar(bool? valor) {
    final marcada = valor ?? false;
    // Si marcas una serie vacía, copia lo de la vez anterior
    if (marcada &&
        widget.serie.peso == 0 &&
        widget.serie.reps == 0 &&
        widget.anterior != null) {
      widget.serie.peso = widget.anterior!.peso;
      widget.serie.reps = widget.anterior!.reps;
      _peso.text = formatoNumero(widget.serie.peso);
      _reps.text = widget.serie.reps.toString();
    }
    setState(() => widget.serie.completada = marcada);
    widget.onCompletadaCambiada(marcada);
  }

  @override
  Widget build(BuildContext context) {
    final ant = widget.anterior;
    final completada = widget.serie.completada;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: completada ? Colors.green.withAlpha(40) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 36, child: Text('${widget.numero}')),
              Expanded(
                child: Center(
                  child: Text(
                    ant == null
                        ? '-'
                        : '${formatoNumero(ant.peso)} kg x ${ant.reps}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _peso,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => widget.serie.peso =
                      double.tryParse(v.replaceAll(',', '.')) ?? 0,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _reps,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => widget.serie.reps = int.tryParse(v) ?? 0,
                ),
              ),
              SizedBox(
                width: 48,
                child: Checkbox(value: completada, onChanged: _alMarcar),
              ),
            ],
          ),
          if (completada)
            const Padding(
              padding: EdgeInsets.only(top: 2, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Serie completada',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultadoTerminar {
  final bool guardarRutina;
  final String nombre;

  const _ResultadoTerminar({
    required this.guardarRutina,
    required this.nombre,
  });
}

class _DialogoTerminar extends StatefulWidget {
  final SesionController ctrl;

  const _DialogoTerminar({required this.ctrl});

  @override
  State<_DialogoTerminar> createState() => _DialogoTerminarState();
}

class _DialogoTerminarState extends State<_DialogoTerminar> {
  final _nombre = TextEditingController(text: 'Mi rutina');
  bool _guardarRutina = false;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final puedeGuardarRutina =
        ctrl.rutina?.id == 'libre' && ctrl.ejercicios.isNotEmpty;

    return AlertDialog(
      title: const Text('¿Terminar entrenamiento?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctrl.seriesCompletadas == 0
                  ? 'No has completado ninguna serie, así que no se guardará nada en el historial.'
                  : 'Completaste ${ctrl.seriesCompletadas} de ${ctrl.seriesTotales} series. '
                      'Se guardan solo las series marcadas como completadas.',
            ),
            if (puedeGuardarRutina) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Guardar también como rutina'),
                value: _guardarRutina,
                onChanged: (v) => setState(() => _guardarRutina = v ?? false),
              ),
              if (_guardarRutina)
                TextField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la rutina',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Seguir'),
        ),
        FilledButton(
          onPressed: () {
            final nombre = _nombre.text.trim();
            Navigator.of(context).pop(
              _ResultadoTerminar(
                guardarRutina: puedeGuardarRutina && _guardarRutina,
                nombre: nombre.isEmpty ? 'Nueva rutina' : nombre,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}