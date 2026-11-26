import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Laporan yang belum dikirim, disimpan di HP.
class Draf {
  const Draf({
    this.id,
    required this.nama,
    required this.jenis,
    required this.kategori,
    required this.lokasi,
    required this.deskripsi,
    required this.dibuat,
    this.kontak = '',
  });

  final int? id; // null = belum pernah disimpan
  final String nama;
  final String jenis;
  final String kategori;
  final String lokasi;
  final String deskripsi;
  final DateTime dibuat;
  final String kontak; // nomor HP (angka saja), kosong jika tidak ditampilkan

  Map<String, Object?> toMap() => {
    'id': id,
    'nama': nama,
    'jenis': jenis,
    'kategori': kategori,
    'lokasi': lokasi,
    'deskripsi': deskripsi,
    'dibuat': dibuat.millisecondsSinceEpoch,
    'kontak': kontak,
  };

  factory Draf.fromMap(Map<String, Object?> map) => Draf(
    id: map['id'] as int,
    nama: map['nama'] as String,
    jenis: map['jenis'] as String,
    kategori: map['kategori'] as String,
    lokasi: map['lokasi'] as String,
    deskripsi: map['deskripsi'] as String,
    dibuat: DateTime.fromMillisecondsSinceEpoch(map['dibuat'] as int),
    kontak: map['kontak'] as String? ?? '',
  );
}

/// Kontrak penyimpanan draf. Aplikasi memakai SQLite, test memakai versi memori.
abstract class PenyimpananDraf {
  Future<List<Draf>> semua();
  Future<int> simpan(Draf draf);
  Future<void> hapus(int id);
}

class DrafSqlite implements PenyimpananDraf {
  Database? _db;

  Future<Database> get _database async {
    return _db ??= await openDatabase(
      join(await getDatabasesPath(), 'temuin.db'),
      version: 2,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE draf(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            jenis TEXT NOT NULL,
            kategori TEXT NOT NULL,
            lokasi TEXT NOT NULL,
            deskripsi TEXT NOT NULL,
            dibuat INTEGER NOT NULL,
            kontak TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
      // v1 -> v2: kolom kontak ditambahkan. Draf lama di HP tetap aman (kontak = '').
      onUpgrade: (db, versiLama, versiBaru) async {
        if (versiLama < 2) {
          await db.execute("ALTER TABLE draf ADD COLUMN kontak TEXT NOT NULL DEFAULT ''");
        }
      },
    );
  }

  @override
  Future<List<Draf>> semua() async {
    final db = await _database;
    final rows = await db.query('draf', orderBy: 'dibuat DESC');
    return rows.map(Draf.fromMap).toList();
  }

  @override
  Future<int> simpan(Draf draf) async {
    final db = await _database;
    if (draf.id == null) {
      final data = draf.toMap()..remove('id');
      return db.insert('draf', data);
    }
    await db.update('draf', draf.toMap(), where: 'id = ?', whereArgs: [draf.id]);
    return draf.id!;
  }

  @override
  Future<void> hapus(int id) async {
    final db = await _database;
    await db.delete('draf', where: 'id = ?', whereArgs: [id]);
  }
}
