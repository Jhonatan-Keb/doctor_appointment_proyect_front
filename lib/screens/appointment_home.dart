import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../routes.dart';
import 'login_page.dart';
import 'messages.dart';
import 'settings.dart';
import 'appointmens.dart';
import 'create_appointment_dialog.dart';

// Wrapper para mantener compatibilidad con el código existente
Future<void> showCreateAppointmentDialog(
  BuildContext context, {
  String? motivoSugerido,
  String? medicoIdSugerido,
}) {
  // medicoIdSugerido se usará solo si coincide con un UID real de un médico;
  // si no, simplemente se ignora y el usuario elige en el dropdown.
  return CreateAppointmentDialog.show(
    context,
    motivoInicial: motivoSugerido,
    medicoIdInicial: medicoIdSugerido,
  );
}

class _MyScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class AppointmentHomePage extends StatefulWidget {
  const AppointmentHomePage({super.key});

  @override
  State<AppointmentHomePage> createState() => _AppointmentHomePageState();
}

class _AppointmentHomePageState extends State<AppointmentHomePage>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _lightHaptic() => HapticFeedback.selectionClick();
  void _mediumHaptic() => HapticFeedback.mediumImpact();

  Widget _buildEspecialistaCard(
    BuildContext context,
    String nombre,
    String especialidad,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _lightHaptic();
            onTap();
          },
          onLongPress: () {
            _mediumHaptic();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Especialista: $nombre - $especialidad'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Ink(
            width: 140,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withOpacity(0.16),
                    child: Icon(icono, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombre,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    especialidad,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logoutToLogin(BuildContext ctx) async {
    await FirebaseAuth.instance.signOut();
    if (ctx.mounted) {
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Acciones rápidas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child:
                    Icon(Icons.add_circle_outline, color: Colors.blue.shade700),
              ),
              title: const Text('Crear nueva cita'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                showCreateAppointmentDialog(context);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.calendar_month, color: Colors.green.shade700),
              ),
              title: const Text('Ver calendario'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                setState(() => _navIndex = 2);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Usuario';
    final theme = Theme.of(context);

    // Si no hay usuario logueado, mostramos algo básico
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aplicación Médica')),
        body: const Center(
          child: Text('Inicia sesión para ver tu información.'),
        ),
      );
    }

    // ================= HOME =================
    final homeBody = RefreshIndicator(
      onRefresh: () async =>
          await Future.delayed(const Duration(milliseconds: 800)),
      color: theme.colorScheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Header con nombre y rol
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;

                    final nombre =
                        (data?['nombre'] ?? email.split('@').first) as String;
                    final rol = (data?['rol'] ?? 'Paciente') as String;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nombre 👋',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rol,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '¿Listo para revisar tu salud hoy?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 🔥 Tarjetas solo para MÉDICOS
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final rol = (data['rol'] ?? 'Paciente').toString().toLowerCase();

              final isMedico = rol == 'médico' || rol == 'medico';

              if (!isMedico) {
                // Paciente NO ve estas tarjetas
                return const SizedBox.shrink();
              }

              return SizedBox(
                height: 110,
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Próxima cita',
                        icon: Icons.access_time_rounded,
                        gradientColors: [
                          theme.colorScheme.primary.withOpacity(0.9),
                          theme.colorScheme.primary.withOpacity(0.6),
                        ],
                        stream: FirebaseFirestore.instance
                            .collection('citas')
                            .where('medicoId', isEqualTo: user.uid)
                            .orderBy('cuando')
                            .limit(1)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Text(
                              'Sin próximas citas',
                              style: TextStyle(color: Colors.white),
                            );
                          }
                          final data = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final motivo = data['motivo'] ?? 'Consulta general';
                          final ts = data['cuando'] as Timestamp?;
                          final fecha = ts?.toDate();
                          final fechaStr = fecha != null
                              ? DateFormat('dd/MM, hh:mm a').format(fecha)
                              : 'Fecha sin definir';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                motivo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fechaStr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Citas del mes',
                        icon: Icons.calendar_today_rounded,
                        gradientColors: [
                          Colors.indigo.shade500,
                          Colors.indigo.shade300,
                        ],
                        stream: FirebaseFirestore.instance
                            .collection('citas')
                            .where('medicoId', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final now = DateTime.now();
                          final count = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final ts = data['cuando'] as Timestamp?;
                            final fecha = ts?.toDate();
                            return fecha != null &&
                                fecha.month == now.month &&
                                fecha.year == now.year;
                          }).length;
                          return Text(
                            '$count citas este mes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Botones de acción según rol
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final rol = (data['rol'] ?? 'Paciente').toString().toLowerCase();
              final isMedico = rol == 'médico' || rol == 'medico';

              return Row(
                children: [
                  Expanded(
                    child: _AnimatedButton(
                      onPressed: isMedico
                          ? () {
                              Navigator.pushNamed(context, AppRoutes.dashboard);
                            }
                          : () {
                              showCreateAppointmentDialog(context);
                            },
                      icon: Icon(
                        isMedico
                            ? Icons.bar_chart_rounded
                            : Icons.add_circle_outline_rounded,
                      ),
                      label: Text(isMedico ? 'Ver citas' : 'Crear cita'),
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnimatedButton(
                      onPressed: () {
                        setState(() => _navIndex = 2);
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Mis citas'),
                      isPrimary: true,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          Center(
            child: SizedBox(
              width: 220,
              child: _AnimatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.consejos),
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
                label: const Text('Consejos de salud'),
                isPrimary: false,
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Especialistas y atajos',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          ScrollConfiguration(
            behavior: _MyScrollBehavior(),
            child: SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildEspecialistaCard(
                    context,
                    'Dr. Ramírez',
                    'Dentista',
                    Icons.medication_liquid_rounded,
                    Colors.blue.shade400,
                    () => showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Dolor de muela',
                      medicoIdSugerido: 'dr_ramirez',
                    ),
                  ),
                  _buildEspecialistaCard(
                    context,
                    'Dra. Gómez',
                    'Dermatóloga',
                    Icons.face_rounded,
                    Colors.purple.shade400,
                    () => showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Acné / erupciones',
                      medicoIdSugerido: 'dra_gomez',
                    ),
                  ),
                  _buildEspecialistaCard(
                    context,
                    'Dr. Pérez',
                    'Nutriólogo',
                    Icons.restaurant_rounded,
                    Colors.green.shade400,
                    () => showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Plan alimenticio',
                      medicoIdSugerido: 'dr_perez',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // ================= OTRAS PESTAÑAS =================
    final citasBody = const MyAppointmentsPage();
    final messagesBody = const MessagesPage();

    final screens = [homeBody, messagesBody, citasBody];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicación Médica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, email),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_navIndex],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.easeOutBack,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            _mediumHaptic();
            if (_navIndex == 2) {
              showCreateAppointmentDialog(context);
            } else {
              _showQuickActionsSheet(context);
            }
          },
          icon: Icon(
            _navIndex == 2 ? Icons.add_rounded : Icons.flash_on_rounded,
          ),
          label: Text(_navIndex == 2 ? 'Nueva cita' : 'Acciones'),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() => _navIndex = index);
          _fabController
            ..reset()
            ..forward();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Citas',
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, String email) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: (user == null)
                        ? const Stream.empty()
                        : FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(user.uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      final data =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      final nombre =
                          (data?['nombre'] ?? email.split('@').first) as String;
                      final rol = (data?['rol'] ?? 'Paciente') as String;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              rol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Cerrar sesión'),
            onTap: () => _logoutToLogin(context),
          ),
        ],
      ),
    );
  }
}

// ========= Widgets de apoyo =========

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Stream<QuerySnapshot> stream;
  final Widget Function(BuildContext, AsyncSnapshot<QuerySnapshot>) builder;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.stream,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    builder(context, snapshot),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;
  final bool isPrimary;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: widget.isPrimary
                      ? Colors.white
                      : theme.colorScheme.primary,
                  size: 22,
                ),
                child: widget.icon,
              ),
              const SizedBox(width: 8),
              DefaultTextStyle(
                style: TextStyle(
                  color: widget.isPrimary
                      ? Colors.white
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                child: widget.label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
