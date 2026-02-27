import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/karyawan.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daftar Karyawan',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const DaftarKaryawan(),
    );
  }
}

class DaftarKaryawan extends StatefulWidget {
  const DaftarKaryawan({super.key});

  @override
  State<DaftarKaryawan> createState() => _DaftarKaryawanState();
}

class _DaftarKaryawanState extends State<DaftarKaryawan> {
  List<Karyawan> karyawans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final String response = await rootBundle.loadString('assets/karyawan.json');
    final data = await json.decode(response) as List<dynamic>;
    setState(() {
      karyawans = data.map((e) => Karyawan.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Karyawan'),
        backgroundColor: Colors.lightBlue[300],
      ),
      body: karyawans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: karyawans.length,
              itemBuilder: (context, index) {
                final k = karyawans[index];
                return ListTile(
                  title: Text(
                    k.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Umur: ${k.umur}'),
                      Text('Alamat: ${k.alamat.jalan}, ${k.alamat.kota}, ${k.alamat.provinsi}'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
