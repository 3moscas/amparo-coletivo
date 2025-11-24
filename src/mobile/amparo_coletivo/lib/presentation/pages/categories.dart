import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/presentation/pages/list_by_category.dart';
import 'package:amparo_coletivo/shared/widgets/custom_drawer.dart';

class Categories extends StatelessWidget {
  const Categories({super.key});

  static final SupabaseClient supabase = Supabase.instance.client;

  // URL correta da API do Supabase
  final String projectUrl =
      "https://luooeidsfkypyctvytok.supabase.co/storage/v1";

  final List<Map<String, String>> categorias = const [
    {'nome': 'Saúde', 'imagem': 'saude.jpg'},
    {'nome': 'Educação', 'imagem': 'educacao.jpg'},
    {'nome': 'Meio Ambiente', 'imagem': 'meio_ambiente.jpg'},
    {'nome': 'Animais', 'imagem': 'animais.jpg'},
    {'nome': 'Moradia', 'imagem': 'moradia.jpg'},
    {'nome': 'Outros', 'imagem': 'outros.jpg'},
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
          final imagemArquivo = categoria['imagem']!;

          // URL completa final do Supabase
          final imagemUrl =
              "$projectUrl/object/public/categories/$imagemArquivo";

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
                    imagemUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loading) {
                      if (loading == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),

                  // camada escura
                  Container(color: Colors.black.withValues(alpha: 0.35)),

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
