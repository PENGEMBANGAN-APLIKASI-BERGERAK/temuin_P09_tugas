import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:temuin/barang_service.dart';
import 'package:temuin/data_dummy.dart';
import 'package:temuin/draf.dart';
import 'package:temuin/main.dart';

/// Membuat layar uji selebar HP (1080 piksel, kepadatan 3x). Tingginya dilebihkan agar
/// seluruh form, termasuk kolom Nomor HP dan tombol di bawahnya, terlihat tanpa menggulir.
void ukuranHp(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Penyimpanan draf di memori (pengganti SQLite saat test).
class DrafMemori implements PenyimpananDraf {
  final Map<int, Draf> isi = {};
  int _idTerakhir = 0;

  @override
  Future<List<Draf>> semua() async => isi.values.toList();

  @override
  Future<int> simpan(Draf draf) async {
    final id = draf.id ?? ++_idTerakhir;
    isi[id] = Draf.fromMap({...draf.toMap(), 'id': id});
    return id;
  }

  @override
  Future<void> hapus(int id) async => isi.remove(id);
}

/// Server palsu yang menyimpan data di memori: mendukung GET dan POST /api/barang.
MockClient buatServerPalsu({
  List<Map<String, dynamic>>? diterima,
  bool tolak = false,
  Map<String, String> detailTolak = const {'nama': 'Nama sudah dipakai laporan lain'},
}) {
  final data = daftarBarangDummy.map((b) => b.toJson()).toList();
  return MockClient((req) async {
    if (req.method == 'POST') {
      final isi = jsonDecode(req.body) as Map<String, dynamic>;
      diterima?.add(isi);
      if (tolak) {
        return http.Response(jsonEncode({'error': 'Data tidak valid', 'detail': detailTolak}), 400);
      }
      final baru = {...isi, 'id': 99, 'tanggal': DateTime(2026, 10, 1).toIso8601String()};
      data.insert(0, baru);
      return http.Response(jsonEncode({'data': baru}), 201);
    }
    return http.Response(jsonEncode({'data': data, 'total': data.length}), 200);
  });
}

final serverMati = MockClient((request) async => throw Exception('connection refused'));

Widget buatApp(http.Client client, {PenyimpananDraf? draf}) => TemuinApp(
  service: BarangService(client: client),
  penyimpananDraf: draf ?? DrafMemori(),
);

/// Isian minimal yang lolos validasi di HP (saklar nomor HP aktif secara bawaan).
Future<void> isiFormValid(WidgetTester tester, {String nama = 'Payung biru'}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Nama barang *'), nama);
  await tester.enterText(find.widgetWithText(TextFormField, 'Lokasi *'), 'Gedung Kuliah Umum');
  await tester.enterText(find.widgetWithText(TextFormField, 'Nomor HP *'), '081234567890');
}

Draf drafContoh(String nama, {String kontak = ''}) => Draf(
  nama: nama,
  jenis: 'Hilang',
  kategori: 'Lainnya',
  lokasi: 'Gedung Kuliah Umum',
  deskripsi: '',
  kontak: kontak,
  dibuat: DateTime(2026, 10, 2),
);

Future<void> bukaFormLapor(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lapor'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Daftar diambil dari server lalu ditampilkan', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(buatApp(buatServerPalsu()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('8 laporan'), findsOneWidget);
  });

  testWidgets('Pesan error muncul jika server mati', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(buatApp(serverMati));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('Form kosong ditolak validasi tanpa mengirim ke server', (tester) async {
    ukuranHp(tester);
    final diterima = <Map<String, dynamic>>[];
    await tester.pumpWidget(buatApp(buatServerPalsu(diterima: diterima)));
    await bukaFormLapor(tester);

    await tester.tap(find.text('Kirim Laporan'));
    await tester.pump();

    expect(find.text('Nama barang wajib diisi'), findsOneWidget);
    expect(find.text('Lokasi wajib diisi'), findsOneWidget);
    expect(find.text('Nomor HP wajib diisi'), findsOneWidget);
    expect(diterima, isEmpty);
  });

  testWidgets('Laporan valid dikirim (POST) lalu muncul di daftar', (tester) async {
    ukuranHp(tester);
    final diterima = <Map<String, dynamic>>[];
    await tester.pumpWidget(buatApp(buatServerPalsu(diterima: diterima)));
    await bukaFormLapor(tester);

    await isiFormValid(tester);
    await tester.tap(find.text('Kirim Laporan'));
    await tester.pumpAndSettle();

    expect(diterima.single['nama'], 'Payung biru');
    expect(diterima.single['jenis'], 'Hilang');
    expect(diterima.single['kontak'], '081234567890');
    expect(find.text('9 laporan'), findsOneWidget);
    expect(find.text('Payung biru'), findsOneWidget);
  });

  testWidgets('Pesan validasi dari server tampil di bawah field', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(buatApp(buatServerPalsu(tolak: true)));
    await bukaFormLapor(tester);

    await isiFormValid(tester);
    await tester.tap(find.text('Kirim Laporan'));
    await tester.pumpAndSettle();

    expect(find.text('Nama sudah dipakai laporan lain'), findsOneWidget);
    expect(find.text('Lapor Barang'), findsOneWidget); // form tetap terbuka
  });

  testWidgets('Pesan server hilang setelah field diperbaiki', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(buatApp(buatServerPalsu(tolak: true)));
    await bukaFormLapor(tester);

    await isiFormValid(tester);
    await tester.tap(find.text('Kirim Laporan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama sudah dipakai laporan lain'), findsOneWidget);

    // nama diganti, lalu form divalidasi ulang: pesan lama tidak boleh menempel
    await tester.enterText(find.widgetWithText(TextFormField, 'Nama barang *'), 'Payung hijau');
    tester.state<FormState>(find.byType(Form)).validate();
    await tester.pump();
    expect(find.text('Nama sudah dipakai laporan lain'), findsNothing);
  });

  testWidgets('Error 400 untuk nomor HP tampil di bawah kolom Nomor HP', (tester) async {
    ukuranHp(tester);
    final server = buatServerPalsu(tolak: true, detailTolak: {'kontak': 'Nomor HP tidak valid'});
    await tester.pumpWidget(buatApp(server));
    await bukaFormLapor(tester);

    await isiFormValid(tester);
    await tester.tap(find.text('Kirim Laporan'));
    await tester.pumpAndSettle();

    expect(find.text('Nomor HP tidak valid'), findsOneWidget);
  });

  testWidgets('Kolom Nomor HP hanya muncul saat saklar aktif', (tester) async {
    ukuranHp(tester);
    final diterima = <Map<String, dynamic>>[];
    await tester.pumpWidget(buatApp(buatServerPalsu(diterima: diterima)));
    await bukaFormLapor(tester);

    expect(find.widgetWithText(TextFormField, 'Nomor HP *'), findsOneWidget);

    await tester.tap(find.text('Tampilkan nomor HP saya'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Nomor HP *'), findsNothing);

    // saklar mati: laporan tetap bisa dikirim, kontak dikirim kosong
    await tester.enterText(find.widgetWithText(TextFormField, 'Nama barang *'), 'Payung biru');
    await tester.enterText(find.widgetWithText(TextFormField, 'Lokasi *'), 'Gedung Kuliah Umum');
    await tester.tap(find.text('Kirim Laporan'));
    await tester.pumpAndSettle();
    expect(diterima.single['kontak'], '');
  });

  testWidgets('Validator Nomor HP: diawali 08 dan 10-13 digit', (tester) async {
    ukuranHp(tester);
    final diterima = <Map<String, dynamic>>[];
    await tester.pumpWidget(buatApp(buatServerPalsu(diterima: diterima)));
    await bukaFormLapor(tester);
    final kolomHp = find.widgetWithText(TextFormField, 'Nomor HP *');

    await tester.enterText(kolomHp, '0712345678');
    await tester.tap(find.text('Kirim Laporan'));
    await tester.pump();
    expect(find.text('Nomor HP harus diawali 08'), findsOneWidget);

    await tester.enterText(kolomHp, '08123');
    await tester.tap(find.text('Kirim Laporan'));
    await tester.pump();
    expect(find.text('Nomor HP harus 10-13 digit'), findsOneWidget);

    expect(diterima, isEmpty); // semua ditolak di HP, tidak ada yang sampai ke server
  });

  testWidgets('Kolom Nomor HP otomatis membuang selain angka', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(buatApp(buatServerPalsu()));
    await bukaFormLapor(tester);
    final kolomHp = find.widgetWithText(TextFormField, 'Nomor HP *');

    await tester.enterText(kolomHp, '0812-34ab56');
    expect(tester.widget<TextFormField>(kolomHp).controller!.text, '08123456');
  });

  testWidgets('Simpan draf menyimpan isian ke penyimpanan lokal', (tester) async {
    ukuranHp(tester);
    final draf = DrafMemori();
    await tester.pumpWidget(buatApp(buatServerPalsu(), draf: draf));
    await bukaFormLapor(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nama barang *'), 'Jaket hitam');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nomor HP *'), '081234567890');
    await tester.tap(find.text('Simpan sebagai draf'));
    await tester.pumpAndSettle();

    expect(draf.isi.values.single.nama, 'Jaket hitam');
    expect(draf.isi.values.single.kontak, '081234567890');
    expect(find.text('Draf disimpan di HP'), findsOneWidget);
  });

  testWidgets('Badge pada ikon draf menunjukkan jumlah draf', (tester) async {
    ukuranHp(tester);
    final draf = DrafMemori();
    await draf.simpan(drafContoh('Kacamata minus'));
    await draf.simpan(drafContoh('Jaket hitam'));
    await tester.pumpWidget(buatApp(buatServerPalsu(), draf: draf));
    await bukaFormLapor(tester);

    expect(find.descendant(of: find.byType(Badge), matching: find.text('2')), findsOneWidget);
  });

  testWidgets('Badge draf bertambah setelah menyimpan draf baru', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(buatApp(buatServerPalsu(), draf: DrafMemori()));
    await bukaFormLapor(tester);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('0')), findsNothing);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nama barang *'), 'Jaket hitam');
    await tester.tap(find.text('Simpan sebagai draf'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);
  });

  testWidgets('Draf dipilih, nomor HP ikut terisi, lalu dikirim dan draf terhapus', (tester) async {
    ukuranHp(tester);
    final draf = DrafMemori();
    await draf.simpan(drafContoh('Kacamata minus', kontak: '081234567890'));
    final diterima = <Map<String, dynamic>>[];
    await tester.pumpWidget(buatApp(buatServerPalsu(diterima: diterima), draf: draf));
    await bukaFormLapor(tester);

    await tester.tap(find.byIcon(Icons.drafts_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kacamata minus'));
    await tester.pumpAndSettle();
    expect(find.text('081234567890'), findsOneWidget);

    await tester.tap(find.text('Kirim Laporan'));
    await tester.pumpAndSettle();

    expect(diterima.single['nama'], 'Kacamata minus');
    expect(diterima.single['kontak'], '081234567890');
    expect(draf.isi, isEmpty);
  });

  testWidgets('Kembali dari form kosong langsung keluar tanpa bertanya', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(buatApp(buatServerPalsu()));
    await bukaFormLapor(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Simpan isian sebagai draf?'), findsNothing);
    expect(find.text('Lapor Barang'), findsNothing);
  });

  testWidgets('Kembali saat ada isian menawarkan simpan draf', (tester) async {
    ukuranHp(tester);
    final draf = DrafMemori();
    await tester.pumpWidget(buatApp(buatServerPalsu(), draf: draf));
    await bukaFormLapor(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nama barang *'), 'Jaket hitam');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Simpan isian sebagai draf?'), findsOneWidget);

    await tester.tap(find.text('Simpan draf'));
    await tester.pumpAndSettle();

    expect(draf.isi.values.single.nama, 'Jaket hitam');
    expect(find.text('Lapor Barang'), findsNothing); // form tertutup
  });

  testWidgets('Pilihan Buang menutup form tanpa menyimpan, Lanjut mengisi tetap di form', (
    tester,
  ) async {
    ukuranHp(tester);
    final draf = DrafMemori();
    await tester.pumpWidget(buatApp(buatServerPalsu(), draf: draf));
    await bukaFormLapor(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nama barang *'), 'Jaket hitam');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut mengisi'));
    await tester.pumpAndSettle();
    expect(find.text('Lapor Barang'), findsOneWidget); // masih di form

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();

    expect(find.text('Lapor Barang'), findsNothing);
    expect(draf.isi, isEmpty);
  });
}
