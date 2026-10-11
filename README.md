# IF4073-Frequency-Domain-Image-Processing

Aplikasi MATLAB untuk pemrosesan citra di ranah frekuensi menggunakan berbagai metode filter dan restorasi.


## Deskripsi

Program ini menyediakan antarmuka grafis (GUI) interaktif untuk melakukan berbagai operasi pemrosesan citra di ranah frekuensi, termasuk:
- **Low-Pass Filtering**: Menghaluskan citra dengan meredam komponen frekuensi tinggi
- **High-Pass Filtering**: Mempertajam tepi dengan meredam komponen frekuensi rendah
- **Brightness Enhancement**: Meningkatkan kecerahan citra melalui manipulasi spektrum DC dan frekuensi rendah
- **Periodic Noise Restoration**: Menghilangkan derau periodik menggunakan filter bandreject dan notch reject
- **Motion Blur Restoration**: Merestorasi citra yang kabur akibat gerak menggunakan filter Wiener dan Inverse


## Dependensi

### Software

* **MATLAB** (R2019b atau versi lebih baru disarankan)
* **MATLAB Image Processing Toolbox** (diperlukan)

### MATLAB Toolbox yang Digunakan

| Toolbox                   | Kegunaan                                                                                               |
| ------------------------- | ------------------------------------------------------------------------------------------------------ |
| Image Processing Toolbox  | Fungsi manipulasi citra dasar (`imread`, `imwrite`, `im2double`, dll.)                                 |
| Signal Processing Toolbox | Fungsi `sinc` untuk perhitungan kernel filter berbasis sinc, jika digunakan dalam implementasi filter. |


## Cara Menjalankan Program

### Melalui MATLAB
1. Buka MATLAB
2. Arahkan ke direktori proyek ini
3. Jalankan perintah berikut di Command Window:
   ```matlab
   runApp()
   ```
4. Aplikasi GUI akan запуститься автоматически

## Struktur Direktori
```
IF4073-Frequency-Domain-Image-Processing/
├── runApp.m              % Entry point untuk запуска приложения
├── src/
│   ├── gui/
│   │   └── IntegratedGUI.m       % Antarmuka grafis utama
│   ├── filters/
│   │   ├── lowPassFilters/       % Filter low pass
│   │   ├── highPassFilters/      % Filter high pass
│   │   ├── brightness/           % Peningkat kecerahan
│   │   ├── noiseRestoration/     % Restorasi derau periodik
│   │   └── motionBlur/           % Restorasi blur akibat gerak
│   └── utils/                    % Utilitas komputasi FFT
├── tests/                        % Unit test
└── README.md
```


## Metode yang Tersedia

### 1. Low-Pass Filter
Filter low pass digunakan untuk menghaluskan citra dengan meredam komponen frekuensi tinggi.

| Metode | Deskripsi |
|--------|-----------|
| **Ideal Low-Pass** | Filter dengan cutoff tajam, menghasilkan rippleGibbs |
| **Butterworth Low-Pass** | Filter dengan karakteristik halus, order dapat diatur |
| **Gaussian Low-Pass** | Filter Gaussian dengan transisi halus |

**Parameter:**
- `Cutoff (D0)`: Frekuensi cutoff [1-250]

### 2. High-Pass Filter
Filter high pass digunakan untuk mempertajam tepi dengan meredam komponen frekuensi rendah.

| Metode | Deskripsi |
|--------|-----------|
| **Ideal High-Pass** | Filter dengan cutoff tajam |
| **Butterworth High-Pass** | Filter halus dengan order dapat diatur |
| **Gaussian High-Pass** | Filter Gaussian |

**Parameter:**
- `Cutoff (D0)`: Frekuensi cutoff [1-250]
- `Order (n)`: Orde filter (khusus Butterworth) [1-10]

### 3. Brightness Enhancement
Metode untuk meningkatkan kecerahan citra melalui manipulasi spektrum frekuensi.

| Metode | Deskripsi |
|--------|-----------|
| **DC Boost** | Menguatkan komponen DC untuk meningkatkan kecerahan keseluruhan |
| **Low-Frequency Boost** | Menguatkan frekuensi rendah secara lokal menggunakan mask Gaussian |

**Parameter:**
- `Gain`: Faktor penguat [0.1-5.0]
- `Cutoff (D0)`: Radius cutoff untuk Low-Frequency Boost [1-100]

### 4. Periodic Noise Restoration
Metode untuk menghilangkan derau periodik (seperti garis atau pola berulang) dalam citra.

#### Filter Bandreject
Menolak pita frekuensi tertentu di sekitar frekuensi gangguan.

| Metode | Deskripsi |
|--------|-----------|
| **Bandreject (Ideal)** | Menolak pita frekuensi secara tajam |
| **Bandreject (Butterworth)** | Penolakan pita halus dengan order dapat diatur |
| **Bandreject (Gaussian)** | Penolakan pita dengan transisi Gaussian |

#### Filter Notch Reject
Menolak komponen frekuensi spesifik pada titik-titik yang ditentukan.

| Metode | Deskripsi |
|--------|-----------|
| **Notch Reject (Ideal)** | Menolak titik frekuensi secara tajam |
| **Notch Reject (Butterworth)** | Penolakan titik halus dengan order dapat diatur |
| **Notch Reject (Gaussian)** | Penolakan titik dengan transisi Gaussian |

**Parameter Bandreject:**
- `Cutoff (D0)`: Radius cutoff pita [2-200]
- `Bandwidth (W)`: Lebar pita frekuensi yang ditolak [1-50]
- `Order (n)`: Orde filter (khusus Butterworth) [1-10]

**Parameter Notch Reject:**
- `Radius (D0)`: Radius notch [1-50]
- `Order (n)`: Orde filter (khusus Butterworth) [1-10]
- Titik notch dapat ditambahkan melalui klik langsung pada spektrum magnitudo

### 5. Motion Blur Restoration
Metode untuk merestorasi citra yang kabur akibat gerak linier.

| Metode | Deskripsi |
|--------|-----------|
| **Wiener Filter** | Restorasi statistik optimal dengan memperhitungkan noise |
| **Inverse Filter** | Restorasi langsung dengan cutoff untuk menghindari amplifikasi noise |

**Parameter:**
- `Length (L)`: Panjang blur [1-50] piksel
- `Angle (θ)`: Sudut blur [-180° - 180°]
- `K (NSR)`: Noise-to-Signal Ratio untuk Wiener [0.0001-1.0]
- `Cutoff (Rc)`: Radius cutoff untuk Inverse [5-200]
- `Threshold (ε)`: Ambang batas untuk Inverse [0.001-0.2]


## Menggunakan GUI

1. **Muat Citra**: Klik tombol "Muat Citra..." untuk memilih berkas citra
2. **Pilih Kategori**: Pilih kategori pemrosesan dari dropdown
3. **Pilih Metode**: Pilih metode spesifik dari dropdown sub-metode
4. **Atur Parameter**: Gunakan slider dan field input untuk mengatur parameter
5. **Proses**: Klik "Jalankan Pemrosesan" atau aktifkan "Proses Otomatis"
6. **Simpan Hasil**: Klik "Simpan Hasil..." untuk menyimpan citra yang telah diproses


##  Pembagian Tugas

| NIM      | Nama                           | Bagian                                                    |
| :---     | :---                           | :---                                                      |
| 13523038 | Abrar Abhirama Widyadhana      | Periodic Noise Restoration, Motion Blur Restoration, GUI  |
| 13523081 | Jethro Jens Norbert Simatupang | Low Pass Filter, High Pass Filter, Brightness Enhancement |
---