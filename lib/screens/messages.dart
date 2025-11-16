import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Inicia sesión para ver tus mensajes.'),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar usuario: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final rol = (data['rol'] ?? 'Paciente').toString().toLowerCase();
        final isMedico = rol == 'médico' || rol == 'medico';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mensajes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              _SearchBar(),
              const SizedBox(height: 16),
              Expanded(
                child: isMedico
                    ? _DoctorConversationsList(medicoId: user.uid)
                    : _PatientDoctorsList(pacienteId: user.uid),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============= Paciente: lista de doctores reales =============

class _PatientDoctorsList extends StatelessWidget {
  final String pacienteId;

  const _PatientDoctorsList({required this.pacienteId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', whereIn: ['Médico', 'medico'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar médicos: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Aún no hay médicos registrados.\n'
              'Cuando se creen cuentas de médicos, aparecerán aquí.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final doctorId = doc.id;
            final nombre = data['nombre'] ?? 'Médico';

            String subtitle;
            if (data['especialidades'] is List &&
                (data['especialidades'] as List).isNotEmpty) {
              subtitle = (data['especialidades'] as List)
                  .map((e) => e.toString())
                  .join(' · ');
            } else if (data['especialidad_principal'] != null) {
              subtitle = data['especialidad_principal'].toString();
            } else if (data['especialidad'] != null) {
              subtitle = data['especialidad'].toString();
            } else {
              subtitle = 'Especialidad no definida';
            }

            return _ConversationTile(
              title: nombre.toString(), // sin Dr(a), sin correo
              subtitle: subtitle,
              trailing: const SizedBox.shrink(),
              leadingIcon: Icons.local_hospital_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      otherUserId: doctorId,
                      otherUserName: nombre.toString(),
                      otherUserRole: 'Médico',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============= Médico: lista de pacientes =============

class _DoctorConversationsList extends StatelessWidget {
  final String medicoId;

  const _DoctorConversationsList({required this.medicoId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('citas')
          .where('medicoId', isEqualTo: medicoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar citas: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final citas = snapshot.data!.docs;

        if (citas.isEmpty) {
          return const Center(
            child: Text(
              'Aún no tienes citas asignadas.\n'
              'Cuando los pacientes agenden contigo, aparecerán aquí.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final Set<String> patientIds = {};
        for (var c in citas) {
          final data = c.data() as Map<String, dynamic>;
          final pid = data['userId'] as String?;
          if (pid != null) patientIds.add(pid);
        }

        final idsList = patientIds.toList();

        return ListView.separated(
          itemCount: idsList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final pacienteId = idsList[index];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(pacienteId)
                  .get(),
              builder: (context, snapshotUser) {
                if (snapshotUser.hasError) {
                  return ListTile(
                    title: Text(
                        'Error al cargar paciente: ${snapshotUser.error}'),
                  );
                }

                if (!snapshotUser.hasData ||
                    snapshotUser.data?.data() == null) {
                  return const ListTile(
                    title: Text('Cargando paciente...'),
                  );
                }

                final dataUser =
                    snapshotUser.data!.data() as Map<String, dynamic>;
                final nombre = dataUser['nombre'] ?? 'Paciente';
                final email = dataUser['email'] ?? '';

                return _ConversationTile(
                  title: nombre.toString(),
                  subtitle: email.toString(),
                  trailing: const SizedBox.shrink(),
                  leadingIcon: Icons.person_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          otherUserId: pacienteId,
                          otherUserName: nombre.toString(),
                          otherUserRole: 'Paciente',
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============= Componentes comunes =============

class _ConversationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final IconData leadingIcon;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.leadingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            leadingIcon,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Buscar doctor o especialidad...',
        prefixIcon:
            Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ============= Chat =============

class ChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;

  const ChatPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final String _chatId;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser!;
    _chatId = _buildChatId(currentUser.uid, widget.otherUserId);
    _ensureChatDocument(currentUser.uid);
  }

  String _buildChatId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  Future<void> _ensureChatDocument(String currentUserId) async {
    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(_chatId);

    await chatRef.set({
      'participants': [currentUserId, widget.otherUserId],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser!;
    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(_chatId);

    await chatRef.collection('mensajes').add({
      'senderId': user.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'ultimoMensaje': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            Text(
              widget.otherUserRole,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('mensajes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar mensajes: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No hay mensajes aún. ¡Envía el primero!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data() as Map<String, dynamic>;
                    final isMine = data['senderId'] == user.uid;
                    final text = data['text'] ?? '';
                    final ts = data['createdAt'] as Timestamp?;
                    final timeStr = ts != null
                        ? DateFormat('HH:mm').format(ts.toDate())
                        : '';

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: isMine
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(14).copyWith(
                            bottomLeft:
                                Radius.circular(isMine ? 14 : 2),
                            bottomRight:
                                Radius.circular(isMine ? 2 : 14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMine
                                    ? Colors.white70
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
