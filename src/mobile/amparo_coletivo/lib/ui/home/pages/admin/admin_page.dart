import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/ui/home/pages/admin/create_ngo_post_screen.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController(); // short
  final _sobreController = TextEditingController(); // long
  String? _category;
  bool _highlighted = false;

  bool _loading = false;
  String? _editingId;

  // image bytes (works on web & mobile)
  Uint8List? _logoBytes;
  String? _logoUrl; // existing url from DB (when editing)

  final List<Uint8List?> _photoBytes = [null, null, null];
  final List<String?> _photoUrls = [null, null, null]; // existing urls from DB

  // categories list
  final List<String> _categories = [
    'Educação',
    'Saúde',
    'Meio Ambiente',
    'Animais',
    'Moradia',
    'Alimentação',
    'Outros',
  ];

  // list of ongs loaded
  List<Map<String, dynamic>> _ongs = [];

  @override
  void initState() {
    super.initState();
    _loadOngs();
  }

  Future<void> _loadOngs() async {
    try {
      final resp = await supabase
          .from('ongs')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _ongs = List<Map<String, dynamic>>.from(resp as List);
      });
    } catch (e) {
      debugPrint('Erro ao carregar ongs: $e');
    }
  }

  // ---- picking images (works on web & mobile) ----
  Future<Uint8List?> _pickSingleImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result == null) return null;
    // prefer bytes (works on web). If no bytes (some mobile cases), read from path.
    final pf = result.files.single;
    if (pf.bytes != null) return pf.bytes;
    if (pf.path != null) {
      return await File(pf.path!).readAsBytes();
    }
    return null;
  }

  Future<void> _pickLogo() async {
    final bytes = await _pickSingleImage();
    if (bytes != null) setState(() => _logoBytes = bytes);
  }

  Future<void> _pickPhoto(int index) async {
    final bytes = await _pickSingleImage();
    if (bytes != null) setState(() => _photoBytes[index] = bytes);
  }

  // ---- helper to upload bytes to bucket ongsimages under folder ONG{id} ----
  Future<String?> _uploadBytesToBucket(Uint8List bytes, String path) async {
    try {
      final bucket = supabase.storage.from('ongsimages');
      // uploadBinary supports upsert
      await bucket.uploadBinary(path, bytes,
          fileOptions: const FileOptions(upsert: true));
      final url = bucket.getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('Erro upload: $e');
      return null;
    }
  }

  // ---- Save (create or update) flow:
  // 1) If creating: insert minimal row to get id -> then upload images to ONG{id} -> then update record with URLs.
  // 2) If editing: use existing id -> upload any new images to same folder ONG{id} -> update record.
  Future<void> _saveOng() async {
    final title = _titleController.text.trim();
    final shortDescription = _descriptionController.text.trim();
    final longDescription = _sobreController.text.trim();

    if (title.isEmpty || shortDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final baseData = {
        'title': title,
        'description': shortDescription,
        'sobre_ong': longDescription,
        'category': _category,
        'highlighted': _highlighted,
        'created_at': DateTime.now().toIso8601String(),
      };

      String id;

      if (_editingId == null) {
        final inserted =
            await supabase.from('ongs').insert(baseData).select('id').single();
        id = inserted['id'].toString();
      } else {
        id = _editingId!;
        await supabase.from('ongs').update(baseData).eq('id', id);
      }

      final folder = 'ONG$id';

      String? logoPublicUrl = _logoUrl;
      if (_logoBytes != null) {
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
        final uploaded =
            await _uploadBytesToBucket(_logoBytes!, '$folder/$fileName');
        if (uploaded != null) logoPublicUrl = uploaded;
      }

      final List<String?> galleryUrls = List<String?>.from(_photoUrls);
      for (int i = 0; i < 3; i++) {
        if (_photoBytes[i] != null) {
          final fileName =
              'foto${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png';
          final uploaded =
              await _uploadBytesToBucket(_photoBytes[i]!, '$folder/$fileName');
          if (uploaded != null) galleryUrls[i] = uploaded;
        }
      }

      final updateData = {
        'image_url': logoPublicUrl,
        'foto_relevante1': galleryUrls[0],
        'foto_relevante2': galleryUrls[1],
        'foto_relevante3': galleryUrls[2],
      };

      await supabase.from('ongs').update(updateData).eq('id', id);

      await _loadOngs();

      _clearForm();

      // ----- FIX IMPORTANTE -----
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ONG salva com sucesso!')),
      );
    } catch (e) {
      debugPrint('Erro salvar ONG: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _sobreController.clear();
    _category = null;
    _highlighted = false;
    _editingId = null;
    _logoBytes = null;
    _logoUrl = null;
    for (int i = 0; i < 3; i++) {
      _photoBytes[i] = null;
      _photoUrls[i] = null;
    }
    setState(() {});
  }

  InputDecoration _m3InputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
    );
  }

  // UI preview helper: show either selected bytes (memory) or existing url (network)
  Widget _imagePreview(
    BuildContext context, {
    Uint8List? bytes,
    String? url,
    double width = 120,
    double height = 90,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    if (bytes != null) {
      return Image.memory(bytes,
          width: width, height: height, fit: BoxFit.cover);
    }
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      return Image.network(url, width: width, height: height, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
        return Container(
            width: width,
            height: height,
            color: colorScheme.surfaceContainerHighest,
            child:
                Icon(Icons.broken_image, color: colorScheme.onSurfaceVariant));
      });
    }
    return Container(
        width: width,
        height: height,
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.add_a_photo, color: colorScheme.onSurfaceVariant));
  }

  @override
  Widget build(BuildContext context) {
    // Material 3 style is typically enabled at MaterialApp level via useMaterial3: true
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ---- BOTÃO PARA CRIAR POST ----
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateNGOPostScreen()),
            );
          },
          icon: const Icon(Icons.post_add),
          label: const Text("Criar Postagem"),
        ),
        const SizedBox(height: 20),

        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Form(
              key: _formKey,
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: _m3InputDecoration('Nome da ONG'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(children: [
                    const Text('Favoritar'),
                    Switch(
                        value: _highlighted,
                        onChanged: (v) => setState(() => _highlighted = v)),
                  ])
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: _m3InputDecoration('Descrição curta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sobreController,
                  maxLines: 4,
                  decoration:
                      _m3InputDecoration('Descrição longa (Sobre a ONG)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: _m3InputDecoration('Categoria'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'Selecione categoria' : null,
                ),
                const SizedBox(height: 12),

                // Logo picker & preview
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Logo da ONG',
                        style: theme.textTheme.titleMedium)),
                const SizedBox(height: 8),
                Row(children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: _imagePreview(context,
                        bytes: _logoBytes,
                        url: _logoUrl,
                        width: 150,
                        height: 110),
                  ),
                  const SizedBox(width: 12),
                  Column(children: [
                    FilledButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.upload),
                        label: const Text('Selecionar')),
                    const SizedBox(height: 8),
                    if (_logoBytes != null ||
                        (_logoUrl != null && _logoUrl!.isNotEmpty))
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _logoBytes = null;
                            _logoUrl = null;
                          });
                        },
                        icon: Icon(Icons.delete_forever,
                            color: colorScheme.error),
                        label: const Text('Remover'),
                      )
                  ])
                ]),

                const SizedBox(height: 14),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Fotos relevantes',
                        style: theme.textTheme.titleMedium)),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 10,
                    children: List.generate(3, (i) {
                      return Column(children: [
                        GestureDetector(
                            onTap: () => _pickPhoto(i),
                            child: _imagePreview(context,
                                bytes: _photoBytes[i],
                                url: _photoUrls[i],
                                width: 120,
                                height: 90)),
                        const SizedBox(height: 6),
                        if (_photoBytes[i] != null ||
                            (_photoUrls[i] != null &&
                                _photoUrls[i]!.isNotEmpty))
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _photoBytes[i] = null;
                                _photoUrls[i] = null;
                              });
                            },
                            icon: Icon(Icons.delete, color: colorScheme.error),
                            label: const Text('Remover'),
                          )
                      ]);
                    })),

                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _saveOng,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(_loading
                          ? 'Enviando...'
                          : (_editingId == null
                              ? 'Cadastrar ONG'
                              : 'Salvar alterações')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _clearForm,
                    child: const Text('Limpar'),
                  ),
                ]),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 18),
        Text('ONGs cadastradas', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),

        // list existing ongs
        for (final ong in _ongs)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: ong['image_url'] != null
                  ? Image.network(ong['image_url'],
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported))
                  : Container(
                      width: 56,
                      height: 56,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image)),
              title: Text(ong['title'] ?? ''),
              subtitle: Text(
                  '${ong['category'] ?? ''} • ${ong['description'] ?? ''}'),
              trailing: Wrap(spacing: 6, children: [
                IconButton(
                  icon: Icon(Icons.edit, color: colorScheme.primary),
                  onPressed: () => _startEditAndLoadImages(ong),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar'),
                        content: const Text('Remover essa ONG?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar')),
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Remover')),
                        ],
                      ),
                    );
                    if (ok == true) await _deleteOngAndRefresh(ong['id']);
                  },
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  // helper: when edit button pressed, load Ong fields and image URLs into form
  void _startEditAndLoadImages(Map<String, dynamic> ong) {
    setState(() {
      _editingId = ong['id'].toString();
      _titleController.text = ong['title'] ?? '';
      _descriptionController.text = ong['description'] ?? '';
      _sobreController.text = ong['sobre_ong'] ?? '';
      _category = ong['category'];
      _highlighted = ong['highlighted'] ?? false;

      _logoBytes = null;
      _logoUrl = ong['image_url'];
      for (int i = 0; i < 3; i++) {
        _photoBytes[i] = null;
        _photoUrls[i] = ong['foto_relevante${i + 1}'];
      }
    });
  }

  Future<void> _deleteOngAndRefresh(dynamic id) async {
    try {
      await supabase.from('ongs').delete().eq('id', id);
      await _loadOngs();

      if (!mounted) return;

      if (_editingId == id.toString()) _clearForm();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ONG removida')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao remover: $e')));
    }
  }
}
