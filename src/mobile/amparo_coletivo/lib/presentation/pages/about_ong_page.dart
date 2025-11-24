import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AboutPage extends StatelessWidget {
  AboutPage({super.key});

  final supabase = Supabase.instance.client;

  // Lista atualizada de integrantes
  final List<Map<String, String>> integrantes = [
    {"nome": "Leandro Alves", "foto": "integrantes/leandro.png"},
    {"nome": "Frank Lima", "foto": "integrantes/frank.png"},
    {"nome": "Lucas Arantes", "foto": "integrantes/arantes.png"},
    {"nome": "Lucas Ferreira", "foto": "integrantes/ferreira.png"},
    {"nome": "Bruno Alves", "foto": "integrantes/bruno.png"},
    {"nome": "Fernando Claudiano", "foto": "integrantes/fernando.png"},
  ];

  @override
  Widget build(BuildContext context) {
    // URL da logo
    final logoUrl = supabase.storage
        .from('amparo_coletivo')
        .getPublicUrl('logo/Amparo_Coletivo-logo.png');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sobre o Amparo Coletivo"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // LOGO MAIOR
            Image.network(
              logoUrl,
              height: 180, // AQUI AUMENTEI O TAMANHO
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 25),

            const Text(
              "O Amparo Coletivo é um projeto dedicado a conectar pessoas que desejam ajudar com ONGs que realmente precisam. "
              "Nosso objetivo é facilitar doações e promover impacto social real através da tecnologia.",
              style: TextStyle(fontSize: 17, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            const Text(
              "Integrantes do Projeto",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // GRID DE INTEGRANTES
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: integrantes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 por linha (ajusta automático)
                mainAxisExtent: 150, // Altura dos cards
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, index) {
                final integrante = integrantes[index];

                final fotoUrl = supabase.storage
                    .from('amparo_coletivo')
                    .getPublicUrl(integrante["foto"]!);

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(fotoUrl),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      integrante["nome"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
