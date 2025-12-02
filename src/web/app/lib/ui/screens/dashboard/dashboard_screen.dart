import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/ong_service.dart';
import '../../../../core/services/user_service.dart';

import '../../../../core/models/ong_model.dart';
import '../../../../core/models/user_model.dart';

import '../ongs/manage_ong_screen.dart';
import '../users/add_user_screen.dart';
import '../users/edit_user_screen.dart';
import '../users/promote_user_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;

  final OngService _ongService = OngService();
  final UserService _userService = UserService();

  late Future<List<Ong>> _ongsFuture;
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _ongsFuture = _ongService.getOngs();
    _usersFuture = _userService.getUsers();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await context.read<AuthService>().isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  void _refreshOngs() {
    setState(() {
      _ongsFuture = _ongService.getOngs();
    });
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _userService.getUsers();
    });
  }

  Future<void> _deleteOng(Ong ong) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('Deseja realmente deletar "${ong.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deletar')),
        ],
      ),
    );

    if (confirm == true) {
      await _ongService.deleteOng(ong.id);
      _refreshOngs();
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(
            'Deseja realmente deletar o usuário "${user.firstName} ${user.lastName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deletar')),
        ],
      ),
    );

    if (confirm == true) {
      await _userService.deleteUser(user.id);
      _refreshUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (mounted) context.go(AppConstants.loginRoute);
            },
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          /// -------------------------- ONGS -----------------------------
          FutureBuilder<List<Ong>>(
            future: _ongsFuture,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Erro: ${snapshot.error}"));
              }

              final ongs = snapshot.data ?? [];
              if (ongs.isEmpty) {
                return const Center(child: Text("Nenhuma ONG cadastrada."));
              }

              return ListView.builder(
                itemCount: ongs.length,
                itemBuilder: (_, index) {
                  final ong = ongs[index];

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: ong.imageUrl.isNotEmpty
                            ? NetworkImage(ong.imageUrl)
                            : null,
                        child: ong.imageUrl.isEmpty
                            ? const Icon(Icons.people)
                            : null,
                      ),
                      title: Text(ong.title),
                      subtitle: Text(
                        ong.description.length > 50
                            ? "${ong.description.substring(0, 50)}..."
                            : ong.description,
                      ),
                      trailing: _isAdmin
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              ManageOngScreen(ong: ong)),
                                    );
                                    if (result == true) _refreshOngs();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteOng(ong),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),

          /// --------------------------- USUÁRIOS -------------------------
          if (_isAdmin)
            FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child:
                          Text("Erro ao carregar usuários: ${snapshot.error}"));
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const Center(
                      child: Text("Nenhum usuário encontrado."));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, index) {
                    final user = users[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text("${user.firstName} ${user.lastName}"),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// EDITAR
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          EditUserScreen(user: user)),
                                );
                                if (result == true) _refreshUsers();
                              },
                            ),

                            /// PROMOVER
                            IconButton(
                              icon: const Icon(Icons.security,
                                  color: Colors.orange),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PromoteUserScreen(user: user)),
                                );
                                if (result == true) _refreshUsers();
                              },
                            ),

                            /// DELETAR
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),

      /// ----------------------- BOTÃO ADD -------------------------
      floatingActionButton: (_isAdmin && _selectedIndex == 1)
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserScreen()),
                );
                if (result == true) _refreshUsers();
              },
            )
          : (_isAdmin && _selectedIndex == 0)
              ? FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageOngScreen()),
                    );
                    if (result == true) _refreshOngs();
                  },
                )
              : null,

      bottomNavigationBar: _isAdmin
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.people), label: 'ONGs'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.admin_panel_settings), label: 'Usuários'),
              ],
            )
          : null,
    );
  }
}
