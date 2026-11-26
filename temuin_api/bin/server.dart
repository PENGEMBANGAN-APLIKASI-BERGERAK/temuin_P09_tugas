import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:temuin_api/penyimpanan.dart';
import 'package:temuin_api/validasi.dart';

final db = Penyimpanan();

/// Membuat respons JSON dengan kode status tertentu.
Response json(Object? isi, {int status = 200}) => Response(
  status,
  body: jsonEncode(isi),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Router buatRouter() {
  final app = Router();

  app.get('/', (Request req) => json({'pesan': 'Temuin API berjalan', 'versi': 'P09'}));

  // GET /api/barang -> daftar semua laporan
  app.get('/api/barang', (Request req) {
    final daftar = db.semua();
    return json({'data': daftar, 'total': daftar.length});
  });

  // GET /api/barang/<id> -> satu laporan
  app.get('/api/barang/<id|[0-9]+>', (Request req, String id) {
    final item = db.cari(int.parse(id));
    if (item == null) {
      return json({'error': 'Barang dengan id $id tidak ditemukan'}, status: 404);
    }
    return json({'data': item});
  });

  // POST /api/barang -> tambah laporan baru
  app.post('/api/barang', (Request req) async {
    final Map<String, dynamic> isi;
    try {
      isi = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return json({'error': 'Body harus berupa JSON object'}, status: 400);
    }

    final salah = validasiBarang(isi);
    if (salah.isNotEmpty) {
      return json({'error': 'Data tidak valid', 'detail': salah}, status: 400);
    }
    final item = await db.tambah(isi);
    return json({'data': item}, status: 201);
  });

  return app;
}

/// Middleware: izinkan akses dari browser (Flutter web) dan tunda respons jika --lambat.
Middleware tambahanHeader({required bool lambat}) {
  return (Handler inner) {
    return (Request req) async {
      if (req.method == 'OPTIONS') return Response.ok('', headers: _cors);
      if (lambat) await Future.delayed(const Duration(milliseconds: 1500));
      final res = await inner(req);
      return res.change(headers: _cors);
    };
  };
}

const _cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers': 'content-type, authorization',
};

Future<void> main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final lambat = args.contains('--lambat');
  await db.muat();

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(tambahanHeader(lambat: lambat))
      .addHandler(buatRouter().call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Temuin API siap di port ${server.port}${lambat ? ' (mode lambat)' : ''}');
  print('  Laptop/emulator/HP via adb reverse : http://127.0.0.1:${server.port}');
  for (final ni in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    for (final addr in ni.addresses) {
      print(
        '  HP lewat Wi-Fi yang sama (${ni.name.padRight(5)})  : http://${addr.address}:${server.port}',
      );
    }
  }
}
