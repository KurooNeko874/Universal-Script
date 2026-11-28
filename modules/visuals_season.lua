return function(ctx)
    local KurooUI         = ctx.KurooUI
    local Players         = ctx.Players
    local RunService      = ctx.RunService
    local UserInputService= ctx.UserInputService
    local TeleportService = ctx.TeleportService
    local Lighting        = ctx.Lighting
    local ContentProvider = ctx.ContentProvider
    local StarterGui      = ctx.StarterGui
    local VirtualUser     = ctx.VirtualUser
    local HttpService     = ctx.HttpService
    local LocalPlayer     = ctx.LocalPlayer
    local isMobile        = ctx.isMobile
    local getCamera       = ctx.getCamera
    local notify          = ctx.notify
    local loadRemoteData  = ctx.loadRemoteData
    local KUROO_DATA_BASE = ctx.KUROO_DATA_BASE
    local window          = ctx.window
-- ========== BRIGHTNESS SYSTEM ==========
local originalBrightness = Lighting.Brightness

local function setBrightness(val)
    Lighting.Brightness = val
end

local function resetBrightness()
    Lighting.Brightness = originalBrightness
end

-- ========== SKY, SHADER, TIME SET & WEATHER SYSTEM ==========
local OriginalLightingSnapshot = {
    ClockTime                = Lighting.ClockTime,
    Brightness               = Lighting.Brightness,
    Ambient                  = Lighting.Ambient,
    OutdoorAmbient           = Lighting.OutdoorAmbient,
    ColorShift_Top           = Lighting.ColorShift_Top,
    ColorShift_Bottom        = Lighting.ColorShift_Bottom,
    ExposureCompensation     = Lighting.ExposureCompensation,
    EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    FogColor                 = Lighting.FogColor,
    FogStart                 = Lighting.FogStart,
    FogEnd                   = Lighting.FogEnd,
}

local originalSkyBackups = {}      -- Simpan Sky & Atmosphere asli game agar bisa dikembalikan utuh
local originalEffectStates = {}    -- [Instance] = original Enabled boolean
local hasBackedUpLighting = false
local activeSkyPreset = "Default"
local activeWeatherMode = "Normal"
local weatherPart = nil
local weatherConn = nil
local Snow3D = { folder = nil, flakes = {} }

local KUROO_SHADER_NAMES = {
    KurooShaderSky        = true,
    KurooShaderAtmosphere = true,
    KurooShaderBloom      = true,
    KurooShaderCC         = true,
    KurooShaderSunRays    = true,
}

local function backupOriginalLightingObjects()
    if hasBackedUpLighting then return end
    hasBackedUpLighting = true
    for _, child in ipairs(Lighting:GetChildren()) do
        if not KUROO_SHADER_NAMES[child.Name] then
            if child:IsA("Sky") or child:IsA("Atmosphere") then
                table.insert(originalSkyBackups, child)
            elseif child:IsA("PostEffect") then
                originalEffectStates[child] = child.Enabled
            end
        end
    end
end

local function clearKurooShaderObjects()
    for _, child in ipairs(Lighting:GetChildren()) do
        if KUROO_SHADER_NAMES[child.Name] then
            pcall(function() child:Destroy() end)
        end
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local kClouds = terrain:FindFirstChild("KurooShaderClouds")
        if kClouds then
            pcall(function() kClouds:Destroy() end)
        end
    end
end

local function restoreOriginalLightingObjects()
    clearKurooShaderObjects()
    for _, origObj in ipairs(originalSkyBackups) do
        pcall(function()
            if origObj and origObj.Parent == nil then
                origObj.Parent = Lighting
            end
        end)
    end
    for eff, wasEnabled in pairs(originalEffectStates) do
        pcall(function()
            if eff and eff.Parent then
                eff.Enabled = wasEnabled
            end
        end)
    end
end

-- Preset Sky & Shader (Dreamcore + 5 Preset Estetik & RTX)
local SkyShaderPresets = loadRemoteData(KUROO_DATA_BASE .. "/sky_shaders.lua", {})

local function applySkyShaderPreset(presetName)
    activeSkyPreset = presetName
    if presetName == "Default" then
        restoreOriginalLightingObjects()
        Lighting.Brightness               = OriginalLightingSnapshot.Brightness
        Lighting.Ambient                  = OriginalLightingSnapshot.Ambient
        Lighting.OutdoorAmbient           = OriginalLightingSnapshot.OutdoorAmbient
        Lighting.ColorShift_Top           = OriginalLightingSnapshot.ColorShift_Top
        Lighting.ColorShift_Bottom        = OriginalLightingSnapshot.ColorShift_Bottom
        Lighting.ExposureCompensation     = OriginalLightingSnapshot.ExposureCompensation
        Lighting.EnvironmentDiffuseScale  = OriginalLightingSnapshot.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = OriginalLightingSnapshot.EnvironmentSpecularScale
        return
    end

    local preset = SkyShaderPresets[presetName]
    if not preset then return end

    backupOriginalLightingObjects()
    clearKurooShaderObjects()

    -- Sembunyikan sementara Sky/Atmosphere bawaan game agar tidak menumpuk
    for _, origObj in ipairs(originalSkyBackups) do
        pcall(function()
            if origObj and origObj.Parent == Lighting then
                origObj.Parent = nil
            end
        end)
    end
    for eff in pairs(originalEffectStates) do
        pcall(function()
            if eff and eff.Parent then
                eff.Enabled = false
            end
        end)
    end

    -- Terapkan Lighting
    Lighting.ClockTime                = preset.ClockTime
    Lighting.Brightness               = preset.Brightness
    Lighting.Ambient                  = preset.Ambient
    Lighting.OutdoorAmbient           = preset.Outdoor
    Lighting.ExposureCompensation     = preset.Exposure
    Lighting.EnvironmentDiffuseScale  = 0.85
    Lighting.EnvironmentSpecularScale = 0.9

    -- Buat Skybox baru
    local sky = Instance.new("Sky")
    sky.Name            = "KurooShaderSky"
    sky.SkyboxBk        = preset.Skybox.Bk
    sky.SkyboxDn        = preset.Skybox.Dn
    sky.SkyboxFt        = preset.Skybox.Ft
    sky.SkyboxLf        = preset.Skybox.Lf
    sky.SkyboxRt        = preset.Skybox.Rt
    sky.SkyboxUp        = preset.Skybox.Up
    sky.StarCount       = preset.Skybox.StarCount
    sky.SunAngularSize  = preset.Skybox.SunSize
    sky.MoonAngularSize = preset.Skybox.MoonSize
    sky.CelestialBodiesShown = true
    sky.Parent          = Lighting

    -- Buat Atmosphere
    local atmo = Instance.new("Atmosphere")
    atmo.Name    = "KurooShaderAtmosphere"
    atmo.Density = preset.Atmosphere.Density
    atmo.Offset  = preset.Atmosphere.Offset
    atmo.Color   = preset.Atmosphere.Color
    atmo.Decay   = preset.Atmosphere.Decay
    atmo.Glare   = preset.Atmosphere.Glare
    atmo.Haze    = preset.Atmosphere.Haze
    atmo.Parent  = Lighting

    -- Buat Bloom
    local bloom = Instance.new("BloomEffect")
    bloom.Name      = "KurooShaderBloom"
    bloom.Intensity = preset.Bloom.Intensity
    bloom.Size      = preset.Bloom.Size
    bloom.Threshold = preset.Bloom.Threshold
    bloom.Parent    = Lighting

    -- Buat ColorCorrection
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name       = "KurooShaderCC"
    cc.Brightness = preset.CC.Brightness
    cc.Contrast   = preset.CC.Contrast
    cc.Saturation = preset.CC.Saturation
    cc.TintColor  = preset.CC.TintColor
    cc.Parent     = Lighting

    -- Buat SunRays
    local rays = Instance.new("SunRaysEffect")
    rays.Name      = "KurooShaderSunRays"
    rays.Intensity = preset.SunRays.Intensity
    rays.Spread    = preset.SunRays.Spread
    rays.Parent    = Lighting

    -- Buat Clouds dinamis di Terrain (jika didukung)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and preset.Clouds then
        pcall(function()
            local clouds = Instance.new("Clouds")
            clouds.Name    = "KurooShaderClouds"
            clouds.Cover   = preset.Clouds.Cover
            clouds.Density = preset.Clouds.Density
            clouds.Color   = preset.Clouds.Color
            clouds.Enabled = true
            clouds.Parent  = terrain
        end)
    end
end

local function setWeatherMode(mode)
    local function clear3DSnowflakes()
        if Snow3D.folder then
            pcall(function() Snow3D.folder:Destroy() end)
            Snow3D.folder = nil
        end
        table.clear(Snow3D.flakes)
    end

    local function create3DSnowflakeModel(parentFolder, scale)
        local m = Instance.new("Model")
        m.Name = "Snowflake3D"
        local root = Instance.new("Part")
        root.Name = "Core"
        root.Size = Vector3.new(scale, scale * 0.14, scale * 0.14)
        root.Color = Color3.fromRGB(245, 250, 255)
        root.Material = Enum.Material.Neon
        root.Anchored = true
        root.CanCollide = false
        root.CanTouch = false
        root.CanQuery = false
        root.CastShadow = false
        root.Parent = m

        for _, deg in ipairs({ 60, -60 }) do
            local arm = root:Clone()
            arm.Name = "Arm"
            arm.Parent = m
            arm:SetAttribute("Angle", math.rad(deg))
        end

        m.PrimaryPart = root
        m.Parent = parentFolder
        return m, root
    end

    activeWeatherMode = mode
    if weatherConn then
        weatherConn:Disconnect()
        weatherConn = nil
    end
    if weatherPart then
        pcall(function() weatherPart:Destroy() end)
        weatherPart = nil
    end
    clear3DSnowflakes()

    if mode == "Normal" then
        return
    end

    local part = Instance.new("Part")
    part.Name = "KurooWeatherEmitter"
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Transparency = 1
    part.Size = Vector3.new(85, 1, 85)
    part.Parent = workspace
    weatherPart = part

    local pe = Instance.new("ParticleEmitter")
    pe.Name = "KurooWeatherParticles"
    pe.EmissionDirection = Enum.NormalId.Bottom

    if mode == "Hujan (Rain)" then
        pe.Texture = "rbxassetid://241876428"
        pe.Color = ColorSequence.new(Color3.fromRGB(185, 215, 255))
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(0.85, 0.45),
            NumberSequenceKeypoint.new(1, 1),
        })
        pe.Size = NumberSequence.new(0.18)
        pe.Squash = NumberSequence.new(2.4)
        pe.Speed = NumberRange.new(58, 78)
        pe.Lifetime = NumberRange.new(0.85, 1.2)
        pe.Rate = 280
        pe.SpreadAngle = Vector2.new(4, 4)
        pe.LightEmission = 0.2
    elseif mode == "Snowfall (Salju)" then
        -- Built-in Roblox sparkle/snowflake texture (100% pasti tampil di semua executor!)
        pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.85, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        })
        pe.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(0.5, 0.6),
            NumberSequenceKeypoint.new(1, 0.25),
        })
        pe.Speed = NumberRange.new(9, 15)
        pe.Lifetime = NumberRange.new(3.5, 5.2)
        pe.Rate = 200
        pe.SpreadAngle = Vector2.new(20, 20)
        pe.Rotation = NumberRange.new(0, 360)
        pe.RotSpeed = NumberRange.new(-70, 70)
        pe.Drag = 0
        pe.LightEmission = 0.5

        -- 3D Snowflake Crystal Models (36 keping kristal salju 3D berputar lembut di sekitar player)
        local folder = Instance.new("Folder")
        folder.Name = "KurooSnowflakes3D"
        folder.Parent = workspace
        Snow3D.folder = folder

        local cam = getCamera()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = (root and root.Position) or (cam and cam.CFrame.Position) or Vector3.new(0, 20, 0)

        for i = 1, 36 do
            local scale = 0.45 + (math.random() * 0.45)
            local mdl, core = create3DSnowflakeModel(folder, scale)
            local arms = {}
            for _, c in ipairs(mdl:GetChildren()) do
                if c ~= core and c:IsA("BasePart") then
                    table.insert(arms, { part = c, ang = c:GetAttribute("Angle") or 0 })
                end
            end
            table.insert(Snow3D.flakes, {
                model = mdl,
                core = core,
                arms = arms,
                offset = Vector3.new(math.random(-42, 42), math.random(-5, 32), math.random(-42, 42)),
                fallSpeed = 4.5 + math.random() * 4.5,
                swayAmp = 1.2 + math.random() * 1.8,
                swayFreq = 0.8 + math.random() * 1.2,
                phase = math.random() * math.pi * 2,
                rotX = math.random() * math.pi * 2,
                rotY = math.random() * math.pi * 2,
                rotSpeedX = (math.random() - 0.5) * 2.2,
                rotSpeedY = (math.random() - 0.5) * 2.6,
            })
            core.CFrame = CFrame.new(origin + Snow3D.flakes[i].offset)
        end
    end

    pe.Parent = part

    local elapsed = 0
    weatherConn = RunService.RenderStepped:Connect(function(dt)
        if not weatherPart or not weatherPart.Parent then return end
        elapsed = elapsed + dt
        local cam = getCamera()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local basePos = (root and root.Position) or (cam and cam.CFrame.Position)
        if not basePos then return end

        weatherPart.CFrame = CFrame.new(basePos.X, basePos.Y + 26, basePos.Z)

        if #Snow3D.flakes > 0 then
            for _, fl in ipairs(Snow3D.flakes) do
                fl.offset = Vector3.new(
                    fl.offset.X,
                    fl.offset.Y - (fl.fallSpeed * dt),
                    fl.offset.Z
                )
                if fl.offset.Y < -10 then
                    fl.offset = Vector3.new(math.random(-42, 42), 28 + math.random(0, 8), math.random(-42, 42))
                end
                fl.rotX = fl.rotX + fl.rotSpeedX * dt
                fl.rotY = fl.rotY + fl.rotSpeedY * dt
                local swayX = math.sin(elapsed * fl.swayFreq + fl.phase) * fl.swayAmp
                local swayZ = math.cos(elapsed * fl.swayFreq * 0.8 + fl.phase) * fl.swayAmp
                local cf = CFrame.new(basePos.X + fl.offset.X + swayX, basePos.Y + fl.offset.Y, basePos.Z + fl.offset.Z + swayZ)
                    * CFrame.Angles(fl.rotX, fl.rotY, 0)
                fl.core.CFrame = cf
                for _, a in ipairs(fl.arms) do
                    a.part.CFrame = cf * CFrame.Angles(0, 0, a.ang)
                end
            end
        end
    end)
end

local function resetAllVisualShaders()
    setWeatherMode("Normal")
    applySkyShaderPreset("Default")
    Lighting.ClockTime = OriginalLightingSnapshot.ClockTime
    Lighting.FogColor  = OriginalLightingSnapshot.FogColor
    Lighting.FogStart  = OriginalLightingSnapshot.FogStart
    Lighting.FogEnd    = OriginalLightingSnapshot.FogEnd
end

-- ========== SEASON MODE SYSTEM (CHRISTMAS WINTER: SKY + TERRAIN + PART + SNOW) ==========
local Season = {
    Active = "Normal (OFF)",
}
do
local activeSeasonMode = "Normal (OFF)"
local seasonTerrainSnapshots = {} -- [Enum.Material] = Color3
local seasonPartSnapshots = {}    -- [BasePart] = { Color = Color3, Material = Enum.Material }
local seasonGiftsFolder = nil
local seasonTaskId = 0

local function isCharacterDescendant(inst)
    local curr = inst
    while curr and curr ~= workspace do
        if curr:IsA("Model") and curr:FindFirstChildOfClass("Humanoid") then
            return true
        end
        curr = curr.Parent
    end
    return false
end

local GIFT_PALETTES = {
    { box = Color3.fromRGB(205, 28, 36),  ribbon = Color3.fromRGB(245, 200, 66) }, -- Merah + Emas
    { box = Color3.fromRGB(26, 130, 64),  ribbon = Color3.fromRGB(220, 36, 44)  }, -- Hijau Natal + Merah
    { box = Color3.fromRGB(242, 245, 250),ribbon = Color3.fromRGB(215, 26, 38)  }, -- Putih Salju + Merah
    { box = Color3.fromRGB(38, 102, 195), ribbon = Color3.fromRGB(235, 240, 250)}, -- Biru Winter + Perak
    { box = Color3.fromRGB(228, 178, 42), ribbon = Color3.fromRGB(195, 25, 34)  }, -- Emas + Merah
}

local function clearSeasonGifts()
    if seasonGiftsFolder then
        pcall(function() seasonGiftsFolder:Destroy() end)
        seasonGiftsFolder = nil
    end
end

local function createChristmasGiftModel(pos, yaw, parentFolder)
    local pal = GIFT_PALETTES[math.random(1, #GIFT_PALETTES)]
    local s = 1.9 + math.random() * 1.1 -- Ukuran 1.9 - 3.0 studs
    local h = s * (0.85 + math.random() * 0.25)

    local mdl = Instance.new("Model")
    mdl.Name = "ChristmasGift"

    local baseCF = CFrame.new(pos.X, pos.Y + (h / 2), pos.Z) * CFrame.Angles(0, yaw, 0)

    local box = Instance.new("Part")
    box.Name = "Box"
    box.Size = Vector3.new(s, h, s)
    box.CFrame = baseCF
    box.Color = pal.box
    box.Material = Enum.Material.SmoothPlastic
    box.Anchored = true
    box.CanCollide = false
    box.CanQuery = false
    box.Parent = mdl

    -- Pita melintang 2 arah
    local rib1 = Instance.new("Part")
    rib1.Name = "Ribbon1"
    rib1.Size = Vector3.new(s + 0.08, h + 0.08, s * 0.22)
    rib1.CFrame = baseCF
    rib1.Color = pal.ribbon
    rib1.Material = Enum.Material.SmoothPlastic
    rib1.Anchored = true
    rib1.CanCollide = false
    rib1.CanQuery = false
    rib1.Parent = mdl

    local rib2 = Instance.new("Part")
    rib2.Name = "Ribbon2"
    rib2.Size = Vector3.new(s * 0.22, h + 0.08, s + 0.08)
    rib2.CFrame = baseCF
    rib2.Color = pal.ribbon
    rib2.Material = Enum.Material.SmoothPlastic
    rib2.Anchored = true
    rib2.CanCollide = false
    rib2.CanQuery = false
    rib2.Parent = mdl

    -- Simpul pita (Bow) di atas kado
    for _, ang in ipairs({ 0.45, -0.45 }) do
        local bow = Instance.new("Part")
        bow.Name = "Bow"
        bow.Size = Vector3.new(s * 0.42, s * 0.16, s * 0.22)
        bow.CFrame = baseCF * CFrame.new(ang > 0 and s * 0.14 or -s * 0.14, h * 0.5 + s * 0.1, 0) * CFrame.Angles(0, 0, ang)
        bow.Color = pal.ribbon
        bow.Material = Enum.Material.Neon
        bow.Anchored = true
        bow.CanCollide = false
        bow.CanQuery = false
        bow.Parent = mdl
    end

    local glow = Instance.new("PointLight")
    glow.Color = pal.ribbon
    glow.Brightness = 0.45
    glow.Range = 7
    glow.Parent = box

    mdl.Parent = parentFolder
end

local function spawnRandomChristmasGifts(maxGifts)
    clearSeasonGifts()
    local folder = Instance.new("Folder")
    folder.Name = "KurooSeasonGifts"
    folder.Parent = workspace
    seasonGiftsFolder = folder

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local cam = getCamera()
    local center = (root and root.Position) or (cam and cam.CFrame.Position) or Vector3.new(0, 10, 0)

    local rcParams = RaycastParams.new()
    rcParams.FilterType = Enum.RaycastFilterType.Exclude
    local excludeList = { folder }
    if weatherPart then table.insert(excludeList, weatherPart) end
    if Snow3D.folder then table.insert(excludeList, Snow3D.folder) end
    if char then table.insert(excludeList, char) end
    rcParams.FilterDescendantsInstances = excludeList

    local placed = {}
    local targetCount = maxGifts or 15
    local attempts = 0

    while #placed < targetCount and attempts < 140 do
        attempts = attempts + 1
        local angle = math.random() * math.pi * 2
        local dist = 18 + math.random() * 105
        local rx = center.X + math.cos(angle) * dist
        local rz = center.Z + math.sin(angle) * dist

        local hit = workspace:Raycast(Vector3.new(rx, center.Y + 90, rz), Vector3.new(0, -180, 0), rcParams)
        if hit and hit.Instance and hit.Material ~= Enum.Material.Water and hit.Normal.Y > 0.75 then
            if not isCharacterDescendant(hit.Instance) then
                local tooClose = false
                for _, p in ipairs(placed) do
                    if (p - hit.Position).Magnitude < 18 then
                        tooClose = true
                        break
                    end
                end
                if not tooClose then
                    table.insert(placed, hit.Position)
                    createChristmasGiftModel(hit.Position, math.random() * math.pi * 2, folder)
                end
            end
        end
    end
end

local SEASON_TERRAIN_SNOW_COLORS = {
    [Enum.Material.Grass]       = Color3.fromRGB(240, 246, 255), -- Sekaligus mengubah rumput 3D Terrain jadi putih salju!
    [Enum.Material.LeafyGrass]  = Color3.fromRGB(238, 245, 255),
    [Enum.Material.Ground]      = Color3.fromRGB(232, 240, 250),
    [Enum.Material.Mud]         = Color3.fromRGB(224, 234, 246),
    [Enum.Material.Sand]        = Color3.fromRGB(236, 243, 252),
    [Enum.Material.Rock]        = Color3.fromRGB(205, 218, 232),
    [Enum.Material.Slate]       = Color3.fromRGB(210, 222, 236),
    [Enum.Material.Asphalt]     = Color3.fromRGB(215, 226, 238),
    [Enum.Material.Pavement]    = Color3.fromRGB(222, 232, 244),
    [Enum.Material.CrackedLava] = Color3.fromRGB(205, 218, 232),
}

local SEASON_PART_MATERIALS = {
    [Enum.Material.Grass]      = true,
    [Enum.Material.LeafyGrass] = true,
    [Enum.Material.Ground]     = true,
    [Enum.Material.Mud]        = true,
    [Enum.Material.Sand]       = true,
    [Enum.Material.Rock]       = true,
    [Enum.Material.Slate]      = true,
}

local SEASON_PART_KEYWORDS = {
    "grass", "rumput", "leaf", "leaves", "foliage", "daun", "bush", "ground", "tanah", "dirt", "terrain", "moss",
}

local function shouldSnowifyPart(part)
    if not part:IsA("BasePart") or part:IsA("Terrain") then return false end
    if part.Name == "KurooWeatherEmitter" or part.Transparency >= 0.95 then return false end
    if isCharacterDescendant(part) then return false end

    if SEASON_PART_MATERIALS[part.Material] then
        return true
    end

    local lower = string.lower(part.Name)
    for _, kw in ipairs(SEASON_PART_KEYWORDS) do
        if lower:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local function restoreSeasonMap(instant)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        for mat, origColor in pairs(seasonTerrainSnapshots) do
            pcall(function()
                terrain:SetMaterialColor(mat, origColor)
            end)
        end
    end
    table.clear(seasonTerrainSnapshots)

    local count = 0
    for part, snap in pairs(seasonPartSnapshots) do
        if part and part.Parent then
            pcall(function()
                part.Material = snap.Material
                part.Color = snap.Color
            end)
        end
        count = count + 1
        if not instant and count % 350 == 0 then
            task.wait()
        end
    end
    table.clear(seasonPartSnapshots)
end

local function disableSeasonMode(instant)
    seasonTaskId = seasonTaskId + 1
    activeSeasonMode = "Normal (OFF)"
    Season.Active = "Normal (OFF)"
    clearSeasonGifts()
    restoreSeasonMap(instant == true)
    resetAllVisualShaders()
end

local function applySeasonMode(modeName)
    seasonTaskId = seasonTaskId + 1
    local myTaskId = seasonTaskId

    if modeName == "Normal (OFF)" or modeName == "Default" then
        disableSeasonMode(false)
        notify("Season Mode", "Map dikembalikan ke kondisi normal.", 2)
        return
    end

    if modeName == "Christmas Winter" then
        activeSeasonMode = "Christmas Winter"
        Season.Active = "Christmas Winter"
        notify("Season Mode", "Mengaktifkan Christmas Winter (Sky + Terrain + Salju)...", 2.5)

        -- 1. Skybox Seamless + Winter Atmosphere + Lighting
        if not SkyShaderPresets["Christmas Winter"] then
            SkyShaderPresets["Christmas Winter"] = {
                ClockTime  = 15.8,
                Brightness = 2.45,
                Ambient    = Color3.fromRGB(145, 165, 190),
                Outdoor    = Color3.fromRGB(185, 205, 228),
                Exposure   = 0.14,
                Skybox = {
                    Bk = "rbxassetid://18603249071",
                    Dn = "rbxassetid://18603241716",
                    Ft = "rbxassetid://18603244510",
                    Lf = "rbxassetid://18603245276",
                    Rt = "rbxassetid://18603246382",
                    Up = "rbxassetid://18603261859",
                    StarCount = 3000,
                    SunSize   = 22,
                    MoonSize  = 12,
                },
                Atmosphere = {
                    Density = 0.42,
                    Offset  = 0.15,
                    Color   = Color3.fromRGB(218, 232, 248),
                    Decay   = Color3.fromRGB(165, 195, 228),
                    Glare   = 0.35,
                    Haze    = 2.4,
                },
                Bloom = { Intensity = 0.65, Size = 26, Threshold = 0.88 },
                CC    = { Brightness = 0.03, Contrast = 0.1, Saturation = -0.12, TintColor = Color3.fromRGB(236, 246, 255) },
                SunRays = { Intensity = 0.1, Spread = 0.8 },
                Clouds = { Cover = 0.78, Density = 0.75, Color = Color3.fromRGB(238, 246, 255) },
            }
        end
        applySkyShaderPreset("Christmas Winter")

        -- 2. Hujan Salju Kristal (Model Salju 2-Layer)
        setWeatherMode("Snowfall (Salju)")

        -- 3. Ubah Warna Terrain (Tanah & Rumput 3D jadi Putih Salju Instan!)
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for mat, snowCol in pairs(SEASON_TERRAIN_SNOW_COLORS) do
                if seasonTerrainSnapshots[mat] == nil then
                    local ok, orig = pcall(function() return terrain:GetMaterialColor(mat) end)
                    if ok and orig then
                        seasonTerrainSnapshots[mat] = orig
                    end
                end
                pcall(function()
                    terrain:SetMaterialColor(mat, snowCol)
                end)
            end
        end

        -- 4. Ubah Part Rumput / Tanah / Daun di Workspace secara bertahap (anti-lag)
        task.spawn(function()
            local descendants = workspace:GetDescendants()
            local processed = 0
            for _, inst in ipairs(descendants) do
                if seasonTaskId ~= myTaskId then return end
                if shouldSnowifyPart(inst) then
                    if not seasonPartSnapshots[inst] then
                        seasonPartSnapshots[inst] = {
                            Color = inst.Color,
                            Material = inst.Material,
                        }
                    end
                    local isStone = (inst.Material == Enum.Material.Rock or inst.Material == Enum.Material.Slate)
                    pcall(function()
                        inst.Material = Enum.Material.Snow
                        inst.Color = isStone and Color3.fromRGB(222, 234, 248) or Color3.fromRGB(238, 245, 255)
                    end)
                end
                processed = processed + 1
                if processed % 350 == 0 then
                    task.wait()
                end
            end
            if seasonTaskId == myTaskId then
                -- 5. Spawn ~15 kado Natal random di atas tanah/terrain (secukupnya, tidak terlalu padat)
                spawnRandomChristmasGifts(15)
                notify("Season Mode", "Christmas Winter aktif sepenuhnya! (Salju 3D + Kado Natal)", 2.5)
            end
        end)
    end
end

Season.Apply = applySeasonMode
Season.Disable = disableSeasonMode
end

-- ========== Tab 3: Visuals ==========
local tabVisuals = window:AddTab({ Name = "Visuals" })

do
local sectionSeason = tabVisuals:AddSection({ Name = "Season Mode" })
local isSyncingSeasonUI = false
local seasonDropdown

seasonDropdown = sectionSeason:AddDropdown({
    Name = "Season Preset",
    Desc = "Ubah seluruh suasana map (Sky + Terrain + Part + Salju)",
    Options = {
        "Normal (OFF)",
        "Christmas Winter",
    },
    Default = "Normal (OFF)",
    Callback = function(modeName)
        if isSyncingSeasonUI then return end
        Season.Apply(modeName)
    end,
})

sectionSeason:AddButton({
    Name = "Reset Season Mode",
    Desc = "Kembalikan Terrain, Part, Sky & Salju ke kondisi asli map",
    Callback = function()
        isSyncingSeasonUI = true
        Season.Disable(false)
        if seasonDropdown then pcall(function() seasonDropdown:Set("Normal (OFF)") end) end
        isSyncingSeasonUI = false
        notify("Season Mode", "Seluruh map dikembalikan ke kondisi normal.", 2)
    end,
})
end

local sectionBrightness = tabVisuals:AddSection({ Name = "Brightness" })
local brightnessSlider = sectionBrightness:AddSlider({
    Name = "Brightness",
    Min = 0,
    Max = 10,
    Default = math.clamp(math.floor(originalBrightness + 0.5), 0, 10),
    Callback = function(val)
        setBrightness(val)
    end,
})

sectionBrightness:AddButton({
    Name = "Reset Brightness",
    Callback = function()
        resetBrightness()
        brightnessSlider:Set(math.clamp(math.floor(originalBrightness + 0.5), 0, 10))
        notify("Brightness", "Reset ke default", 2)
    end,
})

local sectionShader = tabVisuals:AddSection({ Name = "Sky, Shader & Weather" })
local isSyncingShaderUI = false
local skyDropdown, timeSetSlider, weatherDropdown

skyDropdown = sectionShader:AddDropdown({
    Name = "Sky & Shader Preset",
    Options = {
        "Default",
        "Realistic RTX Day",
        "Classical Sunset Sky",
        "Pink Sky",
        "Cloudy Day Sky",
        "Purple Pink Clouds",
    },
    Default = "Default",
    Callback = function(presetName)
        if isSyncingShaderUI then return end
        applySkyShaderPreset(presetName)
        isSyncingShaderUI = true
        if timeSetSlider then
            timeSetSlider:Set(math.clamp(math.floor(Lighting.ClockTime + 0.5), 0, 24))
        end
        if brightnessSlider then
            brightnessSlider:Set(math.clamp(math.floor(Lighting.Brightness + 0.5), 0, 10))
        end
        isSyncingShaderUI = false
        notify("Sky & Shader", "Sky diganti ke: " .. presetName, 2)
    end,
})

timeSetSlider = sectionShader:AddSlider({
    Name = "Time Set (Jam)",
    Min = 0,
    Max = 24,
    Default = math.clamp(math.floor(OriginalLightingSnapshot.ClockTime + 0.5), 0, 24),
    Callback = function(val)
        if isSyncingShaderUI then return end
        Lighting.ClockTime = val
    end,
})

weatherDropdown = sectionShader:AddDropdown({
    Name = "Weather (Cuaca)",
    Options = {
        "Normal",
        "Hujan (Rain)",
        "Snowfall (Salju)",
    },
    Default = "Normal",
    Callback = function(mode)
        if isSyncingShaderUI then return end
        setWeatherMode(mode)
        notify("Weather", "Cuaca diubah ke: " .. mode, 2)
    end,
})

sectionShader:AddButton({
    Name = "Reset Sky, Time & Weather ke Semula",
    Callback = function()
        resetAllVisualShaders()
        isSyncingShaderUI = true
        if skyDropdown     then pcall(function() skyDropdown:Set("Default") end) end
        if weatherDropdown then pcall(function() weatherDropdown:Set("Normal") end) end
        if timeSetSlider   then timeSetSlider:Set(math.clamp(math.floor(OriginalLightingSnapshot.ClockTime + 0.5), 0, 24)) end
        if brightnessSlider then brightnessSlider:Set(math.clamp(math.floor(OriginalLightingSnapshot.Brightness + 0.5), 0, 10)) end
        isSyncingShaderUI = false
        notify("Visual Shader", "Sky, waktu, dan cuaca dikembalikan ke semula.", 2)
    end,
})

local sectionTheme = tabVisuals:AddSection({ Name = "UI Theme" })
sectionTheme:AddDropdown({
    Name = "Theme Preset",
    Options = {
        "Persona5",
        "Dark",
        "Light",
        "Crimson",
        "Midnight",
        "Red",
        "Violet",
        "Indigo",
        "Sky",
        "Emerald",
        "Rose",
        "Amber",
        "Monokai Pro",
        "Cotton Candy",
        "Rainbow",
    },
    Default = "Persona5",
    Callback = function(themeName)
        window:SetTheme(themeName)
        notify("UI Theme", "Tema diganti ke " .. themeName, 2)
    end,
})

sectionTheme:AddColorPicker({
    Name = "Custom Neon Accent",
    Color = Color3.fromRGB(255, 130, 20),
    Callback = function(color)
        window:ModifyTheme({ Neon = color })
    end,
})

    window:OnUnload(function()
        pcall(function()
            if Season and Season.Active ~= "Normal (OFF)" and Season.Disable then
                Season.Disable(true)
            end
        end)
    end)
end