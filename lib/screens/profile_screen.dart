import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _userService.getCurrentUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Error cargando perfil'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Foto de perfil
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _user!.photoUrl != null
                            ? NetworkImage(
                                _user!.photoUrl!,
                                headers: const {'Accept': 'image/*'},
                              )
                            : null,
                        onBackgroundImageError: (exception, stackTrace) {
                          // Manejar errores de carga de imagen (incluyendo 429)
                          print('Error cargando foto de perfil: $exception');
                        },
                        child: _user!.photoUrl == null
                            ? Text(
                                _user!.displayName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 40),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _user!.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _user!.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings),
                      title: const Text('Rol'),
                      trailing: Text(
                        _user!.role.value == 'admin' ? 'Administrador' : 'Usuario',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Miembro desde'),
                      trailing: Text(
                        '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}',
                      ),
                    ),
                    if (_user!.lastLogin != null)
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Último acceso'),
                        trailing: Text(
                          '${_user!.lastLogin!.day}/${_user!.lastLogin!.month}/${_user!.lastLogin!.year}',
                        ),
                      ),
                  ],
                ),
    );
  }
}
