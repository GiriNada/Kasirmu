# Kasirmu 🧾

Aplikasi kasir Android untuk usaha kuliner kecil, dibangun untuk **Warung Ndeso Monggot, Grobogan** guna menggantikan pencatatan transaksi manual di buku tulis.

Dikembangkan sebagai proyek skripsi:
**Perancangan dan Implementasi Sistem Informasi Kasir Berbasis Android Menggunakan Flutter Framework Pada Warung Ndeso Monggot Grobogan**
Giri Nada Wardana — Teknik Informatika, Universitas Surakarta (2026)

---

## Latar Belakang

Sebelum ada Kasirmu, transaksi di warung dicatat manual, yang menimbulkan beberapa masalah:
- Risiko salah hitung total belanja dan kembalian
- Rekap laporan penjualan harian lambat
- Data transaksi rawan rusak atau hilang
- Tidak ada bukti transaksi (struk) untuk pelanggan

Kasirmu dibuat untuk menjawab masalah-masalah itu lewat aplikasi kasir digital yang bisa berjalan offline.

## Fitur Utama

- **Pengelolaan menu** — tambah, edit, hapus menu makanan/minuman lengkap dengan foto dan harga
- **Transaksi** — pilih menu ke keranjang dengan kalkulasi total otomatis
- **Pembayaran & kembalian** — mendukung tunai dan transfer, dengan tombol nominal cepat dan perhitungan kembalian otomatis
- **Cetak & bagikan struk** — cetak langsung ke printer thermal Bluetooth (ESC/POS) atau bagikan sebagai gambar PNG
- **Laporan penjualan** — rekap harian, mingguan, bulanan, daftar menu terlaris/tidak laku, dan ekspor laporan ke Excel (XLSX)

## Teknologi

| Bagian | Teknologi |
|---|---|
| Framework | Flutter (Dart) |
| Database | SQLite (lokal, offline) |
| Cetak struk | Printer thermal Bluetooth (ESC/POS) |
| Ekspor laporan | XLSX / CSV |

## Hasil Pengujian

- **Black box testing** — 28 skenario fungsionalitas, seluruhnya valid
- **White box testing** — 8 fungsi logika inti (query database, kalkulasi pembayaran), seluruh jalur logika benar
- **Evaluasi pengguna** — tanggapan sangat baik dari pemilik Warung Ndeso; sistem dinilai mempercepat transaksi dan menghasilkan laporan yang akurat

## Cara Menjalankan

```bash
# Clone repository
git clone https://github.com/GiriNada/Kasirmu.git
cd Kasirmu

# Ambil dependencies
flutter pub get

# Jalankan di device/emulator
flutter run
```

**Kebutuhan:**
- Flutter SDK (versi stabil terbaru)
- Android Studio / VS Code dengan Flutter & Dart plugin
- Emulator Android atau perangkat fisik

## Struktur Proyek

```
lib/
├── main.dart
├── models/        # Model data (menu, transaksi, dll)
├── screens/       # Halaman UI
├── services/      # Logika database & printer
└── widgets/       # Komponen UI yang bisa dipakai ulang
```

## Screenshot

> Tambahkan screenshot aplikasi di sini, misalnya:
> `![Tampilan menu](assets/screenshots/menu.png)`

## Pengembangan Selanjutnya

- Sinkronisasi data ke cloud untuk multi-perangkat
- Manajemen stok bahan baku
- Login multi-user (kasir & pemilik)

## Kontak

**Giri Nada Wardana**
Teknik Informatika, Universitas Surakarta — 2026
📧 tambahkan-email-kamu@example.com
🔗 [LinkedIn](https://linkedin.com/in/username-kamu)
