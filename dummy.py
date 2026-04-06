#!/usr/bin/env python3
# dummy_sync.py
# Dummy script yang mensimulasikan output logger asli
# Menggunakan konfigurasi logging identik dengan script produksi

import logging
import os
import json
import time
import random
from datetime import datetime
import sys

# ─── Coba import colorlog, fallback ke formatter biasa ────────────────────────
try:
    from colorlog import ColoredFormatter
    formatter = ColoredFormatter(
        "%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    HAS_COLORLOG = True
except ImportError:
    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    HAS_COLORLOG = False

# ─── Setup logger (identik dengan script asli) ────────────────────────────────
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(formatter)
console_handler.setLevel(logging.DEBUG)

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

if not logger.handlers:
    logger.addHandler(console_handler)


# ─── Helper encoder (menggantikan helper.custom_encoder) ─────────────────────
def custom_encoder(obj):
    if isinstance(obj, datetime):
        return obj.strftime('%Y-%m-%d %H:%M:%S')
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")


def logger_data(table: str, data: object, message: str = ""):
    logger.info(f"[{table}] {json.dumps(data, default=custom_encoder)}{message}")


# ─── Helper delay ─────────────────────────────────────────────────────────────
def delay(min_s=0.3, max_s=0.8):
    time.sleep(random.uniform(min_s, max_s))


# ─── Dummy data ───────────────────────────────────────────────────────────────
TABLES = ["TM_JURNAL", "TM_VOUCHER", "TM_TRANSAKSI", "TM_SALDO", "TM_REKENING"]

DUMMY_PEJABAT = {
    "N_DIRUT": "Nama Dirut, S.E., M.Si",
    "I_NIK_DIRUT": "00.00.001",
    "N_DIRUM": "Dr. Ir. Nama Dirum, S.T., M.T.",
    "I_NIK_DIRUM": "00.00.002",
    "N_KABAGKEU": "Nama Kabagkeu, S.T.",
    "I_NIK_KABAGKEU": "00.00.101",
    "I_NIK_KASIEKEU": "00.00.201",
    "N_KASIEKEU": "Nama Kasiekeu, S.E",
}

DUMMY_JURNAL_BASE = {
    "C_UNIT": "00",
    "D_JURNAL": "2026-01-01",
    "C_BAGIAN": None,
    "C_REKAN": None,
    "I_VOUCHER": None,
    "C_REK": "00.00.00",
    "C_PERK_GOL": "0",
    "C_PERK_KEL": "0",
    "C_PERK_KODE": "00",
    "C_PERK_RINCIAN": "0",
    "C_PERK_SUBRINCIAN": "0",
    "I_BPP": "000/BPPB/PA/00/2026",
    "C_STAT_VOUCHER": "OPN",
    "C_STAT_BAYARVOUCHER": "",
    **DUMMY_PEJABAT,
    "D_ENTRY": datetime.now(),
    "C_BULAN": "-",
    "I_ENTRY": "User Test",
}


def make_jurnal_records(n: int) -> list:
    records = []
    for i in range(1, n + 1):
        amount = round(random.uniform(50000, 999999), 4)
        jurnal_id = f"TEST{str(i).zfill(7)}"
        records.append({
            **DUMMY_JURNAL_BASE,
            "I_URUT": (i * 2) - 1,
            "V_DEBET": f"{amount:.4f}",
            "V_KREDIT": 0,
            "N_KET": f"Transaksi dummy nomor {i} untuk keperluan testing",
            "I_JURNAL": jurnal_id,
        })
        records.append({
            **DUMMY_JURNAL_BASE,
            "I_URUT": (i * 2),
            "V_DEBET": 0,
            "V_KREDIT": f"{amount:.4f}",
            "N_KET": f"Transaksi dummy nomor {i} untuk keperluan testing",
            "I_JURNAL": jurnal_id,
        })
    return records


def make_generic_records(table: str, n: int) -> list:
    return [
        {
            "ID": f"{table[:3]}-{str(i).zfill(5)}",
            "C_UNIT": "00",
            "D_TRANSAKSI": "2026-01-01",
            "V_AMOUNT": round(random.uniform(10000, 500000), 2),
            "N_KET": f"Data dummy {table} record ke-{i}",
            "C_STATUS": random.choice(["OPN", "CLS", "PND"]),
            "D_ENTRY": datetime.now(),
            "I_ENTRY": "User Test",
        }
        for i in range(1, n + 1)
    ]


# ─── Tahapan sync ─────────────────────────────────────────────────────────────
def step_check_connection():
    logger.info("Memeriksa koneksi ke server...")
    delay(0.5, 1.2)

    if random.random() < 0.1:
        logger.warning("Koneksi lambat terdeteksi, melakukan retry...")
        delay(1.0, 2.0)

    logger.info("Koneksi ke server berhasil")
    delay()


def step_fetch_table(table: str) -> int:
    logger.info(f"[{table}] Mengambil data dari server...")
    delay(0.4, 1.0)

    if table == "TM_JURNAL":
        records = make_jurnal_records(random.randint(1, 4))
    else:
        records = make_generic_records(table, random.randint(2, 8))

    logger_data(table, records)
    delay(0.2, 0.5)

    if random.random() < 0.05:
        logger.warning(f"[{table}] Data duplikat ditemukan, melewati {random.randint(1, 3)} record...")
        delay(0.3, 0.6)

    return len(records)


def step_write_local(table: str, count: int) -> int:
    logger.info(f"[{table}] Menyimpan {count} record ke database lokal...")
    delay(0.3, 0.8)

    if random.random() < 0.08:
        failed = random.randint(1, min(3, count))
        logger.warning(f"[{table}] {failed} record gagal disimpan, akan di-retry pada sync berikutnya")
        count -= failed

    logger.info(f"[{table}] {count} record berhasil disimpan")
    delay(0.1, 0.3)
    return count


def step_verify(table: str):
    logger.info(f"[{table}] Verifikasi integritas data...")
    delay(0.2, 0.5)
    logger.info(f"[{table}] Verifikasi selesai, data konsisten")


def step_simulate_error() -> bool:
    if random.random() < 0.15:
        errors = [
            "ConnectionError: server tidak merespon setelah 30 detik",
            "TimeoutError: query melebihi batas waktu 60 detik",
            "IntegrityError: constraint violation pada tabel TM_SALDO",
            "PermissionError: akses ditolak ke endpoint /api/sync",
        ]
        logger.error(random.choice(errors))
        return True
    return False


# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    logger.info("=" * 60)
    logger.info("Memulai proses sync...")
    logger.info(f"Mode: DUMMY TEST | Timestamp: {datetime.now().isoformat()}")
    logger.info("=" * 60)
    delay(0.3, 0.6)

    step_check_connection()

    total_fetched = 0
    total_saved = 0
    tables_done = 0

    for table in TABLES:
        logger.info(f"Memproses tabel: {table}")
        delay(0.2, 0.4)

        if step_simulate_error():
            logger.error(f"Proses sync dihentikan pada tabel {table}")
            logger.error(f"Total tabel selesai: {tables_done}/{len(TABLES)}")
            raise SystemExit(1)

        count = step_fetch_table(table)
        saved = step_write_local(table, count)
        step_verify(table)

        total_fetched += count
        total_saved += saved
        tables_done += 1
        delay(0.2, 0.5)

    logger.info("=" * 60)
    logger.info(f"Sync selesai | Tabel diproses: {tables_done}/{len(TABLES)}")
    logger.info(f"Total data diambil : {total_fetched} record")
    logger.info(f"Total data disimpan: {total_saved} record")

    if total_saved < total_fetched:
        logger.warning(f"{total_fetched - total_saved} record dilewati (duplikat atau gagal)")

    logger.info("Sync berhasil diselesaikan")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()