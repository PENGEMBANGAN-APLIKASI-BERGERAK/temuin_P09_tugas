import 'dart:convert';
import 'dart:io';

import 'package:temuin_api/validasi.dart';

/// Menyimpan data laporan barang di file JSON (data/barang.json).
/// Saat pertama dijalankan, isi awal disalin dari data/seed.json.
class Penyimpanan {
  Penyimpanan({this.lokasiFile = 'data/barang.json', this.lokasiSeed = 'data/seed.json'});

  final String lokasiFile;
  final String lokasiSeed;
  final List<Map<String, dynamic>> _data = [];

  Future<void> muat() async {
    final file = File(lokasiFile);
    final sumber = await file.exists() ? file : File(lokasiSeed);
    final isi = jsonDecode(await sumber.readAsString()) as List;
    _data
      ..clear()
      ..addAll(isi.cast<Map<String, dynamic>>());
    if (!await file.exists()) await simpan();
  }

  Future<void> simpan() async {
    const encoder = JsonEncoder.withIndent('  ');
    await File(lokasiFile).writeAsString(encoder.convert(_data));
  }

  /// Semua laporan, terbaru lebih dulu.
  List<Map<String, dynamic>> semua() {
    final hasil = [..._data];
    hasil.sort((a, b) => (b['tanggal'] as String).compareTo(a['tanggal'] as String));
    return hasil;
  }

  Map<String, dynamic>? cari(int id) {
    for (final item in _data) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  /// Menambah laporan baru. id dan tanggal ditentukan server.
  Future<Map<String, dynamic>> tambah(Map<String, dynamic> isi) async {
    final idBaru =
        _data.fold<int>(0, (maks, e) => (e['id'] as int) > maks ? e['id'] as int : maks) + 1;
    final item = {
      'id': idBaru,
      'nama': isi['nama'].toString().trim(),
      'jenis': isi['jenis'],
      'kategori': isi['kategori'],
      'lokasi': isi['lokasi'].toString().trim(),
      'tanggal': DateTime.now().toIso8601String(),
      'deskripsi': (isi['deskripsi'] ?? '').toString().trim(),
      'pelapor': isi['pelapor'] ?? 'Anonim',
      // nomor HP disimpan dalam bentuk angka saja: "0812-3456-7890" -> "081234567890"
      'kontak': bersihkanKontak(isi['kontak']),
      'selesai': false,
    };
    _data.add(item);
    await simpan();
    return item;
  }
}
