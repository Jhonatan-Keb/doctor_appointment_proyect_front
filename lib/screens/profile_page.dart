import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController enfermedadesCtrl = TextEditingController();

  String _rol = 'Paciente';
  String _genero = 'Prefiero no decir';
  String? _clinica;
  List<String> _especialidades = [];

  bool _loading = false;

  final List<String> _listaEspecialidades = const [
    'Medicina general',
    'Odontología',
    'Cardiología',
    'Dermatología',
    'Nutrición',
    'Pediatría',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final data = snap.data() ?? <String, dynamic>{};

    setState(() {
      emailCtrl.text = (data['email'] ?? user.email ?? '') as String;
      nombreCtrl.text = (data['nombre'] ?? '') as String;
      telefonoCtrl.text = (data['telefono'] ?? '') as String;
      enfermedadesCtrl.text = (data['enfermedades'] ?? '') as String;

      _rol = (data['rol'] ?? 'Paciente') as String;
      _genero = (data['genero'] ?? 'Prefiero no decir') as String;
      _clinica = data['clinica']?.toString();

      if (data['especialidades'] is List) {
        _especialidades =
            (data['especialidades'] as List).map((e) => e.toString()).toList();
      }
    });
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newEmail = emailCtrl.text.trim();
    final nombre = nombreCtrl.text.trim();
    final telefono = telefonoCtrl.text.trim();
    final enfermedades = enfermedadesCtrl.text.trim();

    if (newEmail.isEmpty || !newEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

      final dataToUpdate = <String, dynamic>{
        'email': newEmail,
        'nombre': nombre,
        'telefono': telefono,
        'enfermedades': enfermedades,
        'rol': _rol,
        'tipo_usuario': _rol.toLowerCase(),
        'genero': _genero,
        'clinica': _clinica,
        'especialidades': _especialidades,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(dataToUpdate, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar perfil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    nombreCtrl.dispose();
    telefonoCtrl.dispose();
    enfermedadesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esMedico =
        _rol.toLowerCase() == 'médico' || _rol.toLowerCase() == 'medico';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: telefonoCtrl,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: enfermedadesCtrl,
              decoration: const InputDecoration(
                labelText: 'Condiciones médicas',
                prefixIcon: Icon(Icons.healing_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // ===== Rol solo de lectura =====
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Rol',
                prefixIcon: const Icon(Icons.badge_outlined),
                hintText: _rol,
              ),
              controller: TextEditingController(text: _rol),
            ),

            if (esMedico) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Datos profesionales',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),

              // ===== Género =====
              DropdownButtonFormField<String>(
                value: _genero,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Masculino',
                    child: Text('Masculino'),
                  ),
                  DropdownMenuItem(
                    value: 'Femenino',
                    child: Text('Femenino'),
                  ),
                  DropdownMenuItem(
                    value: 'Otro',
                    child: Text('Otro'),
                  ),
                  DropdownMenuItem(
                    value: 'Prefiero no decir',
                    child: Text('Prefiero no decir'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _genero = value);
                },
              ),

              const SizedBox(height: 16),

              // ===== Especialidades múltiples =====
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Especialidades',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _listaEspecialidades.map((esp) {
                  final selected = _especialidades.contains(esp);
                  return FilterChip(
                    label: Text(esp),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _especialidades.add(esp);
                        } else {
                          _especialidades.remove(esp);
                        }
                      });
                    },
                    avatar: const Icon(Icons.local_hospital, size: 16),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ===== Clínica =====
              DropdownButtonFormField<String>(
                value: _clinica,
                decoration: const InputDecoration(
                  labelText: 'Clínica',
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: const [
                  DropdownMenuItem(value: 'T1', child: Text('T1')),
                  DropdownMenuItem(value: 'Heroes', child: Text('Heroes')),
                  DropdownMenuItem(value: 'Pacaptun', child: Text('Pacaptun')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _clinica = val);
                },
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
