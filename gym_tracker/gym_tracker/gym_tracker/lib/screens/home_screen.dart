import 'package:flutter/material.dart';
import 'entrenar_screen.dart';
import '../services/sesion_controller.dart';
import '../utils/formato.dart';
import 'sesion_activa_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  static const _titulos = ['Entrenar', 'Nutrición', 'Hábitos', 'Historial'];

  final _paginas = const [
    EntrenarScreen(),
    _Pendiente(titulo: 'Nutrición', icono: Icons.restaurant_menu),
    _Pendiente(titulo: 'Hábitos', icono: Icons.water_drop),
    _Pendiente(titulo: 'Historial', icono: Icons.show_chart),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titulos[_indice])),
      body: _paginas[_indice],
            bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BannerSesion(),
          NavigationBar(
            selectedIndex: _indice,
            onDestinationSelected: (i) => setState(() => _indice = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.fitness_center), label: 'Entrenar'),
              NavigationDestination(
                  icon: Icon(Icons.restaurant_menu), label: 'Nutrición'),
              NavigationDestination(
                  icon: Icon(Icons.water_drop), label: 'Hábitos'),
              NavigationDestination(
                  icon: Icon(Icons.show_chart), label: 'Historial'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pendiente extends StatelessWidget {
  final String titulo;
  final IconData icono;

  const _Pendiente({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 64),
          const SizedBox(height: 12),
          Text('$titulo (próximamente)'),
        ],
      ),
    );
  }
}

class _BannerSesion extends StatelessWidget {
  const _BannerSesion();

  @override
  Widget build(BuildContext context) {
    final ctrl = SesionController.instancia;
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        if (!ctrl.activa) return const SizedBox.shrink();
        final colores = Theme.of(context).colorScheme;
        final estilo = TextStyle(color: colores.onPrimaryContainer);
        return Material(
          color: colores.primaryContainer,
          child: InkWell(
            onTap: () => abrirSesionActiva(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.fitness_center,
                      size: 20, color: colores.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${ctrl.rutina!.nombre} · en curso',
                      style: estilo,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatoTiempo(ctrl.transcurrido),
                    style: estilo.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: colores.onPrimaryContainer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}