import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amparo_coletivo/ui/home/pages/ngos/selected_ngo_screen.dart';

class NGOsPage extends StatefulWidget {
  const NGOsPage({super.key});

  @override
  State<NGOsPage> createState() => _NGOsPageState();
}

class _NGOsPageState extends State<NGOsPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _ongs = [];
  List<dynamic> _ongsDestaque = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarOngs();
  }

  Future<void> _carregarOngs() async {
    try {
      final data = await supabase
          .from('ongs')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _ongs = data;
        _ongsDestaque = data.where((o) => o['highlighted'] == true).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );

      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _carregarOngs,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              clipBehavior: Clip.none,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ONGs em destaque',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _ongsDestaque.isEmpty
                      ? const Text('Nenhuma ONG em destaque no momento.')
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _ongsDestaque.length,
                            itemBuilder: (context, i) {
                              final ong = _ongsDestaque[i];
                              return GestureDetector(
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
                                child: Card(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    width: 180,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Image.network(
                                            ong['image_url'] ?? '',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(Icons.image),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            ong['title'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 20),
                  Text(
                    'Todas as ONGs',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _ongs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Nenhuma ONG cadastrada ainda.'),
                          ),
                        )
                      : Column(
                          children: _ongs.map((ong) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: Image.network(
                                  ong['image_url'] ?? '',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(Icons.image),
                                ),
                                title: Text(ong['title'] ?? ''),
                                subtitle: Text(ong['category'] ?? ''),
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
                          }).toList(),
                        ),
                ],
              ),
            ),
          );
  }
}
