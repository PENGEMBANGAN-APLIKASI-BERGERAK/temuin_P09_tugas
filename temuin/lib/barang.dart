class Barang {
  const Barang({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.kategori,
    required this.lokasi,
    required this.tanggal,
    this.deskripsi = '',
    this.pelapor = 'Anonim',
    this.kontak = '',
    this.selesai = false,
  });

  final int id;
  final String nama;
  final String jenis; // 'Hilang' atau 'Ditemukan'
  final String kategori;
  final String lokasi;
  final DateTime tanggal;
  final String deskripsi;
  final String pelapor;
  final String kontak;
  final bool selesai; // true jika barang sudah kembali ke pemiliknya

  /// Membuat objek Barang dari JSON yang dikirim server.
  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'] as int,
      nama: json['nama'] as String,
      jenis: json['jenis'] as String,
      kategori: json['kategori'] as String,
      lokasi: json['lokasi'] as String,
      tanggal: DateTime.parse(json['tanggal'] as String),
      deskripsi: json['deskripsi'] as String? ?? '',
      pelapor: json['pelapor'] as String? ?? 'Anonim',
      kontak: json['kontak'] as String? ?? '',
      selesai: json['selesai'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'jenis': jenis,
    'kategori': kategori,
    'lokasi': lokasi,
    'tanggal': tanggal.toIso8601String(),
    'deskripsi': deskripsi,
    'pelapor': pelapor,
    'kontak': kontak,
    'selesai': selesai,
  };
}
