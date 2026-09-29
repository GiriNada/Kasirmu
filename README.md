# Kasirmu 

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

<img width="720" height="1540" alt="kelola menu" src="https://github.com/user-attachments/assets/47165176-204a-4ece-a24c-ae06653592de" />
<img width="720" height="1532" alt="laporan penjualan" src="https://github.com/user-attachments/assets/606c89ab-1f1c-49cd-8d22-ca9635644b22" />
<img width="720" height="1536" alt="menu 2" src="https://github.com/user-attachments/assets/6a76923b-5f5d-4177-9c4d-ab5a1b37fb03" />
<img width="720" height="1538" alt="menu" src="https://github.com/user-attachments/assets/db8a41b0-e0b3-4b46-bf22-628642090d6d" />
<img width="720" height="1528" alt="pembayaran 2" src="https://github.com/user-attachments/assets/6680093e-a78f-44b1-b2c9-202b398173e4" />
<img width="720" height="1529" alt="pembayaran" src="https://github.com/user-attachments/assets/3944d5c0-d22c-45e9-bcd2-19663e6723f0" />
<img width="720" height="1533" alt="pengaturan struke 2" src="https://github.com/user-attachments/assets/24cadc08-f53a-457d-a959-889f49e547ce" />
<img width="720" height="1532" alt="pengaturan struke" src="https://github.com/user-attachments/assets/a7789975-5399-4de8-b53f-1b896ab24c75" />
<img width="720" height="1535" alt="pengaturan" src="https://github.com/user-attachments/assets/8705afcc-3e06-43a2-988d-cf602c2a661f" />
<img width="720" height="1534" alt="pilih printer" src="https://github.com/user-attachments/assets/74368f95-5440-4d61-b8d4-c42baf1fc553" />
<img width="720" height="1528" alt="previiew dan cetak struk" src="https://github.com/user-attachments/assets/b0b1dee0-b02c-4f8d-864d-0a113ee44f87" />
<img width="720" height="1528" alt="profil toko" src="https://github.com/user-attachments/assets/2a358140-e6b1-4a50-966d-99b28f6fabff" />
<img width="1080" height="2400" alt="tambah menu" src="https://github.com/user-attachments/assets/06130685-5687-4ec7-b52c-2b4f9a4425c6" />
<img width="720" height="1528" alt="tentang aplikasi" src="https://github.com/user-attachments/assets/2279114f-9a22-4d5c-90cc-2b7decaed1d4" />
<img width="720" height="1530" alt="WhatsApp Image 2026-04-22 at 11 11 14" src="https://github.com/user-attachments/assets/a1edb311-bb4a-4cc2-a72e-576f438c382c" />
<img width="720" height="1532" alt="WhatsApp Image 2026-04-24 at 09 39 11" src="https://github.com/user-attachments/assets/2181debd-bd38-432b-8281-f529e5f91dbb" />

## Pengembangan Selanjutnya

- Sinkronisasi data ke cloud untuk multi-perangkat
- Manajemen stok bahan baku
- Login multi-user (kasir & pemilik)

## Kontak

**Giri Nada Wardana**
Teknik Informatika, Universitas Surakarta — 2026
📧 girinada79@gmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/giri-nada-wardana-2020a6310)
