import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cepu_app/models/post.dart';
import 'package:cepu_app/service/post_service.dart';
import 'package:http/http.dart' as http;

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
  String? _base64Image;
  List<String> categories = [
    "Jalan Rusak",
    "Lampu Jalan Mati",
    "Lawan Arah",
    "Merokok di Jalan",
    "Tidak Pakai Helm",
    "Lainnya"
  ];
  String? _category;
  String? _latitude;
  String? _longitude;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  bool _isGenerating = false;

  Future<void> pickAndConvertThenCompressImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();

      final compressedImage = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 80,
      );

      setState(() {
        _imageBytes = compressedImage;
        _base64Image = base64Encode(compressedImage);
        _image = _base64Image;
      });
    }
  }

  Future<void> generateDescriptionWithAI() async {
    if (_base64Image == null) return;
    setState(() => _isGenerating = true);
    try {
      const apiKey = "AIzaSyDv5d_EMvEv9HBejeWyuAOiLrJbUWdIf1g";
      const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey';
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": _base64Image,
                }
              },
              {
                "text": "Berdasarkan foto ini, identifikasi utama kerusakan fasilitas umum "
                    "dari daftar berikut: Jalan Rusak, Lampu Jalan Mati, Saluran Air Mampet, Sampah Liar, dan Pagar Rusak dan lainnya. "
                    "Pilih salah satu kategori paling dominan untuk di laporkan. "
                    "Buat deskripsi laporan singkat padat dan jelas untuk laporan perbaikan, dan tambahkan permohonan perbaikan. "
                    "Fokus pada kerusakan fasilitas umum dan hindari spekulasi lain. "
                    "Format output yang diinginkan:\n"
                    "kategori: [Kategori yang dipilih]\n"
                    "deskripsi: [Deskripsi singkat]"
              }
            ]
          }
        ]
      });
      final headers = {'Content-Type': 'application/json'};
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        debugPrint("AI TEXT: $text");
        if (text != null && text.toString().isNotEmpty) {
          final lines = text.toString().trim().split('\n');

          String? aiCategory;
          String? aiDescription;
          for (var line in lines) {
            final lower = line.toLowerCase();
            if (lower.startsWith("kategori: ")) {
              aiCategory = line.substring("kategori: ".length).trim();
            } else if (lower.startsWith("deskripsi: ")) {
              aiDescription = line.substring("deskripsi: ".length).trim();
            }
          }
          aiDescription ??= text.toString().trim();
          
          setState(() {
            if (aiCategory != null && categories.any((cat) => cat.toLowerCase() == aiCategory!.toLowerCase())) {
              _category = categories.firstWhere((cat) => cat.toLowerCase() == aiCategory!.toLowerCase());
            } else {
              _category = "Lainnya";
            }
            _descriptionController.text = aiDescription ?? "";
          });
        }
      } else {
        debugPrint('Error generate AI: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to generate AI: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Layanan Lokasi Tidak Aktif ")));
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Akses Ditolak")));
          }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal mengambil lokasi.")));
      }
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  // ============================================================
  // sendNotificationToTopic - Kirim notifikasi via REST API ke topik
  // ============================================================
  Future<void> sendNotificationToTopic(String body, String senderName) async {
    final url = Uri.parse('https://fasum-cloud-orcin.vercel.app/send-to-topic');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "topic": "berita-fasum",
        "title": "🔔 Laporan Baru",
        "body": body,
        "senderName": senderName,
        "senderPhotoUrl":
            "https://static.vecteezy.com/system/resources/thumbnails/041/642/167/small_2x/ai-generated-portrait-of-handsome-smiling-young-man-with-folded-arms-isolated-free-png.png",
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Notifikasi berhasil dikirim')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal kirim notifikasi: ${response.body}')),
        );
      }
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
        // Kirim notifikasi ke topik setelah post berhasil disimpan
        sendNotificationToTopic(
          _descriptionController.text,
          fullName ?? 'Anonymous',
        );

        setState(() {
          _isSubmitting = false;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Data berhasil ditambahkan"),
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
      appBar: AppBar(title: const Text("Add new post")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                    child: Stack(
                      children: [
                        Image.memory(
                          _imageBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        if (_isGenerating)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 8),
                                    Text(
                                      "Menganalisis gambar...",
                                      style: TextStyle(color: Colors.white),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: (_isSubmitting || _isGenerating) ? null : pickAndConvertThenCompressImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: (_isSubmitting || _isGenerating) ? null : _showCategorySelector,
              child: const Text('Select Category'),
            ),
            const SizedBox(height: 8),
            Text(
              _category ?? 'Belum memilih kategori',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: (_isSubmitting || _isGenerating || _base64Image == null) 
                  ? null 
                  : generateDescriptionWithAI,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Deskripsi dengan AI'),
            ),
            const SizedBox(height: 8),
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
              onPressed: (_isSubmitting || _isGenerating) ? null : _submit,
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
