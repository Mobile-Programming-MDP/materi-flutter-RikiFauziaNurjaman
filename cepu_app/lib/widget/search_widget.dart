import 'package:flutter/material.dart';
import 'package:cepu_app/screens/search_screen.dart';

class SearchWidget extends StatelessWidget {
  final String hintText;
  
  const SearchWidget({super.key, this.hintText = "Cari tempat wisata..."});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8.0),
            Text(
              hintText,
              style: const TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
