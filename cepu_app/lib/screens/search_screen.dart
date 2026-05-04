import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  
  // Data dummy untuk auto-suggestion tempat wisata
  final List<String> _allData = [
    "Candi Borobudur",
    "Pantai Kuta",
    "Gunung Bromo",
    "Raja Ampat",
    "Danau Toba",
    "Taman Nasional Komodo",
    "Candi Prambanan",
    "Kawah Putih",
    "Nusa Penida",
    "Tangkuban Perahu",
    "Pantai Pandawa",
    "Gunung Rinjani",
    "Taman Mini Indonesia Indah",
    "Kebun Raya Bogor",
    "Pantai Parangtritis",
    "Curug Lawe",
    "Malioboro",
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
    } else {
      setState(() {
        _suggestions = _allData
            .where((item) => item.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Cari tempat wisata...",
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          ),
        ),
      ),
      body: _suggestions.isEmpty && _searchController.text.isNotEmpty
          ? const Center(child: Text("Hasil tidak ditemukan."))
          : ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(_suggestions[index]),
                  onTap: () {
                    // Ketika suggestion diklik, teks dimasukkan ke search bar
                    _searchController.text = _suggestions[index];
                    _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _searchController.text.length));
                        
                    // Di sini nanti bisa ditambahkan logika untuk navigate ke hasil pencarian
                  },
                );
              },
            ),
    );
  }
}
