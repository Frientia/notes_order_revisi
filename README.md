<div align="center">
  <img width="500" height="500" alt="icon_app" src="https://github.com/user-attachments/assets/0218e4f4-4943-4a5c-8f6f-4004c83deaaf" />
</div>

<h1 align="center">Notes Order</h1>

<p align="center">
  Sistem Pencatatan Pembelian Barang Operasional Berbasis Mobile<br/>
  <sub>Studi Kasus: PT Lahir Barutama</sub>
</p>

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-Academic-lightgrey)

</div>

<div align="center">
Institut Teknologi dan Bisnis Bina Sarana Global<br/>
Fakultas Teknologi Informasi & Komunikasi<br/>
https://global.ac.id/
</div>

---

## Project Information

| Keterangan | Detail |
|---|---|
| Nama Proyek | Notes Order |
| Pengembang | Muhamad Yajid Rizky & Agra Alfian Hafiz |
| Program Studi | Teknik Informatika, Kelas TI-SE 23 SH |
| Studi Kasus | PT Lahir Barutama |

## Deskripsi

Notes Order adalah aplikasi mobile yang dikembangkan untuk mendigitalisasi dan menormalisasi proses pencatatan pembelian barang operasional bengkel di PT Lahir Barutama, sebuah perusahaan transportasi dengan puluhan armada truk bermuatan besar. Sebelumnya, pencatatan pembelian barang operasional (di luar sparepart utama) masih dilakukan secara manual menggunakan buku besar, sehingga rentan terhadap kehilangan data, human error, dan keterlambatan informasi bagi pihak manajemen.

Aplikasi ini menggantikan proses tersebut dengan ekosistem digital terpadu yang mencakup manajemen master data (armada, toko, dan barang), pencatatan transaksi pembelian di lapangan, manajemen status pembayaran (lunas/hutang), notifikasi eksekutif secara real-time, hingga pusat pelaporan dan ekspor data untuk kebutuhan audit keuangan.

## Fitur Utama

### Manajemen Master Data
- Master Armada (Mobil) : data plat nomor, tahun, dan kategori kendaraan.
- Master Toko : direktori supplier atau tempat pembelian barang.
- Master Kategori : kategori barang dan kategori mobil untuk mempermudah penyaringan data.
- Master Barang dengan logika kecocokan mobil (relasi many-to-many), yang membedakan barang spesifik untuk armada tertentu dan barang bersifat umum, beserta stok yang terpantau secara real-time.

### Form Pencatatan Transaksi
- Smart filtering barang berdasarkan armada yang dipilih, hanya menampilkan barang yang sesuai atau barang umum.
- Sistem draft pada rencana belanja (keranjang) sehingga data tidak hilang apabila aplikasi tertutup secara tidak sengaja, dilengkapi mekanisme edit lock pada item yang sedang diproses.
- Realisasi pembayaran fleksibel dalam satu nota, di mana sebagian item dapat berstatus lunas (cash) dan sebagian lainnya berstatus hutang (pending) dengan tanggal jatuh tempo.
- Manajemen kwitansi digital melalui unggah foto ke Supabase Storage, termasuk opsi menggunakan kembali kwitansi yang sama untuk beberapa barang dalam satu nota.
- Pengurangan stok barang secara otomatis pada Master Barang saat transaksi difinalisasi.

### Notifikasi Eksekutif Real-Time
- Notifikasi push (Firebase Cloud Messaging) dikirim ke perangkat pimpinan setiap kali transaksi difinalisasi oleh petugas lapangan.
- Notifikasi dibedakan berdasarkan status pembayaran: transaksi cash dan transaksi dengan komponen hutang yang memerlukan perhatian jatuh tempo.

### Dashboard & Monitoring
- Dashboard Logistik untuk petugas lapangan, menampilkan ringkasan pekerjaan harian dan draft yang tertunda.
- Dashboard Executive untuk pimpinan, menampilkan ringkasan total belanja, total hutang, total transaksi, serta grafik tren pengadaan 6 bulan terakhir.

### Pusat Pelaporan
- Penyaringan data transaksi berdasarkan rentang tanggal, plat nomor armada, toko, dan status pembayaran.
- Pratinjau agregasi data secara langsung (jumlah baris transaksi dan estimasi total nilai) sesuai filter yang diterapkan.
- Ekspor laporan ke format PDF untuk arsip resmi dan format Excel untuk kebutuhan pengolahan data lebih lanjut oleh tim keuangan.

## Arsitektur Aplikasi

Aplikasi dibangun mengikuti pola arsitektur berbasis fitur (feature-based architecture) agar mudah dikembangkan dan dipelihara, dengan pemisahan tanggung jawab antar layer.

```
lib/
├── core/
│   ├── config/           # Setup Supabase, Firebase, Environment variables
│   ├── services/         # ExportService (PDF/Excel), Notification Service
│   ├── theme/            # Tema aplikasi (Warna Navy 0xFF1E3A5F & Aksen)
│   └── utils/            # Formatters (Rupiah, Tanggal, dll)
├── data/
│   ├── models/           # Data classes (BarangModel, MobilModel, RiwayatTransaksi)
│   └── repositories/     # Akses langsung ke Supabase client (.from().select())
├── domain/
│   └── providers/        # StateNotifier & FutureProvider (Riverpod logic)
├── presentation/
│   ├── screens/          # Halaman UI (Master Data, Form Pencatatan, Pusat Pelaporan)
│   └── widgets/          # Reusable UI components (BottomSheets, Cards)
└── main.dart             # Entry point aplikasi
```

### Arsitektur Data (Normalized Database)

Basis data dirancang dengan skema relasional yang dinormalisasi (hingga 3NF di atas 12 entitas utama) untuk menjaga konsistensi dan menghindari duplikasi data, dengan relasi inti sebagai berikut:

- **users** — menyimpan akun dengan dua peran: Petugas dan Boss (Executive).
- **mobil** ⇄ **kategori_mobil** — data armada beserta kategorinya.
- **barang** ⇄ **kategori_barang** — data barang beserta kategorinya.
- **barang_mobil** — tabel penghubung many-to-many antara barang dan mobil untuk logika kecocokan mobil.
- **toko** — direktori supplier tempat pembelian barang.
- **transaksi** ⇄ **detail_transaksi** — nota transaksi dan rincian item di dalamnya, masing-masing menyimpan status pembayaran (lunas/hutang) dan referensi bukti kwitansi.

### Peran Backend & Layanan

| Komponen | Peran |
|---|---|
| Supabase (PostgreSQL) | Basis data relasional utama, autentikasi, dan real-time sync antara petugas lapangan dan dashboard pimpinan |
| Supabase Storage | Penyimpanan berkas gambar kwitansi transaksi |
| Firebase Cloud Messaging | Pengiriman push notification ke perangkat pimpinan saat ada transaksi baru |
| Riverpod | State management, caching data master, dan smart filtering di sisi klien |

## Alur Sistem

### 1. Alur Autentikasi

```text
1. Splash Screen
   ↓
2. Auth Guard
   (Memeriksa sesi login yang tersimpan)
   ↓
   ├─ Jika belum login   → Login / Registrasi
   └─ Jika sudah login   → Dashboard sesuai peran (Petugas / Boss)
```

### 2. Alur Pencatatan Transaksi (Petugas)

```text
1. Dashboard Logistik → tekan "Catat Baru"
   ↓
2. Rencana Belanja
   (Pilih kategori & mobil alokasi → pilih kategori & barang → pilih toko → isi qty dan harga estimasi)
   ↓
3. Realisasi Lapangan
   (Isi harga riil, pilih metode pembayaran, unggah kwitansi)
   ↓
4. Simpan & Selesaikan Transaksi
   (Data tersimpan ke Supabase, stok Master Barang terpotong otomatis)
   ↓
5. Notifikasi terkirim ke perangkat Boss via Firebase Cloud Messaging
```

### 3. Alur Notifikasi Eksekutif

```text
1. Transaksi difinalisasi oleh Petugas
   ↓
2. Sistem membedah isi nota
   ↓
   ├─ Ada item CASH     → Notifikasi transaksi lunas terkirim
   └─ Ada item HUTANG   → Notifikasi peringatan jatuh tempo terkirim
```

### 4. Alur Pelaporan (Boss)

```text
1. Pusat Pelaporan
   (Atur rentang tanggal & saringan: status pembayaran, toko, plat mobil)
   ↓
2. Pratinjau Jumlah Cetak
   (Live aggregation: jumlah baris & estimasi total)
   ↓
3. Ekspor Laporan
   ├─ Cetak PDF     → arsip resmi
   └─ Ekspor Excel  → pengolahan data lanjutan
```

## Teknologi yang Digunakan

| Kategori | Teknologi |
|---|---|
| Frontend | Flutter |
| Bahasa Pemrograman | Dart |
| Backend & Database | Supabase (PostgreSQL) |
| Penyimpanan Berkas | Supabase Storage |
| Notifikasi | Firebase Cloud Messaging (FCM) |
| State Management | Riverpod |

## Cara Instalasi

### Prasyarat

Pastikan perangkat pengembangan sudah memiliki:
- Flutter SDK versi 3.16.0 atau lebih baru
- Dart SDK versi 3.2.0 atau lebih baru
- Android Studio atau Visual Studio Code
- Akun dan proyek Supabase yang sudah dikonfigurasi
- Akun dan proyek Firebase yang sudah dikonfigurasi (untuk Firebase Cloud Messaging)
- Git

### Langkah Instalasi

1. Clone repository

```bash
git clone https://github.com/Frientia/notes_order_revisi.git
cd notes_order_revisi
```

2. Install dependencies

```bash
flutter pub get
```

3. Konfigurasi Firebase

```bash
# Unduh google-services.json dari Firebase Console
# Letakkan di dalam folder android/app/
cp path/to/google-services.json android/app/
```

4. Jalankan aplikasi

```bash
flutter run
```

### Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK per ABI
flutter build apk --split-per-abi
```

## Cara Penggunaan

### Sebagai Petugas Lapangan

1. Masuk ke aplikasi menggunakan akun yang terdaftar, atau daftar akun baru melalui halaman registrasi.
2. Pada Dashboard Logistik, pilih Catat Baru untuk memulai pencatatan transaksi pembelian.
3. Pada Form Pencatatan, tentukan alokasi armada dan barang yang dibeli — sistem akan menyaring barang yang relevan secara otomatis.
4. Masukkan item ke daftar belanja, lalu lengkapi realisasi lapangan dengan harga riil, metode pembayaran, dan unggahan kwitansi.
5. Simpan dan selesaikan transaksi. Data akan tersinkronisasi secara real-time ke Supabase dan memicu notifikasi ke pimpinan.
6. Kelola data pendukung (toko, barang, mobil) melalui menu Master Data, serta pantau riwayat transaksi yang sudah tercatat.

### Sebagai Pimpinan (Executive)

1. Masuk ke aplikasi menggunakan akun dengan peran Boss/Executive.
2. Pantau ringkasan operasional melalui Dashboard Executive, termasuk total belanja, total hutang, dan tren pengadaan bulanan.
3. Terima notifikasi real-time setiap kali ada transaksi baru, termasuk peringatan untuk transaksi berstatus hutang.
4. Gunakan Riwayat Transaksi dan Filter Lanjutan untuk menelusuri data secara spesifik.
5. Pantau kondisi hutang per toko melalui Rekap Hutang Toko, dan evaluasi produktivitas melalui Akuntabilitas Petugas.
6. Buka Pusat Pelaporan untuk menyaring data sesuai kebutuhan audit, lalu ekspor laporan dalam format PDF atau Excel.

## Preview Tampilan Aplikasi

### Autentikasi

| Login | Registrasi |
|---|---|
| ![Login](<img width="1220" height="2712" alt="Login" src="https://github.com/user-attachments/assets/4472b3c6-77f1-45fa-ac5c-9ea53d11a568" />) | ![Registrasi](<img width="1220" height="2712" alt="Registerasi" src="https://github.com/user-attachments/assets/775ec21e-6d1c-4846-ab40-6103c64e30d7" />) |

### Petugas Lapangan — Dashboard & Master Data

| Dashboard Logistik | Sidebar Petugas | Master Data Toko | Master Data Barang | Master Data Mobil |
|---|---|---|---|---|
| ![Dashboard Petugas](<img width="1220" height="3261" alt="Dashboard Petugas" src="https://github.com/user-attachments/assets/e93286c0-726c-4175-9bbf-ba716b14f6df" />) | ![Sidebar Petugas](<img width="1220" height="2712" alt="Sidebar" src="https://github.com/user-attachments/assets/7762e15f-df63-4601-a161-58fac856fe84" />) | ![Master Data Toko](<img width="1220" height="2712" alt="Master Data Toko" src="https://github.com/user-attachments/assets/faf14def-8f6b-4140-9834-7894270a1644" />) | ![Master Data Barang](<img width="1220" height="2712" alt="Master Data Barang" src="https://github.com/user-attachments/assets/82d49366-2d2c-4249-84c9-ebf0ca917662" />) | ![Master Data Mobil](<img width="1220" height="2712" alt="Master Data Mobil" src="https://github.com/user-attachments/assets/dfbaa4a8-fd6f-4693-85c6-2966c11a4f03" />) |

### Petugas Lapangan — Form Pencatatan Transaksi

| Rencana Belanja | Realisasi Lapangan | Riwayat Pencatatan |
|---|---|---|
| ![Rencana Belanja]() | ![Realisasi Lapangan]() | ![Riwayat Pencatatan]() |

### Pimpinan (Boss) — Dashboard & Laporan

| Dashboard Executive | Riwayat Transaksi | Rekap Hutang Toko | Pusat Pelaporan |
|---|---|---|---|
| ![Dashboard Boss]() | ![Riwayat Boss]() | ![Rekap Hutang]() | ![Pusat Pelaporan]() |

## Dokumentasi

Dokumentasi lengkap penggunaan aplikasi (Manual Book) untuk peran Petugas Lapangan dan Pimpinan tersedia pada tautan berikut:

**[Manual Book — Sistem Pencatatan Pembelian Barang Operasional](https://drive.google.com/file/d/1ZAeOE9K1qe4d9a4bG5K6Es1u6R-ohIi7/view?usp=drive_link)**.

## Lisensi

Proyek ini dikembangkan untuk keperluan akademik (Project 3) di Institut Teknologi dan Bisnis Bina Sarana Global dan tidak diperuntukkan untuk distribusi komersial tanpa izin dari pihak terkait.

---

<div align="center">
  <p>© 2026 Lahir Barutama Logistics & Transaction System. All rights reserved.</p>
</div>
