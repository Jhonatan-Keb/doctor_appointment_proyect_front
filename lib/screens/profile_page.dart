import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ProfilePage que usa un ÚNICO documento por usuario: usuarios/{uid}
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

  bool _loading = true;
  bool _saving = false;
  String? _uid;
  String? _originalEmail;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final user = _auth.currentUser;
    _uid = user?.uid;
    _originalEmail = user?.email;
    emailCtrl.text = _originalEmail ?? '';

    if (_uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_uid)
          .get();

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        nombreCtrl.text = (data['nombre'] ?? '').toString();
        telefonoCtrl.text = (data['telefono'] ?? '').toString();
        enfermedadesCtrl.text = (data['enfermedades'] ?? '').toString();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando perfil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _requestPassword(String title, String message) async {
    final passwordCtrl = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || passwordCtrl.text.isEmpty) {
      return null;
    }

    try {
      final user = _auth.currentUser;
      if (user == null || _originalEmail == null) {
        throw Exception('Usuario no autenticado');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _originalEmail!,
        password: passwordCtrl.text,
      );

      await user.reauthenticateWithCredential(credential);
      return passwordCtrl.text;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return null;
      
      String errorMessage = 'Error de autenticación';
      if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Credenciales inválidas';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Demasiados intentos. Intenta más tarde';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return null;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return null;
    }
  }

  Future<void> _guardar() async {
    if (_uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar tu perfil.')),
      );
      return;
    }

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

    if (nombre.isEmpty && telefono.isEmpty && enfermedades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa al menos un campo')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Siempre pedir contraseña antes de guardar cualquier cambio
      final password = await _requestPassword(
        'Confirmar cambios',
        'Por seguridad, ingresa tu contraseña para guardar los cambios:',
      );

      if (password == null) {
        setState(() => _saving = false);
        return;
      }

      // Si el correo cambió, actualizarlo en Firebase Auth
      if (newEmail != _originalEmail) {
        final user = _auth.currentUser;
        if (user != null) {
          await user.verifyBeforeUpdateEmail(newEmail);
          _originalEmail = newEmail;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se ha enviado un correo de verificación. Verifica tu nuevo correo para completar el cambio.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_uid)
          .set({
        'uid': _uid,
        'email': newEmail,
        'nombre': nombre,
        'telefono': telefono,
        'enfermedades': enfermedades,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado ✅')),
      );
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (_uid == null) return;

    // Primera confirmación
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Borrar cuenta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar tu cuenta?\n\n'
          'Esta acción es PERMANENTE y eliminará:\n'
          '• Tu perfil y datos personales\n'
          '• Todas tus citas\n'
          '• Tu cuenta de usuario\n\n'
          'No podrás recuperar esta información.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    // Pedir contraseña para confirmar
    final password = await _requestPassword(
      'Confirmar eliminación',
      'Por seguridad, ingresa tu contraseña para eliminar tu cuenta:',
    );

    if (password == null) return;

    // Mostrar indicador de carga
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Eliminando cuenta...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final db = FirebaseFirestore.instance;

      // 1. Eliminar todas las citas del usuario en la subcolección
      final citasSnapshot = await db
          .collection('usuarios')
          .doc(_uid)
          .collection('citas')
          .get();

      for (var doc in citasSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Eliminar todas las citas del usuario en la colección global
      final citasGlobalesSnapshot = await db
          .collection('citas')
          .where('uid', isEqualTo: _uid)
          .get();

      for (var doc in citasGlobalesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3. Eliminar el documento del usuario
      await db.collection('usuarios').doc(_uid).delete();

      // 4. Eliminar la cuenta de Firebase Auth
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }

      // 5. Cerrar el diálogo de carga
      if (!mounted) return;
      Navigator.pop(context);

      // 6. Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // 7. Redirigir al login
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } catch (e) {
      // Cerrar el diálogo de carga
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar cuenta: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_uid == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay usuario autenticado.\nInicia sesión para ver y guardar tu perfil.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.person, size: 28, color: Color(0xFF1565C0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _auth.currentUser?.email ?? 'Usuario',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      const Text('Perfil', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('Editar datos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              helperText: 'Cambiar el correo requiere verificación',
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: enfermedadesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Padeciminetos/Alergias',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _guardar,
              icon: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),

          const Text('Tus Datos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(_uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Text('Error: ${snap.error}');
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (!snap.data!.exists) {
                return const Text('Aún no hay datos guardados para este usuario.');
              }
              final data = snap.data!.data() as Map<String, dynamic>;
              return Container(
                decoration: BoxDecoration(
                  boxShadow: const [BoxShadow(color: Colors.black12,)],
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFC8E6C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Correo: ${data['email'] ?? ''}\n'
                  'Nombre: ${data['nombre'] ?? ''}\n'
                  'Teléfono: ${data['telefono'] ?? ''}\n'
                  'Enfermedades: ${data['enfermedades'] ?? ''}',
                  style: const TextStyle(height: 1.4),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          
          const Text(
            'Zona de peligro',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          
          OutlinedButton.icon(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Borrar cuenta permanentemente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta acción no se puede deshacer. Se eliminarán todos tus datos.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
