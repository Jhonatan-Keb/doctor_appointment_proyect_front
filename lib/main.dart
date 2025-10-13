import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Asegúrate de que este archivo exista y esté configurado
import 'firebase_options.dart';

// [NOTE]: Este widget debe existir en tu proyecto para que la navegación funcione.
class AppointmentHomePage extends StatelessWidget {
  const AppointmentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Citas')),
      body: Center(
        child: Text(
          '¡Autenticación Exitosa! Bienvenido al Doctor Appointment.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: DraculaThemeColors.text,
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// DEFINICIÓN DE COLORES DRACULA
// ====================================================================

class DraculaThemeColors {
  // Fondo principal oscuro (Dracula's background)
  static const Color base = Color(0xFF282A36);
  // Color de superficie para tarjetas y elementos elevados
  static const Color surface = Color(0xFF44475A);
  // Color de fondo para inputs (un poco más claro que la base)
  static const Color mantle = Color(0xFF383A59); 
  // Color principal (Pink/Fuchsia, clave de Dracula)
  static const Color primaryPink = Color(0xFFFF79C6);
  // Color secundario (Cyan, para acentos y éxito)
  static const Color secondaryCyan = Color(0xFF8BE9FD);
  // Color de texto claro (Foreground)
  static const Color text = Color(0xFFF8F8F2);
  // Color de error (Red)
  static const Color red = Color(0xFFFF5555);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Tema Dracula (Dark Mode)
  ThemeData _buildDraculaTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: DraculaThemeColors.base,
      colorScheme: const ColorScheme.dark(
        primary: DraculaThemeColors.primaryPink,
        secondary: DraculaThemeColors.secondaryCyan,
        background: DraculaThemeColors.base,
        surface: DraculaThemeColors.surface,
        onBackground: DraculaThemeColors.text,
        onSurface: DraculaThemeColors.text,
        error: DraculaThemeColors.red,
      ),
      // Estilo de los campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DraculaThemeColors.mantle, // Fondo oscuro para inputs
        labelStyle: const TextStyle(color: DraculaThemeColors.secondaryCyan),
        prefixIconColor: DraculaThemeColors.secondaryCyan,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DraculaThemeColors.surface, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DraculaThemeColors.primaryPink, width: 2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      // Estilo de los botones elevados (Ingresar)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: DraculaThemeColors.base, // Texto oscuro en botón claro
          backgroundColor: DraculaThemeColors.primaryPink,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 4,
        ),
      ),
      // Estilo de los botones de texto (Olvidaste Contraseña)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DraculaThemeColors.primaryPink,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // Estilo del AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: DraculaThemeColors.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: DraculaThemeColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: DraculaThemeColors.primaryPink),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dracula Auth',
      theme: _buildDraculaTheme(),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ====================================================================
// WIDGET PRINCIPAL DE LOGIN
// *Toda la UI está aquí para hacer el código más corto*
// ====================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Muestra un SnackBar de forma centralizada
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: DraculaThemeColors.base)),
          backgroundColor: isError ? DraculaThemeColors.red : DraculaThemeColors.secondaryCyan,
          duration: const Duration(milliseconds: 2000),
        ),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      _showSnackBar("Bienvenido ${userCredential.user!.email}");

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppointmentHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "user-not-found":
        case "wrong-password":
          message = "Credenciales inválidas. Verifica tu correo y contraseña.";
          break;
        case "invalid-email":
          message = "Formato de correo inválido. Revisa tu input.";
          break;
        case "user-disabled":
          message = "Esta cuenta ha sido deshabilitada.";
          break;
        default:
          message = "Error de autenticación: ${e.message}";
      }
      _showSnackBar(message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    _showSnackBar("Sesión cerrada. ¡Vuelve pronto!");
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  // =========================
  // Olvidaste tu contraseña
  // =========================
  Future<void> _forgotPassword() async {
    final ctrl = TextEditingController(text: emailController.text.trim());
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DraculaThemeColors.surface,
        title: const Text('Recuperar Contraseña'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _auth.sendPasswordResetEmail(email: ctrl.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar(
                    'Te enviamos un correo para restablecer tu contraseña. 📧',
                  );
                }
              } on FirebaseAuthException catch (e) {
                String msg = 'No se pudo enviar el correo';
                if (e.code == 'user-not-found') {
                  msg = 'No existe una cuenta con ese correo.';
                } else if (e.code == 'invalid-email') {
                  msg = 'Correo inválido.';
                }
                _showSnackBar(msg, isError: true);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: DraculaThemeColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: DraculaThemeColors.mantle,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: DraculaThemeColors.primaryPink.withOpacity(0.3),
                width: 1,
              )
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono estilizado con Dracula Pink
                    Icon(Icons.vpn_key_outlined, size: 72, color: DraculaThemeColors.primaryPink),
                    const SizedBox(height: 16),
                    const Text(
                      "Dracula Secure Access",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: DraculaThemeColors.primaryPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ingresa tus credenciales para continuar.",
                      style: TextStyle(
                        fontSize: 14,
                        color: DraculaThemeColors.text,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Correo
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor ingresa tu correo";
                        }
                        if (!value.contains("@") || !value.contains(".")) return "Correo inválido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: DraculaThemeColors.primaryPink,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor ingresa tu contraseña";
                        }
                        if (value.length < 6) {
                          return "Debe tener al menos 6 caracteres";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // >>> Olvidaste tu contraseña (link)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Ingresar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: DraculaThemeColors.base,
                                  strokeWidth: 2
                                )
                              )
                            : const Text("Ingresar"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Crear cuenta (OutlinedButton con color Pink)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DraculaThemeColors.primaryPink,
                          side: const BorderSide(color: DraculaThemeColors.primaryPink),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _goToRegister,
                        child: const Text("Crear cuenta nueva"),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cerrar sesión (opcional/ejemplo)
                    TextButton(
                      onPressed: _signOut,
                      child: Text(
                        'Cerrar sesión (Pruebas)',
                        style: TextStyle(
                          color: DraculaThemeColors.surface,
                          fontSize: 12
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ====================================================================
// PANTALLA DE REGISTRO
// ====================================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: DraculaThemeColors.base)),
          backgroundColor: isError ? DraculaThemeColors.red : DraculaThemeColors.secondaryCyan,
          duration: const Duration(milliseconds: 2000),
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      if (mounted) {
        _showSnackBar("Cuenta creada correctamente. ¡Inicia sesión!");
        Navigator.of(context).pop(); // vuelve al LoginPage
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "email-already-in-use":
          message = "Ese correo ya está registrado en el sistema.";
          break;
        case "invalid-email":
          message = "Correo inválido. Por favor, verifica el formato.";
          break;
        case "weak-password":
          message = "Contraseña muy débil. Necesita al menos 6 caracteres.";
          break;
        default:
          message = "Error de Registro: ${e.message}";
      }
      _showSnackBar(message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Cuenta"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DraculaThemeColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: DraculaThemeColors.mantle.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Registro de Nuevo Usuario", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: DraculaThemeColors.text)),
                  const SizedBox(height: 24),

                  // Campo Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Correo electrónico",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Ingresa tu correo";
                      if (!v.contains("@")) return "Correo inválido";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Contraseña
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure1,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure1 ? Icons.visibility_off : Icons.visibility,
                            color: DraculaThemeColors.primaryPink),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Ingresa una contraseña";
                      if (v.length < 6) return "Mínimo 6 caracteres";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Confirmar Contraseña
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure2,
                    decoration: InputDecoration(
                      labelText: "Confirmar contraseña",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure2 ? Icons.visibility_off : Icons.visibility,
                            color: DraculaThemeColors.primaryPink),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Confirma tu contraseña";
                      }
                      if (v != _password.text) {
                        return "Las contraseñas no coinciden";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón Registrarse
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: DraculaThemeColors.base,
                                strokeWidth: 2
                              )
                            )
                          : const Text("Crear cuenta"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
