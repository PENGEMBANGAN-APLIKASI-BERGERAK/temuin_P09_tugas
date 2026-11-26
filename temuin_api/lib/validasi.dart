/// Aturan validasi laporan barang. Dipisah dari server.dart agar mudah diuji
/// tanpa menjalankan server.
library;

const jenisValid = ['Hilang', 'Ditemukan'];

/// Batas panjang deskripsi (karakter).
const maksDeskripsi = 200;

final _hanyaAngka = RegExp(r'^\d+$');

/// Membersihkan nomor HP dari spasi, tanda hubung, dan titik.
/// "0812-3456-7890" -> "081234567890". Nilai null menjadi string kosong.
String bersihkanKontak(Object? mentah) =>
    (mentah ?? '').toString().replaceAll(RegExp(r'[\s\-.]'), '');

/// Mengembalikan daftar kesalahan per field. Kosong berarti valid.
Map<String, String> validasiBarang(Map<String, dynamic> isi) {
  final salah = <String, String>{};
  String teks(String field) => (isi[field] ?? '').toString().trim();

  if (teks('nama').length < 3) salah['nama'] = 'Nama barang minimal 3 karakter';
  if (!jenisValid.contains(isi['jenis'])) salah['jenis'] = 'Jenis harus Hilang atau Ditemukan';
  if (teks('kategori').isEmpty) salah['kategori'] = 'Kategori wajib diisi';
  if (teks('lokasi').isEmpty) salah['lokasi'] = 'Lokasi wajib diisi';

  // Tugas P9 no. 1: deskripsi maksimal 200 karakter.
  if (teks('deskripsi').runes.length > maksDeskripsi) {
    salah['deskripsi'] = 'Deskripsi maksimal $maksDeskripsi karakter';
  }

  // Tugas P9 no. 1: kontak (jika diisi) harus diawali 08.
  // Inovasi: panjangnya juga dicek (10-13 digit) agar sejalan dengan validator di aplikasi.
  final kontak = bersihkanKontak(isi['kontak']);
  if (kontak.isNotEmpty) {
    if (!_hanyaAngka.hasMatch(kontak)) {
      salah['kontak'] = 'Nomor HP hanya boleh berisi angka';
    } else if (!kontak.startsWith('08')) {
      salah['kontak'] = 'Nomor HP harus diawali 08';
    } else if (kontak.length < 10 || kontak.length > 13) {
      salah['kontak'] = 'Nomor HP harus 10-13 digit';
    }
  }
  return salah;
}
