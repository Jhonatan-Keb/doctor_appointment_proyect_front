import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _chats = [
    {
      'name': 'Dr. López',
      'specialty': 'Cardiólogo',
      'lastMsg': 'Su cita está confirmada para mañana.',
      'time': '10:32 AM',
      'avatar': '❤️'
    },
    {
      'name': 'Dra. Martínez',
      'specialty': 'Pediatra',
      'lastMsg': 'Envíame los resultados cuando los tengas.',
      'time': '09:15 AM',
      'avatar': '🩺'
    },
    {
      'name': 'Dr. Ramírez',
      'specialty': 'Dentista',
      'lastMsg': 'Recuerde no comer antes de la revisión.',
      'time': 'Ayer',
      'avatar': '🦷'
    },
    {
      'name': 'Dra. Gómez',
      'specialty': 'Dermatóloga',
      'lastMsg': 'Le enviaré una crema recomendada.',
      'time': 'Lun',
      'avatar': '💊'
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _chats
        .where((chat) =>
            chat['name']!.toLowerCase().contains(_query.toLowerCase()) ||
            chat['specialty']!.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mensajes"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Buscar doctor o especialidad...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                // Hereda estilos del tema oscuro para el input
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: filteredChats.map((chat) {
          // ✅ Tarjeta de chat ajustada para Dark Mode
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF282828), // Fondo gris oscuro para la tarjeta
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30, width: 1.2), // Borde blanco sutil
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54, 
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF00B0FF), // Azul fuerte de acento para el avatar
                child: Text(
                  chat['avatar']!,
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              title: Text(
                chat['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                chat['lastMsg']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Hereda el color de texto
              ),
              trailing: Text(
                chat['time']!,
                style: const TextStyle(color: Colors.white54, fontSize: 14), // Color de texto sutil
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailPage(
                    doctor: chat['name']!,
                    specialty: chat['specialty']!,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ChatDetailPage extends StatelessWidget {
  final String doctor;
  final String specialty;

  const ChatDetailPage({
    super.key,
    required this.doctor,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(specialty, style: const TextStyle(fontSize: 15, color: Colors.white70)),
          ],
        ),
      ),
      body: Center(
        child: Text('Aquí aparecerán los mensajes del chat',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.white54, fontSize: 16)),
      ),
    );
  }
}