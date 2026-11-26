import 'dart:convert';

import 'package:http/http.dart' as http;

import 'barang.dart';

/// Alamat server. Bisa diganti saat run:
/// flutter run --dart-define=API_URL=http://192.168.1.10:8080
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:8080');

class ApiException implements Exception {
  ApiException(this.pesan, {this.detail = const {}});
  final String pesan;

  /// Kesalahan per field dari server, misalnya {'nama': 'minimal 3 karakter'}.
  final Map<String, dynamic> detail;

  @override
  String toString() => pesan;
}

class BarangService {
  BarangService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Barang>> ambilSemua() async {
    final http.Response res;
    try {
      res = await _client.get(Uri.parse('$apiUrl/api/barang')).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw ApiException('Tidak bisa terhubung ke server ($apiUrl). Pastikan server menyala.');
    }

    if (res.statusCode != 200) {
      throw ApiException('Server membalas kode ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data.map((e) => Barang.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Mengirim laporan baru. Server menentukan id & tanggal, lalu mengembalikan data lengkap.
  Future<Barang> kirim(Barang barang) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$apiUrl/api/barang'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(barang.toJson()),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw ApiException('Tidak bisa terhubung ke server ($apiUrl). Laporan belum terkirim.');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(
        body['error'] as String? ?? 'Gagal mengirim (kode ${res.statusCode})',
        detail: body['detail'] as Map<String, dynamic>? ?? {},
      );
    }
    return Barang.fromJson(body['data'] as Map<String, dynamic>);
  }
}
