import 'package:flutter/material.dart';
import '../../../../core/models/ong_model.dart';

class OngFormScreen extends StatefulWidget {
  final Ong? ong;
  const OngFormScreen({super.key, this.ong});

  @override
  State<OngFormScreen> createState() => _OngFormScreenState();
}

class _OngFormScreenState extends State<OngFormScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ong == null ? 'Nova ONG' : 'Editar ONG'),
      ),
      body: const Center(
        child: Text('Formulário da ONG aqui'),
      ),
    );
  }
}
