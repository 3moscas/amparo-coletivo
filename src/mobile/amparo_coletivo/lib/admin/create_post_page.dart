// lib/admin/post_create_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amparo_coletivo/services/posts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostCreatePage extends StatefulWidget {
  final String? postId;
  final String? selectedOngId;

  const PostCreatePage({
    super.key,
    this.postId,
    this.selectedOngId,
  });

  @override
  State<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final PostsService _postsService = PostsService();

  String? _postId;
  String? _selectedOngId;

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  Uint8List? _selectedImageBytes;
  String? _currentImageUrl;

  bool _isLoading = false;
  bool _editing = false;

  List<Map<String, dynamic>> _ongs = [];

  @override
  void initState() {
    super.initState();

    _postId = widget.postId;
    _selectedOngId = widget.selectedOngId;

    _titleController = TextEditingController();
    _contentController = TextEditingController();

    if (_postId != null) {
      _editing = true;
      _loadPostData();
    }

    _loadOngs();
  }

  // --------------------------------------------------------------
  // CARREGAR ONGs
  // --------------------------------------------------------------
  Future<void> _loadOngs() async {
    try {
      final res = await Supabase.instance.client
          .from('ongs')
          .select('id, title')
          .order('title');

      if (!mounted) return;

      setState(() {
        _ongs = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('Erro ao carregar ONGs: $e');
    }
  }

  // --------------------------------------------------------------
  // CARREGAR POST EXISTENTE PARA EDIÇÃO
  // --------------------------------------------------------------
  Future<void> _loadPostData() async {
    try {
      final res = await Supabase.instance.client
          .from('posts')
          .select()
          .eq('id', _postId!)
          .single();

      if (!mounted) return;

      setState(() {
        _titleController.text = res['title'];
        _contentController.text = res['content'];
        _selectedOngId = res['ong_id'];
        _currentImageUrl = res['image_url'];
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados do post: $e");
    }
  }

  // --------------------------------------------------------------
  // SELECIONAR IMAGEM
  // --------------------------------------------------------------
  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final picked =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final bytes = await picked.readAsBytes();

          if (!mounted) return;
          setState(() => _selectedImageBytes = bytes);
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );

        if (result != null && result.files.single.bytes != null) {
          if (!mounted) return;
          setState(() => _selectedImageBytes = result.files.single.bytes);
        }
      }
    } catch (e) {
      debugPrint("Erro ao selecionar imagem: $e");
    }
  }

  // --------------------------------------------------------------
  // SALVAR POSTAGEM
  // --------------------------------------------------------------
  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? newImageUrl;

      // UPLOAD DE IMAGEM
      if (_selectedImageBytes != null) {
        newImageUrl = await PostsService.uploadPostImage(
          bytes: _selectedImageBytes!,
          postId: _postId,
        );

        // APAGA IMAGEM ANTIGA SE ESTIVER EDITANDO
        if (_editing &&
            _currentImageUrl != null &&
            newImageUrl != _currentImageUrl) {
          await PostsService.deleteImageIfExists(_currentImageUrl!);
        }
      }

      // EDITAR POST EXISTENTE
      if (_editing) {
        await _postsService.updatePost(
          id: _postId!,
          title: _titleController.text,
          content: _contentController.text,
          ongId: _selectedOngId!,
          imageUrl: newImageUrl ?? _currentImageUrl,
        );
      } else {
        // CRIAR NOVO POST
        await _postsService.createPost(
          title: _titleController.text,
          content: _contentController.text,
          ongId: _selectedOngId!,
          imageUrl: newImageUrl,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Erro ao salvar post: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao salvar postagem.")),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // --------------------------------------------------------------
  // INTERFACE
  // --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? "Editar Postagem" : "Criar Postagem"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOngId,
                      decoration: const InputDecoration(labelText: "ONG"),
                      items: _ongs.map((ong) {
                        return DropdownMenuItem<String>(
                          value: ong['id'] as String,
                          child: Text(ong['title']),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedOngId = v),
                      validator: (v) => v == null ? "Selecione uma ONG" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Título"),
                      validator: (v) => v!.isEmpty ? "Informe um título" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: "Conteúdo"),
                      maxLines: 5,
                      validator: (v) =>
                          v!.isEmpty ? "Informe o conteúdo" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text("Selecionar Imagem"),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedImageBytes != null)
                      Image.memory(
                        _selectedImageBytes!,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    if (_selectedImageBytes == null &&
                        _currentImageUrl != null &&
                        _currentImageUrl!.isNotEmpty)
                      Image.network(
                        _currentImageUrl!,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 30),
                    FilledButton(
                      onPressed: _savePost,
                      child: Text(
                        _editing ? "Atualizar Postagem" : "Criar Postagem",
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
