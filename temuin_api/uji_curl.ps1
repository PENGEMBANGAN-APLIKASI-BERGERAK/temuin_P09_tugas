# Uji endpoint POST /api/barang di Windows PowerShell (Tugas P9 no. 1).
# Jalankan server di terminal lain:  dart run bin/server.dart
# Lalu:  .\uji_curl.ps1
param([string]$Server = "http://127.0.0.1:8080")
$url = "$Server/api/barang"

function Kirim([string]$judul, [hashtable]$tambahan = @{}) {
    $isi = @{ nama = "Jaket hoodie"; jenis = "Hilang"; kategori = "Lainnya"; lokasi = "Aula" }
    foreach ($k in $tambahan.Keys) { $isi[$k] = $tambahan[$k] }
    $berkas = New-TemporaryFile
    Set-Content -Path $berkas -Value ($isi | ConvertTo-Json -Compress) -Encoding utf8
    Write-Host "`n=== $judul"
    curl.exe -s -w "`n-> HTTP %{http_code}`n" -X POST $url -H "content-type: application/json" --data-binary "@$berkas"
    Remove-Item $berkas
}

Kirim "1. Deskripsi 201 karakter -> 400" @{ deskripsi = ("a" * 201) }
Kirim "2. Kontak 0712345678 (bukan 08) -> 400" @{ kontak = "0712345678" }
Kirim "3. Kontak 08123 (terlalu pendek) -> 400" @{ kontak = "08123" }
Kirim "4. Kontak berisi huruf -> 400" @{ kontak = "08abc45678" }
Kirim "5. Deskripsi 200 karakter + kontak valid -> 201" @{ deskripsi = ("a" * 200); kontak = "0812-3456-7890" }
Kirim "6. Tanpa kontak -> 201"
