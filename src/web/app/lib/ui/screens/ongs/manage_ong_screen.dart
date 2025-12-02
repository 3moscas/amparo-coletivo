import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/ong_model.dart';
import '../../../core/services/ong_service.dart';

class ManageOngScreen extends StatefulWidget {
  final Ong? ong;

  const ManageOngScreen({super.key, this.ong});

  @override
  State<ManageOngScreen> createState() => _ManageOngScreenState();
}

class _ManageOngScreenState extends State<ManageOngScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final OngService _ongService = OngService();

  bool _isLoading = false;
  bool _highlighted = false;
  Uint8List? _imageBytes;
  String? _imageUrl;

  String? _selectedCategory;

  final List<Map<String, String>> _categories = [
    {'nome': 'Saúde', 'imagem': 'saude.jpg'},
    {'nome': 'Educação', 'imagem': 'educacao.jpg'},
    {'nome': 'Meio Ambiente', 'imagem': 'meio_ambiente.jpg'},
    {'nome': 'Animais', 'imagem': 'animais.jpg'},
    {'nome': 'Moradia', 'imagem': 'moradia.jpg'},
    {'nome': 'Outros', 'imagem': 'outros.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ong != null) {
      final ong = widget.ong!;
      _titleController.text = ong.title;
      _descriptionController.text = ong.description;
      _highlighted = ong.highlighted;
      _imageUrl = ong.imageUrl;
      _selectedCategory = ong.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageUrl = null;
      });
    }
  }

  Future<void> _saveOng() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _imageUrl;

      if (_imageBytes != null) {
        final fileName = 'ong_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _ongService.uploadImageBytes(_imageBytes!, fileName);
        
        if (imageUrl == null) {
          throw Exception('Falha ao fazer upload da imagem');
        }
      }

      final ong = Ong(
        id: widget.ong?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl ?? '',
        highlighted: _highlighted,
        category: _selectedCategory!,
        fotoRelevante1: widget.ong?.fotoRelevante1 ?? '',
        fotoRelevante2: widget.ong?.fotoRelevante2 ?? '',
        fotoRelevante3: widget.ong?.fotoRelevante3 ?? '',
        sobreOng: widget.ong?.sobreOng ?? '',
      );

      if (widget.ong == null) {
        await _ongService.createOng(ong);
      } else {
        await _ongService.updateOng(ong);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar ONG: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ong == null ? 'Nova ONG' : 'Editar ONG'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagem principal
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image: _imageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_imageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : (_imageUrl != null && _imageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: _imageBytes == null && (_imageUrl == null || _imageUrl!.isEmpty)
                            ? const Center(
                                child:
                                    Icon(Icons.add_photo_alternate, size: 50),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título da ONG *',
                        prefixIcon: Icon(Icons.people),
                      ),
                      validator:
                          RequiredValidator(errorText: 'Título é obrigatório').call,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição *',
                        hintText: 'Fale sobre a ONG, sua missão, etc.',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: RequiredValidator(
                          errorText: 'Descrição é obrigatória').call,
                    ),
                    const SizedBox(height: 16),
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c['nome'],
                                child: Text(c['nome']!),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Categoria *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator:
                          RequiredValidator(errorText: 'Selecione uma categoria').call,
                    ),
                    const SizedBox(height: 16),
                    // Destacar ONG
                    SwitchListTile(
                      title: const Text('Destacar ONG'),
                      value: _highlighted,
                      onChanged: (value) {
                        setState(() => _highlighted = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveOng,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.ong == null
                              ? 'Cadastrar ONG'
                              : 'Salvar Alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
