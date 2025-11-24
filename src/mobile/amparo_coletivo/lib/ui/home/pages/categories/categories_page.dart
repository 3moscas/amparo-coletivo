import 'package:flutter/material.dart';
import 'package:amparo_coletivo/ui/home/pages/categories/selected_category_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  final List<Map<String, String>> categorias = const [
    {
      'nome': 'Saúde',
      'imagem':
          'https://images.unsplash.com/photo-1527613426441-4da17471b66d?q=80&w=1152&auto=format&fit=crop'
    },
    {
      'nome': 'Educação',
      'imagem':
          'https://images.unsplash.com/photo-1512238972088-8acb84db0771?q=80&w=1170&auto=format&fit=crop'
    },
    {
      'nome': 'Meio Ambiente',
      'imagem':
          'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?q=80&w=1170&auto=format&fit=crop'
    },
    {
      'nome': 'Animais',
      'imagem':
          'https://images.unsplash.com/photo-1493916665398-143bdeabe500?q=80&w=1074&auto=format&fit=crop'
    },
    {
      'nome': 'Moradia',
      'imagem':
          'https://images.unsplash.com/photo-1516156008625-3a9d6067fab5?q=80&w=1170&auto=format&fit=crop'
    },
    {
      'nome': 'Outros',
      'imagem':
          'https://images.unsplash.com/photo-1596495577886-d920f1b62f90?q=80&w=1170&auto=format&fit=crop'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final categoria = categorias[index];
        final nome = categoria['nome']!;
        final imagem = categoria['imagem']!;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SelectedCategoryPage(category: nome),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imagem,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loading) {
                    if (loading == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stack) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image,
                        size: 40, color: colorScheme.onSurfaceVariant),
                  ),
                ),
                Container(
                  color: colorScheme.scrim.withValues(alpha: 0.35),
                ),
                Center(
                  child: Text(
                    nome,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: colorScheme.scrim,
                          offset: const Offset(1, 1),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
