import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: TextStyle(color: scheme.onSurface),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Header / Perfil =====
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.displayName?.trim().isNotEmpty == true
                              ? _user!.displayName!
                              : 'Usuario',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? 'sin-correo@ejemplo.com',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Perfil',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== Preferencias =====
          _SectionCard(
            title: 'Preferencias',
            children: [
              _SettingTile(
                icon: Icons.palette_outlined,
                title: 'Apariencia',
                subtitle: 'Se adapta al modo del sistema',
                onTap: () {
                  // Si en el futuro agregas un toggle manual, navega a tu pantalla.
                  // Navigator.pushNamed(context, AppRoutes.appearance);
                },
              ),
              _SettingTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                subtitle: 'Recordatorios de citas y avisos',
                onTap: () {
                  // Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
            ],
          ),

          // ===== Cuenta =====
          _SectionCard(
            title: 'Cuenta',
            children: [
              _SettingTile(
                icon: Icons.lock_outline,
                title: 'Seguridad',
                subtitle: 'Cambiar contraseña / 2FA',
                onTap: () {
                  // Navigator.pushNamed(context, AppRoutes.security);
                },
              ),
              _SettingTile(
                icon: Icons.logout,
                title: 'Cerrar sesión',
                destructive: true,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    // Vuelve a tu login (ajusta la ruta si es distinta)
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),

          // ===== Información / Descripción =====
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Text(
              'Administra tu cuenta, preferencias de notificaciones y opciones de apariencia. '
              'El modo oscuro/claro ahora se adapta automáticamente al sistema.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          // encabezado de sección
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: scheme.surfaceVariant,
        child: Icon(
          icon,
          color: scheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: destructive ? scheme.error : scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
      trailing: Icon(
        Icons.chevron_right,
        color: destructive ? scheme.error : scheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
