import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/ui/home/pages/ngos/selected_ngo_screen.dart';

class SelectedCategoryPage extends StatefulWidget {
  final String category;

  const SelectedCategoryPage({super.key, required this.category});

  @override
  State<SelectedCategoryPage> createState() => _SelectedCategoryPageState();
}

class _SelectedCategoryPageState extends State<SelectedCategoryPage> {
  List<Map<String, dynamic>> ongs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarOngs();
  }

  Future<void> carregarOngs() async {
    try {
      final response = await Supabase.instance.client
          .from('ongs')
          .select()
          .eq('category', widget.category);

      if (!mounted) return;
      setState(() {
        ongs = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Erro ao carregar ONGs: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ongs.isEmpty
              ? const Center(child: Text('Nenhuma ONG encontrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ongs.length,
                  itemBuilder: (context, index) {
                    final ong = ongs[index];

                    return Card(
                      child: ListTile(
                        title: Text(ong['title'] ?? 'Sem nome'),
                        subtitle: Text(ong['description'] ?? 'Sem descrição'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SelectedNGOScreen(
                                ongData: ong,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
