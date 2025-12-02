import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/user_service.dart';

class PromoteUserScreen extends StatefulWidget {
  final UserModel user;

  const PromoteUserScreen({super.key, required this.user});

  @override
  State<PromoteUserScreen> createState() => _PromoteUserScreenState();
}

class _PromoteUserScreenState extends State<PromoteUserScreen> {
  final UserService _userService = UserService();
  late bool isAdmin;

  @override
  void initState() {
    super.initState();
    isAdmin = widget.user.isAdmin;
  }

  Future<void> _save() async {
    final updated = widget.user.copyWith(isAdmin: isAdmin);
    await _userService.updateUser(updated);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Permissões de ${widget.user.firstName}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Administrador"),
              value: isAdmin,
              onChanged: (v) => setState(() => isAdmin = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text("Salvar"),
            )
          ],
        ),
      ),
    );
  }
}
