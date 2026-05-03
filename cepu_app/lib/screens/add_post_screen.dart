import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cepu_app/models/post.dart';
import 'package:cepu_app/service/post_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _image;
  Uint8List? _imageBytes;
  List<String> categories = [
    "Jalan Rusak",
    "Lampu Jalan Mati",
    "Lawan Arah",
    "Merokok di Jalan",
    "Tidak Pakai Helm",
  ];
  String? _category;
  String? _latitude;
  String? _longitude;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  Future<void> pickAndConvertThenCompressImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();

      var result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 80,
        minWidth: 1280,
        minHeight: 1280,
      );

      final encodedResult = base64Encode(result);

      setState(() {
        _image = encodedResult;
        _imageBytes = result;
      });
    }
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((cat) {
            return ListTile(
              title: Text(cat),
              onTap: () {
                setState(() {
                  _category = cat;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Layanan Lokasi Tidak Aktif ")));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Akses Ditolak")));
          return;
        }
      }
      setState(() {
        _isGettingLocation = true;
      });
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
      _isGettingLocation = false;
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });
      debugPrint("Failed to retrieve location : $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengambil lokasi.")));
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_image == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Isi gambar dan deskripsi"),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final fullName = FirebaseAuth.instance.currentUser?.displayName;
    setState(() {
      _isSubmitting = true;
    });
    try {
      await _getLocation();
      PostService.addPost(
        Post(
          category: _category,
          description: _descriptionController.text,
          fullName: fullName,
          userId: userId,
          image: _image,
          latitude: _latitude,
          longitude: _longitude,
        ),
      ).whenComplete(() {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Data berhasil ditambahkan"),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi Error : $e"),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add new post")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _imageBytes == null
                ? Container(
                    height: 180,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Text('Belum ada gambar dipilih'),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSubmitting ? null : pickAndConvertThenCompressImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isSubmitting ? null : _showCategorySelector,
              child: const Text('Select Category'),
            ),
            const SizedBox(height: 8),
            Text(
              _category ?? 'Belum memilih kategori',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Masukkan deskripsi laporan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: (_isSubmitting || _isGettingLocation)
                  ? null
                  : _getLocation,
              child: Text(
                _isGettingLocation ? 'Mengambil Lokasi...' : 'Get Location',
              ),
            ),
            const SizedBox(height: 8),
            _latitude == null || _longitude == null
                ? const Text(
                    'Lokasi belum diambil',
                    textAlign: TextAlign.center,
                  )
                : Text(
                    'Lat: $_latitude\nLng: $_longitude',
                    textAlign: TextAlign.center,
                  ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
