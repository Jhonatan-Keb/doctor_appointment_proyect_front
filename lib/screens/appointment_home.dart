import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

class _AppointmentHomePageState extends State<AppointmentHomePage> {
  int _navIndex = 0;

  Widget _buildEspecialistaCard(
    BuildContext context,
    String nombre,
    String especialidad,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 160,
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, size: 32, color: color),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Usuario';
    final theme = Theme.of(context);

    final homeBody = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BIENVENIDA
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: theme.colorScheme.primary,
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

        const SizedBox(height: 16),

        // BOTONES ACCIÓN
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showCreateAppointmentDialog(context),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Crear cita'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _navIndex = 2),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Mis citas'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // BOTÓN CONSEJOS
        Center(
          child: SizedBox(
            width: 220,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.consejos),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
              label: const Text('Consejos de salud'),
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
                // ESPECIALISTAS
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

                // SÍNTOMAS
                _buildEspecialistaCard(
                  context,
                  'Gripe / Resfriado',
                  'Consulta general',
                  Icons.masks_rounded,
                  Colors.cyan.shade400,
                  () => showCreateAppointmentDialog(
                    context,
                    motivoSugerido: 'Síntomas de gripe o resfriado',
                  ),
                ),
                _buildEspecialistaCard(
                  context,
                  'Fiebre',
                  'Evaluación',
                  Icons.device_thermostat_rounded,
                  Colors.deepOrange.shade400,
                  () => showCreateAppointmentDialog(
                    context,
                    motivoSugerido: 'Fiebre persistente',
                  ),
                ),
                _buildEspecialistaCard(
                  context,
                  'Dolor de garganta',
                  'Otorrino/GP',
                  Icons.healing_rounded,
                  Colors.amber.shade400,
                  () => showCreateAppointmentDialog(
                    context,
                    motivoSugerido: 'Dolor de garganta',
                  ),
                ),
                _buildEspecialistaCard(
                  context,
                  'Alergias',
                  'Tratamiento',
                  Icons.spa_rounded,
                  Colors.lightGreen.shade400,
                  () => showCreateAppointmentDialog(
                    context,
                    motivoSugerido: 'Alergias estacionales',
                  ),
                ),
                _buildEspecialistaCard(
                  context,
                  'Dolor de estómago',
                  'Gastro',
                  Icons.restaurant_rounded,
                  Colors.brown.shade400,
                  () => showCreateAppointmentDialog(
                    context,
                    motivoSugerido: 'Dolor de estómago / náuseas',
                  ),
                ),
                _buildEspecialistaCard(
                  context,
                  'Diarrea/Vómito',
                  'Gastro',
                  Icons.warning_amber_rounded,
                  Colors.deepOrange.shade400,
                  () => showCreateAppointmentDialog(
                    context,
                    motivoSugerido: 'Diarrea o vómito agudo',
                  ),
                ),
                _buildEspecialistaCard(
                  context,
                  'Dolor de espalda',
                  'Fisio/Ortopedia',
                  Icons.fitness_center_rounded,
                  Colors.indigo.shade400,
                  () => showCreateAppointmentDialog(
                    context,
                    motivoSugerido: 'Dolor de espalda baja',
                  ),
                ),
                _buildEspecialistaCard(
                  context,
                  'Ansiedad / Estrés',
                  'Salud mental',
                  Icons.psychology_alt_rounded,
                  Colors.purple.shade300,
                  () => showCreateAppointmentDialog(
                    context,
                    motivoSugerido: 'Ansiedad / manejo del estrés',
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
          StreamBuilder<QuerySnapshot>(
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

                  return Card(
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
                      onTap: () => setState(() => _navIndex = 2),
                    ),
                  );
                }).toList(),
              );
            },
          ),

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