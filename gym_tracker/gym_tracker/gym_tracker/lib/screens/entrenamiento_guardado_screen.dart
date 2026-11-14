import 'package:flutter/material.dart';
import '../models/sesion.dart';
import '../services/almacen.dart';
import '../utils/formato.dart';
import '../utils/racha.dart';

class EntrenamientoGuardadoScreen extends StatefulWidget {
  final Sesion sesion;
  final String? rutinaGuardada;

  const EntrenamientoGuardadoScreen({
    super.key,
    required this.sesion,
    this.rutinaGuardada,
  });

  @override
  State<EntrenamientoGuardadoScreen> createState() =>
      _EntrenamientoGuardadoScreenState();
}

class _EntrenamientoGuardadoScreenState
    extends State<EntrenamientoGuardadoScreen> {
  final _almacen = Almacen();
  int? _total;
  int _racha = 0;
  Set<int> _dias = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final sesiones = await _almacen.cargarSesiones();
    final hoy = DateTime.now();
    if (!mounted) return;
    setState(() {
      _total = sesiones.length;
      _racha = rachaSemanas(sesiones, hoy);
      _dias = diasEntrenadosSemana(sesiones, hoy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final s = widget.sesion;
    final series = s.ejercicios.fold<int>(0, (a, e) => a + e.series.length);

    return Scaffold(
      body: SafeArea(
        child: total == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Icon(Icons.emoji_events,
                        size: 88, color: Colors.amber),
                    const SizedBox(height: 16),
                    Text(
                      '¡Felicidades!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      total == 1
                          ? '¡Este es tu primer entrenamiento!'
                          : 'Este es tu entrenamiento número $total',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    _TarjetaRacha(racha: _racha, dias: _dias),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _Estadistica(
                                titulo: 'Duración',
                                valor: formatoTiempo(
                                    Duration(seconds: s.duracionSegundos)),
                              ),
                            ),
                            Expanded(
                              child: _Estadistica(
                                titulo: 'Ejercicios',
                                valor: '${s.ejercicios.length}',
                              ),
                            ),
                            Expanded(
                              child: _Estadistica(
                                titulo: 'Series',
                                valor: '$series',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.rutinaGuardada != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'También guardaste la rutina "${widget.rutinaGuardada}".',
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Listo'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Estadistica extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Estadistica({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(titulo, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(valor, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

const _letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

class _TarjetaRacha extends StatelessWidget {
  final int racha;
  final Set<int> dias;

  const _TarjetaRacha({required this.racha, required this.dias});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now().weekday;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 32),
                const SizedBox(width: 8),
                Text(
                  racha == 1 ? '1 semana de racha' : '$racha semanas de racha',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int d = 1; d <= 7; d++)
                  _Dia(
                    letra: _letras[d - 1],
                    entrenado: dias.contains(d),
                    esHoy: d == hoy,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  final String letra;
  final bool entrenado;
  final bool esHoy;

  const _Dia({
    required this.letra,
    required this.entrenado,
    required this.esHoy,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(letra, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: esHoy ? colores.primary : colores.outlineVariant,
                    width: esHoy ? 2 : 1,
                  ),
                ),
              ),
              if (entrenado)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: esHoy ? 800 : 300),
                  curve: esHoy ? Curves.easeOutBack : Curves.easeOut,
                  builder: (context, valor, child) =>
                      Transform.scale(scale: valor, child: child),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange,
                    ),
                    child: const Icon(Icons.check,
                        size: 20, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}