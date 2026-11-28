<div align="center">

# 🚀 Kuroo Universal Script + KurooEmote

**Script Universal Roblox All-in-One dengan UI Persona 5 Edition ([KurooUI WindVersion](https://github.com/KurooNeko874/KurooUI_WindVersion)) & Roda Emote 62.000+ Marketplace**

[![Version](https://img.shields.io/badge/Version-1.2.1%20Season%20%26%20Modular-E60012?style=for-the-badge)](https://github.com/KurooNeko874/Universal-Script)
[![UI Library](https://img.shields.io/badge/UI-KurooUI%20WindVersion-09090B?style=for-the-badge&labelColor=E60012)](https://github.com/KurooNeko874/KurooUI_WindVersion)
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
  <img src="assets/preview-main.png" alt="Kuroo Universal Script v1.2.1 - Persona 5 Edition" width="85%" />
  <p><i>Tampilan Utama Kuroo Universal Script v1.2.1 (Powered by KurooUI WindVersion — Persona 5 Edition)</i></p>
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
  <p><i>Tampilan Responsif Mobile dengan Ikon Bulat Melayang yang Bisa Di-Drag</i></p>
</div>
</details>

---

## ⚡ Cara Menggunakan (Loadstring)

### 1. Paket Lengkap (Universal Script v1.2.1 + KurooEmote)
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

## ✨ Fitur Utama (`v1.2.1`)

### 🧩 Kuroo Universal Script (`KurooUI WindVersion — Persona 5 Edition`)
Dibangun menggunakan [**KurooUI WindVersion**](https://github.com/KurooNeko874/KurooUI_WindVersion) dengan tampilan **Persona 5 (Hitam–Merah–Putih)**, **Arsitektur Modular Ringan** (loader super cepat dengan modul open-source di folder `modules/` & `data/`), Profile Card + halaman **UI Settings** terintegrasi, **Single-Instance Auto-Cleanup Engine**, serta dukungan penuh **PC & Mobile**:

- **Main** — ESP Universal, Anti-AFK, Click Teleport (`Ctrl + Klik` PC), Freecam PC (`WASD` + **`Q`/`E`** naik-turun seperti Roblox Studio + `Shift` boost + Scroll FOV), dan Rejoin Server.
- **Spectate** — Tab khusus dengan **Live Player List** (foto avatar, DisplayName, `@username`) + **pencarian real-time**; klik kartu player langsung masuk target & tekan Spectate.
- **Sync** — Tab khusus **Sync Emote Player** dengan **Live Player List** & pencarian real-time yang sama.
- **Combat** — Pengaturan WalkSpeed (Jalan / Normal / Lari) dengan mode Hold (`Ctrl`/`Shift`) atau Toggle.
- **Animations** — All Emote (KurooEmote terintegrasi), Auto Apply saat Respawn/Rejoin, dan puluhan preset animasi karakter (Idle, Walk, Run, Jump, Fall, Climb, Swim, SwimIdle).
- **Visuals & Season Mode *(BARU di v1.2.1!)***:
  - **4 Season Mode Lengkap** *(100% bisa di-Reset kembali ke map asli)* + **Suara Ambient Otomatis** *(dengan toggle & volume)*:
    - **`Christmas Winter`** — Langit musim dingin, Terrain & Part bersalju putih, **Kristal Salju 3D**, **8 Snowman**, **5 Rusa bergerak + 1 Pet Rudolph** pengikut player, ~15 Kado Natal random, dan suara angin dingin.
    - **`Musim Hujan`** — Langit mendung tebal, **Hujan Deras 5-Emitter** + cipratan tanah, efek **tanah gelap basah mengkilap (*wet ground*)**, dan suara hujan deras.
    - **`Musim Kabut`** — Kabut tebal dengan ambient **hijau gelap + sunset sinematik**, **Cinematic Border hitam atas-bawah**, dan suara angin kabut.
    - **`Musim Gugur (Autumn)`** — Ambient **Golden Brown**, perubahan warna Terrain & dedaunan musim gugur, serta **efek daun kering 3D yang gugur**.
  - **Lighting, Fog & True Darkness** — Slider **Darkness (Kegelapan)** nyata *(Exposure + Ambient + ColorCorrection)*, **Fog Intensity (Kabut)** real-time, Brightness, dan toggle **Cinematic Border** manual.
  - **10 Sky & Shader Preset** — `Realistic RTX Day`, `DLSS / Ultra RTX`, `Cinematic`, `Senja`, `Vibrant Anime`, `Cyberpunk Neon`, `Classical Sunset Sky`, `Pink Sky`, `Cloudy Day Sky`, `Purple Pink Clouds`.
  - **Weather (Cuaca)** — `Normal`, `Hujan (Rain)` deras, `Snowfall (Salju)` 3D, dan `Daun Gugur (Autumn)` 3D + Time Set & UI Theme Switcher.
- **Larping (Visual)** — Body Part (Headless Horseman, Korblox Deathspeaker Kanan/Kiri), Item Visual berefek lengkap dengan pengaturan Scale/Posisi/Rotasi, serta Apply ke Player Lain.
- **Server** — Daftar otomatis **Friendlist yang sedang bermain di server lain pada map yang sama** lengkap dengan foto avatar & tombol **Join** 1-klik tanpa keluar map + Copy Server JobId.
- **Auto-Responsive PC & Mobile** — Ikon bulat melayang (*draggable*) untuk Mobile & PC, tombol `⚙` UI Settings khusus PC (ganti keybind buka UI & toggle show/hide ikon bulat tersimpan otomatis), serta auto-cleanup bersih saat di-execute 2×.

### 🎭 KurooEmote (`v1.1.0`)
Roda emote kustom bergaya radial 8-slot yang menggantikan Emote Wheel bawaan Roblox:
- **62.000+ Emote Marketplace Otomatis** — Mengambil seluruh katalog emote Official & UGC secara otomatis dengan cache JSON lokal (`KurooEmote/emotes_catalog_v2.json`).
- **Pencarian Nama & Asset ID** — Cari emote berdasarkan nama (pencarian cerdas & live Marketplace) atau langsung ketik Asset ID.
- **Pengaturan Kecepatan (`0.05x` – `10x`)** — Atur kecepatan animasi emote secara real-time.
- **Sistem Favorit Permanen (`★`)** — Simpan emote favorit otomatis di perangkat masing-masing user (`KurooEmote/favorites.json`).
- **Ramah Mobile & PC** — Tombol navigasi `<` dan `>` besar, serta tombol ikon senyum (`☺`) yang **bisa di-drag bebas**.
- **Auto-Stop Seperti Bawaan Roblox** — Emote otomatis berhenti saat bergerak, melompat, duduk, atau respawn.

---

## 🎮 Kontrol & Pintasan

| Aksi | PC | Mobile |
| :--- | :--- | :--- |
| **Buka / Tutup Universal UI** | Tombol `K` *(bisa diubah di UI Settings `⚙`)* | Tap ikon bulat floating *(bisa di-drag)* |
| **Freecam Gerak & Naik/Turun** | `WASD` + `E` (Naik) / `Q` (Turun) + `Shift` (Boost) | — *(Khusus PC)* |
| **Buka / Tutup Emote Wheel** | Tombol `.` *(Titik)* atau klik ikon `☺` | Tap ikon `☺` *(bisa ditahan & di-drag)* |
| **Ganti Halaman Emote** | Klik `<` / `>` atau Scroll Mouse | Tap tombol `<` / `>` di samping Favorit |
| **Tutup Emote Wheel** | Tombol `ESC` atau `.` | Tap ikon `☺` |

---

## 🇬🇧 English Version

<details>
<summary><b>Click to expand English documentation</b></summary>

### Overview
**Kuroo Universal Script v1.2.1** is a fast, modular all-in-one Roblox universal utility script powered by [**KurooUI WindVersion (Persona 5 Edition)**](https://github.com/KurooNeko874/KurooUI_WindVersion), bundled with **KurooEmote v1.1.0** — a custom 8-slot radial Emote Wheel featuring **62,000+ Roblox Marketplace emotes** with full **PC & Mobile** support, **open-source modules (`modules/` & `data/`)**, and **No Key System**.

### Quick Start
```lua
-- Full Bundle (Universal Script v1.2.1 + KurooEmote)
loadstring(game:HttpGet("https://raw.githubusercontent.com/KurooNeko874/Universal-Script/refs/heads/main/KurooUniversalScript.lua"))()

-- KurooEmote Standalone Only
loadstring(game:HttpGet("https://raw.githubusercontent.com/KurooNeko874/Universal-Script/refs/heads/main/KurooEmote.lua"))()
```

### Key Features (`v1.2.1`)
- **Persona 5 Edition UI (`KurooUI WindVersion`) & Parallel Modular Loader:** Crisp Black/Red/White aesthetic, lightweight parallel module loading, circular draggable open button, Sidebar Profile Card + PC UI Settings page, and Single-Instance Auto-Cleanup Engine on re-execute.
- **8 Organized Tabs:**
  - `Main` — Universal ESP, Anti-AFK, Click Teleport, Studio-style Freecam (`WASD` + `Q`/`E` vertical), Rejoin.
  - `Spectate` & `Sync` — Dedicated tabs with **Live Player Lists** (Avatar + DisplayName + `@username`) and instant real-time search filtering.
  - `Combat` — WalkSpeed controller (Walk / Normal / Sprint, Hold or Toggle mode).
  - `Animations` — Integrated KurooEmote, Auto-Apply on Respawn/Rejoin, and full animation pack presets.
  - `Visuals & Season Mode` — **4 Reversible Season Modes** (`Christmas Winter` with 3D snow, snowmen, moving deer & Pet Rudolph; `Musim Hujan` with heavy 5-emitter rain & wet ground; `Musim Kabut` with dark-green sunset fog & cinematic letterbox bars; `Musim Gugur (Autumn)` with golden-brown terrain & 3D falling dry leaves), **Season Ambient Audio**, **True Darkness** & **Fog Intensity** sliders, **Cinematic Border** toggle, and **10 curated Sky/Shader presets**.
  - `Larping (Visual)` — Korblox/Headless body parts, visual accessories with live transform sliders, and Apply-to-Player.
  - `Server` — Live Friend Server Browser showing friends playing in other servers of the same map with 1-click **Join** + Copy JobId.

</details>

---

## 📬 Kontak & Komunitas / Contact

Suka dengan script ini? Jangan lupa kasih **⭐ Star** di repository ini dan ikuti update terbaru di:

- **GitHub:** [KurooNeko874](https://github.com/KurooNeko874)
- **TikTok:** [@kuro.neko874](https://www.tiktok.com/@kuro.neko874)
- **Discord:** `kuroneko4411`

---

<div align="center">
  Made with ❤️ by <b>Kuroo</b> • Powered by <a href="https://github.com/KurooNeko874/KurooUI_WindVersion">KurooUI WindVersion</a>
</div>
