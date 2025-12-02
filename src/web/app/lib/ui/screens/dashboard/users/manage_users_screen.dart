import 'package:flutter/material.dart';
import 'package:app/core/services/user_service.dart';
import 'package:app/core/models/user_model.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserService _userService = UserService();
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _userService.getUsers();
    });
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(
            'Deseja realmente deletar "${user.firstName} ${user.lastName}"?'),
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
      _loadUsers();
    }
  }

  Future<void> _editUser(UserModel user) async {
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final bioController = TextEditingController(text: user.bio);
    bool isAdmin = user.isAdmin;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Usuário'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Nome')),
              TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Sobrenome')),
              TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Bio')),
              SwitchListTile(
                title: const Text('Admin'),
                value: isAdmin,
                onChanged: (val) => isAdmin = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar')),
        ],
      ),
    );

    if (result == true) {
      final updatedUser = UserModel(
        id: user.id,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        gender: user.gender,
        email: user.email,
        bio: bioController.text.trim(),
        avatarUrl: user.avatarUrl,
        isAdmin: isAdmin,
      );
      await _userService.updateUser(updatedUser);
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('Nenhum usuário cadastrado.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user.avatarUrl!))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(user)),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
