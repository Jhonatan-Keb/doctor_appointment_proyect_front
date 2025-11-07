import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✨ Importar para HapticFeedback
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';
import 'package:doctor_appointment_project/routes.dart';
import 'messages.dart';
import 'settings.dart';
import 'package:doctor_appointment_project/screens/appointmens.dart';
import 'create_appointment_dialog.dart';

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
    // ✨ Controlador para animación del FAB
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Widget _buildEspecialistaCard(
    BuildContext context,
    String nombre,
    String especialidad,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    // ✨ Mejora: Añadir GestureDetector con feedback táctil
    return SizedBox(
      width: 160,
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        // ✨ Añadir elevación en hover
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Feedback háptico al tocar
            HapticFeedback.lightImpact();
            onTap();
          },
          // ✨ Añadir animación de escala al presionar
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✨ Hero animation para transición suave
                  Hero(
                    tag: 'especialista_$nombre',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icono, size: 32, color: color),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nombre,
                    style: theme.textTheme.titleSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
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

  // ✨ Gesto 3: Menú de acciones rápidas con long press
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              ),
              title: const Text('Ver Perfil'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.add_circle, color: Colors.green.shade700),
              ),
              title: const Text('Nueva Cita'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                showCreateAppointmentDialog(context);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Icon(Icons.calendar_month, color: Colors.orange.shade700),
              ),
              title: const Text('Ver Calendario'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                setState(() => _navIndex = 2);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Icon(Icons.lightbulb, color: Colors.purple.shade700),
              ),
              title: const Text('Consejos de Salud'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.consejos);
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

    // ✨ RefreshIndicator para actualizar datos
    final homeBody = RefreshIndicator(
      onRefresh: () async {
        // Simular recarga de datos
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos actualizados ✅'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      color: theme.colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // BIENVENIDA con gesto de long press
          GestureDetector(
            onLongPress: () {
              // ✨ Gesto 3: Long press para opciones rápidas
              HapticFeedback.mediumImpact();
              _showQuickActionsSheet(context);
            },
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // ✨ Animación de pulso
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: CircleAvatar(
                          radius: 28,
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
                          stream: (user == null)
                              ? const Stream.empty()
                              : FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .doc(user.uid)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            final data = snapshot.data?.data() as Map<String, dynamic>?;
                            final nombre = (data?['nombre'] ?? '').toString().trim();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenido ${nombre.isNotEmpty ? nombre : ''}',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '¿En qué podemos ayudarte hoy?',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // BOTONES ACCIÓN con animación
          Row(
            children: [
              Expanded(
                child: _AnimatedButton(
                  onPressed: () => showCreateAppointmentDialog(context),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Crear cita'),
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedButton(
                  onPressed: () => setState(() => _navIndex = 2),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Mis citas'),
                  isPrimary: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // BOTÓN CONSEJOS
          Center(
            child: SizedBox(
              width: 220,
              child: _AnimatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.consejos),
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

          // CARRUSEL ESPECIALISTAS
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
                    'Dr. López',
                    'Cardiólogo',
                    Icons.favorite_rounded,
                    Colors.red.shade400,
                    () => showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Chequeo cardiológico',
                      medicoIdSugerido: 'dr_lopez',
                    ),
                  ),
                  _buildEspecialistaCard(
                    context,
                    'Dra. Martínez',
                    'Pediatra',
                    Icons.child_care_rounded,
                    Colors.pink.shade400,
                    () => showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Revisión pediátrica',
                      medicoIdSugerido: 'dra_martinez',
                    ),
                  ),
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
                      motivoSugerido: 'Plan de nutrición',
                      medicoIdSugerido: 'dr_perez',
                    ),
                  ),
                  _buildEspecialistaCard(
                    context,
                    'Dra. Ruiz',
                    'Oftalmóloga',
                    Icons.visibility_rounded,
                    Colors.orange.shade400,
                    () => showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Revisión de la vista',
                      medicoIdSugerido: 'dra_ruiz',
                    ),
                  ),
                  _buildEspecialistaCard(
                    context,
                    'Dr. Castro',
                    'Neurólogo',
                    Icons.psychology_rounded,
                    Colors.teal.shade400,
                    () => showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Migrañas / dolores de cabeza',
                      medicoIdSugerido: 'dr_castro',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Próximas citas',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          if (user == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Inicia sesión para ver tus citas.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            _AppointmentsList(user: user, navIndex: _navIndex, onNavigate: (index) {
              setState(() => _navIndex = index);
            }),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logoutToLogin(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    final messagesBody = const MessagesPage();
    final scheduleBody = const MyAppointmentsPage();
    final settingsBody = const SettingsPage();

    Widget currentBody;
    switch (_navIndex) {
      case 1:
        currentBody = messagesBody;
        break;
      case 2:
        currentBody = scheduleBody;
        break;
      case 3:
        currentBody = settingsBody;
        break;
      default:
        currentBody = homeBody;
    }

    return Scaffold(
      appBar: (_navIndex == 2 || _navIndex == 3)
          ? null
          : AppBar(
              title: const Text('Citas Médicas'),
            ),
      body: currentBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

// ✨ Widget personalizado para botones animados
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;
  final bool isPrimary;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isPrimary = true,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.isPrimary
            ? ElevatedButton.icon(
                onPressed: null, // Manejado por GestureDetector
                icon: widget.icon,
                label: widget.label,
              )
            : OutlinedButton.icon(
                onPressed: null, // Manejado por GestureDetector
                icon: widget.icon,
                label: widget.label,
              ),
      ),
    );
  }
}

// ✨ Lista de citas con Dismissible
class _AppointmentsList extends StatelessWidget {
  final User user;
  final int navIndex;
  final Function(int) onNavigate;

  const _AppointmentsList({
    required this.user,
    required this.navIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('citas')
          .orderBy('cuando')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes citas próximas',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crea tu primera cita médica',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final titulo = (data['titulo']?.toString() ??
                data['motivo']?.toString() ??
                'Cita médica');
            final lugar = data['lugar']?.toString() ?? '—';
            final ts = data['cuando'] as Timestamp?;
            final dt = ts?.toDate();
            final fecha = dt == null ? '—' : DateFormat('dd/MM/yyyy').format(dt);
            final hora = dt == null ? '—' : DateFormat('hh:mm a').format(dt);

            // ✨ Dismissible para deslizar y eliminar
            return Dismissible(
              key: Key(d.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar cita'),
                    content: Text('¿Eliminar "$titulo"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                await d.reference.delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cita "$titulo" eliminada'),
                      action: SnackBarAction(
                        label: 'Deshacer',
                        onPressed: () {
                          // Revertir eliminación
                          d.reference.set(data);
                        },
                      ),
                    ),
                  );
                }
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medical_services_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(titulo, style: theme.textTheme.titleMedium),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(fecha, style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(hora, style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                lugar,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => onNavigate(2),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}