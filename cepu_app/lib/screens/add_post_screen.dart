import 'dart:convert';
import 'package:cepu_app/models/post.dart';
import 'package:cepu_app/service/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  String? _base64Image;
  String? _latitude;
  String? _longitude;
  String? _category;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;

  List<String> get categories {
    return [
      'Jalan Rusak',
      'Banjir',
      'Sampah',
      'Lampu Penerang Jalan',
      'Lainnya',
    ];
  }

  // 1. Fungsi pick, compress and convert image
  Future<void> pickImageAndConvert() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final compressedImage = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 80,
    );
    setState(() {
      _base64Image = base64Encode(compressedImage);
    });
  }

  // 2. Fungsi untuk mendapatkan location
  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location Permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied")),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  // 3. Fungsi tampil pilihan kategori
  void _showCategoryModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Kategori",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ...categories.map((category) {
                return ListTile(
                  title: Text(category),
                  onTap: () {
                    setState(() {
                      _category = category;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // 4. Fungsi Submit Post
  Future<void> _submitPost() async {
    if (_base64Image == null || _descriptionController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Gambar dan Masukkan Deskripsi")),
      );
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final fullname = FirebaseAuth.instance.currentUser?.displayName;
    
    try {
        _getLocation();
        await PostService.addPost(
            Post(
                imageUrl: _base64Image,
                description: _descriptionController.text,
                category: _category,
                userId: userId,
                fullname: fullname,
                latitude: _latitude,
                longitude: _longitude,
            )
        ).whenComplete(() {
            Navigator.of(context).pop();
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Post Berhasil Ditambahkan"))
        
    } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal Menambahkan Post: $e"))
        );

    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}