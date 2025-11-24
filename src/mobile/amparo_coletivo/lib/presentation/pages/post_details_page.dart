import 'package:flutter/material.dart';
import 'package:amparo_coletivo/services/posts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostDetailsPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailsPage({super.key, required this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final PostsService _service = PostsService();
  final TextEditingController _commentController = TextEditingController();

  late Map<String, dynamic> post;
  bool loadingComments = true;
  bool hasLiked = false;
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    post = widget.post;
    _initStateAsync();
  }

  Future<void> _initStateAsync() async {
    await _loadComments();
    await _checkLike();
  }

  Future<void> _checkLike() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final liked = await _service.hasUserLiked(post['id'], userId);
    setState(() => hasLiked = liked);
  }

  Future<void> _toggleLike() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (hasLiked) {
      await _service.unlikePost(post['id'], userId);
      setState(() {
        hasLiked = false;
        post['likes_count'] = (post['likes_count'] ?? 1) - 1;
      });
    } else {
      await _service.likePost(post['id'], userId);
      setState(() {
        hasLiked = true;
        post['likes_count'] = (post['likes_count'] ?? 0) + 1;
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => loadingComments = true);
    final result = await _service.listComments(post['id']);
    setState(() {
      comments = result;
      loadingComments = false;
      post['comments_count'] = comments.length;
    });
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await _service.createComment(
      postId: post['id'],
      userId: userId,
      content: content,
    );

    _commentController.clear();
    await _loadComments();
  }

  String _formatDate(String? date) {
    if (date == null) return "";
    final d = DateTime.tryParse(date);
    if (d == null) return "";
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post['title'] ?? '')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post['image_url'] != null &&
                post['image_url'].toString().isNotEmpty)
              Image.network(post['image_url'],
                  width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 12),
            Text(post['content'] ?? ''),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(
                    Icons.favorite,
                    color: hasLiked ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text("${post['likes_count'] ?? 0}"),
                const SizedBox(width: 16),
                const Icon(Icons.comment, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text("${post['comments_count'] ?? 0}"),
              ],
            ),
            const Divider(height: 32),
            const Text("Comentários",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            loadingComments
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? const Text("Nenhum comentário ainda.")
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          final user = c['usuarios'];
                          return ListTile(
                            leading: user?['avatar_url'] != null
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(user['avatar_url']),
                                  )
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(
                                "${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['comment'] ?? ''),
                                Text(
                                  _formatDate(c['created_at']),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Escreva um comentário...",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addComment,
                  child: const Text("Enviar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
