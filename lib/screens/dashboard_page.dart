import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/doctor_dashboard_cubit.dart';
import '../routes.dart';
import 'login_page.dart';
import 'messages.dart';
import 'profile_page.dart';
import 'settings.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Si no hay sesión, manda al login
      return const LoginPage();
    }

    return BlocProvider(
      create: (_) => DoctorDashboardCubit(medicoId: user.uid),
      child: _DashboardScaffold(userId: user.uid),
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  final String userId;

  const _DashboardScaffold({required this.userId});

  Future<void> _updateStatus(
    BuildContext context, {
    required String docId,
    required String? pacienteId,
    required String newStatus,
    required String confirmTitle,
    required String confirmMessage,
    required Color confirmColor,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Actualizar cita global
      final globalRef =
          FirebaseFirestore.instance.collection('citas').doc(docId);
      batch.update(globalRef, {'estado': newStatus});

      // 2. Actualizar cita del paciente (si existe ID)
      if (pacienteId != null) {
        final userRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(pacienteId)
            .collection('citas')
            .doc(docId);
        // Usamos set con merge por si acaso no existiera (aunque debería)
        batch.set(userRef, {'estado': newStatus}, SetOptions(merge: true));
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cita actualizada a: $newStatus'),
            backgroundColor: confirmColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuarioRef =
        FirebaseFirestore.instance.collection('usuarios').doc(userId);
    final citasQuery = FirebaseFirestore.instance
        .collection('citas')
        .where('medicoId', isEqualTo: userId);

    return Scaffold(
      // ========== DRAWER ==========
      drawer: _DoctorDashboardDrawer(userId: userId),

      // ========== APPBAR CON MENÚ + ENGRANAJE ==========
      appBar: AppBar(
        title: const Text('Aplicación Médica'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          // 👇 NUEVO: icono para ir a la pantalla de gráficas
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.graphics);
            },
          ),
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

      // ========== CONTENIDO ==========
      body: StreamBuilder<DocumentSnapshot>(
        stream: usuarioRef.snapshots(),
        builder: (context, snapshotUser) {
          if (snapshotUser.hasError) {
            return Center(
              child: Text('Error al cargar usuario: ${snapshotUser.error}'),
            );
          }

          if (!snapshotUser.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dataUser =
              snapshotUser.data!.data() as Map<String, dynamic>? ?? {};

          final nombre =
              (dataUser['nombre'] ?? 'Médico') as String; // sin correo
          final rol = (dataUser['rol'] ?? 'Médico') as String;

          List<String> especialidades = [];
          if (dataUser['especialidades'] is List) {
            especialidades = (dataUser['especialidades'] as List)
                .map((e) => e.toString())
                .toList();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Header: saludo (sin Dr(a) ni correo) =====
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.medical_services_outlined,
                          color: theme.colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, $nombre',
                              style: theme.textTheme.titleLarge?.copyWith(
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
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ===== Especialidades =====
                  Text(
                    'Especialidades',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (especialidades.isEmpty)
                    Text(
                      'Configura tus especialidades desde tu perfil.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: especialidades
                          .map(
                            (e) => Chip(
                              label: Text(e),
                              avatar: const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 20),

                  // ===== Botones Chat / Perfil =====
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(title: const Text('Mensajes')),
                                  body: const MessagesPage(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Chat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_outline_rounded),
                          label: const Text('Perfil'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===== Resumen de citas (Bloc) =====
                  Text(
                    'Resumen de citas',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
                    builder: (context, state) {
                      if (state.loading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (state.error != null) {
                        return Center(
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardStatCard(
                                  title: 'Total de citas',
                                  icon: Icons.calendar_today_rounded,
                                  value: state.totalCitas.toString(),
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DashboardStatCard(
                                  title: 'Citas próximas',
                                  icon: Icons.event_available_rounded,
                                  value: state.citasProximas.toString(),
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardStatCard(
                                  title: 'Pacientes únicos',
                                  icon: Icons.group_outlined,
                                  value: state.totalPacientes.toString(),
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ===== Próximas citas =====
                  Text(
                    'Próximas citas',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream: citasQuery.snapshots(),
                    builder: (context, snapshotCitas) {
                      if (snapshotCitas.hasError) {
                        return Text(
                          'Error al cargar próximas citas: ${snapshotCitas.error}',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        );
                      }

                      if (!snapshotCitas.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // Client-side processing to avoid Firestore Index requirement
                      final allDocs = snapshotCitas.data!.docs;
                      final now = DateTime.now();

                      // 1. Filter future appointments (optional, but good for "Próximas")
                      // 2. Sort by date
                      final sortedDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final ts = data['cuando'] as Timestamp?;
                        if (ts == null) return false;
                        return ts.toDate().isAfter(now.subtract(
                            const Duration(hours: 2))); // Show recent ones too
                      }).toList()
                        ..sort((a, b) {
                          final dataA = a.data() as Map<String, dynamic>;
                          final dataB = b.data() as Map<String, dynamic>;
                          final tsA = dataA['cuando'] as Timestamp?;
                          final tsB = dataB['cuando'] as Timestamp?;
                          if (tsA == null) return 1;
                          if (tsB == null) return -1;
                          return tsA.compareTo(tsB);
                        });

                      // 3. Limit to 5
                      final docs = sortedDocs.take(5).toList();

                      if (docs.isEmpty) {
                        return Text(
                          'No tienes próximas citas.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final motivo = data['motivo'] ?? 'Consulta médica';
                          final ts = data['cuando'] as Timestamp?;
                          final fecha = ts?.toDate();
                          final fechaStr = fecha != null
                              ? '${fecha.day.toString().padLeft(2, '0')}/'
                                  '${fecha.month.toString().padLeft(2, '0')} '
                                  '${fecha.hour.toString().padLeft(2, '0')}:'
                                  '${fecha.minute.toString().padLeft(2, '0')}'
                              : 'Sin fecha';
                          final pacienteId =
                              (data['pacienteId'] ?? data['userId']) as String?;

                          final estado = (data['estado'] ?? 'pendiente')
                              .toString()
                              .toLowerCase();
                          final isCancelada = estado == 'cancelada';
                          final isCompletada =
                              estado == 'completada' || estado == 'realizada';
                          final isPendiente = !isCancelada && !isCompletada;

                          return FutureBuilder<DocumentSnapshot>(
                            future: pacienteId == null
                                ? Future.value(null)
                                : FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(pacienteId)
                                    .get(),
                            builder: (context, snapshotPaciente) {
                              String nombrePaciente = 'Paciente';
                              if (snapshotPaciente.hasData &&
                                  snapshotPaciente.data?.data() != null) {
                                final d = snapshotPaciente.data!.data()
                                    as Map<String, dynamic>;
                                nombrePaciente = d['nombre'] ?? 'Paciente';
                              }

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: isCancelada
                                      ? theme.colorScheme.errorContainer
                                      : isCompletada
                                          ? Colors.green.shade100
                                          : theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    isCancelada
                                        ? Icons.cancel_outlined
                                        : isCompletada
                                            ? Icons.check_circle_outline
                                            : Icons.person_rounded,
                                    color: isCancelada
                                        ? theme.colorScheme.error
                                        : isCompletada
                                            ? Colors.green.shade800
                                            : theme.colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  motivo,
                                  style: (isCancelada || isCompletada)
                                      ? const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                subtitle: Text(
                                  isCancelada
                                      ? 'CANCELADA • $nombrePaciente'
                                      : isCompletada
                                          ? 'COMPLETADA • $nombrePaciente'
                                          : '$nombrePaciente · $fechaStr',
                                  style: isCancelada
                                      ? TextStyle(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : isCompletada
                                          ? TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : null,
                                ),
                                trailing: isPendiente
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Completar',
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green,
                                            ),
                                            onPressed: () => _updateStatus(
                                              context,
                                              docId: doc.id,
                                              pacienteId: pacienteId,
                                              newStatus: 'completada',
                                              confirmTitle: 'Completar cita',
                                              confirmMessage:
                                                  '¿Marcar esta cita como realizada?',
                                              confirmColor: Colors.green,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Rechazar',
                                            icon: const Icon(
                                              Icons.cancel_outlined,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _updateStatus(
                                              context,
                                              docId: doc.id,
                                              pacienteId: pacienteId,
                                              newStatus: 'cancelada',
                                              confirmTitle: 'Rechazar cita',
                                              confirmMessage:
                                                  '¿Estás seguro de rechazar/cancelar esta cita?',
                                              confirmColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ====== Drawer del doctor ======

class _DoctorDashboardDrawer extends StatelessWidget {
  final String userId;

  const _DoctorDashboardDrawer({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(userId)
                  .get(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                final nombre = (data['nombre'] ?? 'Médico') as String;

                return UserAccountsDrawerHeader(
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  accountName: Text(nombre),
                  accountEmail: const Text('Médico'),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: const Text('Mensajes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Mensajes')),
                      body: const MessagesPage(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfilePage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              textColor: theme.colorScheme.error,
              iconColor: theme.colorScheme.error,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Tarjeta de estadística ======

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.16),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
