import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/models/note.dart';
import 'package:notes/services/note_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDialog extends StatefulWidget {
  final Note? note;
  const NoteDialog({super.key, this.note});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _base64Image;
  Uint8List? _imageBytes;
  bool _isEdit = false;
  final ImagePicker _picker = ImagePicker();
  String? _latitude;
  String? _longitude;

  @override
  void initState() {
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
      if (widget.note?.imageBase64 != null) {
        _imageBytes = base64Decode(widget.note!.imageBase64!);
      }
      _isEdit = true;
      _base64Image = widget.note!.imageBase64;
      _latitude = widget.note!.latitude;
      _longitude = widget.note!.longitude;
    }
    super.initState();
  }

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
        _base64Image = encodedResult;
        _imageBytes = result;
      });
    }
  }

  Future<void> getLocation() async {
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
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
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

  Future<void> openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
    );

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuka maps")));
    }
  }

  Future<void> submit() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Semua field harus diisi"),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final Note note = Note(
      id: widget.note?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      imageBase64: _base64Image,
      latitude: _latitude,
      longitude: _longitude,
    );

    _isEdit
        ? await NoteService.updateNote(note)
        : await NoteService.addNote(note);

    _titleController.clear();
    _descriptionController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? "Data berhasil diupdate" : "Data berhasil ditambahkan",
          ),
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Add Notes' : 'Update Notes'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Title"),
          TextFormField(controller: _titleController),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text("Description"),
          ),
          TextFormField(controller: _descriptionController, maxLines: null),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text("Image: "),
          ),
          Expanded(
            child: _imageBytes != null
                ? Image.memory(_imageBytes!, fit: BoxFit.cover, height: 150)
                : Center(child: Text("No image selected")),
          ),
          ElevatedButton(
            onPressed: pickAndConvertThenCompressImage,
            child: Text("Pick Image"),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              getLocation();
            },
            child: Text("Get Current Location"),
          ),
          if (_latitude != null && _longitude != null)
            Text('Location: ($_latitude, $_longitude)'),

          if (_latitude != null && _longitude != null)
            TextButton(onPressed: openMap, child: const Text('Open in Maps')),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              submit();
            },
            child: Text(_isEdit ? "Update" : "Simpan"),
          ),
        ],
      ),
    );
  }
}
