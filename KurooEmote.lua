--[[
    ============================================================
    KurooEmote - Roda Emote Universal Marketplace Roblox
    Versi       : 1.1.0
    Pembuat     : Kuroo
    Deskripsi   : UI Emote Wheel kustom (PC & Mobile) dengan:
                  - 62.000+ Emote Marketplace Roblox otomatis
                    lewat katalog JSON + AvatarEditorService
                    bawaan Roblox + pencarian live Marketplace
                  - Cache JSON lokal & daftar Favorit otomatis
                    tersimpan di device masing-masing user
                  - Tombol navigasi < dan > di kiri & kanan
                    tombol Favorit agar mudah dipakai di HP
                  - Ikon emote (☺) bisa di-drag / digeser bebas
                    di layar agar nyaman bagi player Mobile & PC
                  - Pengaturan kecepatan animasi (0.05x - 10x)
                  - Berhenti otomatis saat karakter bergerak
    ============================================================
]]

-- ============================================================
-- 1. DEKLARASI SERVICE ROBLOX (Cukup Sekali di Paling Atas)
-- ============================================================
local Players              = game:GetService("Players")
local UserInputService     = game:GetService("UserInputService")
local TweenService         = game:GetService("TweenService")
local StarterGui           = game:GetService("StarterGui")
local HttpService          = game:GetService("HttpService")
local MarketplaceService   = game:GetService("MarketplaceService")
local AvatarEditorService  = game:GetService("AvatarEditorService")
local CoreGui              = game:GetService("CoreGui")

-- ============================================================
-- 2. PEMBERSIHAN INSTANCE LAMA (Agar Tidak Dobel Jika Dijalankan Ulang)
-- ============================================================
local lingkungan = (type(getgenv) == "function" and getgenv()) or _G
if type(lingkungan.KurooEmoteCleanup) == "function" then
    pcall(lingkungan.KurooEmoteCleanup)
end

-- ============================================================
-- 3. KONSTANTA & PENGATURAN UTAMA
-- ============================================================
local VERSI              = "1.2.0"
local NAMA_FOLDER        = "KurooEmote"
local FILE_FAVORIT       = NAMA_FOLDER .. "/favorites.json"
local FILE_CACHE         = NAMA_FOLDER .. "/emotes_catalog_v2.json"
local FILE_META_CACHE    = NAMA_FOLDER .. "/emotes_catalog_v2_meta.json"
local UMUR_MAKS_CACHE    = 60 * 60 * 24 -- Perbarui cache katalog setiap 24 jam
local MIN_CACHE_VALID    = 50           -- Abaikan cache jika isinya terlalu sedikit
local SLOT_PER_HALAMAN   = 8            -- Jumlah slot dalam 1 lingkaran wheel
local KECEPATAN_MIN      = 0.05         -- Batas kecepatan paling lambat
local KECEPATAN_MAKS     = 10           -- Batas kecepatan paling cepat
local KECEPATAN_DEFAULT  = 1            -- Kecepatan normal

-- Daftar URL database JSON katalog emote Marketplace (62.000+ emote ter-update otomatis)
local URL_JSON_EMOTE_REMOTE = {
    "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json",
    "https://raw.githubusercontent.com/7yd7/sniper-Emote/test/EmoteSniper.json",
}

-- Palet warna utama UI
local WARNA = {
    LatarWheel     = Color3.fromRGB(36, 37, 42),
    GarisWheel     = Color3.fromRGB(70, 72, 82),
    LatarTengah    = Color3.fromRGB(16, 17, 21),
    GarisTengah    = Color3.fromRGB(58, 60, 70),
    GarisPembagi   = Color3.fromRGB(220, 224, 235),
    SlotNormal     = Color3.fromRGB(48, 50, 58),
    SlotHover      = Color3.fromRGB(78, 84, 102),
    SlotModeFav    = Color3.fromRGB(95, 80, 32),
    SlotModeUnfav  = Color3.fromRGB(110, 42, 46),
    LatarPanel     = Color3.fromRGB(20, 21, 26),
    GarisPanel     = Color3.fromRGB(62, 65, 78),
    TombolNav      = Color3.fromRGB(24, 26, 33),
    TombolNavHover = Color3.fromRGB(44, 48, 60),
    Aksen          = Color3.fromRGB(0, 207, 255),
    Emas           = Color3.fromRGB(255, 204, 51),
    Bahaya         = Color3.fromRGB(245, 78, 86),
    Sukses         = Color3.fromRGB(64, 214, 128),
    TeksUtama      = Color3.fromRGB(245, 247, 252),
    TeksSekunder   = Color3.fromRGB(168, 174, 190),
    TeksRedup      = Color3.fromRGB(115, 120, 136),
}

-- Emote cadangan awal (hanya muncul sesaat saat katalog sedang diunduh atau saat offline)
local EMOTE_CADANGAN = {
    { id = 3360686498, name = "Stadium" },
    { id = 3360692915, name = "Tilt" },
    { id = 3576968026, name = "Shrug" },
    { id = 3576686446, name = "Hello" },
    { id = 3360689775, name = "Salute" },
    { id = 3576823880, name = "Agree" },
    { id = 3576717965, name = "Disagree" },
    { id = 3360694441, name = "Applaud" },
    { id = 3576721660, name = "Shy" },
    { id = 3576719440, name = "Sleep" },
    { id = 3576745472, name = "Hero Landing" },
    { id = 3696761354, name = "Line Dance" },
    { id = 3696763549, name = "Heisman Pose" },
    { id = 3994130516, name = "Hype Dance" },
    { id = 4049646104, name = "Curtsy" },
    { id = 4212496830, name = "Cower" },
}

-- ============================================================
-- 4. FUNGSI BANTUAN UMUM
-- ============================================================
local PemainLokal = Players.LocalPlayer

-- Selalu ambil kamera terbaru agar tidak error saat respawn / ganti kamera
local function ambilKamera()
    return workspace.CurrentCamera
end

-- Deteksi apakah user memakai perangkat Mobile (HP/Tablet)
local function apakahPerangkatMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Buat URL gambar thumbnail resmi Roblox berdasarkan Asset ID emote
local function buatUrlThumbnail(assetId)
    return "rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=150&h=150"
end

-- Batasi angka kecepatan agar tetap berada di rentang 0.05 - 10
local function batasiKecepatan(nilai)
    local angka = tonumber(nilai)
    if not angka or angka ~= angka then
        return KECEPATAN_DEFAULT
    end
    return math.clamp(angka, KECEPATAN_MIN, KECEPATAN_MAKS)
end

-- Rapikan tampilan angka kecepatan (maksimal 2 angka di belakang koma)
local function formatKecepatan(nilai)
    local dibulatkan = math.floor(nilai * 100 + 0.5) / 100
    return tostring(dibulatkan)
end

-- Format angka ribuan dengan titik (contoh: 62560 -> "62.560")
local function formatAngka(n)
    local teks = tostring(math.floor(tonumber(n) or 0))
    local hasil = teks:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return hasil
end

-- Tentukan tempat aman untuk menaruh ScreenGui (gethui -> CoreGui -> PlayerGui)
local function ambilIndukGui()
    if type(gethui) == "function" then
        local ok, hasil = pcall(gethui)
        if ok and hasil then
            return hasil
        end
    end
    local ok, _ = pcall(function()
        return CoreGui.Name
    end)
    if ok then
        return CoreGui
    end
    return PemainLokal:WaitForChild("PlayerGui")
end

-- ============================================================
-- 5. PENYIMPANAN FILE LOKAL (BACA & TULIS JSON DI DEVICE USER)
-- ============================================================
local punyaAksesFile = (type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function")

-- Pastikan folder "KurooEmote" sudah dibuat sebelum menulis file
local function pastikanFolderAda()
    if not punyaAksesFile then return end
    if type(isfolder) == "function" and type(makefolder) == "function" then
        pcall(function()
            if not isfolder(NAMA_FOLDER) then
                makefolder(NAMA_FOLDER)
            end
        end)
    end
end

local function tulisFileMentah(jalur, isi)
    if not punyaAksesFile or type(isi) ~= "string" then return false end
    pastikanFolderAda()
    local ok = pcall(writefile, jalur, isi)
    return ok
end

local function bacaFileMentah(jalur)
    if not punyaAksesFile then return nil end
    local okCek, ada = pcall(isfile, jalur)
    if not okCek or not ada then return nil end
    local okBaca, isi = pcall(readfile, jalur)
    if not okBaca or type(isi) ~= "string" or isi == "" then return nil end
    return isi
end

local function tulisFileJson(jalur, data)
    if not punyaAksesFile then return false end
    pastikanFolderAda()
    local ok, jsonTeks = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false end
    return tulisFileMentah(jalur, jsonTeks)
end

local function bacaFileJson(jalur)
    local mentah = bacaFileMentah(jalur)
    if not mentah then return nil end
    local ok, hasil = pcall(HttpService.JSONDecode, HttpService, mentah)
    if not ok then return nil end
    return hasil
end

-- ============================================================
-- 6. PENGAMBILAN DATA HTTP (MULTI-METODE & VALIDASI JSON)
-- ============================================================
local function ambilFungsiRequest()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(http) == "table" and type(http.request) == "function" then return http.request end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    return nil
end

-- Ambil isi teks mentah dari URL (pakai game:HttpGet lalu fallback ke request)
local function ambilTeksHttp(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(res) == "string" and #res > 20 then
        return res, 200
    end

    local fnReq = ambilFungsiRequest()
    if fnReq then
        local reqOk, resp = pcall(fnReq, {
            Url = url,
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json, text/plain, */*",
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            },
        })
        if reqOk and type(resp) == "table" and type(resp.Body) == "string" and #resp.Body > 20 then
            return resp.Body, tonumber(resp.StatusCode) or 200
        end
    end

    return nil, nil
end

-- Ubah string JSON katalog menjadi tabel daftar emote + cursor halaman berikutnya
local function uraiJsonKatalog(mentah)
    if type(mentah) ~= "string" or #mentah < 2 then return nil, nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, mentah)
    if ok and type(data) == "table" then
        if type(data.data) == "table" then
            return data.data, data.nextPageCursor
        elseif #data > 0 and type(data[1]) == "table" then
            return data, nil
        end
    end
    return nil, nil
end

-- Ambil data katalog via HTTP API (request executor terlebih dahulu, lalu HttpGet)
local function ambilDataKatalogHttp(url)
    local fnReq = ambilFungsiRequest()
    local kodeStatus = nil

    if fnReq then
        local reqOk, resp = pcall(fnReq, {
            Url = url,
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json",
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            },
        })
        if reqOk and type(resp) == "table" then
            kodeStatus = tonumber(resp.StatusCode)
            local daftar, cursor = uraiJsonKatalog(resp.Body)
            if daftar then
                return daftar, cursor, kodeStatus
            end
        end
    end

    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(res) == "string" then
        local daftar, cursor = uraiJsonKatalog(res)
        if daftar then
            return daftar, cursor, 200
        end
    end

    return nil, nil, kodeStatus
end

-- ============================================================
-- 7. MANAJEMEN DATA & STATUS (STATE)
-- ============================================================
local Status = {
    Terbuka             = false,
    SudahDihancurkan    = false,
    ModeTampilan        = "Semua",   -- "Semua" atau "Favorit"
    ModeBintang         = false,     -- true = Tambah Fav (di Semua) / Hapus Fav (di Favorit)
    Kecepatan           = KECEPATAN_DEFAULT,
    KataKunciCari       = "",
    HalamanSekarang     = 1,
    TotalHalaman        = 1,

    SemuaEmote          = {},        -- Daftar { id = angka, name = string, l = hurufKecil }
    SetSemuaEmote       = {},        -- Indeks cepat [id] = true agar tidak duplikat
    DaftarFavorit       = {},        -- Daftar emote favorit user
    SetFavorit          = {},        -- Indeks cepat [id] = true untuk cek status favorit
    DaftarTampil        = {},        -- Daftar emote yang sedang ditampilkan di wheel
    HasilCariLive       = {},        -- Hasil pencarian langsung dari Marketplace
    KataKunciLive       = "",        -- Kata kunci yang cocok dengan HasilCariLive
    CacheNamaId         = {},        -- Cache nama emote hasil pencarian berdasarkan ID
    CacheAnimId         = {},        -- Cache konversi AssetId -> AnimationId

    SedangMuatKatalog   = false,
    MasihPakaiCadangan  = true,
    IdDebounceCari      = 0,
    IdPermintaanCari    = 0,

    PosisiIkonKustom    = false,     -- Menjadi true jika user menggeser (drag) ikon senyum

    TrackAktif          = nil,       -- AnimationTrack emote yang sedang diputar
    IdEmoteAktif        = nil,
    DaftarKoneksi       = {},        -- Semua koneksi event global (untuk dibersihkan nanti)
    KoneksiKarakter     = {},        -- Koneksi event khusus karakter saat ini
}

-- Simpan koneksi event agar mudah di-Disconnect saat script dimatikan/dijalankan ulang
local function catatKoneksi(koneksi)
    if koneksi then
        table.insert(Status.DaftarKoneksi, koneksi)
    end
    return koneksi
end

local function bersihkanKoneksiKarakter()
    for _, koneksi in ipairs(Status.KoneksiKarakter) do
        pcall(function() koneksi:Disconnect() end)
    end
    table.clear(Status.KoneksiKarakter)
end

-- Muat daftar Favorit dari file JSON lokal
local function muatFavorit()
    local data = bacaFileJson(FILE_FAVORIT)
    Status.DaftarFavorit = {}
    Status.SetFavorit = {}
    if type(data) == "table" then
        for _, item in ipairs(data) do
            local id = tonumber(item.id)
            local nama = tostring(item.name or ("Emote #" .. tostring(id)))
            if id and not Status.SetFavorit[id] then
                Status.SetFavorit[id] = true
                table.insert(Status.DaftarFavorit, {
                    id   = id,
                    name = nama,
                    l    = string.lower(nama),
                })
            end
        end
    end
end

-- Simpan daftar Favorit ke file JSON lokal
local function simpanFavorit()
    local ringkas = {}
    for _, item in ipairs(Status.DaftarFavorit) do
        table.insert(ringkas, { id = item.id, name = item.name })
    end
    tulisFileJson(FILE_FAVORIT, ringkas)
end

-- Tambahkan 1 emote ke daftar utama jika belum ada
local function tambahEmoteKeDaftar(id, nama)
    id = tonumber(id)
    if not id or Status.SetSemuaEmote[id] then return false end
    local namaBersih = tostring(nama or ("Emote #" .. tostring(id)))
    Status.SetSemuaEmote[id] = true
    table.insert(Status.SemuaEmote, {
        id   = id,
        name = namaBersih,
        l    = string.lower(namaBersih),
    })
    return true
end

-- Masukkan ribuan emote sekaligus secara bertahap (chunking) agar game tidak lag/freeze
local function masukkanArrayEmote(daftarItem, gantiCadangan)
    if type(daftarItem) ~= "table" or #daftarItem == 0 then return 0 end

    if gantiCadangan and Status.MasihPakaiCadangan then
        Status.SemuaEmote = {}
        Status.SetSemuaEmote = {}
        Status.MasihPakaiCadangan = false
    end

    local jumlahBaru = 0
    for idx = 1, #daftarItem do
        if Status.SudahDihancurkan then break end
        local item = daftarItem[idx]
        if type(item) == "table" then
            local id = tonumber(item.id or item.Id)
            local nama = item.name or item.Name
            if id and not Status.SetSemuaEmote[id] then
                local namaBersih = tostring(nama or ("Emote #" .. tostring(id)))
                Status.SetSemuaEmote[id] = true
                Status.SemuaEmote[#Status.SemuaEmote + 1] = {
                    id   = id,
                    name = namaBersih,
                    l    = string.lower(namaBersih),
                }
                jumlahBaru = jumlahBaru + 1
            end
        end
        -- Beri jeda 1 frame setiap 6.000 item agar FPS tetap mulus di HP
        if idx % 6000 == 0 then
            task.wait()
        end
    end
    return jumlahBaru
end

-- Muat katalog emote dari cache JSON lokal jika tersedia
local function muatCacheEmote()
    local mentah = bacaFileMentah(FILE_CACHE)
    if not mentah then return false, false end

    local daftar = uraiJsonKatalog(mentah)
    if not daftar or #daftar < MIN_CACHE_VALID then
        return false, false
    end

    masukkanArrayEmote(daftar, true)

    local meta = bacaFileJson(FILE_META_CACHE)
    local waktuUpdate = (type(meta) == "table" and tonumber(meta.updatedAt)) or 0
    local masihSegar = (os.time() - waktuUpdate) < UMUR_MAKS_CACHE
    return (#Status.SemuaEmote >= MIN_CACHE_VALID), masihSegar
end

-- Simpan JSON mentah hasil unduhan langsung ke file cache lokal
local function simpanCacheMentah(jsonMentah)
    if type(jsonMentah) ~= "string" or #jsonMentah < 500 then return end
    tulisFileMentah(FILE_CACHE, jsonMentah)
    tulisFileJson(FILE_META_CACHE, {
        version   = VERSI,
        updatedAt = os.time(),
        count     = #Status.SemuaEmote,
    })
end

-- Simpan tabel katalog emote ke file cache lokal
local function simpanCacheTabel()
    if #Status.SemuaEmote < MIN_CACHE_VALID then return end
    local ringkas = {}
    for idx = 1, #Status.SemuaEmote do
        local item = Status.SemuaEmote[idx]
        ringkas[idx] = { id = item.id, name = item.name }
    end
    tulisFileJson(FILE_CACHE, { data = ringkas })
    tulisFileJson(FILE_META_CACHE, {
        version   = VERSI,
        updatedAt = os.time(),
        count     = #Status.SemuaEmote,
    })
end

-- ============================================================
-- 8. MATIKAN EMOTE WHEEL BAWAAN ROBLOX
-- ============================================================
local function matikanEmoteBawaan()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
    end)
end

matikanEmoteBawaan()

-- ============================================================
-- 9. MESIN PEMUTAR ANIMASI EMOTE (BERHENTI OTOMATIS SAAT GERAK)
-- ============================================================
local tampilkanNotif -- Deklarasi awal agar bisa dipanggil sebelum didefinisikan

local function hentikanEmoteAktif(waktuFade)
    if Status.TrackAktif then
        pcall(function()
            Status.TrackAktif:Stop(waktuFade or 0.15)
        end)
        Status.TrackAktif = nil
        Status.IdEmoteAktif = nil
    end
end

-- Pantau pergerakan karakter agar emote otomatis berhenti seperti bawaan Roblox
local function pasangDeteksiGerakKarakter(karakter)
    bersihkanKoneksiKarakter()
    if not karakter then return end

    local humanoid = karakter:FindFirstChildOfClass("Humanoid") or karakter:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    -- Berhenti saat mulai berjalan / menggerakkan analog atau WASD
    table.insert(Status.KoneksiKarakter, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        if Status.TrackAktif and humanoid.MoveDirection.Magnitude > 0.05 then
            hentikanEmoteAktif(0.15)
        end
    end))

    -- Berhenti saat melompat
    table.insert(Status.KoneksiKarakter, humanoid.Jumping:Connect(function(aktif)
        if aktif and Status.TrackAktif then
            hentikanEmoteAktif(0.1)
        end
    end))

    -- Berhenti saat memanjat, berenang, duduk, jatuh, ragdoll, atau mati
    table.insert(Status.KoneksiKarakter, humanoid.StateChanged:Connect(function(_, statusBaru)
        if not Status.TrackAktif then return end
        if statusBaru == Enum.HumanoidStateType.Climbing
            or statusBaru == Enum.HumanoidStateType.Swimming
            or statusBaru == Enum.HumanoidStateType.Seated
            or statusBaru == Enum.HumanoidStateType.FallingDown
            or statusBaru == Enum.HumanoidStateType.Ragdoll
            or statusBaru == Enum.HumanoidStateType.Dead
            or statusBaru == Enum.HumanoidStateType.Freefall
        then
            hentikanEmoteAktif(0.15)
        end
    end))

    table.insert(Status.KoneksiKarakter, humanoid.Died:Connect(function()
        hentikanEmoteAktif(0)
    end))
end

if PemainLokal.Character then
    pasangDeteksiGerakKarakter(PemainLokal.Character)
end
catatKoneksi(PemainLokal.CharacterAdded:Connect(function(karakterBaru)
    hentikanEmoteAktif(0)
    pasangDeteksiGerakKarakter(karakterBaru)
end))

-- Ambil AnimationId dari Asset Emote Marketplace menggunakan game:GetObjects
local function ambilAnimationId(assetId)
    assetId = tonumber(assetId)
    if not assetId then return nil end

    if Status.CacheAnimId[assetId] then
        return Status.CacheAnimId[assetId]
    end

    local ok, daftarObjek = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)

    if ok and type(daftarObjek) == "table" and #daftarObjek > 0 then
        local animIdKetemu = nil
        for _, obj in ipairs(daftarObjek) do
            if obj:IsA("Animation") and obj.AnimationId ~= "" then
                animIdKetemu = obj.AnimationId
            else
                local anim = obj:FindFirstChildWhichIsA("Animation", true)
                if anim and anim.AnimationId ~= "" then
                    animIdKetemu = anim.AnimationId
                end
            end
            pcall(function() obj:Destroy() end)
            if animIdKetemu then break end
        end
        if animIdKetemu then
            Status.CacheAnimId[assetId] = animIdKetemu
            return animIdKetemu
        end
    end

    return nil
end

-- Atur kecepatan dan pantau saat track animasi selesai
local function ikatSiklusTrack(track, idEmote)
    Status.TrackAktif = track
    Status.IdEmoteAktif = idEmote
    pcall(function()
        track:AdjustSpeed(Status.Kecepatan)
    end)
    track.Stopped:Connect(function()
        if Status.TrackAktif == track then
            Status.TrackAktif = nil
            Status.IdEmoteAktif = nil
        end
    end)
end

-- Putar emote dengan 3 tahap cadangan agar kompatibel dengan semua Emote Official, UGC, & AnimationId
local function putarEmote(itemEmote)
    if not itemEmote or not itemEmote.id then return end

    local karakter = PemainLokal.Character
    if not karakter then
        tampilkanNotif("Karakter belum siap!", WARNA.Bahaya)
        return
    end

    local humanoid = karakter:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        tampilkanNotif("Tidak bisa melakukan emote saat ini.", WARNA.Bahaya)
        return
    end

    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        tampilkanNotif("Avatar R6 terdeteksi — Emote Marketplace membutuhkan R15.", WARNA.Emas)
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    hentikanEmoteAktif(0.1)

    task.spawn(function()
        local karSaatIni = PemainLokal.Character
        local humSaatIni = karSaatIni and karSaatIni:FindFirstChildOfClass("Humanoid")
        local animSaatIni = humSaatIni and humSaatIni:FindFirstChildOfClass("Animator")
        if not humSaatIni or humSaatIni.Health <= 0 or not animSaatIni or Status.SudahDihancurkan then return end

        -- Tahap 1: Ekstrak AnimationId dari asset via game:GetObjects lalu jalankan lewat Animator
        local animId = ambilAnimationId(itemEmote.id)
        if animId then
            local animObj = Instance.new("Animation")
            animObj.AnimationId = animId
            local okMuat, track = pcall(function()
                return animSaatIni:LoadAnimation(animObj)
            end)
            animObj:Destroy()

            if okMuat and track then
                track.Priority = Enum.AnimationPriority.Action
                track:Play(0.1)
                ikatSiklusTrack(track, itemEmote.id)
                return
            end
        end

        -- Tahap 2: Gunakan fungsi bawaan Roblox HumanoidDescription:AddEmote + PlayEmoteAndGetAnimTrackById
        local okNative, hasil1, hasil2 = pcall(function()
            local deskripsi = humSaatIni:FindFirstChildOfClass("HumanoidDescription")
            if deskripsi then
                deskripsi:AddEmote(tostring(itemEmote.name or itemEmote.id), itemEmote.id)
            end
            return humSaatIni:PlayEmoteAndGetAnimTrackById(itemEmote.id)
        end)

        local trackNative = nil
        if okNative then
            if typeof(hasil1) == "Instance" and hasil1:IsA("AnimationTrack") then
                trackNative = hasil1
            elseif typeof(hasil2) == "Instance" and hasil2:IsA("AnimationTrack") then
                trackNative = hasil2
            end
        end

        if trackNative then
            ikatSiklusTrack(trackNative, itemEmote.id)
            return
        end

        -- Tahap 3: Cadangan terakhir jika user memasukkan AnimationId mentah secara langsung
        local animMentah = Instance.new("Animation")
        animMentah.AnimationId = "rbxassetid://" .. tostring(itemEmote.id)
        local okMentah, trackMentah = pcall(function()
            return animSaatIni:LoadAnimation(animMentah)
        end)
        animMentah:Destroy()

        if okMentah and trackMentah then
            trackMentah.Priority = Enum.AnimationPriority.Action
            trackMentah:Play(0.1)
            ikatSiklusTrack(trackMentah, itemEmote.id)
        else
            tampilkanNotif("Gagal memutar emote: " .. tostring(itemEmote.name), WARNA.Bahaya)
        end
    end)
end

-- ============================================================
-- 10. PEMBUATAN ANTARMUKA UI (RODA EMOTE + TOMBOL TOPBAR DRAGGABLE)
-- ============================================================
local IndukGui = ambilIndukGui()
local LayarGui = Instance.new("ScreenGui")
LayarGui.Name = "KurooEmote_UI"
LayarGui.ResetOnSpawn = false
LayarGui.IgnoreGuiInset = true
LayarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LayarGui.DisplayOrder = 100
LayarGui.Parent = IndukGui

-- ------------------------------------------------------------
-- 10A. Wadah Notifikasi Melayang (Toast)
-- ------------------------------------------------------------
local WadahNotif = Instance.new("Frame")
WadahNotif.Name = "WadahNotif"
WadahNotif.AnchorPoint = Vector2.new(0.5, 0)
WadahNotif.Position = UDim2.new(0.5, 0, 0, 68)
WadahNotif.Size = UDim2.new(0, 380, 0, 200)
WadahNotif.BackgroundTransparency = 1
WadahNotif.ZIndex = 50
WadahNotif.Parent = LayarGui

local LayoutNotif = Instance.new("UIListLayout")
LayoutNotif.SortOrder = Enum.SortOrder.LayoutOrder
LayoutNotif.HorizontalAlignment = Enum.HorizontalAlignment.Center
LayoutNotif.Padding = UDim.new(0, 6)
LayoutNotif.Parent = WadahNotif

tampilkanNotif = function(pesan, warnaAksen)
    if Status.SudahDihancurkan or not WadahNotif.Parent then return end
    warnaAksen = warnaAksen or WARNA.Aksen

    local kartu = Instance.new("Frame")
    kartu.Size = UDim2.new(0, 0, 0, 34)
    kartu.AutomaticSize = Enum.AutomaticSize.X
    kartu.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
    kartu.BackgroundTransparency = 0.08
    kartu.BorderSizePixel = 0
    kartu.ZIndex = 51
    kartu.Parent = WadahNotif

    local sudut = Instance.new("UICorner")
    sudut.CornerRadius = UDim.new(0, 10)
    sudut.Parent = kartu

    local garis = Instance.new("UIStroke")
    garis.Color = warnaAksen
    garis.Thickness = 1.4
    garis.Transparency = 0.25
    garis.Parent = kartu

    local jarak = Instance.new("UIPadding")
    jarak.PaddingLeft = UDim.new(0, 14)
    jarak.PaddingRight = UDim.new(0, 14)
    jarak.Parent = kartu

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 0, 1, 0)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = WARNA.TeksUtama
    label.Text = tostring(pesan)
    label.ZIndex = 52
    label.Parent = kartu

    kartu.BackgroundTransparency = 1
    label.TextTransparency = 1
    garis.Transparency = 1

    TweenService:Create(kartu, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.08,
    }):Play()
    TweenService:Create(label, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
    TweenService:Create(garis, TweenInfo.new(0.18), { Transparency = 0.25 }):Play()

    task.delay(2.4, function()
        if not kartu or not kartu.Parent then return end
        local animKeluar = TweenService:Create(kartu, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
        TweenService:Create(label, TweenInfo.new(0.22), { TextTransparency = 1 }):Play()
        TweenService:Create(garis, TweenInfo.new(0.22), { Transparency = 1 }):Play()
        animKeluar:Play()
        animKeluar.Completed:Wait()
        if kartu and kartu.Parent then
            kartu:Destroy()
        end
    end)
end

-- ------------------------------------------------------------
-- 10B. Tombol Lingkaran Ikon Senyum (☺) — Bisa Di-Drag di HP & PC
-- ------------------------------------------------------------
local TombolIkonEmote = Instance.new("TextButton")
TombolIkonEmote.Name = "TombolIkonEmote"
TombolIkonEmote.Text = ""
TombolIkonEmote.AutoButtonColor = false
TombolIkonEmote.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
TombolIkonEmote.BackgroundTransparency = 0.18
TombolIkonEmote.BorderSizePixel = 0
TombolIkonEmote.ZIndex = 40
TombolIkonEmote.Parent = LayarGui

local SudutIkonEmote = Instance.new("UICorner")
SudutIkonEmote.CornerRadius = UDim.new(1, 0)
SudutIkonEmote.Parent = TombolIkonEmote

local GarisIkonEmote = Instance.new("UIStroke")
GarisIkonEmote.Color = Color3.fromRGB(95, 100, 118)
GarisIkonEmote.Thickness = 1.4
GarisIkonEmote.Transparency = 0.35
GarisIkonEmote.Parent = TombolIkonEmote

local LabelSenyum = Instance.new("TextLabel")
LabelSenyum.Name = "IkonSenyum"
LabelSenyum.BackgroundTransparency = 1
LabelSenyum.Size = UDim2.new(1, 0, 1, 0)
LabelSenyum.Position = UDim2.new(0, 0, 0, -1)
LabelSenyum.Font = Enum.Font.GothamBold
LabelSenyum.Text = "☺"
LabelSenyum.TextColor3 = WARNA.TeksUtama
LabelSenyum.TextScaled = false
LabelSenyum.TextSize = 24
LabelSenyum.ZIndex = 41
LabelSenyum.Parent = TombolIkonEmote

-- ------------------------------------------------------------
-- 10C. Wadah Utama Roda Emote (Otomatis Menyesuaikan Ukuran Layar)
-- ------------------------------------------------------------
local WadahWheel = Instance.new("Frame")
WadahWheel.Name = "WadahWheel"
WadahWheel.AnchorPoint = Vector2.new(0.5, 0.5)
WadahWheel.Position = UDim2.new(0.5, 0, 0.5, 4)
WadahWheel.Size = UDim2.new(0, 560, 0, 598)
WadahWheel.BackgroundTransparency = 1
WadahWheel.Visible = false
WadahWheel.ZIndex = 10
WadahWheel.Parent = LayarGui

local SkalaWheel = Instance.new("UIScale")
SkalaWheel.Scale = 1
SkalaWheel.Parent = WadahWheel

-- ------------------------------------------------------------
-- 10D. Watermark "KurooEmote" di Atas Pencarian
-- ------------------------------------------------------------
local LabelWatermark = Instance.new("TextLabel")
LabelWatermark.Name = "Watermark"
LabelWatermark.AnchorPoint = Vector2.new(0.5, 0)
LabelWatermark.Position = UDim2.new(0.5, 0, 0, 0)
LabelWatermark.Size = UDim2.new(0, 320, 0, 22)
LabelWatermark.BackgroundTransparency = 1
LabelWatermark.Font = Enum.Font.GothamBold
LabelWatermark.TextSize = 15
LabelWatermark.TextColor3 = WARNA.TeksUtama
LabelWatermark.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
LabelWatermark.TextStrokeTransparency = 0.55
LabelWatermark.RichText = true
LabelWatermark.Text = '<font color="#00CFFF">Kuroo</font>Emote  <font size="11" color="#A8AEBE">v' .. VERSI .. "</font>"
LabelWatermark.ZIndex = 15
LabelWatermark.Parent = WadahWheel

-- ------------------------------------------------------------
-- 10E. Kolom Pencarian Nama Emote / ID Emote di Atas Wheel
-- ------------------------------------------------------------
local BingkaiCari = Instance.new("Frame")
BingkaiCari.Name = "BingkaiCari"
BingkaiCari.AnchorPoint = Vector2.new(0.5, 0)
BingkaiCari.Position = UDim2.new(0.5, 0, 0, 26)
BingkaiCari.Size = UDim2.new(0, 310, 0, 36)
BingkaiCari.BackgroundColor3 = WARNA.LatarPanel
BingkaiCari.BackgroundTransparency = 0.1
BingkaiCari.BorderSizePixel = 0
BingkaiCari.ZIndex = 15
BingkaiCari.Parent = WadahWheel

local SudutCari = Instance.new("UICorner")
SudutCari.CornerRadius = UDim.new(0, 18)
SudutCari.Parent = BingkaiCari

local GarisCari = Instance.new("UIStroke")
GarisCari.Color = WARNA.GarisPanel
GarisCari.Thickness = 1.3
GarisCari.Parent = BingkaiCari

local IkonCari = Instance.new("TextLabel")
IkonCari.BackgroundTransparency = 1
IkonCari.Position = UDim2.new(0, 12, 0, 0)
IkonCari.Size = UDim2.new(0, 20, 1, 0)
IkonCari.Font = Enum.Font.GothamBold
IkonCari.TextSize = 14
IkonCari.TextColor3 = WARNA.TeksSekunder
IkonCari.Text = "🔍"
IkonCari.ZIndex = 16
IkonCari.Parent = BingkaiCari

local KotakCari = Instance.new("TextBox")
KotakCari.Name = "KotakCari"
KotakCari.BackgroundTransparency = 1
KotakCari.Position = UDim2.new(0, 36, 0, 0)
KotakCari.Size = UDim2.new(1, -68, 1, 0)
KotakCari.Font = Enum.Font.Gotham
KotakCari.TextSize = 13
KotakCari.TextColor3 = WARNA.TeksUtama
KotakCari.PlaceholderColor3 = WARNA.TeksRedup
KotakCari.PlaceholderText = "Cari nama emote / masukkan ID..."
KotakCari.Text = ""
KotakCari.ClearTextOnFocus = false
KotakCari.TextXAlignment = Enum.TextXAlignment.Left
KotakCari.ZIndex = 16
KotakCari.Parent = BingkaiCari

local TombolHapusCari = Instance.new("TextButton")
TombolHapusCari.Name = "TombolHapusCari"
TombolHapusCari.AnchorPoint = Vector2.new(1, 0.5)
TombolHapusCari.Position = UDim2.new(1, -8, 0.5, 0)
TombolHapusCari.Size = UDim2.new(0, 22, 0, 22)
TombolHapusCari.BackgroundColor3 = Color3.fromRGB(45, 47, 56)
TombolHapusCari.BackgroundTransparency = 0.3
TombolHapusCari.Font = Enum.Font.GothamBold
TombolHapusCari.TextSize = 12
TombolHapusCari.TextColor3 = WARNA.TeksSekunder
TombolHapusCari.Text = "×"
TombolHapusCari.Visible = false
TombolHapusCari.ZIndex = 17
TombolHapusCari.Parent = BingkaiCari

local SudutHapusCari = Instance.new("UICorner")
SudutHapusCari.CornerRadius = UDim.new(1, 0)
SudutHapusCari.Parent = TombolHapusCari

-- ------------------------------------------------------------
-- 10F. Panel Kiri: Input Kecepatan Emote (0.05x - 10x)
-- ------------------------------------------------------------
local PanelKecepatan = Instance.new("Frame")
PanelKecepatan.Name = "PanelKecepatan"
PanelKecepatan.AnchorPoint = Vector2.new(1, 0.5)
PanelKecepatan.Position = UDim2.new(0.5, -186, 0, 250)
PanelKecepatan.Size = UDim2.new(0, 86, 0, 76)
PanelKecepatan.BackgroundColor3 = WARNA.LatarPanel
PanelKecepatan.BackgroundTransparency = 0.12
PanelKecepatan.BorderSizePixel = 0
PanelKecepatan.ZIndex = 15
PanelKecepatan.Parent = WadahWheel

local SudutPanelKecepatan = Instance.new("UICorner")
SudutPanelKecepatan.CornerRadius = UDim.new(0, 14)
SudutPanelKecepatan.Parent = PanelKecepatan

local GarisPanelKecepatan = Instance.new("UIStroke")
GarisPanelKecepatan.Color = WARNA.GarisPanel
GarisPanelKecepatan.Thickness = 1.3
GarisPanelKecepatan.Parent = PanelKecepatan

local JudulKecepatan = Instance.new("TextLabel")
JudulKecepatan.BackgroundTransparency = 1
JudulKecepatan.Position = UDim2.new(0, 0, 0, 6)
JudulKecepatan.Size = UDim2.new(1, 0, 0, 16)
JudulKecepatan.Font = Enum.Font.GothamBold
JudulKecepatan.TextSize = 10
JudulKecepatan.TextColor3 = WARNA.TeksSekunder
JudulKecepatan.Text = "KECEPATAN"
JudulKecepatan.ZIndex = 16
JudulKecepatan.Parent = PanelKecepatan

local KotakKecepatan = Instance.new("TextBox")
KotakKecepatan.Name = "KotakKecepatan"
KotakKecepatan.AnchorPoint = Vector2.new(0.5, 0)
KotakKecepatan.Position = UDim2.new(0.5, 0, 0, 24)
KotakKecepatan.Size = UDim2.new(1, -18, 0, 28)
KotakKecepatan.BackgroundColor3 = Color3.fromRGB(32, 34, 42)
KotakKecepatan.BorderSizePixel = 0
KotakKecepatan.Font = Enum.Font.GothamBold
KotakKecepatan.TextSize = 14
KotakKecepatan.TextColor3 = WARNA.Aksen
KotakKecepatan.PlaceholderColor3 = WARNA.TeksRedup
KotakKecepatan.PlaceholderText = "1"
KotakKecepatan.Text = tostring(KECEPATAN_DEFAULT)
KotakKecepatan.ClearTextOnFocus = false
KotakKecepatan.ZIndex = 16
KotakKecepatan.Parent = PanelKecepatan

local SudutKotakKecepatan = Instance.new("UICorner")
SudutKotakKecepatan.CornerRadius = UDim.new(0, 8)
SudutKotakKecepatan.Parent = KotakKecepatan

local PetunjukKecepatan = Instance.new("TextLabel")
PetunjukKecepatan.BackgroundTransparency = 1
PetunjukKecepatan.Position = UDim2.new(0, 0, 1, -18)
PetunjukKecepatan.Size = UDim2.new(1, 0, 0, 14)
PetunjukKecepatan.Font = Enum.Font.Gotham
PetunjukKecepatan.TextSize = 9
PetunjukKecepatan.TextColor3 = WARNA.TeksRedup
PetunjukKecepatan.Text = "0.05 - 10x"
PetunjukKecepatan.ZIndex = 16
PetunjukKecepatan.Parent = PanelKecepatan

-- ------------------------------------------------------------
-- 10G. Panel Kanan: Tombol Bintang (Mode Favorit / Unfav)
-- ------------------------------------------------------------
local PanelBintang = Instance.new("Frame")
PanelBintang.Name = "PanelBintang"
PanelBintang.AnchorPoint = Vector2.new(0, 0.5)
PanelBintang.Position = UDim2.new(0.5, 186, 0, 250)
PanelBintang.Size = UDim2.new(0, 74, 0, 76)
PanelBintang.BackgroundTransparency = 1
PanelBintang.ZIndex = 15
PanelBintang.Parent = WadahWheel

local TombolBintang = Instance.new("TextButton")
TombolBintang.Name = "TombolBintang"
TombolBintang.AnchorPoint = Vector2.new(0.5, 0)
TombolBintang.Position = UDim2.new(0.5, 0, 0, 4)
TombolBintang.Size = UDim2.new(0, 52, 0, 52)
TombolBintang.BackgroundColor3 = WARNA.LatarPanel
TombolBintang.BackgroundTransparency = 0.1
TombolBintang.AutoButtonColor = false
TombolBintang.Font = Enum.Font.GothamBold
TombolBintang.TextSize = 26
TombolBintang.TextColor3 = WARNA.TeksSekunder
TombolBintang.Text = "★"
TombolBintang.ZIndex = 16
TombolBintang.Parent = PanelBintang

local SudutTombolBintang = Instance.new("UICorner")
SudutTombolBintang.CornerRadius = UDim.new(1, 0)
SudutTombolBintang.Parent = TombolBintang

local GarisTombolBintang = Instance.new("UIStroke")
GarisTombolBintang.Color = WARNA.GarisPanel
GarisTombolBintang.Thickness = 1.5
GarisTombolBintang.Parent = TombolBintang

local LabelBintang = Instance.new("TextLabel")
LabelBintang.Name = "LabelBintang"
LabelBintang.BackgroundTransparency = 1
LabelBintang.Position = UDim2.new(0, 0, 1, -16)
LabelBintang.Size = UDim2.new(1, 0, 0, 16)
LabelBintang.Font = Enum.Font.GothamBold
LabelBintang.TextSize = 10
LabelBintang.TextColor3 = WARNA.TeksSekunder
LabelBintang.Text = "FAVORIT"
LabelBintang.ZIndex = 16
LabelBintang.Parent = PanelBintang

-- ------------------------------------------------------------
-- 10H. Lingkaran Roda Emote 8-Slot (Sesuai Desain Referensi)
-- ------------------------------------------------------------
local UKURAN_WHEEL = 344
local UKURAN_TENGAH = 148
local JARAK_SLOT = 120

local LingkaranWheel = Instance.new("Frame")
LingkaranWheel.Name = "LingkaranWheel"
LingkaranWheel.AnchorPoint = Vector2.new(0.5, 0.5)
LingkaranWheel.Position = UDim2.new(0.5, 0, 0, 250)
LingkaranWheel.Size = UDim2.new(0, UKURAN_WHEEL, 0, UKURAN_WHEEL)
LingkaranWheel.BackgroundColor3 = WARNA.LatarWheel
LingkaranWheel.BackgroundTransparency = 0.14
LingkaranWheel.BorderSizePixel = 0
LingkaranWheel.ZIndex = 11
LingkaranWheel.Parent = WadahWheel

local SudutWheel = Instance.new("UICorner")
SudutWheel.CornerRadius = UDim.new(1, 0)
SudutWheel.Parent = LingkaranWheel

local GarisWheel = Instance.new("UIStroke")
GarisWheel.Color = WARNA.GarisWheel
GarisWheel.Thickness = 2
GarisWheel.Parent = LingkaranWheel

-- Buat 8 garis putih pembagi radial (setiap 45 derajat)
local panjangGaris = (UKURAN_WHEEL - UKURAN_TENGAH) / 2 - 4
local jarakTengahGaris = (UKURAN_TENGAH / 2) + (panjangGaris / 2)

for i = 0, 7 do
    local sudutDerajat = 22.5 + (i * 45)
    local radian = math.rad(sudutDerajat - 90)
    local posX = (UKURAN_WHEEL / 2) + math.cos(radian) * jarakTengahGaris
    local posY = (UKURAN_WHEEL / 2) + math.sin(radian) * jarakTengahGaris

    local garis = Instance.new("Frame")
    garis.Name = "Pembagi_" .. tostring(i + 1)
    garis.AnchorPoint = Vector2.new(0.5, 0.5)
    garis.Position = UDim2.new(0, posX, 0, posY)
    garis.Size = UDim2.new(0, 1.5, 0, panjangGaris)
    garis.Rotation = sudutDerajat
    garis.BackgroundColor3 = WARNA.GarisPembagi
    garis.BackgroundTransparency = 0.25
    garis.BorderSizePixel = 0
    garis.ZIndex = 12
    garis.Parent = LingkaranWheel

    local gradasi = Instance.new("UIGradient")
    gradasi.Rotation = 90
    gradasi.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(0.45, 0.15),
        NumberSequenceKeypoint.new(1, 0.05),
    })
    gradasi.Parent = garis
end

-- Buat 8 tombol slot emote melingkar
local DaftarTombolSlot = {}
local IndeksSlotHover = nil

for i = 1, SLOT_PER_HALAMAN do
    local sudutDerajat = (i - 1) * 45
    local radian = math.rad(sudutDerajat - 90)
    local sx = (UKURAN_WHEEL / 2) + math.cos(radian) * JARAK_SLOT
    local sy = (UKURAN_WHEEL / 2) + math.sin(radian) * JARAK_SLOT

    local tombolSlot = Instance.new("TextButton")
    tombolSlot.Name = "Slot_" .. tostring(i)
    tombolSlot.AnchorPoint = Vector2.new(0.5, 0.5)
    tombolSlot.Position = UDim2.new(0, sx, 0, sy)
    tombolSlot.Size = UDim2.new(0, 74, 0, 74)
    tombolSlot.BackgroundColor3 = WARNA.SlotNormal
    tombolSlot.BackgroundTransparency = 0.55
    tombolSlot.BorderSizePixel = 0
    tombolSlot.AutoButtonColor = false
    tombolSlot.Text = ""
    tombolSlot.ZIndex = 14
    tombolSlot.Parent = LingkaranWheel

    local sudutSlot = Instance.new("UICorner")
    sudutSlot.CornerRadius = UDim.new(1, 0)
    sudutSlot.Parent = tombolSlot

    local garisSlot = Instance.new("UIStroke")
    garisSlot.Color = WARNA.Aksen
    garisSlot.Thickness = 2
    garisSlot.Transparency = 1
    garisSlot.Parent = tombolSlot

    local gambarThumb = Instance.new("ImageLabel")
    gambarThumb.Name = "Thumbnail"
    gambarThumb.AnchorPoint = Vector2.new(0.5, 0.5)
    gambarThumb.Position = UDim2.new(0.5, 0, 0.44, 0)
    gambarThumb.Size = UDim2.new(0, 50, 0, 50)
    gambarThumb.BackgroundTransparency = 1
    gambarThumb.ScaleType = Enum.ScaleType.Fit
    gambarThumb.Image = ""
    gambarThumb.ZIndex = 15
    gambarThumb.Parent = tombolSlot

    local namaSlot = Instance.new("TextLabel")
    namaSlot.Name = "NamaSlot"
    namaSlot.AnchorPoint = Vector2.new(0.5, 1)
    namaSlot.Position = UDim2.new(0.5, 0, 1, -4)
    namaSlot.Size = UDim2.new(1, -8, 0, 14)
    namaSlot.BackgroundTransparency = 1
    namaSlot.Font = Enum.Font.GothamMedium
    namaSlot.TextSize = 9
    namaSlot.TextColor3 = WARNA.TeksUtama
    namaSlot.TextTruncate = Enum.TextTruncate.AtEnd
    namaSlot.Text = ""
    namaSlot.ZIndex = 16
    namaSlot.Parent = tombolSlot

    local lencanaFav = Instance.new("TextLabel")
    lencanaFav.Name = "LencanaFav"
    lencanaFav.AnchorPoint = Vector2.new(1, 0)
    lencanaFav.Position = UDim2.new(1, -2, 0, 2)
    lencanaFav.Size = UDim2.new(0, 18, 0, 18)
    lencanaFav.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    lencanaFav.BackgroundTransparency = 0.2
    lencanaFav.Font = Enum.Font.GothamBold
    lencanaFav.TextSize = 11
    lencanaFav.TextColor3 = WARNA.Emas
    lencanaFav.Text = "★"
    lencanaFav.Visible = false
    lencanaFav.ZIndex = 17
    lencanaFav.Parent = tombolSlot

    local sudutLencana = Instance.new("UICorner")
    sudutLencana.CornerRadius = UDim.new(1, 0)
    sudutLencana.Parent = lencanaFav

    DaftarTombolSlot[i] = {
        Tombol     = tombolSlot,
        Garis      = garisSlot,
        Thumbnail  = gambarThumb,
        LabelNama  = namaSlot,
        LencanaFav = lencanaFav,
        DataEmote  = nil,
    }
end

-- Lingkaran Tengah Hitam (Menampilkan Mode, Nama Emote, & Nomor Halaman)
local LingkaranTengah = Instance.new("Frame")
LingkaranTengah.Name = "LingkaranTengah"
LingkaranTengah.AnchorPoint = Vector2.new(0.5, 0.5)
LingkaranTengah.Position = UDim2.new(0.5, 0, 0.5, 0)
LingkaranTengah.Size = UDim2.new(0, UKURAN_TENGAH, 0, UKURAN_TENGAH)
LingkaranTengah.BackgroundColor3 = WARNA.LatarTengah
LingkaranTengah.BackgroundTransparency = 0.04
LingkaranTengah.BorderSizePixel = 0
LingkaranTengah.ZIndex = 18
LingkaranTengah.Parent = LingkaranWheel

local SudutTengah = Instance.new("UICorner")
SudutTengah.CornerRadius = UDim.new(1, 0)
SudutTengah.Parent = LingkaranTengah

local GarisTengah = Instance.new("UIStroke")
GarisTengah.Color = WARNA.GarisTengah
GarisTengah.Thickness = 1.6
GarisTengah.Parent = LingkaranTengah

local LabelModeTengah = Instance.new("TextLabel")
LabelModeTengah.Name = "LabelMode"
LabelModeTengah.AnchorPoint = Vector2.new(0.5, 0)
LabelModeTengah.Position = UDim2.new(0.5, 0, 0, 20)
LabelModeTengah.Size = UDim2.new(1, -24, 0, 14)
LabelModeTengah.BackgroundTransparency = 1
LabelModeTengah.Font = Enum.Font.GothamBold
LabelModeTengah.TextSize = 10
LabelModeTengah.TextColor3 = WARNA.Aksen
LabelModeTengah.Text = "SEMUA EMOTE"
LabelModeTengah.ZIndex = 19
LabelModeTengah.Parent = LingkaranTengah

local LabelNamaTengah = Instance.new("TextLabel")
LabelNamaTengah.Name = "LabelNamaEmote"
LabelNamaTengah.AnchorPoint = Vector2.new(0.5, 0.5)
LabelNamaTengah.Position = UDim2.new(0.5, 0, 0.5, 0)
LabelNamaTengah.Size = UDim2.new(1, -22, 0, 52)
LabelNamaTengah.BackgroundTransparency = 1
LabelNamaTengah.Font = Enum.Font.GothamBold
LabelNamaTengah.TextSize = 13
LabelNamaTengah.TextWrapped = true
LabelNamaTengah.TextColor3 = WARNA.TeksUtama
LabelNamaTengah.Text = "Pilih Emote"
LabelNamaTengah.ZIndex = 19
LabelNamaTengah.Parent = LingkaranTengah

local LabelHalaman = Instance.new("TextLabel")
LabelHalaman.Name = "LabelHalaman"
LabelHalaman.AnchorPoint = Vector2.new(0.5, 1)
LabelHalaman.Position = UDim2.new(0.5, 0, 1, -18)
LabelHalaman.Size = UDim2.new(1, -26, 0, 18)
LabelHalaman.BackgroundTransparency = 1
LabelHalaman.Font = Enum.Font.GothamMedium
LabelHalaman.TextSize = 11
LabelHalaman.TextColor3 = WARNA.TeksSekunder
LabelHalaman.Text = "1 / 1"
LabelHalaman.ZIndex = 19
LabelHalaman.Parent = LingkaranTengah

-- ------------------------------------------------------------
-- 10I. Bar Bawah: [ < ]   [ ★ Favorit (0) ]   [ > ]
--      (Tombol < dan > Besar di Samping Favorit agar Nyaman di HP)
-- ------------------------------------------------------------
local BarBawah = Instance.new("Frame")
BarBawah.Name = "BarBawah"
BarBawah.AnchorPoint = Vector2.new(0.5, 0)
BarBawah.Position = UDim2.new(0.5, 0, 0, 434)
BarBawah.Size = UDim2.new(0, 326, 0, 44)
BarBawah.BackgroundTransparency = 1
BarBawah.ZIndex = 15
BarBawah.Parent = WadahWheel

local TombolSebelumnya = Instance.new("TextButton")
TombolSebelumnya.Name = "TombolSebelumnya"
TombolSebelumnya.AnchorPoint = Vector2.new(0, 0.5)
TombolSebelumnya.Position = UDim2.new(0, 0, 0.5, 0)
TombolSebelumnya.Size = UDim2.new(0, 44, 0, 44)
TombolSebelumnya.BackgroundColor3 = WARNA.TombolNav
TombolSebelumnya.BackgroundTransparency = 0.08
TombolSebelumnya.AutoButtonColor = false
TombolSebelumnya.Font = Enum.Font.GothamBold
TombolSebelumnya.TextSize = 20
TombolSebelumnya.TextColor3 = WARNA.TeksUtama
TombolSebelumnya.Text = "<"
TombolSebelumnya.ZIndex = 16
TombolSebelumnya.Parent = BarBawah

local SudutSebelumnya = Instance.new("UICorner")
SudutSebelumnya.CornerRadius = UDim.new(1, 0)
SudutSebelumnya.Parent = TombolSebelumnya

local GarisSebelumnya = Instance.new("UIStroke")
GarisSebelumnya.Color = WARNA.GarisPanel
GarisSebelumnya.Thickness = 1.4
GarisSebelumnya.Parent = TombolSebelumnya

local TombolDaftarFav = Instance.new("TextButton")
TombolDaftarFav.Name = "TombolDaftarFav"
TombolDaftarFav.AnchorPoint = Vector2.new(0.5, 0.5)
TombolDaftarFav.Position = UDim2.new(0.5, 0, 0.5, 0)
TombolDaftarFav.Size = UDim2.new(0, 214, 0, 40)
TombolDaftarFav.BackgroundColor3 = WARNA.LatarPanel
TombolDaftarFav.BackgroundTransparency = 0.08
TombolDaftarFav.AutoButtonColor = false
TombolDaftarFav.Font = Enum.Font.GothamBold
TombolDaftarFav.TextSize = 13
TombolDaftarFav.TextColor3 = WARNA.Emas
TombolDaftarFav.Text = "★  Favorit (0)"
TombolDaftarFav.ZIndex = 16
TombolDaftarFav.Parent = BarBawah

local SudutDaftarFav = Instance.new("UICorner")
SudutDaftarFav.CornerRadius = UDim.new(0, 20)
SudutDaftarFav.Parent = TombolDaftarFav

local GarisDaftarFav = Instance.new("UIStroke")
GarisDaftarFav.Color = WARNA.Emas
GarisDaftarFav.Thickness = 1.4
GarisDaftarFav.Transparency = 0.35
GarisDaftarFav.Parent = TombolDaftarFav

local TombolBerikutnya = Instance.new("TextButton")
TombolBerikutnya.Name = "TombolBerikutnya"
TombolBerikutnya.AnchorPoint = Vector2.new(1, 0.5)
TombolBerikutnya.Position = UDim2.new(1, 0, 0.5, 0)
TombolBerikutnya.Size = UDim2.new(0, 44, 0, 44)
TombolBerikutnya.BackgroundColor3 = WARNA.TombolNav
TombolBerikutnya.BackgroundTransparency = 0.08
TombolBerikutnya.AutoButtonColor = false
TombolBerikutnya.Font = Enum.Font.GothamBold
TombolBerikutnya.TextSize = 20
TombolBerikutnya.TextColor3 = WARNA.TeksUtama
TombolBerikutnya.Text = ">"
TombolBerikutnya.ZIndex = 16
TombolBerikutnya.Parent = BarBawah

local SudutBerikutnya = Instance.new("UICorner")
SudutBerikutnya.CornerRadius = UDim.new(1, 0)
SudutBerikutnya.Parent = TombolBerikutnya

local GarisBerikutnya = Instance.new("UIStroke")
GarisBerikutnya.Color = WARNA.GarisPanel
GarisBerikutnya.Thickness = 1.4
GarisBerikutnya.Parent = TombolBerikutnya

local LabelStatus = Instance.new("TextLabel")
LabelStatus.Name = "LabelStatus"
LabelStatus.AnchorPoint = Vector2.new(0.5, 0)
LabelStatus.Position = UDim2.new(0.5, 0, 0, 580)
LabelStatus.Size = UDim2.new(0, 360, 0, 16)
LabelStatus.BackgroundTransparency = 1
LabelStatus.Font = Enum.Font.Gotham
LabelStatus.TextSize = 10
LabelStatus.TextColor3 = WARNA.TeksRedup
LabelStatus.Text = ""
LabelStatus.ZIndex = 15
LabelStatus.Parent = WadahWheel

-- ============================================================
-- 10J. SISTEM ANIMATION MODE & CUSTOM ANIMATION PACKS (v1.2.0)
-- ============================================================
local AnimSys = (function()
    local ContentProvider = game:GetService("ContentProvider")
    local ANIM_DB_URL     = "https://raw.githubusercontent.com/KurooNeko874/Universal-Script/main/data/animations.lua"
    local ANIM_JSON_URLS  = {
        "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json",
        "https://raw.githubusercontent.com/7yd7/sniper-Emote/test/AnimationSniper.json",
    }
    local FILE_ANIM_CACHE = NAMA_FOLDER .. "/animations_catalog_v1.json"
    local FILE_CUSTOM     = NAMA_FOLDER .. "/custom_animations.json"
    local FILE_AUTO_ANIM  = NAMA_FOLDER .. "/active_animations.json"

    local S = {
        SubMode         = "All Anim", -- All Anim | Idle | Walk | Run | Jump | Fall | Climb | Swim | Custom
        AnimDB          = { Full = {}, Idle = {}, Walk = {}, Run = {}, Jump = {}, Fall = {}, Climb = {}, Swim = {}, SwimIdle = {} },
        MarketPacks     = {},         -- Array of { id = bundleId, name = string, l = lower, bundledItems = table }
        BundleAnimCache = {},         -- [bundleId] = { Idle = {id1,id2}, Walk = id, Run = id, Jump = id, Fall = id, Climb = id, Swim = id, SwimIdle = id }
        CustomPacks     = {},         -- Array of { name = string, data = { Idle=..., Walk=..., ... } }
        ActiveState     = {},         -- [animType] = id (or {id1, id2} for Idle)
        AutoApply       = true,
        DbLoaded        = false,
        MarketLoaded    = false,
        OnRefreshUI     = nil,
    }

    local function saveCustomPacks()
        tulisFileJson(FILE_CUSTOM, S.CustomPacks)
    end

    local function loadCustomPacks()
        local raw = bacaFileJson(FILE_CUSTOM)
        if type(raw) == "table" then
            S.CustomPacks = {}
            for _, p in ipairs(raw) do
                if type(p) == "table" and type(p.name) == "string" and type(p.data) == "table" then
                    table.insert(S.CustomPacks, p)
                end
            end
        end
    end

    local function saveActiveState()
        tulisFileJson(FILE_AUTO_ANIM, { auto = S.AutoApply, state = S.ActiveState })
    end

    local function loadActiveState()
        local raw = bacaFileJson(FILE_AUTO_ANIM)
        if type(raw) == "table" then
            if type(raw.auto) == "boolean" then S.AutoApply = raw.auto end
            if type(raw.state) == "table" then S.ActiveState = raw.state end
        end
    end

    local function preloadAnim(animId)
        if not animId then return end
        local ids = (type(animId) == "table") and animId or { animId }
        local list = {}
        for _, id in ipairs(ids) do
            local clean = tostring(id or ""):gsub("%D", "")
            if clean ~= "" then
                local a = Instance.new("Animation")
                a.AnimationId = "rbxassetid://" .. clean
                table.insert(list, a)
            end
        end
        if #list > 0 then
            pcall(function() ContentProvider:PreloadAsync(list) end)
        end
    end

    local function getAnimObj(folder, names)
        for _, n in ipairs(names) do
            local obj = folder:FindFirstChild(n)
            if obj and obj:IsA("Animation") then return obj end
        end
        return folder:FindFirstChildOfClass("Animation")
    end

    local function reloadHumanoidAnim(hum)
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, tr in pairs(animator:GetPlayingAnimationTracks()) do
                pcall(function() if tr.IsPlaying then tr:Stop(0.12) end end)
            end
        end
        task.wait(0.05)
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hum:Move(Vector3.new(0.1, 0, 0), true)
            task.wait(0.05)
            hum:Move(Vector3.new(), true)
        end)
    end

    local function setAnimOnAnimate(animate, animType, animId)
        local function fmtId(v)
            local clean = tostring(v or ""):gsub("%D", "")
            if clean == "" then return nil end
            return "rbxassetid://" .. clean
        end
        if animType == "Idle" then
            local folder = animate:FindFirstChild("idle")
            if folder then
                local a1 = getAnimObj(folder, { "Animation1", "IdleAnim" })
                local a2 = getAnimObj(folder, { "Animation2" })
                if type(animId) == "table" then
                    local f1 = fmtId(animId[1])
                    local f2 = fmtId(animId[2] or animId[1])
                    if a1 and f1 then a1.AnimationId = f1 end
                    if a2 and f2 then a2.AnimationId = f2 end
                else
                    local f1 = fmtId(animId)
                    if a1 and f1 then a1.AnimationId = f1 end
                    if a2 and f1 then a2.AnimationId = f1 end
                end
            end
        elseif animType == "Walk" then
            local folder = animate:FindFirstChild("walk")
            local f = fmtId(animId)
            if folder and f then local a = getAnimObj(folder, { "WalkAnim", "Animation" }); if a then a.AnimationId = f end end
        elseif animType == "Run" then
            local folder = animate:FindFirstChild("run")
            local f = fmtId(animId)
            if folder and f then local a = getAnimObj(folder, { "RunAnim", "Animation" }); if a then a.AnimationId = f end end
        elseif animType == "Jump" then
            local folder = animate:FindFirstChild("jump")
            local f = fmtId(animId)
            if folder and f then local a = getAnimObj(folder, { "JumpAnim", "Animation" }); if a then a.AnimationId = f end end
        elseif animType == "Fall" then
            local folder = animate:FindFirstChild("fall")
            local f = fmtId(animId)
            if folder and f then local a = getAnimObj(folder, { "FallAnim", "Animation" }); if a then a.AnimationId = f end end
        elseif animType == "Climb" then
            local folder = animate:FindFirstChild("climb")
            local f = fmtId(animId)
            if folder and f then local a = getAnimObj(folder, { "ClimbAnim", "Animation" }); if a then a.AnimationId = f end end
        elseif animType == "Swim" then
            local folder = animate:FindFirstChild("swim")
            local f = fmtId(animId)
            if folder and f then local a = getAnimObj(folder, { "Swim", "SwimAnim", "Animation" }); if a then a.AnimationId = f end end
        elseif animType == "SwimIdle" then
            local folder = animate:FindFirstChild("swimidle")
            local f = fmtId(animId)
            if folder and f then local a = getAnimObj(folder, { "SwimIdle", "Animation" }); if a then a.AnimationId = f end end
        end
    end

    local function applyTableToChar(char, animMap)
        if not char or type(animMap) ~= "table" then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local animate = char:FindFirstChild("Animate")
        if not hum or not animate then return false end
        for animType, animId in pairs(animMap) do
            if animId then
                preloadAnim(animId)
                pcall(setAnimOnAnimate, animate, animType, animId)
            end
        end
        pcall(function()
            animate.Disabled = true
            task.wait(0.08)
            animate.Disabled = false
        end)
        reloadHumanoidAnim(hum)
        return true
    end

    -- Ekstrak semua AnimationId (Idle/Walk/Run/Jump/Fall/Climb/Swim/SwimIdle) dari Bundle Marketplace via game:GetObjects
    local FOLDER_TO_TYPE = {
        idle     = "Idle",
        walk     = "Walk",
        run      = "Run",
        jump     = "Jump",
        fall     = "Fall",
        climb    = "Climb",
        swim     = "Swim",
        swimidle = "SwimIdle",
    }

    local function resolveBundleAnimations(pack)
        if not pack or not pack.id then return nil end
        if S.BundleAnimCache[pack.id] then
            return S.BundleAnimCache[pack.id]
        end
        if type(pack.bundledItems) ~= "table" then return nil end

        local assetIds = {}
        for _, arr in pairs(pack.bundledItems) do
            if type(arr) == "table" then
                for _, aid in ipairs(arr) do
                    local n = tonumber(aid)
                    if n and n > 0 then table.insert(assetIds, n) end
                end
            elseif tonumber(arr) then
                table.insert(assetIds, tonumber(arr))
            end
        end
        if #assetIds == 0 then return nil end

        local result = {}
        local done = 0
        for _, aid in ipairs(assetIds) do
            task.spawn(function()
                local okObj, objs = pcall(function()
                    return game:GetObjects("rbxassetid://" .. tostring(aid))
                end)
                if okObj and type(objs) == "table" then
                    for _, root in ipairs(objs) do
                        for _, desc in ipairs(root:GetDescendants()) do
                            if desc:IsA("Animation") and desc.AnimationId ~= "" then
                                local parentName = desc.Parent and string.lower(desc.Parent.Name) or ""
                                local mappedType = FOLDER_TO_TYPE[parentName]
                                local cleanId = tostring(desc.AnimationId):gsub("%D", "")
                                if mappedType and cleanId ~= "" then
                                    if mappedType == "Idle" then
                                        if type(result.Idle) ~= "table" then
                                            result.Idle = { cleanId, cleanId }
                                        else
                                            local lname = string.lower(desc.Name)
                                            if lname:find("2") then
                                                result.Idle[2] = cleanId
                                            else
                                                result.Idle[1] = cleanId
                                            end
                                        end
                                    else
                                        result[mappedType] = cleanId
                                    end
                                end
                            end
                        end
                        pcall(function() root:Destroy() end)
                    end
                end
                done = done + 1
            end)
        end

        local tStart = os.clock()
        while done < #assetIds and (os.clock() - tStart) < 5 do
            task.wait(0.05)
        end

        if next(result) ~= nil then
            S.BundleAnimCache[pack.id] = result
            return result
        end
        return nil
    end

    function S.ApplyMarketPack(pack, onlyType)
        if not pack then return end
        local char = PemainLokal.Character
        if not char then return end
        tampilkanNotif('Memuat animasi "' .. pack.name .. '"...', WARNA.Aksen)
        task.spawn(function()
            local animMap = resolveBundleAnimations(pack)
            if not animMap then
                tampilkanNotif('Gagal memuat bundle "' .. pack.name .. '".', WARNA.Bahaya)
                return
            end
            if onlyType and onlyType ~= "All Anim" then
                local id = animMap[onlyType]
                if not id then
                    tampilkanNotif('Bundle "' .. pack.name .. '" tidak punya animasi ' .. onlyType .. '.', WARNA.Bahaya)
                    return
                end
                S.ActiveState[onlyType] = id
                saveActiveState()
                if applyTableToChar(char, { [onlyType] = id }) then
                    tampilkanNotif(onlyType .. ': "' .. pack.name .. '" diterapkan!', WARNA.Sukses)
                end
            else
                for k, v in pairs(animMap) do
                    S.ActiveState[k] = v
                end
                saveActiveState()
                if applyTableToChar(char, animMap) then
                    tampilkanNotif('Full Pack "' .. pack.name .. '" diterapkan!', WARNA.Sukses)
                end
            end
        end)
    end

    function S.ApplySingle(animType, animId, labelName)
        local char = PemainLokal.Character
        if not char then return end
        S.ActiveState[animType] = animId
        saveActiveState()
        task.spawn(function()
            if applyTableToChar(char, { [animType] = animId }) then
                tampilkanNotif(animType .. ": " .. tostring(labelName or animId) .. " diterapkan!", WARNA.Sukses)
            end
        end)
    end

    function S.ApplyFullPack(packName)
        local char = PemainLokal.Character
        if not char then return end
        local types = { "Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim", "SwimIdle" }
        local toApply = {}
        for _, t in ipairs(types) do
            local id = S.AnimDB[t] and S.AnimDB[t][packName]
            if id then
                toApply[t] = id
                S.ActiveState[t] = id
            end
        end
        saveActiveState()
        task.spawn(function()
            if applyTableToChar(char, toApply) then
                tampilkanNotif('Animasi "' .. packName .. '" diterapkan!', WARNA.Sukses)
            end
        end)
    end

    function S.ApplyCustomPack(pack)
        if type(pack) ~= "table" or type(pack.data) ~= "table" then return end
        local char = PemainLokal.Character
        if not char then return end
        for k, v in pairs(pack.data) do
            if v and tostring(v) ~= "" then
                S.ActiveState[k] = v
            end
        end
        saveActiveState()
        task.spawn(function()
            if applyTableToChar(char, pack.data) then
                tampilkanNotif('Custom "' .. pack.name .. '" diterapkan!', WARNA.Emas)
            end
        end)
    end

    function S.DeleteCustomPack(idx)
        local p = S.CustomPacks[idx]
        if not p then return end
        local nm = p.name
        table.remove(S.CustomPacks, idx)
        saveCustomPacks()
        tampilkanNotif('Custom "' .. nm .. '" dihapus.', WARNA.Bahaya)
        if S.OnRefreshUI then S.OnRefreshUI(false) end
    end

    function S.ResetAnimations()
        S.ActiveState = {}
        saveActiveState()
        local char = PemainLokal.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local animate = char and char:FindFirstChild("Animate")
        if animate then
            pcall(function()
                animate.Disabled = true
                task.wait(0.08)
                animate.Disabled = false
            end)
        end
        if hum then reloadHumanoidAnim(hum) end
        tampilkanNotif("Animasi di-reset (respawn untuk default penuh).", WARNA.Aksen)
    end

    -- Auto-Apply saat Respawn
    catatKoneksi(PemainLokal.CharacterAdded:Connect(function(newChar)
        if not S.AutoApply or next(S.ActiveState) == nil then return end
        newChar:WaitForChild("Humanoid", 10)
        newChar:WaitForChild("Animate", 10)
        task.wait(0.3)
        applyTableToChar(newChar, S.ActiveState)
    end))

    -- Parse JSON AnimationSniper (12.155+ Marketplace Animation Packs)
    local function parseMarketAnimJson(raw)
        if type(raw) ~= "string" or #raw < 100 then return false end
        local okDec, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
        if not okDec or type(decoded) ~= "table" then return false end
        local arr = type(decoded.data) == "table" and decoded.data or decoded
        if type(arr) ~= "table" or #arr < 5 then return false end

        local list = {}
        local seen = {}
        for i = 1, #arr do
            local it = arr[i]
            if type(it) == "table" then
                local id = tonumber(it.id)
                local nm = tostring(it.name or "")
                if id and nm ~= "" and not seen[id] and type(it.bundledItems) == "table" then
                    seen[id] = true
                    list[#list + 1] = {
                        id           = id,
                        name         = nm,
                        l            = string.lower(nm),
                        bundledItems = it.bundledItems,
                    }
                end
            end
        end
        if #list > 0 then
            S.MarketPacks = list
            S.MarketLoaded = true
            return true
        end
        return false
    end

    -- Muat AnimDB & 12.155+ Marketplace Animations (dengan cache lokal!)
    local isLoadingDb = false
    local function ensureAnimDbLoaded()
        if isLoadingDb then return end
        if S.DbLoaded and S.MarketLoaded then return end
        isLoadingDb = true
        task.spawn(function()
            -- 1. Muat AnimDB bawaan cepat
            if not S.DbLoaded then
                local raw = ambilTeksHttp(ANIM_DB_URL)
                if type(raw) == "string" and #raw > 100 then
                    local fn = loadstring(raw)
                    if type(fn) == "function" then
                        local ok, tbl = pcall(fn)
                        if ok and type(tbl) == "table" then
                            S.AnimDB = tbl
                            S.DbLoaded = true
                            if Status.ModeTampilan == "Animasi" and S.OnRefreshUI then
                                S.OnRefreshUI(false)
                            end
                        end
                    end
                end
            end

            -- 2. Muat 12.155+ Marketplace Animations dari cache lokal atau GitHub AnimationSniper.json
            if not S.MarketLoaded then
                local loadedFromCache = false
                if punyaAksesFile then
                    local okEx, exists = pcall(isfile, FILE_ANIM_CACHE)
                    if okEx and exists then
                        local okR, cachedRaw = pcall(readfile, FILE_ANIM_CACHE)
                        if okR and type(cachedRaw) == "string" and #cachedRaw > 1000 then
                            loadedFromCache = parseMarketAnimJson(cachedRaw)
                        end
                    end
                end

                if not loadedFromCache then
                    if Status.ModeTampilan == "Animasi" then
                        LabelStatus.Text = "Mengunduh 12.000+ Animasi Marketplace..."
                    end
                    for _, url in ipairs(ANIM_JSON_URLS) do
                        local raw = ambilTeksHttp(url)
                        if raw and #raw > 1000 and parseMarketAnimJson(raw) then
                            if punyaAksesFile then
                                pastikanFolderAda()
                                pcall(writefile, FILE_ANIM_CACHE, raw)
                            end
                            break
                        end
                    end
                end

                if S.MarketLoaded and Status.ModeTampilan == "Animasi" and S.OnRefreshUI then
                    LabelStatus.Text = formatAngka(#S.MarketPacks) .. " Animasi Marketplace tersedia"
                    S.OnRefreshUI(false)
                end
            end
            isLoadingDb = false
        end)
    end

    loadCustomPacks()
    loadActiveState()
    ensureAnimDbLoaded()

    -- 1) Tombol "Animation" tepat di bawah tombol Favorit
    local TombolModeAnim = Instance.new("TextButton")
    TombolModeAnim.Name = "TombolModeAnimasi"
    TombolModeAnim.AnchorPoint = Vector2.new(0.5, 0)
    TombolModeAnim.Position = UDim2.new(0.5, 0, 0, 484)
    TombolModeAnim.Size = UDim2.new(0, 214, 0, 34)
    TombolModeAnim.BackgroundColor3 = WARNA.LatarPanel
    TombolModeAnim.BackgroundTransparency = 0.08
    TombolModeAnim.AutoButtonColor = false
    TombolModeAnim.Font = Enum.Font.GothamBold
    TombolModeAnim.TextSize = 13
    TombolModeAnim.TextColor3 = WARNA.Aksen
    TombolModeAnim.Text = "Animation"
    TombolModeAnim.ZIndex = 16
    TombolModeAnim.Parent = WadahWheel

    local scAnim = Instance.new("UICorner")
    scAnim.CornerRadius = UDim.new(0, 17)
    scAnim.Parent = TombolModeAnim

    local stAnim = Instance.new("UIStroke")
    stAnim.Color = WARNA.Aksen
    stAnim.Thickness = 1.4
    stAnim.Transparency = 0.3
    stAnim.Parent = TombolModeAnim

    -- 2) Bar Kategori Animasi (tampil hanya saat Mode Animasi aktif)
    local BarKat = Instance.new("Frame")
    BarKat.Name = "BarKategoriAnim"
    BarKat.AnchorPoint = Vector2.new(0.5, 0)
    BarKat.Position = UDim2.new(0.5, 0, 0, 524)
    BarKat.Size = UDim2.new(0, 540, 0, 52)
    BarKat.BackgroundTransparency = 1
    BarKat.Visible = false
    BarKat.ZIndex = 16
    BarKat.Parent = WadahWheel

    local Row1 = Instance.new("Frame")
    Row1.Size = UDim2.new(1, 0, 0, 24)
    Row1.Position = UDim2.new(0, 0, 0, 0)
    Row1.BackgroundTransparency = 1
    Row1.ZIndex = 16
    Row1.Parent = BarKat
    local lay1 = Instance.new("UIListLayout")
    lay1.FillDirection = Enum.FillDirection.Horizontal
    lay1.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lay1.VerticalAlignment = Enum.VerticalAlignment.Center
    lay1.Padding = UDim.new(0, 4)
    lay1.Parent = Row1

    local Row2 = Instance.new("Frame")
    Row2.Size = UDim2.new(1, 0, 0, 24)
    Row2.Position = UDim2.new(0, 0, 0, 28)
    Row2.BackgroundTransparency = 1
    Row2.ZIndex = 16
    Row2.Parent = BarKat
    local lay2 = Instance.new("UIListLayout")
    lay2.FillDirection = Enum.FillDirection.Horizontal
    lay2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lay2.VerticalAlignment = Enum.VerticalAlignment.Center
    lay2.Padding = UDim.new(0, 6)
    lay2.Parent = Row2

    local catButtons = {}
    local CATS = { "All Anim", "Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim", "Custom" }

    local function refreshCatHighlight()
        for catName, info in pairs(catButtons) do
            local isSel = (S.SubMode == catName)
            info.btn.BackgroundColor3 = isSel and (catName == "Custom" and WARNA.Emas or WARNA.Aksen) or WARNA.LatarPanel
            info.btn.TextColor3 = isSel and Color3.fromRGB(16, 17, 21) or WARNA.TeksUtama
            info.stroke.Color = isSel and (catName == "Custom" and WARNA.Emas or WARNA.Aksen) or WARNA.GarisPanel
        end
    end

    for _, catName in ipairs(CATS) do
        local b = Instance.new("TextButton")
        b.Name = "Cat_" .. catName
        b.AutomaticSize = Enum.AutomaticSize.X
        b.Size = UDim2.new(0, 0, 0, 22)
        b.BackgroundColor3 = WARNA.LatarPanel
        b.BackgroundTransparency = 0.08
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.TextColor3 = WARNA.TeksUtama
        b.Text = catName
        b.ZIndex = 17
        b.Parent = Row1

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = b

        local cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(1, 0)
        cr.Parent = b

        local st = Instance.new("UIStroke")
        st.Color = WARNA.GarisPanel
        st.Thickness = 1.1
        st.Parent = b

        catButtons[catName] = { btn = b, stroke = st }
        catatKoneksi(b.MouseButton1Click:Connect(function()
            Status.ModeBintang = false
            S.SubMode = catName
            refreshCatHighlight()
            if S.OnRefreshUI then S.OnRefreshUI(true) end
        end))
    end

    -- Tombol Baris 2: [+ Buat Custom]  [Auto Apply: ON]  [Reset Anim]
    local function makeActionBtn(text, color, parent)
        local b = Instance.new("TextButton")
        b.AutomaticSize = Enum.AutomaticSize.X
        b.Size = UDim2.new(0, 0, 0, 22)
        b.BackgroundColor3 = WARNA.LatarPanel
        b.BackgroundTransparency = 0.06
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.TextColor3 = color
        b.Text = text
        b.ZIndex = 17
        b.Parent = parent
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        pad.Parent = b
        local cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(1, 0)
        cr.Parent = b
        local st = Instance.new("UIStroke")
        st.Color = color
        st.Thickness = 1.1
        st.Transparency = 0.35
        st.Parent = b
        return b, st
    end

    local btnBuatCustom = makeActionBtn("+ Buat Custom Anim", WARNA.Emas, Row2)
    local btnAutoApply, stAutoApply = makeActionBtn("Auto Apply: " .. (S.AutoApply and "ON" or "OFF"), S.AutoApply and WARNA.Sukses or WARNA.TeksSekunder, Row2)
    local btnResetAnim = makeActionBtn("Reset Anim", WARNA.Bahaya, Row2)

    catatKoneksi(btnAutoApply.MouseButton1Click:Connect(function()
        S.AutoApply = not S.AutoApply
        saveActiveState()
        btnAutoApply.Text = "Auto Apply: " .. (S.AutoApply and "ON" or "OFF")
        btnAutoApply.TextColor3 = S.AutoApply and WARNA.Sukses or WARNA.TeksSekunder
        stAutoApply.Color = S.AutoApply and WARNA.Sukses or WARNA.TeksSekunder
        tampilkanNotif("Auto Apply Animasi: " .. (S.AutoApply and "ON" or "OFF"), S.AutoApply and WARNA.Sukses or WARNA.TeksSekunder)
    end))

    catatKoneksi(btnResetAnim.MouseButton1Click:Connect(function()
        S.ResetAnimations()
    end))

    -- 3) Modal Pembuat Custom Animation Pack (bebas nama & bebas ID / ambil dari aktif)
    local ModalCustom = Instance.new("Frame")
    ModalCustom.Name = "ModalCustomAnim"
    ModalCustom.AnchorPoint = Vector2.new(0.5, 0.5)
    ModalCustom.Position = UDim2.new(0.5, 0, 0.5, 0)
    ModalCustom.Size = UDim2.new(0, 340, 0, 376)
    ModalCustom.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
    ModalCustom.BackgroundTransparency = 0.03
    ModalCustom.BorderSizePixel = 0
    ModalCustom.Visible = false
    ModalCustom.ZIndex = 60
    ModalCustom.Parent = LayarGui

    local mcCorner = Instance.new("UICorner")
    mcCorner.CornerRadius = UDim.new(0, 14)
    mcCorner.Parent = ModalCustom

    local mcStroke = Instance.new("UIStroke")
    mcStroke.Color = WARNA.Emas
    mcStroke.Thickness = 1.6
    mcStroke.Parent = ModalCustom

    local mcTitle = Instance.new("TextLabel")
    mcTitle.Size = UDim2.new(1, -24, 0, 28)
    mcTitle.Position = UDim2.new(0, 12, 0, 8)
    mcTitle.BackgroundTransparency = 1
    mcTitle.Font = Enum.Font.GothamBold
    mcTitle.TextSize = 14
    mcTitle.TextColor3 = WARNA.Emas
    mcTitle.Text = "Buat Custom Animasi"
    mcTitle.TextXAlignment = Enum.TextXAlignment.Left
    mcTitle.ZIndex = 61
    mcTitle.Parent = ModalCustom

    local mcSub = Instance.new("TextLabel")
    mcSub.Size = UDim2.new(1, -24, 0, 16)
    mcSub.Position = UDim2.new(0, 12, 0, 32)
    mcSub.BackgroundTransparency = 1
    mcSub.Font = Enum.Font.Gotham
    mcSub.TextSize = 10
    mcSub.TextColor3 = WARNA.TeksSekunder
    mcSub.Text = "Otomatis terisi dari animasi aktif, atau isi ID bebas:"
    mcSub.TextXAlignment = Enum.TextXAlignment.Left
    mcSub.ZIndex = 61
    mcSub.Parent = ModalCustom

    local mcInputs = {}
    local FIELDS = {
        { key = "Name",  label = "Nama Preset", ph = "contoh: Custom 1 / Anime Mix" },
        { key = "Idle",  label = "Idle ID",     ph = "id1 atau id1,id2 (opsional)" },
        { key = "Walk",  label = "Walk ID",     ph = "Animation ID (opsional)" },
        { key = "Run",   label = "Run ID",      ph = "Animation ID (opsional)" },
        { key = "Jump",  label = "Jump ID",     ph = "Animation ID (opsional)" },
        { key = "Fall",  label = "Fall ID",     ph = "Animation ID (opsional)" },
        { key = "Climb", label = "Climb ID",    ph = "Animation ID (opsional)" },
        { key = "Swim",  label = "Swim ID",     ph = "Animation ID (opsional)" },
    }

    for idx, f in ipairs(FIELDS) do
        local yPos = 54 + (idx - 1) * 34
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 86, 0, 26)
        lbl.Position = UDim2.new(0, 12, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextColor3 = (f.key == "Name") and WARNA.Emas or WARNA.TeksUtama
        lbl.Text = f.label
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 61
        lbl.Parent = ModalCustom

        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1, -112, 0, 26)
        tb.Position = UDim2.new(0, 100, 0, yPos)
        tb.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
        tb.BorderSizePixel = 0
        tb.Font = Enum.Font.GothamMedium
        tb.TextSize = 11
        tb.TextColor3 = WARNA.TeksUtama
        tb.PlaceholderColor3 = WARNA.TeksRedup
        tb.PlaceholderText = f.ph
        tb.Text = ""
        tb.ClearTextOnFocus = false
        tb.ZIndex = 61
        tb.Parent = ModalCustom

        local tbc = Instance.new("UICorner")
        tbc.CornerRadius = UDim.new(0, 7)
        tbc.Parent = tb

        local tbp = Instance.new("UIPadding")
        tbp.PaddingLeft = UDim.new(0, 8)
        tbp.PaddingRight = UDim.new(0, 8)
        tbp.Parent = tb

        mcInputs[f.key] = tb
    end

    local function prefillFromActive()
        mcInputs.Name.Text = "Custom " .. tostring(#S.CustomPacks + 1)
        for _, key in ipairs({ "Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim" }) do
            local v = S.ActiveState[key]
            if type(v) == "table" then
                mcInputs[key].Text = tostring(v[1] or "") .. (v[2] and ("," .. tostring(v[2])) or "")
            elseif v then
                mcInputs[key].Text = tostring(v)
            else
                mcInputs[key].Text = ""
            end
        end
    end

    local btnSaveCustom = Instance.new("TextButton")
    btnSaveCustom.Size = UDim2.new(0, 150, 0, 32)
    btnSaveCustom.Position = UDim2.new(0, 12, 1, -42)
    btnSaveCustom.BackgroundColor3 = WARNA.Sukses
    btnSaveCustom.AutoButtonColor = false
    btnSaveCustom.Font = Enum.Font.GothamBold
    btnSaveCustom.TextSize = 12
    btnSaveCustom.TextColor3 = Color3.fromRGB(14, 18, 16)
    btnSaveCustom.Text = "Simpan & Pakai"
    btnSaveCustom.ZIndex = 61
    btnSaveCustom.Parent = ModalCustom
    local csc = Instance.new("UICorner"); csc.CornerRadius = UDim.new(0, 8); csc.Parent = btnSaveCustom

    local btnCancelCustom = Instance.new("TextButton")
    btnCancelCustom.Size = UDim2.new(0, 150, 0, 32)
    btnCancelCustom.Position = UDim2.new(1, -162, 1, -42)
    btnCancelCustom.BackgroundColor3 = Color3.fromRGB(48, 50, 60)
    btnCancelCustom.AutoButtonColor = false
    btnCancelCustom.Font = Enum.Font.GothamBold
    btnCancelCustom.TextSize = 12
    btnCancelCustom.TextColor3 = WARNA.TeksUtama
    btnCancelCustom.Text = "Batal"
    btnCancelCustom.ZIndex = 61
    btnCancelCustom.Parent = ModalCustom
    local ccc = Instance.new("UICorner"); ccc.CornerRadius = UDim.new(0, 8); ccc.Parent = btnCancelCustom

    catatKoneksi(btnBuatCustom.MouseButton1Click:Connect(function()
        prefillFromActive()
        ModalCustom.Visible = true
    end))

    catatKoneksi(btnCancelCustom.MouseButton1Click:Connect(function()
        ModalCustom.Visible = false
    end))

    catatKoneksi(btnSaveCustom.MouseButton1Click:Connect(function()
        local nm = string.gsub(mcInputs.Name.Text or "", "^%s*(.-)%s*$", "%1")
        if nm == "" then nm = "Custom " .. tostring(#S.CustomPacks + 1) end

        local data = {}
        local hasAny = false
        for _, key in ipairs({ "Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim" }) do
            local raw = string.gsub(mcInputs[key].Text or "", "^%s*(.-)%s*$", "%1")
            if raw ~= "" then
                if key == "Idle" and string.find(raw, ",", 1, true) then
                    local parts = {}
                    for seg in string.gmatch(raw, "[^,]+") do
                        local clean = seg:gsub("%D", "")
                        if clean ~= "" then table.insert(parts, clean) end
                    end
                    if #parts > 0 then
                        data.Idle = { parts[1], parts[2] or parts[1] }
                        hasAny = true
                    end
                else
                    local clean = raw:gsub("%D", "")
                    if clean ~= "" then
                        data[key] = (key == "Idle") and { clean, clean } or clean
                        hasAny = true
                    end
                end
            end
        end

        if not hasAny then
            tampilkanNotif("Isi minimal 1 Animation ID atau pilih animasi dulu!", WARNA.Bahaya)
            return
        end

        local newPack = { name = nm, data = data }
        -- Timpa jika nama sama, atau tambah baru
        local replaced = false
        for idx, p in ipairs(S.CustomPacks) do
            if string.lower(p.name) == string.lower(nm) then
                S.CustomPacks[idx] = newPack
                replaced = true
                break
            end
        end
        if not replaced then
            table.insert(S.CustomPacks, newPack)
        end
        saveCustomPacks()
        ModalCustom.Visible = false
        S.SubMode = "Custom"
        refreshCatHighlight()
        S.ApplyCustomPack(newPack)
        if S.OnRefreshUI then S.OnRefreshUI(true) end
    end))

    function S.CloseModal()
        ModalCustom.Visible = false
    end

    function S.UpdateVisibility()
        local inAnim = (Status.ModeTampilan == "Animasi")
        BarKat.Visible = inAnim
        if inAnim then
            TombolModeAnim.Text = "←  Kembali ke Emote"
            TombolModeAnim.TextColor3 = WARNA.TeksUtama
            stAnim.Color = WARNA.GarisPanel
            refreshCatHighlight()
        else
            TombolModeAnim.Text = "Animation"
            TombolModeAnim.TextColor3 = WARNA.Aksen
            stAnim.Color = WARNA.Aksen
            ModalCustom.Visible = false
        end
    end

    function S.BuildList(kataKunci)
        local out = {}
        local q = string.lower(string.gsub(kataKunci or "", "^%s*(.-)%s*$", "%1"))

        if S.SubMode == "Custom" then
            for idx, p in ipairs(S.CustomPacks) do
                if q == "" or string.find(string.lower(p.name), q, 1, true) then
                    table.insert(out, {
                        id        = 0,
                        name      = p.name,
                        l         = string.lower(p.name),
                        isAnim    = true,
                        isCustom  = true,
                        customIdx = idx,
                        pack      = p,
                        subMode   = "Custom",
                    })
                end
            end
            return out
        end

        -- Jika mengetik langsung angka Animation ID di sub-mode tunggal (Idle/Walk/Run/dll), tampilkan langsung di Slot 1!
        local idAngka = tonumber(q)
        if idAngka and math.floor(idAngka) == idAngka and idAngka > 0 and S.SubMode ~= "All Anim" then
            table.insert(out, {
                id       = idAngka,
                name     = S.SubMode .. " #" .. tostring(idAngka),
                l        = q,
                isAnim   = true,
                animType = S.SubMode,
                animId   = (S.SubMode == "Idle") and { tostring(idAngka), tostring(idAngka) } or tostring(idAngka),
                subMode  = S.SubMode,
            })
        end

        if S.SubMode == "All Anim" then
            -- Gabungkan 12.155+ Marketplace Animation Packs + Preset Klasik
            if #S.MarketPacks > 0 then
                local limit = (q == "") and #S.MarketPacks or 400
                for i = 1, #S.MarketPacks do
                    local mp = S.MarketPacks[i]
                    if q == "" or string.find(mp.l, q, 1, true) or (idAngka and string.find(tostring(mp.id), q, 1, true)) then
                        out[#out + 1] = {
                            id         = mp.id,
                            name       = mp.name,
                            l          = mp.l,
                            isAnim     = true,
                            isMarket   = true,
                            marketPack = mp,
                            subMode    = "All Anim",
                        }
                        if q ~= "" and #out >= limit then break end
                    end
                end
            end

            -- Fallback preset klasik jika Marketplace JSON masih loading
            if #out == 0 then
                local names = {}
                if type(S.AnimDB.Full) == "table" and #S.AnimDB.Full > 0 then
                    names = S.AnimDB.Full
                elseif type(S.AnimDB.Idle) == "table" then
                    for k in pairs(S.AnimDB.Idle) do table.insert(names, k) end
                    table.sort(names)
                end
                for _, nm in ipairs(names) do
                    if q == "" or string.find(string.lower(nm), q, 1, true) then
                        local thumbId = (S.AnimDB.Walk and S.AnimDB.Walk[nm]) or (S.AnimDB.Run and S.AnimDB.Run[nm]) or 0
                        out[#out + 1] = {
                            id      = tonumber(thumbId) or 0,
                            name    = nm,
                            l       = string.lower(nm),
                            isAnim  = true,
                            isFull  = true,
                            subMode = "All Anim",
                        }
                    end
                end
            end
        else
            -- Sub-mode tunggal (Idle / Walk / Run / Jump / Fall / Climb / Swim):
            -- 1) Tampilkan 12.155+ Marketplace Packs (saat diklik otomatis ekstrak HANYA slot ini!)
            if #S.MarketPacks > 0 then
                local limit = (q == "") and #S.MarketPacks or 400
                for i = 1, #S.MarketPacks do
                    local mp = S.MarketPacks[i]
                    if q == "" or string.find(mp.l, q, 1, true) or (idAngka and string.find(tostring(mp.id), q, 1, true)) then
                        out[#out + 1] = {
                            id         = mp.id,
                            name       = mp.name,
                            l          = mp.l,
                            isAnim     = true,
                            isMarket   = true,
                            marketPack = mp,
                            animType   = S.SubMode,
                            subMode    = S.SubMode,
                        }
                        if q ~= "" and #out >= limit then break end
                    end
                end
            end

            -- 2) Tambahkan juga preset klasik AnimDB jika cocok / saat loading
            local tbl = S.AnimDB[S.SubMode]
            if type(tbl) == "table" and (#out == 0 or q ~= "") then
                local keys = {}
                for k in pairs(tbl) do table.insert(keys, k) end
                table.sort(keys)
                for _, nm in ipairs(keys) do
                    if q == "" or string.find(string.lower(nm), q, 1, true) then
                        local rawId = tbl[nm]
                        local numId = tonumber(type(rawId) == "table" and rawId[1] or rawId) or 0
                        out[#out + 1] = {
                            id       = numId,
                            name     = nm,
                            l        = string.lower(nm),
                            isAnim   = true,
                            animType = S.SubMode,
                            animId   = rawId,
                            subMode  = S.SubMode,
                        }
                    end
                end
            end
        end
        return out
    end

    function S.HandleSlotClick(item)
        if not item or not item.isAnim then return false end
        if item.isCustom then
            if Status.ModeBintang then
                S.DeleteCustomPack(item.customIdx)
                return false
            else
                S.ApplyCustomPack(item.pack)
                return true
            end
        elseif item.isMarket then
            S.ApplyMarketPack(item.marketPack, item.animType or "All Anim")
            return true
        elseif item.isFull then
            S.ApplyFullPack(item.name)
            return true
        else
            S.ApplySingle(item.animType, item.animId, item.name)
            return true
        end
    end

    catatKoneksi(TombolModeAnim.MouseButton1Click:Connect(function()
        Status.ModeBintang = false
        if Status.ModeTampilan == "Animasi" then
            Status.ModeTampilan = "Semua"
        else
            Status.ModeTampilan = "Animasi"
            ensureAnimDbLoaded()
        end
        S.UpdateVisibility()
        if S.OnRefreshUI then S.OnRefreshUI(true) end
    end))

    return S
end)()

-- ============================================================
-- 11. PENYESUAIAN LAYAR OTOMATIS (RESPONSIF PC & MOBILE)
-- ============================================================
-- Pastikan posisi tombol ikon senyum tidak pernah keluar dari batas layar
local function jagaPosisiIkonDalamLayar()
    local kamera = ambilKamera()
    local ukuranLayar = kamera and kamera.ViewportSize or Vector2.new(1280, 720)
    local lebarTombol = TombolIkonEmote.Size.X.Offset
    local tinggiTombol = TombolIkonEmote.Size.Y.Offset
    local posX = math.clamp(TombolIkonEmote.Position.X.Offset, 6, math.max(6, ukuranLayar.X - lebarTombol - 6))
    local posY = math.clamp(TombolIkonEmote.Position.Y.Offset, 6, math.max(6, ukuranLayar.Y - tinggiTombol - 6))
    TombolIkonEmote.Position = UDim2.new(0, posX, 0, posY)
end

local function perbaruiTataLetakResponsif()
    local kamera = ambilKamera()
    local ukuranLayar = kamera and kamera.ViewportSize or Vector2.new(1280, 720)
    local modeMobile = apakahPerangkatMobile() or (ukuranLayar.X < 900)

    -- Skala otomatis seluruh wadah wheel agar pas di layar HP maupun monitor PC
    local skalaX = (ukuranLayar.X * 0.94) / 560
    local skalaY = (ukuranLayar.Y * 0.88) / 598
    SkalaWheel.Scale = math.clamp(math.min(skalaX, skalaY), 0.44, 1.02)

    -- Ukuran tombol ikon senyum menyesuaikan perangkat
    if modeMobile then
        local ukuranTombol = math.clamp(math.floor(ukuranLayar.Y * 0.085), 36, 44)
        TombolIkonEmote.Size = UDim2.new(0, ukuranTombol, 0, ukuranTombol)
        LabelSenyum.TextSize = math.floor(ukuranTombol * 0.62)
        if not Status.PosisiIkonKustom then
            TombolIkonEmote.Position = UDim2.new(0, 184, 0, 10)
        end
    else
        TombolIkonEmote.Size = UDim2.new(0, 44, 0, 44)
        LabelSenyum.TextSize = 26
        if not Status.PosisiIkonKustom then
            TombolIkonEmote.Position = UDim2.new(0, 224, 0, 12)
        end
    end

    if Status.PosisiIkonKustom then
        jagaPosisiIkonDalamLayar()
    end
end

perbaruiTataLetakResponsif()

local function pasangPantauUkuranLayar()
    local kamera = ambilKamera()
    if kamera then
        catatKoneksi(kamera:GetPropertyChangedSignal("ViewportSize"):Connect(perbaruiTataLetakResponsif))
    end
end
pasangPantauUkuranLayar()
catatKoneksi(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    perbaruiTataLetakResponsif()
    pasangPantauUkuranLayar()
end))

-- ============================================================
-- 12. FITUR DRAG / GESER IKON EMOTE (SENTUH DI HP & MOUSE DI PC)
-- ============================================================
local sedangTahanIkon = false
local ikonBaruDigeser = false
local posisiInputAwal = Vector3.new()
local posisiTombolAwal = UDim2.new()

catatKoneksi(TombolIkonEmote.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sedangTahanIkon = true
        ikonBaruDigeser = false
        posisiInputAwal = input.Position
        posisiTombolAwal = TombolIkonEmote.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                sedangTahanIkon = false
            end
        end)
    end
end))

catatKoneksi(UserInputService.InputChanged:Connect(function(input)
    if not sedangTahanIkon then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local selisih = input.Position - posisiInputAwal
        -- Anggap sebagai geser (drag) jika jari/mouse bergerak lebih dari 6 pixel
        if selisih.Magnitude > 6 then
            ikonBaruDigeser = true
            Status.PosisiIkonKustom = true
        end

        if ikonBaruDigeser then
            local kamera = ambilKamera()
            local ukuranLayar = kamera and kamera.ViewportSize or Vector2.new(1280, 720)
            local lebarTombol = TombolIkonEmote.Size.X.Offset
            local tinggiTombol = TombolIkonEmote.Size.Y.Offset

            local baruX = math.clamp(posisiTombolAwal.X.Offset + selisih.X, 6, math.max(6, ukuranLayar.X - lebarTombol - 6))
            local baruY = math.clamp(posisiTombolAwal.Y.Offset + selisih.Y, 6, math.max(6, ukuranLayar.Y - tinggiTombol - 6))
            TombolIkonEmote.Position = UDim2.new(0, baruX, 0, baruY)
        end
    end
end))

-- ============================================================
-- 13. PEMBARUAN TAMPILAN WHEEL & FILTER PENCARIAN (RINGAN 60K+)
-- ============================================================
local function perbaruiTampilanBintang()
    if Status.ModeTampilan == "Animasi" then
        if AnimSys.SubMode == "Custom" then
            LabelBintang.Text = "HAPUS"
            if Status.ModeBintang then
                TombolBintang.BackgroundColor3 = WARNA.Bahaya
                TombolBintang.TextColor3 = WARNA.TeksUtama
                GarisTombolBintang.Color = WARNA.Bahaya
                GarisWheel.Color = WARNA.Bahaya
                LabelModeTengah.Text = "KLIK UTK HAPUS"
                LabelModeTengah.TextColor3 = WARNA.Bahaya
            else
                TombolBintang.BackgroundColor3 = WARNA.LatarPanel
                TombolBintang.TextColor3 = WARNA.TeksSekunder
                GarisTombolBintang.Color = WARNA.GarisPanel
                GarisWheel.Color = WARNA.Emas
                LabelModeTengah.Text = "CUSTOM ANIM"
                LabelModeTengah.TextColor3 = WARNA.Emas
            end
        else
            LabelBintang.Text = "ANIMASI"
            TombolBintang.BackgroundColor3 = WARNA.LatarPanel
            TombolBintang.TextColor3 = WARNA.TeksSekunder
            GarisTombolBintang.Color = WARNA.GarisPanel
            GarisWheel.Color = WARNA.Aksen
            LabelModeTengah.Text = string.upper(AnimSys.SubMode)
            LabelModeTengah.TextColor3 = WARNA.Aksen
        end
        return
    end
    if Status.ModeTampilan == "Favorit" then
        LabelBintang.Text = "UNFAV"
        if Status.ModeBintang then
            TombolBintang.BackgroundColor3 = WARNA.Bahaya
            TombolBintang.TextColor3 = WARNA.TeksUtama
            GarisTombolBintang.Color = WARNA.Bahaya
            GarisWheel.Color = WARNA.Bahaya
            LabelModeTengah.Text = "★ KLIK UTK UNFAV"
            LabelModeTengah.TextColor3 = WARNA.Bahaya
        else
            TombolBintang.BackgroundColor3 = WARNA.LatarPanel
            TombolBintang.TextColor3 = WARNA.TeksSekunder
            GarisTombolBintang.Color = WARNA.GarisPanel
            GarisWheel.Color = WARNA.Emas
            LabelModeTengah.Text = "★ FAVORIT"
            LabelModeTengah.TextColor3 = WARNA.Emas
        end
    else
        LabelBintang.Text = "FAVORIT"
        if Status.ModeBintang then
            TombolBintang.BackgroundColor3 = WARNA.Emas
            TombolBintang.TextColor3 = Color3.fromRGB(20, 20, 24)
            GarisTombolBintang.Color = WARNA.Emas
            GarisWheel.Color = WARNA.Emas
            LabelModeTengah.Text = "★ KLIK UTK FAV"
            LabelModeTengah.TextColor3 = WARNA.Emas
        else
            TombolBintang.BackgroundColor3 = WARNA.LatarPanel
            TombolBintang.TextColor3 = WARNA.TeksSekunder
            GarisTombolBintang.Color = WARNA.GarisPanel
            GarisWheel.Color = WARNA.GarisWheel
            LabelModeTengah.Text = "SEMUA EMOTE"
            LabelModeTengah.TextColor3 = WARNA.Aksen
        end
    end
end

local function perbaruiTombolDaftarFav()
    if Status.ModeTampilan == "Favorit" then
        TombolDaftarFav.Text = "←  Semua Emote (" .. formatAngka(#Status.SemuaEmote) .. ")"
        TombolDaftarFav.TextColor3 = WARNA.Aksen
        GarisDaftarFav.Color = WARNA.Aksen
    else
        TombolDaftarFav.Text = "★  Favorit (" .. formatAngka(#Status.DaftarFavorit) .. ")"
        TombolDaftarFav.TextColor3 = WARNA.Emas
        GarisDaftarFav.Color = WARNA.Emas
    end
end

local function perbaruiTampilanTengah(itemEmote)
    if itemEmote then
        LabelNamaTengah.Text = itemEmote.name
        LabelNamaTengah.TextColor3 = WARNA.TeksUtama
    else
        if Status.ModeTampilan == "Animasi" then
            if AnimSys.SubMode == "Custom" and #AnimSys.CustomPacks == 0 then
                LabelNamaTengah.Text = "Belum ada Custom\n(+ Buat Custom)"
                LabelNamaTengah.TextColor3 = WARNA.TeksRedup
            elseif #Status.DaftarTampil == 0 then
                LabelNamaTengah.Text = "Animasi kosong"
                LabelNamaTengah.TextColor3 = WARNA.TeksRedup
            else
                LabelNamaTengah.Text = "Pilih " .. AnimSys.SubMode
                LabelNamaTengah.TextColor3 = WARNA.TeksSekunder
            end
        elseif Status.ModeTampilan == "Favorit" and #Status.DaftarFavorit == 0 then
            LabelNamaTengah.Text = "Belum ada Favorit"
            LabelNamaTengah.TextColor3 = WARNA.TeksRedup
        elseif #Status.DaftarTampil == 0 then
            LabelNamaTengah.Text = "Tidak ditemukan"
            LabelNamaTengah.TextColor3 = WARNA.TeksRedup
        else
            LabelNamaTengah.Text = "Pilih Emote"
            LabelNamaTengah.TextColor3 = WARNA.TeksSekunder
        end
    end
end

local function gambarHalamanWheel()
    local totalItem = #Status.DaftarTampil
    Status.TotalHalaman = math.max(1, math.ceil(totalItem / SLOT_PER_HALAMAN))
    Status.HalamanSekarang = math.clamp(Status.HalamanSekarang, 1, Status.TotalHalaman)

    LabelHalaman.Text = formatAngka(Status.HalamanSekarang) .. " / " .. formatAngka(Status.TotalHalaman)

    local bisaSebelumnya = Status.HalamanSekarang > 1
    local bisaBerikutnya = Status.HalamanSekarang < Status.TotalHalaman
    TombolSebelumnya.TextTransparency = bisaSebelumnya and 0 or 0.65
    GarisSebelumnya.Transparency = bisaSebelumnya and 0.15 or 0.65
    TombolBerikutnya.TextTransparency = bisaBerikutnya and 0 or 0.65
    GarisBerikutnya.Transparency = bisaBerikutnya and 0.15 or 0.65

    local indeksAwal = (Status.HalamanSekarang - 1) * SLOT_PER_HALAMAN

    for i = 1, SLOT_PER_HALAMAN do
        local slot = DaftarTombolSlot[i]
        local item = Status.DaftarTampil[indeksAwal + i]
        slot.DataEmote = item

        if item then
            slot.Tombol.Visible = true
            if item.isAnim then
                if item.isMarket and item.id and item.id > 0 then
                    slot.Thumbnail.Image = "rbxthumb://type=BundleThumbnail&id=" .. tostring(item.id) .. "&w=150&h=150"
                elseif item.id and item.id > 0 then
                    slot.Thumbnail.Image = buatUrlThumbnail(item.id)
                else
                    slot.Thumbnail.Image = ""
                end
                slot.LabelNama.Text = item.name
                slot.LencanaFav.Visible = (item.isCustom == true)
            else
                slot.Thumbnail.Image = buatUrlThumbnail(item.id)
                slot.LabelNama.Text = item.name
                slot.LencanaFav.Visible = (Status.SetFavorit[item.id] == true)
            end
            slot.Tombol.BackgroundColor3 = WARNA.SlotNormal
            slot.Garis.Transparency = 1
        else
            slot.Tombol.Visible = false
            slot.Thumbnail.Image = ""
            slot.LabelNama.Text = ""
            slot.LencanaFav.Visible = false
        end
    end

    IndeksSlotHover = nil
    perbaruiTampilanBintang()
    perbaruiTombolDaftarFav()
    perbaruiTampilanTengah(nil)
end

-- Bangun ulang daftar emote sesuai kata kunci pencarian / mode tampilan
local function bangunUlangDaftarTampil(resetHalaman)
    if Status.ModeTampilan == "Animasi" then
        Status.DaftarTampil = AnimSys.BuildList(Status.KataKunciCari)
        if resetHalaman then
            Status.HalamanSekarang = 1
        end
        AnimSys.UpdateVisibility()
        gambarHalamanWheel()
        return
    end
    AnimSys.UpdateVisibility()
    local sumber = (Status.ModeTampilan == "Favorit") and Status.DaftarFavorit or Status.SemuaEmote
    local kataKunci = string.lower(string.gsub(Status.KataKunciCari or "", "^%s*(.-)%s*$", "%1"))

    if kataKunci == "" then
        -- Referensi langsung tanpa menyalin 62.000+ tabel (super cepat / O(1))
        Status.DaftarTampil = sumber
        if resetHalaman then
            Status.HalamanSekarang = 1
        end
        gambarHalamanWheel()
        return
    end

    local hasil = {}
    local sudahAda = {}

    -- Jika user mengetik angka Asset ID secara langsung, tampilkan langsung di Slot 1
    local idAngka = tonumber(kataKunci)
    if idAngka and math.floor(idAngka) == idAngka and idAngka > 0 and Status.ModeTampilan == "Semua" then
        local namaKetemu = Status.CacheNamaId[idAngka]
        if not namaKetemu then
            for idx = 1, #sumber do
                if sumber[idx].id == idAngka then
                    namaKetemu = sumber[idx].name
                    break
                end
            end
        end

        sudahAda[idAngka] = true
        hasil[#hasil + 1] = {
            id   = idAngka,
            name = namaKetemu or ("Emote #" .. tostring(idAngka)),
            l    = string.lower(namaKetemu or tostring(idAngka)),
        }

        -- Ambil nama asli dari Marketplace secara asynchronous jika belum ada di cache
        if not namaKetemu then
            task.spawn(function()
                local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, idAngka)
                if ok and type(info) == "table" and info.Name then
                    Status.CacheNamaId[idAngka] = info.Name
                    if not Status.SudahDihancurkan and tonumber(Status.KataKunciCari) == idAngka then
                        bangunUlangDaftarTampil(false)
                    end
                end
            end)
        end
    end

    -- Prioritaskan hasil pencarian live Marketplace jika cocok dengan kata kunci saat ini
    if Status.ModeTampilan == "Semua" and Status.KataKunciLive == kataKunci and #Status.HasilCariLive > 0 then
        for idx = 1, #Status.HasilCariLive do
            local item = Status.HasilCariLive[idx]
            if not sudahAda[item.id] then
                sudahAda[item.id] = true
                hasil[#hasil + 1] = item
            end
        end
    end

    -- Tahap 1: Pencarian substring cepat pada nama emote (huruf kecil)
    local batasHasil = 400
    for idx = 1, #sumber do
        local item = sumber[idx]
        if not sudahAda[item.id] then
            if string.find(item.l, kataKunci, 1, true)
                or (idAngka and string.find(tostring(item.id), kataKunci, 1, true))
            then
                sudahAda[item.id] = true
                hasil[#hasil + 1] = item
                if #hasil >= batasHasil then break end
            end
        end
    end

    -- Tahap 2: Pencarian cerdas per-kata jika hasil sedikit (contoh: "i got that feelin" -> "Got that feelin'")
    if #hasil < 16 and not idAngka then
        local daftarKata = {}
        for kata in string.gmatch(kataKunci, "%w+") do
            if #kata >= 2 then
                daftarKata[#daftarKata + 1] = kata
            end
        end
        if #daftarKata >= 2 then
            local minimalCocok = math.max(2, #daftarKata - 1)
            for idx = 1, #sumber do
                local item = sumber[idx]
                if not sudahAda[item.id] then
                    local cocok = 0
                    for wi = 1, #daftarKata do
                        if string.find(item.l, daftarKata[wi], 1, true) then
                            cocok = cocok + 1
                        end
                    end
                    if cocok >= minimalCocok then
                        sudahAda[item.id] = true
                        hasil[#hasil + 1] = item
                        if #hasil >= 120 then break end
                    end
                end
            end
        end
    end

    Status.DaftarTampil = hasil
    if resetHalaman then
        Status.HalamanSekarang = 1
    end
    gambarHalamanWheel()
end

-- ============================================================
-- 14. BUKA / TUTUP RODA EMOTE
-- ============================================================
local function aturBukaWheel(buka)
    if Status.SudahDihancurkan then return end
    Status.Terbuka = buka
    WadahWheel.Visible = buka

    if buka then
        matikanEmoteBawaan()
        GarisIkonEmote.Color = WARNA.Aksen
        GarisIkonEmote.Transparency = 0.05
        LabelSenyum.TextColor3 = WARNA.Aksen
        bangunUlangDaftarTampil(false)
    else
        GarisIkonEmote.Color = Color3.fromRGB(95, 100, 118)
        GarisIkonEmote.Transparency = 0.35
        LabelSenyum.TextColor3 = WARNA.TeksUtama
        if Status.ModeBintang then
            Status.ModeBintang = false
            perbaruiTampilanBintang()
        end
        AnimSys.CloseModal()
    end
end

-- ============================================================
-- 15. PENANGANAN INTERAKSI TOMBOL, KEYBOARD, & SLOT
-- ============================================================
-- Klik tombol ikon senyum (diabaikan jika barusan di-drag/digeser)
catatKoneksi(TombolIkonEmote.MouseButton1Click:Connect(function()
    if ikonBaruDigeser then
        ikonBaruDigeser = false
        return
    end
    aturBukaWheel(not Status.Terbuka)
end))

-- Pintasan keyboard: titik "." untuk buka/tutup, Escape untuk menutup
catatKoneksi(UserInputService.InputBegan:Connect(function(input, sedangKetik)
    if sedangKetik then return end
    if input.KeyCode == Enum.KeyCode.Period then
        aturBukaWheel(not Status.Terbuka)
    elseif input.KeyCode == Enum.KeyCode.Escape and Status.Terbuka then
        aturBukaWheel(false)
    end
end))

-- Scroll mouse di atas roda emote untuk berpindah halaman (PC)
catatKoneksi(LingkaranWheel.InputChanged:Connect(function(input)
    if not Status.Terbuka then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        if input.Position.Z > 0 and Status.HalamanSekarang > 1 then
            Status.HalamanSekarang = Status.HalamanSekarang - 1
            gambarHalamanWheel()
        elseif input.Position.Z < 0 and Status.HalamanSekarang < Status.TotalHalaman then
            Status.HalamanSekarang = Status.HalamanSekarang + 1
            gambarHalamanWheel()
        end
    end
end))

-- Tombol navigasi halaman < (kiri tombol Favorit)
catatKoneksi(TombolSebelumnya.MouseEnter:Connect(function()
    if Status.HalamanSekarang > 1 then
        TombolSebelumnya.BackgroundColor3 = WARNA.TombolNavHover
        GarisSebelumnya.Color = WARNA.Aksen
    end
end))
catatKoneksi(TombolSebelumnya.MouseLeave:Connect(function()
    TombolSebelumnya.BackgroundColor3 = WARNA.TombolNav
    GarisSebelumnya.Color = WARNA.GarisPanel
end))
catatKoneksi(TombolSebelumnya.MouseButton1Click:Connect(function()
    if Status.HalamanSekarang > 1 then
        Status.HalamanSekarang = Status.HalamanSekarang - 1
        gambarHalamanWheel()
    end
end))

-- Tombol navigasi halaman > (kanan tombol Favorit)
catatKoneksi(TombolBerikutnya.MouseEnter:Connect(function()
    if Status.HalamanSekarang < Status.TotalHalaman then
        TombolBerikutnya.BackgroundColor3 = WARNA.TombolNavHover
        GarisBerikutnya.Color = WARNA.Aksen
    end
end))
catatKoneksi(TombolBerikutnya.MouseLeave:Connect(function()
    TombolBerikutnya.BackgroundColor3 = WARNA.TombolNav
    GarisBerikutnya.Color = WARNA.GarisPanel
end))
catatKoneksi(TombolBerikutnya.MouseButton1Click:Connect(function()
    if Status.HalamanSekarang < Status.TotalHalaman then
        Status.HalamanSekarang = Status.HalamanSekarang + 1
        gambarHalamanWheel()
    end
end))

-- Terapkan kecepatan dari kotak input (dan ubah kecepatan emote yang sedang berjalan)
local function terapkanKecepatanDariInput()
    local hasil = batasiKecepatan(KotakKecepatan.Text)
    Status.Kecepatan = hasil
    KotakKecepatan.Text = formatKecepatan(hasil)
    if Status.TrackAktif then
        pcall(function()
            Status.TrackAktif:AdjustSpeed(Status.Kecepatan)
        end)
    end
end

catatKoneksi(KotakKecepatan.FocusLost:Connect(function()
    terapkanKecepatanDariInput()
end))

-- Tombol Bintang ★ (Mode Tambah Favorit di Semua Emote / Mode Unfav di Daftar Favorit)
catatKoneksi(TombolBintang.MouseButton1Click:Connect(function()
    if Status.ModeTampilan == "Animasi" then
        if AnimSys.SubMode == "Custom" then
            Status.ModeBintang = not Status.ModeBintang
            perbaruiTampilanBintang()
            if Status.ModeBintang then
                tampilkanNotif("Mode Hapus aktif — klik Custom Animasi yang ingin dihapus.", WARNA.Bahaya)
            end
        else
            tampilkanNotif("Buka kategori Custom untuk menghapus preset Custom.", WARNA.Aksen)
        end
        return
    end
    Status.ModeBintang = not Status.ModeBintang
    perbaruiTampilanBintang()
    if Status.ModeBintang then
        if Status.ModeTampilan == "Favorit" then
            tampilkanNotif("Mode Unfav aktif — klik emote untuk menghapus dari Favorit.", WARNA.Bahaya)
        else
            tampilkanNotif("Mode Favorit aktif — klik emote yang ingin difavoritkan.", WARNA.Emas)
        end
    end
end))

-- Tombol Bawah: Beralih antara Semua Emote dan Daftar Favorit
catatKoneksi(TombolDaftarFav.MouseButton1Click:Connect(function()
    Status.ModeBintang = false -- Matikan mode bintang otomatis agar tidak salah klik unfav
    if Status.ModeTampilan == "Semua" then
        Status.ModeTampilan = "Favorit"
    else
        Status.ModeTampilan = "Semua"
    end
    bangunUlangDaftarTampil(true)
end))

-- Pencarian live ke Marketplace Roblox (untuk menemukan emote terbaru yang belum masuk cache)
local function cariLiveMarketplace(kataKunci, idPermintaan)
    local kataNormal = string.lower(string.gsub(kataKunci or "", "^%s*(.-)%s*$", "%1"))
    if #kataNormal < 2 then return end

    local daftarKetemu = {}
    local setKetemu = {}

    -- Metode A: AvatarEditorService bawaan Roblox (menggunakan Enum.AvatarAssetType.EmoteAnimation)
    pcall(function()
        local param = CatalogSearchParams.new()
        param.AssetTypes = { Enum.AvatarAssetType.EmoteAnimation }
        param.SalesTypeFilter = Enum.SalesTypeFilter.All
        param.IncludeOffSale = true
        param.SearchKeyword = kataKunci
        param.Limit = 30

        local halaman = AvatarEditorService:SearchCatalog(param)
        if halaman then
            local isiHalaman = halaman:GetCurrentPage()
            if type(isiHalaman) == "table" then
                for _, item in ipairs(isiHalaman) do
                    local id = tonumber(item.Id)
                    local nama = tostring(item.Name or ("Emote #" .. tostring(id)))
                    if id and not setKetemu[id] then
                        setKetemu[id] = true
                        daftarKetemu[#daftarKetemu + 1] = {
                            id   = id,
                            name = nama,
                            l    = string.lower(nama),
                        }
                        tambahEmoteKeDaftar(id, nama)
                    end
                end
            end
        end
    end)

    -- Metode B: Cadangan Catalog HTTP API jika metode A kosong
    if #daftarKetemu == 0 then
        local terencode = HttpService:UrlEncode(kataKunci)
        local daftarUrl = {
            "https://catalog.roproxy.com/v1/search/items/details?Category=12&Subcategory=39&Limit=30&Keyword=" .. terencode,
            "https://catalog.roblox.com/v1/search/items/details?Category=12&Subcategory=39&Limit=30&Keyword=" .. terencode,
        }
        for _, url in ipairs(daftarUrl) do
            local daftar = ambilDataKatalogHttp(url)
            if daftar and #daftar > 0 then
                for _, item in ipairs(daftar) do
                    local id = tonumber(item.id)
                    local nama = tostring(item.name or ("Emote #" .. tostring(id)))
                    if id and not setKetemu[id] then
                        setKetemu[id] = true
                        daftarKetemu[#daftarKetemu + 1] = {
                            id   = id,
                            name = nama,
                            l    = string.lower(nama),
                        }
                        tambahEmoteKeDaftar(id, nama)
                    end
                end
                break
            end
        end
    end

    if not Status.SudahDihancurkan and Status.IdPermintaanCari == idPermintaan and #daftarKetemu > 0 then
        Status.KataKunciLive = kataNormal
        Status.HasilCariLive = daftarKetemu
        LabelStatus.Text = formatAngka(#Status.SemuaEmote) .. " Emote tersedia"
        bangunUlangDaftarTampil(true)
    end
end

-- Event saat user mengetik di kotak pencarian
catatKoneksi(KotakCari:GetPropertyChangedSignal("Text"):Connect(function()
    local teks = KotakCari.Text
    Status.KataKunciCari = teks
    TombolHapusCari.Visible = (#teks > 0)

    if teks == "" then
        Status.KataKunciLive = ""
        Status.HasilCariLive = {}
        bangunUlangDaftarTampil(true)
        return
    end

    -- Debounce ringan 0.08 detik agar mengetik tetap mulus 60 FPS di HP
    Status.IdDebounceCari = Status.IdDebounceCari + 1
    local idDebounceIni = Status.IdDebounceCari
    task.delay(0.08, function()
        if not Status.SudahDihancurkan and Status.IdDebounceCari == idDebounceIni then
            bangunUlangDaftarTampil(true)
        end
    end)

    -- Pencarian live Marketplace setelah berhenti mengetik 0.45 detik (minimal 2 huruf)
    local teksRapih = string.gsub(teks, "^%s*(.-)%s*$", "%1")
    if Status.ModeTampilan == "Semua" and #teksRapih >= 2 and not tonumber(teksRapih) then
        Status.IdPermintaanCari = Status.IdPermintaanCari + 1
        local idPermintaanIni = Status.IdPermintaanCari
        task.delay(0.45, function()
            if not Status.SudahDihancurkan and Status.IdPermintaanCari == idPermintaanIni then
                cariLiveMarketplace(teksRapih, idPermintaanIni)
            end
        end)
    end
end))

catatKoneksi(TombolHapusCari.MouseButton1Click:Connect(function()
    KotakCari.Text = ""
end))

-- Event hover & klik untuk ke-8 slot pada roda emote
for i = 1, SLOT_PER_HALAMAN do
    local slot = DaftarTombolSlot[i]

    catatKoneksi(slot.Tombol.MouseEnter:Connect(function()
        if not slot.DataEmote then return end
        IndeksSlotHover = i
        if Status.ModeBintang then
            if Status.ModeTampilan == "Favorit" then
                slot.Tombol.BackgroundColor3 = WARNA.SlotModeUnfav
                slot.Garis.Color = WARNA.Bahaya
            else
                slot.Tombol.BackgroundColor3 = WARNA.SlotModeFav
                slot.Garis.Color = WARNA.Emas
            end
        else
            slot.Tombol.BackgroundColor3 = WARNA.SlotHover
            slot.Garis.Color = WARNA.Aksen
        end
        slot.Garis.Transparency = 0.1
        perbaruiTampilanTengah(slot.DataEmote)
    end))

    catatKoneksi(slot.Tombol.MouseLeave:Connect(function()
        slot.Tombol.BackgroundColor3 = WARNA.SlotNormal
        slot.Garis.Transparency = 1
        if IndeksSlotHover == i then
            IndeksSlotHover = nil
            perbaruiTampilanTengah(nil)
        end
    end))

    catatKoneksi(slot.Tombol.MouseButton1Click:Connect(function()
        local item = slot.DataEmote
        if not item then return end

        perbaruiTampilanTengah(item)

        if item.isAnim then
            if AnimSys.HandleSlotClick(item) then
                aturBukaWheel(false)
            end
            return
        end

        if Status.ModeBintang then
            if Status.ModeTampilan == "Favorit" then
                -- MODE UNFAV (hanya aktif saat berada di menu Favorit)
                if Status.SetFavorit[item.id] then
                    Status.SetFavorit[item.id] = nil
                    for idx, fav in ipairs(Status.DaftarFavorit) do
                        if fav.id == item.id then
                            table.remove(Status.DaftarFavorit, idx)
                            break
                        end
                    end
                    simpanFavorit()
                    tampilkanNotif('Emote "' .. item.name .. '" dihapus dari Favorit.', WARNA.Bahaya)
                    bangunUlangDaftarTampil(false)
                end
            else
                -- MODE TAMBAH FAVORIT (tidak bisa unfav dari menu Semua Emote)
                if Status.SetFavorit[item.id] then
                    tampilkanNotif('Emote "' .. item.name .. '" sudah ada di Favorit!', WARNA.Emas)
                else
                    Status.SetFavorit[item.id] = true
                    table.insert(Status.DaftarFavorit, {
                        id   = item.id,
                        name = item.name,
                        l    = string.lower(item.name),
                    })
                    simpanFavorit()
                    slot.LencanaFav.Visible = true
                    perbaruiTombolDaftarFav()
                    tampilkanNotif('Emote "' .. item.name .. '" berhasil difavoritkan! ★', WARNA.Sukses)
                end
            end
        else
            -- Putar emote dengan kecepatan yang diatur lalu tutup wheel
            terapkanKecepatanDariInput()
            putarEmote(item)
            aturBukaWheel(false)
        end
    end))
end

-- ============================================================
-- 16. PENGAMBILAN KATALOG EMOTE MARKETPLACE OTOMATIS (3 LAPIS)
-- ============================================================
-- Lapisan 1: Unduh database JSON Marketplace (62.000+ emote dalam 1 kali unduh)
local function muatLewatJsonRemote()
    for _, url in ipairs(URL_JSON_EMOTE_REMOTE) do
        if Status.SudahDihancurkan then return false end
        local mentah = ambilTeksHttp(url)
        if mentah and #mentah > 1000 then
            local daftar = uraiJsonKatalog(mentah)
            if daftar and #daftar >= MIN_CACHE_VALID then
                LabelStatus.Text = "Memproses " .. formatAngka(#daftar) .. " emote Marketplace..."
                masukkanArrayEmote(daftar, true)
                simpanCacheMentah(mentah)
                return true
            end
        end
    end
    return false
end

-- Lapisan 2: AvatarEditorService bawaan Roblox (tanpa butuh proxy HTTP)
local function muatLewatAvatarEditorService()
    local daftarUrutan = {
        Enum.CatalogSortType.Relevance,
        Enum.CatalogSortType.BestSelling,
        Enum.CatalogSortType.MostFavorited,
        Enum.CatalogSortType.RecentlyCreated,
    }

    local berhasilDapat = false
    for _, urutan in ipairs(daftarUrutan) do
        if Status.SudahDihancurkan then break end
        pcall(function()
            local param = CatalogSearchParams.new()
            param.AssetTypes = { Enum.AvatarAssetType.EmoteAnimation }
            param.SalesTypeFilter = Enum.SalesTypeFilter.All
            param.IncludeOffSale = true
            param.SortType = urutan
            param.Limit = 30

            local halaman = AvatarEditorService:SearchCatalog(param)
            local noHal = 0
            while halaman and noHal < 34 and not Status.SudahDihancurkan do
                local isi = halaman:GetCurrentPage()
                if type(isi) == "table" and #isi > 0 then
                    masukkanArrayEmote(isi, true)
                    berhasilDapat = true
                else
                    break
                end

                noHal = noHal + 1
                if noHal == 1 or noHal % 3 == 0 then
                    if not Status.SudahDihancurkan then
                        LabelStatus.Text = "Memuat katalog Roblox: " .. formatAngka(#Status.SemuaEmote) .. "..."
                        if Status.Terbuka and Status.ModeTampilan == "Semua" and Status.KataKunciCari == "" then
                            bangunUlangDaftarTampil(false)
                        end
                    end
                end

                if halaman.IsFinished then break end
                local okLanjut = pcall(function()
                    halaman:AdvanceToNextPageAsync()
                end)
                if not okLanjut then break end
                task.wait(0.18)
            end
        end)
    end

    if berhasilDapat then
        simpanCacheTabel()
    end
    return berhasilDapat
end

-- Lapisan 3: Cadangan Catalog REST API / RoProxy
local function muatLewatCatalogApi()
    local daftarHost = {
        "https://catalog.roproxy.com/v1/search/items/details?Category=12&Subcategory=39&Limit=30",
        "https://catalog.roblox.com/v1/search/items/details?Category=12&Subcategory=39&Limit=30",
    }
    local daftarSort = { 0, 2, 1, 3 }
    local hostAktif = nil

    for _, host in ipairs(daftarHost) do
        local daftar = ambilDataKatalogHttp(host .. "&SortType=0")
        if daftar and #daftar > 0 then
            hostAktif = host
            break
        end
    end

    if not hostAktif then return false end

    local berhasilDapat = false
    for _, tipeSort in ipairs(daftarSort) do
        if Status.SudahDihancurkan then break end
        local cursor = ""
        local hal = 0
        local urlDasar = hostAktif .. "&SortType=" .. tostring(tipeSort)

        while hal < 34 and not Status.SudahDihancurkan do
            local url = (cursor ~= "") and (urlDasar .. "&Cursor=" .. HttpService:UrlEncode(cursor)) or urlDasar
            local daftar, nextCursor, kode = ambilDataKatalogHttp(url)
            if not daftar and kode == 429 then
                task.wait(1.5)
                daftar, nextCursor = ambilDataKatalogHttp(url)
            end
            if not daftar or #daftar == 0 then break end

            masukkanArrayEmote(daftar, true)
            berhasilDapat = true
            hal = hal + 1
            cursor = nextCursor or ""

            if hal == 1 or hal % 3 == 0 then
                if not Status.SudahDihancurkan then
                    LabelStatus.Text = "Memuat Catalog API: " .. formatAngka(#Status.SemuaEmote) .. "..."
                    if Status.Terbuka and Status.ModeTampilan == "Semua" and Status.KataKunciCari == "" then
                        bangunUlangDaftarTampil(false)
                    end
                end
            end

            if cursor == "" then break end
            task.wait(0.2)
        end
    end

    if berhasilDapat then
        simpanCacheTabel()
    end
    return berhasilDapat
end

-- Jalankan pengambilan katalog di latar belakang secara otomatis
local function muatKatalogMarketplaceAsync()
    if Status.SedangMuatKatalog then return end
    Status.SedangMuatKatalog = true

    task.spawn(function()
        if not Status.SudahDihancurkan then
            LabelStatus.Text = "Mengunduh database emote Marketplace..."
        end

        local berhasil = muatLewatJsonRemote()

        if not berhasil and not Status.SudahDihancurkan then
            LabelStatus.Text = "Memuat via Roblox AvatarEditorService..."
            berhasil = muatLewatAvatarEditorService()
        end

        if not berhasil and not Status.SudahDihancurkan then
            LabelStatus.Text = "Memuat via Catalog API..."
            berhasil = muatLewatCatalogApi()
        end

        Status.SedangMuatKatalog = false
        if not Status.SudahDihancurkan then
            LabelStatus.Text = formatAngka(#Status.SemuaEmote) .. " Emote tersedia"
            bangunUlangDaftarTampil(false)
            if berhasil and #Status.SemuaEmote >= MIN_CACHE_VALID then
                tampilkanNotif("Berhasil memuat " .. formatAngka(#Status.SemuaEmote) .. " Emote Marketplace!", WARNA.Sukses)
            end
        end
    end)
end

-- ============================================================
-- 17. INISIALISASI AWAL & FUNGSI PEMBERSIHAN (CLEANUP)
-- ============================================================
muatFavorit()
AnimSys.OnRefreshUI = bangunUlangDaftarTampil

-- Isi emote cadangan sementara agar UI langsung bisa dibuka sambil katalog 62k dimuat
for _, item in ipairs(EMOTE_CADANGAN) do
    tambahEmoteKeDaftar(item.id, item.name)
end
bangunUlangDaftarTampil(true)

task.spawn(function()
    local adaCache, masihSegar = muatCacheEmote()
    if adaCache and not Status.SudahDihancurkan then
        LabelStatus.Text = formatAngka(#Status.SemuaEmote) .. " Emote tersedia (cache)"
        bangunUlangDaftarTampil(true)
        if not masihSegar then
            muatKatalogMarketplaceAsync()
        end
    else
        muatKatalogMarketplaceAsync()
    end
end)

tampilkanNotif("KurooEmote v" .. VERSI .. " aktif! Tekan ( . ) atau geser/klik ikon ☺.", WARNA.Aksen)

-- Daftarkan fungsi pembersihan jika script dijalankan ulang
lingkungan.KurooEmoteCleanup = function()
    Status.SudahDihancurkan = true
    hentikanEmoteAktif(0)
    bersihkanKoneksiKarakter()
    for _, koneksi in ipairs(Status.DaftarKoneksi) do
        pcall(function() koneksi:Disconnect() end)
    end
    table.clear(Status.DaftarKoneksi)
    if LayarGui and LayarGui.Parent then
        LayarGui:Destroy()
    end
end
