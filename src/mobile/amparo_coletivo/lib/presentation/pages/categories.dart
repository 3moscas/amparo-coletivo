import 'package:flutter/material.dart';
import 'package:amparo_coletivo/presentation/pages/list_by_category.dart';
import 'package:amparo_coletivo/shared/widgets/custom_drawer.dart';

class Categories extends StatelessWidget {
  const Categories({super.key});

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
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text("Categorias de ONGs"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: GridView.builder(
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
                  builder: (_) => ListaOngsPorCategoriaPage(category: nome),
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
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),

                  // camada escura
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),

                  // texto
                  Center(
                    child: Text(
                      nome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black,
                            offset: Offset(1, 1),
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
      ),
    );
  }
}
