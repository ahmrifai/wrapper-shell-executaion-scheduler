# 🔄 Inventory Sync Dashboard

Desktop app Flutter untuk menjalankan sync script Python antara database desktop dan web.

---

## ✨ Fitur

| Fitur | Keterangan |
|---|---|
| **Realtime Clock** | Jam dan tanggal live dalam Bahasa Indonesia |
| **Manual Sync** | Tombol "Sync Now" untuk trigger sync kapan saja |
| **Stop Sync** | Hentikan proses sync yang sedang berjalan |
| **Auto Sync** | Jadwalkan sync otomatis per X menit |
| **Live Log** | Tampilan log real-time dari output Python script |
| **Log Levels** | ERROR (merah), SUCCESS (hijau), WARNING (kuning), INFO (biru) |
| **Settings Page** | Konfigurasi path python, script, argumen, dan interval |
| **Last Sync Info** | Info terakhir kali sync berhasil dijalankan |
| **Clear Logs** | Bersihkan log panel |

---

## 🚀 Cara Setup

### 1. Install Flutter

Download Flutter SDK dari https://docs.flutter.dev/get-started/install

Pastikan Flutter sudah ter-install untuk desktop (Windows/macOS/Linux):

```bash
flutter config --enable-windows-desktop   # Windows
flutter config --enable-macos-desktop     # macOS
flutter config --enable-linux-desktop     # Linux

flutter doctor
```

### 2. Clone / Copy Project

```bash
cd sync_dashboard
flutter pub get
```

### 3. Jalankan App

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### 4. Build Release

```bash
# Windows — output di build/windows/x64/runner/Release/
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## ⚙️ Konfigurasi Settings

Buka halaman Settings (ikon gear di kanan atas), isi:

| Field | Contoh | Keterangan |
|---|---|---|
| **Python Executable** | `python3` atau `C:\Python311\python.exe` | Path ke Python |
| **Script Path** | `/home/user/sync.py` | Path lengkap ke file .py |
| **Arguments** | `--mode full --verbose` | Argumen tambahan (opsional) |
| **Auto Sync** | ON/OFF | Aktifkan sync otomatis |
| **Interval (menit)** | `30` | Seberapa sering auto sync |

---

## 📋 Format Log Python (Opsional)

App ini bisa mem-parse log dengan format:

```
YYYY-MM-DD HH:MM:SS | LEVEL | Pesan log di sini
```

Contoh output dari script Python:
```
2026-04-04 11:53:10 | SUCCESS | Data produk berhasil disync: 142 records
2026-04-04 11:53:11 | ERROR   | Koneksi ke server gagal: timeout
2026-04-04 11:53:12 | WARNING | Data duplikat ditemukan di tabel orders
2026-04-04 11:53:13 | INFO    | Memulai sync tabel customers...
```

Jika format berbeda, app akan tetap mendeteksi level log dari keyword dalam pesan.

### Contoh Python Logging:

```python
import sys
from datetime import datetime

def log(level, message):
    ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"{ts} | {level} | {message}", flush=True)

def main():
    log("INFO", "Memulai proses sync...")
    
    try:
        # ... proses sync ...
        log("SUCCESS", "Sync selesai: 142 records diproses")
    except Exception as e:
        log("ERROR", f"Sync gagal: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

> **Penting:** Gunakan `flush=True` di `print()` agar output muncul real-time di log viewer.

---

## 🏗️ Struktur Project

```
sync_dashboard/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── models/
│   │   └── log_entry.dart           # Model log (level, message, timestamp)
│   ├── services/
│   │   ├── sync_service.dart        # Execute Python, capture output
│   │   └── settings_service.dart    # Simpan/load settings (SharedPreferences)
│   ├── screens/
│   │   ├── home_screen.dart         # Halaman utama
│   │   └── settings_screen.dart     # Halaman settings
│   └── widgets/
│       └── log_entry_tile.dart      # Widget satu baris log
├── pubspec.yaml
└── README.md
```

---

## 📦 Dependencies

```yaml
shared_preferences: ^2.2.2   # Simpan settings lokal
intl: ^0.19.0                # Format tanggal/waktu
path_provider: ^2.1.2        # Akses filesystem
```

---

## 💡 Tips

- **Gunakan `flush=True`** di setiap `print()` di Python agar log muncul real-time
- **Redirect stderr ke stdout** jika pakai library logging: `stream=sys.stdout`
- Script bisa berupa file `.py` tunggal maupun entrypoint dari project Python
- Untuk Windows, jika `python3` tidak dikenal, gunakan `python` saja
