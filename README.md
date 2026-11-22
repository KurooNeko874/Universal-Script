<div align="center">

# 🚀 Kuroo Universal Script + KurooEmote

**Script Universal Roblox All-in-One dengan UI Modern ([KurooUI](https://github.com/KurooNeko874/KurooUI)) & Roda Emote 62.000+ Marketplace**

[![Version](https://img.shields.io/badge/Version-1.1.7%20Plus-00CFFF?style=for-the-badge)](https://github.com/KurooNeko874/Universal-Script)
[![KurooEmote](https://img.shields.io/badge/KurooEmote-v1.1.0%20(62K+%20Emotes)-FFCC33?style=for-the-badge)](https://github.com/KurooNeko874/Universal-Script)
[![Platform](https://img.shields.io/badge/Support-PC%20%26%20Mobile-40D680?style=for-the-badge)](#)
[![Key System](https://img.shields.io/badge/Key%20System-No%20Key-brightgreen?style=for-the-badge)](#)

[![TikTok](https://img.shields.io/badge/TikTok-@kuro.neko874-000000?style=for-the-badge&logo=tiktok&logoColor=white)](https://www.tiktok.com/@kuro.neko874)
[![Discord](https://img.shields.io/badge/Discord-kuroneko4411-5865F2?style=for-the-badge&logo=discord&logoColor=white)](#kontak--komunitas--contact)
[![GitHub](https://img.shields.io/badge/GitHub-KurooNeko874-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/KurooNeko874)

<br/>

🇮🇩 **Bahasa Indonesia** | 🇬🇧 [English Version](#-english-version)

</div>

---

## 📸 Preview / Tangkapan Layar

<div align="center">
  <img src="assets/preview-main.png" alt="Kuroo Universal Script - Main UI" width="85%" />
  <p><i>Tampilan Utama Kuroo Universal Script (Powered by KurooUI)</i></p>
</div>

<br/>

<div align="center">
  <img src="assets/preview-emote.png" alt="KurooEmote Radial Wheel" width="85%" />
  <p><i>KurooEmote — Roda Emote 8-Slot dengan 62.000+ Emote Marketplace Roblox</i></p>
</div>

<details>
<summary><b>📱 Lihat Preview Lainnya (Mode Favorit & Tampilan Mobile)</b></summary>
<br/>
<div align="center">
  <img src="assets/preview-emote-fav.png" alt="KurooEmote Favorites Mode" width="80%" />
  <p><i>Mode Favorit & Pencarian Emote UGC</i></p>
  <br/>
  <img src="assets/preview-mobile.png" alt="Mobile Responsive View" width="80%" />
  <p><i>Tampilan Responsif Mobile dengan Ikon Melayang yang Bisa Di-Drag</i></p>
</div>
</details>

---

## ⚡ Cara Menggunakan (Loadstring)

### 1. Paket Lengkap (Universal Script + KurooEmote)
Salin dan jalankan kode berikut di executor Anda:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/KurooNeko874/Universal-Script/refs/heads/main/KurooUniversalScript.lua"))()
```

### 2. Khusus KurooEmote Saja (Standalone)
Jika hanya ingin menjalankan roda emote Marketplace tanpa menu universal:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/KurooNeko874/Universal-Script/refs/heads/main/KurooEmote.lua"))()
```

---

## ✨ Fitur Utama

### 🧩 Kuroo Universal Script (`KurooUI`)
Dibangun menggunakan library open-source [**KurooUI**](https://github.com/KurooNeko874/KurooUI) dengan dukungan penuh PC & Mobile otomatis:
- **Main 🚀** — Utilitas karakter, kontrol pergerakan, dan fitur cepat harian.
- **Combat ⚔️** — Fitur pendukung pertempuran & utilitas gameplay.
- **Animations 🎭** — Pengganti paket animasi karakter (Idle, Walk, Run, Jump, Fall, Climb, Swim) lengkap dengan puluhan preset animasi Roblox.
- **Visuals 👁️** — Pengaturan visual, kamera, dan pencahayaan.
- **Larping (Visual) ✨** — Efek visual tambahan untuk tampilan karakter.
- **Auto-Responsive PC & Mobile** — Skala otomatis di layar HP + tombol bulat floating yang bisa di-drag saat UI disembunyikan.

### 🎭 KurooEmote (`v1.1.0`)
Roda emote kustom bergaya radial 8-slot yang menggantikan Emote Wheel bawaan Roblox:
- **62.000+ Emote Marketplace Otomatis** — Mengambil seluruh katalog emote Official & UGC secara otomatis dengan sistem cache JSON lokal (`KurooEmote/emotes_catalog_v2.json`) agar loading berikutnya instan.
- **Pencarian Nama & Asset ID** — Cari emote berdasarkan nama (mendukung pencarian cerdas & pencarian live Marketplace) atau langsung ketik Asset ID emote.
- **Pengaturan Kecepatan (`0.05x` – `10x`)** — Atur kecepatan animasi emote secara real-time (semakin kecil semakin lambat, maksimal `10x`).
- **Sistem Favorit Permanen (`★`)** — Simpan emote favorit secara otomatis di perangkat masing-masing user (`KurooEmote/favorites.json`).
  - Di menu **Semua Emote**, tombol `★` mengaktifkan *Mode Favorit* (klik banyak emote sekaligus untuk menyimpan).
  - Di menu **Favorit**, tombol `★` berubah menjadi *Mode Unfav* untuk menghapus emote dari daftar favorit.
- **Ramah Mobile & PC** — Tombol navigasi halaman `<` dan `>` besar di kiri & kanan tombol Favorit, serta tombol ikon senyum (`☺`) yang **bisa di-drag bebas** di layar.
- **Auto-Stop Seperti Bawaan Roblox** — Emote otomatis berhenti saat karakter berjalan, melompat, memanjat, berenang, duduk, atau respawn.

---

## 🎮 Kontrol & Pintasan

| Aksi | PC | Mobile |
| :--- | :--- | :--- |
| **Buka / Tutup Universal UI** | Tombol `K` *(default KurooUI)* | Tap tombol bulat floating |
| **Buka / Tutup Emote Wheel** | Tombol `.` *(Titik)* atau klik ikon `☺` | Tap ikon `☺` *(bisa ditahan & di-drag)* |
| **Ganti Halaman Emote** | Klik `<` / `>` atau Scroll Mouse | Tap tombol `<` / `>` di samping Favorit |
| **Tutup Emote Wheel** | Tombol `ESC` atau `.` | Tap ikon `☺` |

---

## 🇬🇧 English Version

<details>
<summary><b>Click to expand English documentation</b></summary>

### Overview
**Kuroo Universal Script** is an all-in-one Roblox universal utility script powered by the open-source [**KurooUI**](https://github.com/KurooNeko874/KurooUI) library, bundled with **KurooEmote v1.1.0** — a custom 8-slot radial Emote Wheel featuring **62,000+ Roblox Marketplace emotes** with full **PC & Mobile** support and **No Key System**.

### Quick Start
```lua
-- Full Bundle (Universal Script + KurooEmote)
loadstring(game:HttpGet("https://raw.githubusercontent.com/KurooNeko874/Universal-Script/refs/heads/main/KurooUniversalScript.lua"))()

-- KurooEmote Standalone Only
loadstring(game:HttpGet("https://raw.githubusercontent.com/KurooNeko874/Universal-Script/refs/heads/main/KurooEmote.lua"))()
```

### Key Features
- **Universal Script (`KurooUI`):** Includes `Main 🚀`, `Combat ⚔️`, `Animations 🎭`, `Visuals 👁️`, and `Larping (Visual) ✨` tabs with automatic mobile scaling and floating toggle button.
- **KurooEmote (`v1.1.0`):**
  - Automatically loads **62,000+ official & UGC Marketplace emotes** with local JSON caching.
  - Search by **emote name** (smart local + live Marketplace search) or direct **Asset ID**.
  - Real-time **animation speed control** (`0.05x` – `10x`).
  - Per-device **Favorites (`★`)** saved automatically to local JSON (`KurooEmote/favorites.json`), with dedicated Add-Fav & Unfav modes.
  - **Mobile-friendly layout:** Large `<` and `>` page buttons flanking the Favorites button + a **draggable `☺` toggle icon** and `.` keybind.
  - Replaces the default Roblox Emotes Menu and automatically stops emotes when moving or jumping.

</details>

---

## 📬 Kontak & Komunitas / Contact

Suka dengan script ini? Jangan lupa kasih **⭐ Star** di repository ini dan ikuti update terbaru di:

- **GitHub:** [KurooNeko874](https://github.com/KurooNeko874)
- **TikTok:** [@kuro.neko874](https://www.tiktok.com/@kuro.neko874)
- **Discord:** `kuroneko4411`

---

<div align="center">
  Made with ❤️ by <b>Kuroo</b> • Powered by <a href="https://github.com/KurooNeko874/KurooUI">KurooUI</a>
</div>
