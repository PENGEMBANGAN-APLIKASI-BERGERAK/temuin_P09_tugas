#!/usr/bin/env bash
# Uji endpoint POST /api/barang (Tugas P9 no. 1).
# Jalankan server di terminal lain:  dart run bin/server.dart
# Lalu:  bash uji_curl.sh
# Perhatikan log server: POST [400] untuk kasus 1-4 dan POST [201] untuk kasus 5-6.

URL="${1:-http://127.0.0.1:8080}/api/barang"
DASAR='"nama":"Jaket hoodie","jenis":"Hilang","kategori":"Lainnya","lokasi":"Aula"'

kirim() {
  echo
  echo "=== $1"
  curl -s -w '\n-> HTTP %{http_code}\n' -X POST "$URL" \
    -H 'content-type: application/json' -d "{$DASAR$2}"
}

DESKRIPSI_201=$(printf 'a%.0s' $(seq 1 201))
DESKRIPSI_200=$(printf 'a%.0s' $(seq 1 200))

kirim "1. Deskripsi 201 karakter -> 400"        ",\"deskripsi\":\"$DESKRIPSI_201\""
kirim "2. Kontak 0712345678 (bukan 08) -> 400"  ',"kontak":"0712345678"'
kirim "3. Kontak 08123 (terlalu pendek) -> 400" ',"kontak":"08123"'
kirim "4. Kontak berisi huruf -> 400"           ',"kontak":"08abc45678"'
kirim "5. Deskripsi 200 karakter + kontak valid -> 201" \
      ",\"deskripsi\":\"$DESKRIPSI_200\",\"kontak\":\"0812-3456-7890\""
kirim "6. Tanpa kontak -> 201" ''
echo
