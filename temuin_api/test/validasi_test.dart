import 'dart:convert';
import 'dart:io';

import 'package:temuin_api/penyimpanan.dart';
import 'package:temuin_api/validasi.dart';
import 'package:test/test.dart';

Map<String, dynamic> dasar([Map<String, dynamic> tambahan = const {}]) => {
  'nama': 'Jaket hoodie',
  'jenis': 'Hilang',
  'kategori': 'Lainnya',
  'lokasi': 'Aula',
  ...tambahan,
};

void main() {
  group('validasi dasar (hands-on)', () {
    test('data lengkap dinyatakan valid', () {
      expect(validasiBarang(dasar()), isEmpty);
    });

    test('data kosong menghasilkan kesalahan per field', () {
      final salah = validasiBarang({'nama': 'a'});
      expect(salah.keys, containsAll(['nama', 'jenis', 'kategori', 'lokasi']));
    });
  });

  group('deskripsi maksimal 200 karakter (tugas P9 no. 1)', () {
    test('tepat 200 karakter masih valid', () {
      expect(validasiBarang(dasar({'deskripsi': 'a' * 200})), isEmpty);
    });

    test('201 karakter ditolak', () {
      final salah = validasiBarang(dasar({'deskripsi': 'a' * 201}));
      expect(salah['deskripsi'], 'Deskripsi maksimal 200 karakter');
    });
  });

  group('kontak (jika diisi) harus diawali 08 (tugas P9 no. 1)', () {
    test('kontak kosong atau tidak dikirim tetap valid', () {
      expect(validasiBarang(dasar()), isEmpty);
      expect(validasiBarang(dasar({'kontak': ''})), isEmpty);
      expect(validasiBarang(dasar({'kontak': null})), isEmpty);
    });

    test('awalan selain 08 ditolak', () {
      expect(
        validasiBarang(dasar({'kontak': '0712345678'}))['kontak'],
        'Nomor HP harus diawali 08',
      );
      expect(
        validasiBarang(dasar({'kontak': '628123456789'}))['kontak'],
        'Nomor HP harus diawali 08',
      );
    });

    test('huruf ditolak', () {
      expect(
        validasiBarang(dasar({'kontak': '08abc45678'}))['kontak'],
        'Nomor HP hanya boleh berisi angka',
      );
    });

    test('panjang di luar 10-13 digit ditolak', () {
      expect(validasiBarang(dasar({'kontak': '08123'})), contains('kontak'));
      expect(validasiBarang(dasar({'kontak': '08123456789012'})), contains('kontak'));
    });

    test('batas 10 dan 13 digit diterima', () {
      expect(validasiBarang(dasar({'kontak': '0812345678'})), isEmpty);
      expect(validasiBarang(dasar({'kontak': '0812345678901'})), isEmpty);
    });

    test('tanda hubung dan spasi diabaikan', () {
      expect(validasiBarang(dasar({'kontak': '0812-3456-7890'})), isEmpty);
      expect(validasiBarang(dasar({'kontak': '0812 3456 7890'})), isEmpty);
    });
  });

  group('Penyimpanan.tambah', () {
    late Directory folder;
    late Penyimpanan db;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('temuin_uji');
      await File('${folder.path}/seed.json').writeAsString(jsonEncode([]));
      db = Penyimpanan(
        lokasiFile: '${folder.path}/barang.json',
        lokasiSeed: '${folder.path}/seed.json',
      );
      await db.muat();
    });

    tearDown(() => folder.delete(recursive: true));

    test('nomor HP disimpan sebagai angka saja dan id dibuat server', () async {
      final item = await db.tambah(dasar({'nama': '  Jaket  ', 'kontak': '0812-3456-7890'}));
      expect(item['id'], 1);
      expect(item['nama'], 'Jaket');
      expect(item['kontak'], '081234567890');
      expect(item['selesai'], false);
    });

    test('tanpa kontak disimpan sebagai string kosong', () async {
      final item = await db.tambah(dasar());
      expect(item['kontak'], '');
    });
  });
}
