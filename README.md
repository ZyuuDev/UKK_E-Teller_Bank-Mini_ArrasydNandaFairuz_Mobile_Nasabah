# E-Teller Bank Mini SMKN 1 Bantul — Aplikasi Siswa
### Aplikasi Mobile Nasabah Penabung Berbasis Flutter (Android)

Dokumentasi teknis untuk proyek **Uji Kompetensi Keahlian (UKK)**  
**Konsentrasi Keahlian:** Rekayasa Perangkat Lunak (RPL)  
**Institusi:** SMK Negeri 1 Bantul  
**Pengembang:** Arrasyd Nanda Fairuz ([@ZyuuDev](https://github.com/ZyuuDev))

---

## 1. Deskripsi Aplikasi

Aplikasi mobile pada direktori `mobile/` ini dibangun menggunakan **Flutter** dan **Dart** sebagai platform layanan mandiri (*self-service*) bagi **Siswa SMKN 1 Bantul** yang terdaftar sebagai nasabah penabung di Bank Mini sekolah.

Melalui aplikasi ini, siswa tidak perlu lagi membawa buku tabungan fisik manual yang rentan hilang atau rusak. Seluruh informasi rekening, pergerakan saldo debet/kredit, kode identitas transaksi, dan pengajuan penarikan tabungan dapat diakses langsung dari ponsel pintar siswa secara aman dan real-time.

---

## 2. Fitur Utama Aplikasi Siswa

### 📱 1. Dasbor Saldo & Rekening Digital
* **Informasi Saldo Real-Time**: Menampilkan rincian saldo secara transparan:
  * **Saldo Total**: Akumulasi seluruh dana yang tersimpan di rekening.
  * **Saldo Minimum Mengendap**: Saldo proteksi batas minimal (Rp 10.000) yang tidak dapat ditarik.
  * **Saldo Tersedia**: Dana yang bebas ditarik kapan saja melalui loket teller.
* **Status Layanan Loket Sekolah**: Indikator langsung apakah loket teller di sekolah saat ini sedang dalam status **Buka**, **Istirahat**, atau **Tutup**, sehingga siswa tidak perlu mendatangi loket saat sedang tidak melayani.

### 💳 2. QR Code Rekening Identitas Digital
* Menghasilkan barcode **QR Code** unik yang terikat pada nomor rekening siswa.
* Saat bertransaksi di loket, siswa cukup menunjukkan QR Code ini pada layar ponsel untuk dipindai oleh kamera teller, mempercepat proses identifikasi dan mengeliminasi kesalahan input nomor rekening.

### 📜 3. Riwayat Mutasi Buku Tabungan
* Menampilkan riwayat transaksi perbankan siswa secara kronologis (*terbaru ke terlama*).
* Setiap entri mutasi memuat jenis transaksi (badge hijau untuk **Setoran**, merah untuk **Penarikan**), nominal mutasi, saldo sesudah transaksi, nama petugas teller yang memproses, dan catatan transaksi.

### 📅 4. Janji Temu Penarikan Tabungan (Withdrawal Appointments)
* Siswa dapat mengajukan reservasi penarikan tabungan untuk tanggal tertentu.
* **Proteksi Likuiditas Kas**: Membantu pengelola bank mini mempersiapkan uang tunai fisik di loket untuk penarikan bernominal besar tanpa mengganggu operasional harian.
* Sistem memvalidasi saldo tersedia siswa dan batas kuota penarikan harian.
* Siswa menerima **Kode Janji Temu unik** beserta status permohonan (*Menunggu*, *Disetujui*, *Selesai*, atau *Ditolak*).

### 🔒 5. Keamanan Akun & Pemulihan Mandiri
* **Penyimpanan Token Aman**: Token sesi otentikasi disimpan menggunakan enkripsi tingkat perangkat (`flutter_secure_storage` pada Android Keystore).
* **Verifikasi Email**: Siswa dapat mendaftarkan alamat email pribadi untuk keamanan pemulihan akun.
* **Lupa PIN Mandiri**: Jika siswa lupa 6-digit PIN tabungan, siswa dapat melakukan reset PIN secara mandiri melalui kode verifikasi 6-digit yang dikirimkan ke email terverifikasi.
* **Ganti Password**: Siswa diwajibkan memperbarui kata sandi awal saat pertama kali login.

---

## 3. Arsitektur & Struktur Direktori

Kode aplikasi disusun dengan pola arsitektur bersih (*Clean & Modular Structure*):

```plaintext
mobile/
├── assets/
│   └── brand/                 # Aset logo resmi Bank Mini SMKN 1 Bantul
├── lib/
│   ├── config/
│   │   └── api_config.dart    # Konfigurasi endpoint URL API backend
│   ├── models/
│   │   ├── account_model.dart     # Model profil anggota, rekening, & saldo
│   │   ├── appointment_model.dart # Model permohonan janji temu penarikan
│   │   └── mutation_model.dart    # Model data baris mutasi transaksi
│   ├── screens/
│   │   ├── appointment_screen.dart # Layar pengajuan & riwayat janji temu
│   │   ├── auth_screens.dart       # Layar login siswa & aktivasi password
│   │   ├── dashboard_screen.dart   # Dasbor utama saldo, QR, & mutasi tabungan
│   │   ├── email_panel.dart        # Panel verifikasi email akun siswa
│   │   └── pin_recovery_screen.dart # Layar verifikasi reset PIN mandiri
│   ├── services/
│   │   ├── api_service.dart        # Klien HTTP terpusat (Sanctum Bearer Token)
│   │   └── storage_service.dart    # Enkripsi penyimpanan token lokal
│   ├── theme/
│   │   └── bank_theme.dart         # Skema warna, tipografi, & komponen UI
│   ├── widgets/
│   │   ├── account_widgets.dart    # Widget kartu saldo, mutasi, & QR badge
│   │   └── bank_widgets.dart       # Widget tombol, input, & status pill
│   └── main.dart                   # Titik masuk aplikasi & routing navigasi
├── pubspec.yaml                    # Dependensi paket Flutter
└── README.md                       # Dokumentasi resmi proyek mobile
```

---

## 4. Teknologi & Dependensi Pustaka

| Paket | Versi | Kegunaan dalam Proyek |
|---|:---:|---|
| **Flutter SDK** | `>= 3.10.4` | Framework UI multi-platform berbasis Dart |
| **http** | `^1.2.0` | Komunikasi REST API client ke backend Laravel |
| **flutter_secure_storage** | `^11.2.0` | Penyimpanan token sesi terenkripsi (Android Keystore) |
| **shared_preferences** | `^2.2.2` | Cache preferensi lokal dan status onboarding |
| **qr_flutter** | `^4.1.0` | Rendering gambar QR Code rekening siswa secara instan |
| **intl** | `^0.19.0` | Pemformatan angka Rupiah (`id_ID`) dan penanggalan lokal |
| **flutter_launcher_icons** | `^0.14.4` | Otomatisasi icon launcher aplikasi dengan logo Bank Mini |

---

## 5. Panduan Menjalankan Aplikasi di Komputer Lokal

### Prasyarat
1. Telah menginstal **Flutter SDK** (versi 3.10 atau yang lebih baru).
2. Perangkat Android fisik (kabel USB & USB Debugging aktif) atau **Android Emulator**.
3. Backend Laravel (`dekstop/`) sudah berjalan pada server lokal.

### Langkah Menjalankan

1. **Masuk ke Direktori Mobile**:
   ```bash
   cd c:\laragon\www\UKK_E-Teller_Bank_Mini_ArrasydNandaFairuz\mobile
   ```

2. **Unduh Dependensi Paket**:
   ```bash
   flutter pub get
   ```

3. **Jalankan Aplikasi Sesuai Target Perangkat**:

   * **Opsi A: Menggunakan Android Emulator**:
     Alamat localhost komputer dari dalam emulator Android adalah `10.0.2.2`:
     ```bash
     flutter run --dart-define=BANK_API_URL=http://10.0.2.2:8000/api
     ```

   * **Opsi B: Menggunakan Perangkat Fisik (HP Android via Wi-Fi)**:
     Gunakan alamat IP lokal komputer yang menjalankan backend Laravel (misal `192.168.1.10`):
     ```bash
     flutter run --dart-define=BANK_API_URL=http://192.168.1.10:8000/api
     ```

   * **Opsi C: Menggunakan Server Live Production**:
     Aplikasi secara default telah terkonfigurasi ke server online:
     ```bash
     flutter run
     ```

---

## 6. Pembuatan Berkas Instalasi (Build APK Release)

Untuk menghasilkan berkas `.apk` siap pasang di ponsel penguji atau siswa:

```bash
flutter build apk --release
```

Berkas APK akan dihasilkan pada:
```plaintext
mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## 7. Akun Siswa untuk Pengujian UKK

Untuk melakukan uji coba login aplikasi mobile:
1. Daftarkan siswa baru melalui menu **Data Anggota** di panel Web Admin, atau gunakan akun siswa yang sudah terdaftar.
2. Gunakan **Nomor Siswa (NIS)** sebagai *Username* login.
3. Masukkan kata sandi sementara yang diterbitkan oleh Admin.
4. Pada login pertama kali, aplikasi akan memandu siswa untuk memperbarui kata sandi demi keamanan akun.

---

## 8. Profil Pengembang

* **Nama Siswa:** Arrasyd Nanda Fairuz
* **Institusi:** SMK Negeri 1 Bantul
* **Program Keahlian:** Rekayasa Perangkat Lunak (RPL)
* **Tahun Pembuatan:** 2026/2027
