// test/parse_line_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sync_dashboard/models/log_entry.dart';

// ─── Copy fungsi _parseLine agar bisa di-test secara independen ───────────────

LogEntry parseLine(String line) {
  final regex = RegExp(
    r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s*\|\s*(\w+)\s*\|\s*(.*)',
    dotAll: true,
  );

  final match = regex.firstMatch(line);
  if (match != null) {
    final levelStr = match.group(2)!.trim().toUpperCase();
    final message = match.group(3)!.trim();

    LogLevel level;
    switch (levelStr) {
      case 'INFO':
        level = LogLevel.success;
        break;
      case 'ERROR':
        level = LogLevel.error;
        break;
      case 'WARNING':
      case 'WARN':
        level = LogLevel.warning;
        break;
      default:
        level = LogLevel.info;
    }

    return LogEntry(timestamp: DateTime.now(), level: level, message: message);
  }

  // Fallback
  final upper = line.toUpperCase();
  LogLevel level;
  if (upper.contains('ERROR') ||
      upper.contains('FAIL') ||
      upper.contains('EXCEPTION')) {
    level = LogLevel.error;
  } else if (upper.contains('WARN')) {
    level = LogLevel.warning;
  } else if (upper.contains('SUCCESS') ||
      upper.contains('DONE') ||
      upper.contains('COMPLETE')) {
    level = LogLevel.success;
  } else {
    level = LogLevel.info;
  }

  return LogEntry(timestamp: DateTime.now(), level: level, message: line);
}

// ─── Test data ────────────────────────────────────────────────────────────────

const String kRealJsonLog =
    '2026-04-06 09:43:17 | INFO | [TM_JURNAL] [{"C_UNIT": "00", "D_JURNAL": "2026-01-01", '
    '"C_BAGIAN": null, "C_REKAN": null, "I_URUT": 1, "I_VOUCHER": null, "C_REK": "00.00.00", '
    '"C_PERK_GOL": "0", "C_PERK_KEL": "0", "C_PERK_KODE": "00", "C_PERK_RINCIAN": "0", '
    '"C_PERK_SUBRINCIAN": "0", "I_BPP": "000/BPPB/PA/00/2026", "V_DEBET": "100000.0000", '
    '"V_KREDIT": 0, "N_KET": "Kegiatan dummy untuk keperluan testing", '
    '"C_STAT_VOUCHER": "OPN", "C_STAT_BAYARVOUCHER": "", "N_DIRUT": "Nama Dirut, S.E., M.Si", '
    '"I_NIK_DIRUT": "00.00.001", "N_DIRUM": "Dr. Ir. Nama Dirum, S.T., M.T.", '
    '"I_NIK_DIRUM": "00.00.002", "N_KABAGKEU": "Nama Kabagkeu, S.T.", '
    '"I_NIK_KABAGKEU": "00.00.101", "I_NIK_KASIEKEU": "00.00.201", '
    '"N_KASIEKEU": "Nama Kasiekeu, S.E", "D_ENTRY": "2026-04-06 09:43:03", '
    '"C_BULAN": "-", "I_JURNAL": "TEST0000001", "I_ENTRY": "User Test"}, '
    '{"C_UNIT": "00", "D_JURNAL": "2026-01-01", "C_BAGIAN": null, "C_REKAN": null, '
    '"I_URUT": 2, "I_VOUCHER": null, "C_REK": "00.00.00", "C_PERK_GOL": "0", '
    '"C_PERK_KEL": "0", "C_PERK_KODE": "00", "C_PERK_RINCIAN": "0", '
    '"C_PERK_SUBRINCIAN": "0", "I_BPP": "000/BPPB/PA/00/2026", "V_DEBET": 0, '
    '"V_KREDIT": "100000.0000", "N_KET": "Kegiatan dummy untuk keperluan testing", '
    '"C_STAT_VOUCHER": "OPN", "C_STAT_BAYARVOUCHER": "", "N_DIRUT": "Nama Dirut, S.E., M.Si", '
    '"I_NIK_DIRUT": "00.00.001", "N_DIRUM": "Dr. Ir. Nama Dirum, S.T., M.T.", '
    '"I_NIK_DIRUM": "00.00.002", "N_KABAGKEU": "Nama Kabagkeu, S.T.", '
    '"I_NIK_KABAGKEU": "00.00.101", "I_NIK_KASIEKEU": "00.00.201", '
    '"N_KASIEKEU": "Nama Kasiekeu, S.E", "D_ENTRY": "2026-04-06 09:43:03", '
    '"C_BULAN": "-", "I_JURNAL": "TEST0000001", "I_ENTRY": "User Test"}]';

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('parseLine — format standar', () {
    test('INFO → level info', () {
      final entry = parseLine('2026-04-06 09:43:17 | INFO | Memulai sync...');
      expect(entry.level, LogLevel.info);
      expect(entry.message, 'Memulai sync...');
    });

    test('SUCCESS → level success', () {
      final entry = parseLine(
          '2026-04-06 09:43:20 | SUCCESS | Sync selesai: 142 records');
      expect(entry.level, LogLevel.success);
      expect(entry.message, 'Sync selesai: 142 records');
    });

    test('ERROR → level error', () {
      final entry = parseLine(
          '2026-04-06 09:43:21 | ERROR | Koneksi ke server gagal: timeout');
      expect(entry.level, LogLevel.error);
      expect(entry.message, 'Koneksi ke server gagal: timeout');
    });

    test('WARNING → level warning', () {
      final entry =
          parseLine('2026-04-06 09:43:22 | WARNING | Data duplikat ditemukan');
      expect(entry.level, LogLevel.warning);
      expect(entry.message, 'Data duplikat ditemukan');
    });

    test('WARN (singkat) → level warning', () {
      final entry = parseLine('2026-04-06 09:43:22 | WARN | Retry ke-2...');
      expect(entry.level, LogLevel.warning);
    });

    test('level tidak dikenal → fallback ke info', () {
      final entry =
          parseLine('2026-04-06 09:43:22 | DEBUG | Checking connection...');
      expect(entry.level, LogLevel.info);
    });
  });

  group('parseLine — JSON panjang di message (kasus nyata)', () {
    test('INFO + JSON tidak ter-split menjadi ERROR', () {
      final entry = parseLine(kRealJsonLog);

      // ✅ Harus INFO, bukan ERROR
      expect(entry.level, LogLevel.info,
          reason: 'JSON di message tidak boleh mempengaruhi deteksi level');
    });

    test('message mengandung prefix [TM_JURNAL]', () {
      final entry = parseLine(kRealJsonLog);
      expect(entry.message, startsWith('[TM_JURNAL]'));
    });

    test('message mengandung seluruh JSON (tidak terpotong)', () {
      final entry = parseLine(kRealJsonLog);
      expect(entry.message, contains('TEST0000001'));
      expect(entry.message, contains('User Test'));
      expect(entry.message, contains('100000.0000'));
    });

    test('message mengandung 2 records JSON', () {
      final entry = parseLine(kRealJsonLog);
      expect(entry.message, contains('"I_URUT": 1'));
      expect(entry.message, contains('"I_URUT": 2'));
    });

    test('field N_DIRUM yang ada titik tidak mempengaruhi parse', () {
      // "Dr. Ir. Nama Dirum, S.T., M.T." — banyak titik & koma
      final entry = parseLine(kRealJsonLog);
      expect(entry.message, contains('Dr. Ir. Nama Dirum, S.T., M.T.'));
    });
  });

  group('parseLine — tepi kasus (edge cases)', () {
    test('INFO + message mengandung kata ERROR di dalamnya → tetap INFO', () {
      final entry = parseLine(
        '2026-04-06 09:43:17 | INFO | Response: {"status": "ERROR_HANDLED", "code": 0}',
      );
      expect(entry.level, LogLevel.info,
          reason:
              'Kata ERROR di message tidak boleh override level yang sudah di-parse');
    });

    test('INFO + message mengandung kata FAIL di dalamnya → tetap INFO', () {
      final entry = parseLine(
        '2026-04-06 09:43:17 | INFO | retry_on_fail=True, attempt=1',
      );
      expect(entry.level, LogLevel.info);
    });

    test('INFO + message mengandung kata SUCCESS di dalamnya → tetap INFO', () {
      final entry = parseLine(
        '2026-04-06 09:43:17 | INFO | C_STAT_VOUCHER: OPN, prev_status: SUCCESS',
      );
      expect(entry.level, LogLevel.info);
    });

    test('baris tanpa format timestamp → fallback keyword scan aktif', () {
      final entry = parseLine('Traceback (most recent call last): ...');
      expect(entry.level, LogLevel.info); // tidak ada keyword → info
    });

    test('baris tanpa format + keyword ERROR → fallback error', () {
      final entry = parseLine('ConnectionError: timed out after 30s');
      expect(entry.level, LogLevel.error);
    });

    test('baris tanpa format + keyword WARNING → fallback warning', () {
      final entry = parseLine('UserWarning: deprecated function used');
      expect(entry.level, LogLevel.warning);
    });

    test('baris kosong → tidak crash, fallback info', () {
      final entry = parseLine('');
      expect(entry.level, LogLevel.info);
      expect(entry.message, '');
    });

    test('hanya spasi → tidak crash', () {
      final entry = parseLine('   ');
      expect(entry.level, LogLevel.info);
    });

    test('format timestamp valid tapi message kosong', () {
      final entry = parseLine('2026-04-06 09:43:17 | INFO | ');
      expect(entry.level, LogLevel.info);
      expect(entry.message, '');
    });
  });
}
