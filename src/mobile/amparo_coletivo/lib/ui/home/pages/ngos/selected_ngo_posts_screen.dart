// ONG posts listing screen
import 'package:flutter/material.dart';
import 'package:amparo_coletivo/services/posts_service.dart';

class SelectedNGOPostsScreen extends StatefulWidget {
  final Map<String, dynamic> ongData;
  const SelectedNGOPostsScreen({super.key, required this.ongData});

  @override
  State<SelectedNGOPostsScreen> createState() => _SelectedNGOPostsScreenState();
}

class _SelectedNGOPostsScreenState extends State<SelectedNGOPostsScreen> {
  final PostsService _service = PostsService();
  bool loading = true;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      posts = await _service.listPostsByOng(widget.ongData['id'].toString());
    } catch (e) {
      debugPrint('Erro posts: $e');
      posts = [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) return 'Data desconhecida';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return createdAt;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ongTitle = widget.ongData['title'] ?? 'Publicações';
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Publicações — $ongTitle')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text('Nenhuma publicação por enquanto'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = posts[i];
                    return Card(
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p['image_url'] != null &&
                              p['image_url'].toString().isNotEmpty)
                            Image.network(p['image_url'],
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: Icon(
                                            Icons.image_not_supported_outlined),
                                      ),
                                    )),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['title'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                const SizedBox(height: 8),
                                Text(p['content'] ?? ''),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDate(p['created_at']),
                                        style: textTheme.bodySmall),
                                    Row(children: [
                                      const Icon(Icons.favorite_border,
                                          size: 18),
                                      const SizedBox(width: 6),
                                      Text('${p['likes'] ?? 0}'),
                                    ])
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
