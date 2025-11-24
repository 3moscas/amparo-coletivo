import 'package:flutter/material.dart';
import 'package:amparo_coletivo/services/posts_service.dart';
import 'package:amparo_coletivo/presentation/pages/post_details_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OngPostsPage extends StatefulWidget {
  final String ongId;

  const OngPostsPage({super.key, required this.ongId});

  @override
  State<OngPostsPage> createState() => _OngPostsPageState();
}

class _OngPostsPageState extends State<OngPostsPage> {
  final PostsService _service = PostsService();

  bool loading = true;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final result = await _service.listPostsByOng(widget.ongId);

    if (mounted) {
      setState(() {
        posts = result;
        loading = false;
      });
    }
  }

  String _formatDate(String? date) {
    if (date == null) return "";
    final d = DateTime.tryParse(date);
    if (d == null) return "";
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final hasLiked = await _service.hasUserLiked(post['id'], userId);

    if (hasLiked) {
      await _service.unlikePost(post['id'], userId);
      setState(() {
        post['likes_count'] = (post['likes_count'] ?? 1) - 1;
      });
    } else {
      await _service.likePost(post['id'], userId);
      setState(() {
        post['likes_count'] = (post['likes_count'] ?? 0) + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Publicações")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text("Nenhuma publicação encontrada."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  itemBuilder: (context, i) {
                    final p = posts[i];

                    return InkWell(
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailsPage(post: p),
                          ),
                        );

                        if (updated == true) {
                          _loadPosts();
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p['image_url'] != null &&
                                p['image_url'].toString().isNotEmpty)
                              Image.network(
                                p['image_url'],
                                height: 190,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    p['content'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(p['created_at']),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // Botão de like funcional
                                          GestureDetector(
                                            onTap: () => _toggleLike(p),
                                            child: Icon(
                                              Icons.favorite,
                                              size: 18,
                                              color: (p['likes_count'] ?? 0) > 0
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text("${p['likes_count'] ?? 0}"),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.comment,
                                            size: 18,
                                            color: Colors.blueGrey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text("${p['comments_count'] ?? 0}"),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
