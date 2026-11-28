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
local weatherSplashPart = nil
local weatherConn = nil
local Snow3D = { folder = nil, flakes = {} }

-- ========== SEASON & WEATHER AMBIENT AUDIO (AUTO-FALLBACK PUBLIC SFX) ==========
local SeasonAudio = {}
do
    local SoundService = game:GetService("SoundService")
    local TweenService = game:GetService("TweenService")

    local AUDIO_BANKS = {
        WinterWind = {
            "rbxassetid://9056698612",     -- Heavy Wind Ambience 2 (Roblox Official)
            "rbxassetid://6455667685",     -- Wind Sound Effect
            "rbxassetid://9120769331",     -- Wind Ambience Fallback
        },
        HeavyRain = {
            "rbxassetid://137061816250912", -- Rain Sound Effect
            "rbxassetid://88831001122997",  -- Rain Sound Effects
            "rbxassetid://16850883198",     -- Rain Ambience
            "rbxassetid://9056698612",      -- Wind/Storm Fallback
        },
        MistWind = {
            "rbxassetid://6455667685",     -- Soft Wind Ambience
            "rbxassetid://9056698612",     -- Wind Fallback
        },
    }

    local enabled = true
    local volume = 0.45
    local activeSound = nil
    local activeKind = nil
    local playToken = 0

    function SeasonAudio.Stop(instant)
        playToken = playToken + 1
        activeKind = nil
        if not activeSound then return end
        local snd = activeSound
        activeSound = nil
        if instant then
            pcall(function() snd:Stop(); snd:Destroy() end)
        else
            pcall(function()
                TweenService:Create(snd, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Volume = 0 }):Play()
            end)
            task.delay(0.5, function()
                if snd and snd.Parent then
                    pcall(function() snd:Stop(); snd:Destroy() end)
                end
            end)
        end
    end

    function SeasonAudio.Play(kind)
        if not kind or not AUDIO_BANKS[kind] then
            SeasonAudio.Stop(false)
            return
        end
        if activeKind == kind and activeSound and activeSound.Parent then
            pcall(function() activeSound.Volume = enabled and volume or 0 end)
            return
        end

        SeasonAudio.Stop(true)
        activeKind = kind
        playToken = playToken + 1
        local myToken = playToken

        if not enabled then return end

        local ids = AUDIO_BANKS[kind]
        task.spawn(function()
            for _, assetId in ipairs(ids) do
                if playToken ~= myToken or not enabled then return end
                local snd = Instance.new("Sound")
                snd.Name = "KurooSeasonAmbient"
                snd.SoundId = assetId
                snd.Looped = true
                snd.Volume = 0
                snd.PlaybackSpeed = (kind == "MistWind") and 0.82 or ((kind == "WinterWind") and 0.92 or 1.0)
                snd.Parent = SoundService

                local okPlay = pcall(function() snd:Play() end)
                -- Tunggu max 1.8 detik untuk memastikan audio benar-benar ter-load
                local waited = 0
                while waited < 1.8 and playToken == myToken do
                    if snd.IsLoaded and snd.TimeLength > 0 then break end
                    task.wait(0.15)
                    waited = waited + 0.15
                end

                if playToken ~= myToken or not enabled then
                    pcall(function() snd:Stop(); snd:Destroy() end)
                    return
                end

                if okPlay and snd.IsLoaded and snd.TimeLength > 0 then
                    activeSound = snd
                    pcall(function()
                        TweenService:Create(snd, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Volume = volume }):Play()
                    end)
                    return
                else
                    pcall(function() snd:Stop(); snd:Destroy() end)
                end
            end
        end)
    end

    function SeasonAudio.SetEnabled(state)
        enabled = (state == true)
        if not enabled then
            if activeSound and activeSound.Parent then
                pcall(function() activeSound.Volume = 0 end)
            end
        else
            if activeSound and activeSound.Parent then
                pcall(function() activeSound.Volume = volume end)
            elseif activeKind then
                local k = activeKind
                activeKind = nil
                SeasonAudio.Play(k)
            end
        end
    end

    function SeasonAudio.SetVolume(pct)
        volume = math.clamp((tonumber(pct) or 45) / 100, 0, 1)
        if enabled and activeSound and activeSound.Parent then
            pcall(function() activeSound.Volume = volume end)
        end
    end
end

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
                if origObj:IsA("Sky") then
                    if preset.Skybox then
                        origObj.Parent = nil
                    end
                else
                    origObj.Parent = nil
                end
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

    -- Buat Skybox baru (hanya jika preset mendefinisikan Skybox custom)
    if preset.Skybox then
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
    end

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
    if weatherSplashPart then
        pcall(function() weatherSplashPart:Destroy() end)
        weatherSplashPart = nil
    end
    clear3DSnowflakes()

    if mode == "Normal" then
        SeasonAudio.Stop(false)
        return
    end

    local part = Instance.new("Part")
    part.Name = "KurooWeatherEmitter"
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Transparency = 1
    part.Size = (mode == "Hujan (Rain)") and Vector3.new(105, 1, 105) or Vector3.new(85, 1, 85)
    part.Parent = workspace
    weatherPart = part

    local pe = Instance.new("ParticleEmitter")
    pe.Name = "KurooWeatherParticles"
    pe.EmissionDirection = Enum.NormalId.Bottom

    if mode == "Hujan (Rain)" then
        -- Hujan SANGAT LEBAT & TEBAL (5 emitter PC / 2 Mobile + cipratan tanah + efek becek genangan air)
        local emitterCount = isMobile and 2 or 5
        local rainRate = isMobile and 190 or 480
        local function applyRainStyle(em)
            em.EmissionDirection = Enum.NormalId.Bottom
            em.Color = ColorSequence.new(Color3.fromRGB(205, 220, 238))
            em.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.08, 0.22),
                NumberSequenceKeypoint.new(0.88, 0.25),
                NumberSequenceKeypoint.new(1, 1),
            })
            em.Size = NumberSequence.new(0.56)
            em.Squash = NumberSequence.new(3.6)
            em.Rotation = NumberRange.new(-5, 5)
            em.Speed = NumberRange.new(78, 102)
            em.Acceleration = Vector3.new(0, -48, 0)
            em.Lifetime = NumberRange.new(0.45, 0.62)
            em.Rate = rainRate
            em.SpreadAngle = Vector2.new(3.5, 3.5)
            em.LightInfluence = 0.55
            em.LightEmission = 0.16
        end
        applyRainStyle(pe)
        for idx = 2, emitterCount do
            local extra = Instance.new("ParticleEmitter")
            extra.Name = "KurooWeatherRain_" .. tostring(idx)
            applyRainStyle(extra)
            extra.Parent = part
        end

        -- Layer cipratan air & embun tipis di permukaan tanah sekitar player
        local sp = Instance.new("Part")
        sp.Name = "KurooRainSplashEmitter"
        sp.Anchored = true
        sp.CanCollide = false
        sp.CanTouch = false
        sp.CanQuery = false
        sp.Transparency = 1
        sp.Size = Vector3.new(65, 0.5, 65)
        sp.Parent = workspace
        weatherSplashPart = sp

        local spe = Instance.new("ParticleEmitter")
        spe.Name = "KurooRainSplash"
        spe.EmissionDirection = Enum.NormalId.Top
        spe.Color = ColorSequence.new(Color3.fromRGB(200, 218, 235))
        spe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(0.7, 0.65),
            NumberSequenceKeypoint.new(1, 1),
        })
        spe.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.14),
            NumberSequenceKeypoint.new(0.5, 0.28),
            NumberSequenceKeypoint.new(1, 0.08),
        })
        spe.Speed = NumberRange.new(3.5, 7.5)
        spe.Acceleration = Vector3.new(0, -24, 0)
        spe.Lifetime = NumberRange.new(0.22, 0.38)
        spe.SpreadAngle = Vector2.new(45, 45)
        spe.Rate = isMobile and 45 or 140
        spe.Parent = sp

        -- Aktifkan suara hujan deras
        SeasonAudio.Play("HeavyRain")
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
    elseif mode == "Daun Gugur (Autumn)" then
        -- Partikel serpihan daun kering gugur + 3D Falling Dry Leaves berputar tertiup angin
        pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        pe.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(224, 138, 44)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(196, 86, 32)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 84, 34)),
        })
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(0.85, 0.25),
            NumberSequenceKeypoint.new(1, 1),
        })
        pe.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(0.5, 0.48),
            NumberSequenceKeypoint.new(1, 0.2),
        })
        pe.Speed = NumberRange.new(5, 10)
        pe.Lifetime = NumberRange.new(4.2, 6.2)
        pe.Rate = isMobile and 45 or 85
        pe.SpreadAngle = Vector2.new(32, 32)
        pe.Rotation = NumberRange.new(0, 360)
        pe.RotSpeed = NumberRange.new(-95, 95)
        pe.Drag = 0.2
        pe.LightEmission = 0.08

        local folder = Instance.new("Folder")
        folder.Name = "KurooAutumnLeaves3D"
        folder.Parent = workspace
        Snow3D.folder = folder

        local cam = getCamera()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = (root and root.Position) or (cam and cam.CFrame.Position) or Vector3.new(0, 20, 0)

        local leafPalette = {
            Color3.fromRGB(214, 96, 32),   -- Burnt Orange
            Color3.fromRGB(228, 162, 48),  -- Golden Amber
            Color3.fromRGB(178, 54, 34),   -- Dry Crimson
            Color3.fromRGB(156, 98, 42),   -- Golden Brown
            Color3.fromRGB(198, 124, 38),  -- Autumn Ochre
        }
        local leafCount = isMobile and 24 or 44
        for i = 1, leafCount do
            local leaf = Instance.new("Part")
            leaf.Name = "AutumnLeaf3D"
            local sc = 0.7 + math.random() * 0.55
            leaf.Size = Vector3.new(0.85 * sc, 0.05, 0.5 * sc)
            leaf.Color = leafPalette[math.random(1, #leafPalette)]
            leaf.Material = Enum.Material.SmoothPlastic
            leaf.Anchored = true
            leaf.CanCollide = false
            leaf.CanTouch = false
            leaf.CanQuery = false
            leaf.CastShadow = false
            leaf.Parent = folder

            table.insert(Snow3D.flakes, {
                model = leaf,
                core = leaf,
                arms = {},
                offset = Vector3.new(math.random(-44, 44), math.random(-4, 32), math.random(-44, 44)),
                fallSpeed = 2.6 + math.random() * 3.0,
                swayAmp = 2.4 + math.random() * 3.0,
                swayFreq = 0.9 + math.random() * 1.1,
                phase = math.random() * math.pi * 2,
                rotX = math.random() * math.pi * 2,
                rotY = math.random() * math.pi * 2,
                rotSpeedX = (math.random() - 0.5) * 3.4,
                rotSpeedY = (math.random() - 0.5) * 3.8,
            })
            leaf.CFrame = CFrame.new(origin + Snow3D.flakes[i].offset)
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
        if weatherSplashPart and weatherSplashPart.Parent then
            weatherSplashPart.CFrame = CFrame.new(basePos.X, basePos.Y - 2.6, basePos.Z)
        end

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

-- ========== DARKNESS, FOG & CINEMATIC BORDER CONTROLLER ==========
local VisualEnv = {}
do
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")

    local darknessLevel = 0
    local fogLevel = 0
    local borderEnabled = false
    local borderGui = nil
    local origAtmoSnap = nil -- { inst = Atmosphere, Density = number, Haze = number }

    local function getBaseLighting()
        local p = (activeSkyPreset ~= "Default") and SkyShaderPresets[activeSkyPreset] or nil
        if p then
            return p.Brightness or OriginalLightingSnapshot.Brightness,
                p.Exposure or OriginalLightingSnapshot.ExposureCompensation,
                p.Ambient or OriginalLightingSnapshot.Ambient,
                p.Outdoor or OriginalLightingSnapshot.OutdoorAmbient
        end
        return OriginalLightingSnapshot.Brightness,
            OriginalLightingSnapshot.ExposureCompensation,
            OriginalLightingSnapshot.Ambient,
            OriginalLightingSnapshot.OutdoorAmbient
    end

    function VisualEnv.SetDarkness(pct)
        darknessLevel = math.clamp(tonumber(pct) or 0, 0, 100)
        local baseBright, baseExp, baseAmb, baseOut = getBaseLighting()
        local oldCC = Lighting:FindFirstChild("KurooDarknessCC")

        if darknessLevel <= 0 then
            if oldCC then pcall(function() oldCC:Destroy() end) end
            Lighting.Brightness           = baseBright
            Lighting.ExposureCompensation = baseExp
            Lighting.Ambient              = baseAmb
            Lighting.OutdoorAmbient       = baseOut
            return
        end

        local t = darknessLevel / 100
        Lighting.Brightness           = baseBright * (1 - t)
        Lighting.ExposureCompensation = baseExp - (t * 3.8)
        Lighting.Ambient              = baseAmb:Lerp(Color3.fromRGB(0, 0, 0), t)
        Lighting.OutdoorAmbient       = baseOut:Lerp(Color3.fromRGB(0, 0, 0), t)

        local cc = oldCC
        if not cc then
            cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "KurooDarknessCC"
            cc.Parent = Lighting
        end
        cc.Enabled    = true
        cc.Brightness = -(t * 0.55)
        cc.Contrast   = t * 0.14
        cc.Saturation = -(t * 0.35)
    end

    function VisualEnv.SetFog(pct)
        fogLevel = math.clamp(tonumber(pct) or 0, 0, 100)
        local customAtmo = Lighting:FindFirstChild("KurooCustomFogAtmo")

        if fogLevel <= 0 then
            if customAtmo then pcall(function() customAtmo:Destroy() end) end
            Lighting.FogStart = OriginalLightingSnapshot.FogStart
            Lighting.FogEnd   = OriginalLightingSnapshot.FogEnd
            Lighting.FogColor = OriginalLightingSnapshot.FogColor

            local activeAtmo = Lighting:FindFirstChild("KurooShaderAtmosphere")
            if activeAtmo and activeSkyPreset ~= "Default" and SkyShaderPresets[activeSkyPreset] and SkyShaderPresets[activeSkyPreset].Atmosphere then
                local a = SkyShaderPresets[activeSkyPreset].Atmosphere
                activeAtmo.Density = a.Density
                activeAtmo.Haze    = a.Haze
            elseif origAtmoSnap and origAtmoSnap.inst and origAtmoSnap.inst.Parent then
                origAtmoSnap.inst.Density = origAtmoSnap.Density
                origAtmoSnap.inst.Haze    = origAtmoSnap.Haze
            end
            origAtmoSnap = nil
            return
        end

        local t = fogLevel / 100
        Lighting.FogStart = math.max(0, math.floor(35 * (1 - t)))
        Lighting.FogEnd   = math.floor(1200 * ((1 - t) ^ 2.2) + 18)

        local atmo = Lighting:FindFirstChild("KurooShaderAtmosphere") or Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo and atmo.Name ~= "KurooCustomFogAtmo" then
            if not origAtmoSnap or origAtmoSnap.inst ~= atmo then
                origAtmoSnap = { inst = atmo, Density = atmo.Density, Haze = atmo.Haze }
            end
            atmo.Density = math.clamp(0.22 + t * 0.72, 0, 0.96)
            atmo.Haze    = math.clamp(1.0 + t * 9.0, 0, 10)
        else
            if not customAtmo then
                customAtmo = Instance.new("Atmosphere")
                customAtmo.Name  = "KurooCustomFogAtmo"
                customAtmo.Color = Color3.fromRGB(175, 185, 195)
                customAtmo.Decay = Color3.fromRGB(120, 130, 145)
                customAtmo.Offset = 0.05
                customAtmo.Parent = Lighting
            end
            customAtmo.Density = math.clamp(0.22 + t * 0.72, 0, 0.96)
            customAtmo.Haze    = math.clamp(1.0 + t * 9.0, 0, 10)
        end
    end

    function VisualEnv.SetCinematicBorder(enabled, instant)
        borderEnabled = (enabled == true)
        if not borderEnabled then
            if borderGui then
                local g = borderGui
                borderGui = nil
                if instant then
                    pcall(function() g:Destroy() end)
                else
                    local top = g:FindFirstChild("TopBar")
                    local bot = g:FindFirstChild("BottomBar")
                    local ti = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    if top then pcall(function() TweenService:Create(top, ti, { Size = UDim2.new(1, 0, 0, 0) }):Play() end) end
                    if bot then pcall(function() TweenService:Create(bot, ti, { Size = UDim2.new(1, 0, 0, 0) }):Play() end) end
                    task.delay(0.35, function()
                        if g and g.Parent then pcall(function() g:Destroy() end) end
                    end)
                end
            end
            return
        end

        if borderGui and borderGui.Parent then return end

        local gui = Instance.new("ScreenGui")
        gui.Name = "KurooCinematicBorder"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 1
        local parented = pcall(function() gui.Parent = CoreGui end)
        if not parented or not gui.Parent then
            pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
        end
        borderGui = gui

        local barHeight = 0.105

        local top = Instance.new("Frame")
        top.Name = "TopBar"
        top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        top.BorderSizePixel = 0
        top.Active = false
        top.Position = UDim2.new(0, 0, 0, 0)
        top.Size = instant and UDim2.new(1, 0, barHeight, 0) or UDim2.new(1, 0, 0, 0)
        top.Parent = gui

        local bot = Instance.new("Frame")
        bot.Name = "BottomBar"
        bot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bot.BorderSizePixel = 0
        bot.Active = false
        bot.AnchorPoint = Vector2.new(0, 1)
        bot.Position = UDim2.new(0, 0, 1, 0)
        bot.Size = instant and UDim2.new(1, 0, barHeight, 0) or UDim2.new(1, 0, 0, 0)
        bot.Parent = gui

        if not instant then
            local ti = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            pcall(function() TweenService:Create(top, ti, { Size = UDim2.new(1, 0, barHeight, 0) }):Play() end)
            pcall(function() TweenService:Create(bot, ti, { Size = UDim2.new(1, 0, barHeight, 0) }):Play() end)
        end
    end

    function VisualEnv.ResetAll(instant)
        VisualEnv.SetDarkness(0)
        VisualEnv.SetFog(0)
        if instant then
            VisualEnv.SetCinematicBorder(false, true)
        end
    end
end

local function resetAllVisualShaders()
    setWeatherMode("Normal")
    applySkyShaderPreset("Default")
    VisualEnv.ResetAll(false)
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
    if Season._StopZoo then pcall(Season._StopZoo) end
    if Season._RestoreWet then pcall(Season._RestoreWet) end
    SeasonAudio.Stop(instant == true)
    VisualEnv.SetCinematicBorder(false, instant == true)
    restoreSeasonMap(instant == true)
    resetAllVisualShaders()
end

-- ===== TANAH BASAH (efek Musim Hujan: gelap + mengkilap, 100% bisa di-reset) =====
local wetGround = { Parts = {}, Terrain = {}, Conn = nil, Token = 0, S = 1 }
local WET_MATS = {
    [Enum.Material.Grass] = true, [Enum.Material.LeafyGrass] = true, [Enum.Material.Ground] = true,
    [Enum.Material.Mud] = true, [Enum.Material.Sand] = true, [Enum.Material.Sandstone] = true,
    [Enum.Material.Asphalt] = true, [Enum.Material.Pavement] = true, [Enum.Material.Cobblestone] = true,
}
local WET_TERRAIN = {
    Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud,
    Enum.Material.Sand, Enum.Material.Sandstone, Enum.Material.Rock, Enum.Material.Slate,
    Enum.Material.Asphalt, Enum.Material.Pavement, Enum.Material.Cobblestone,
}

local function wetColor(c, s)
    local k = 1 - 0.38 * s
    return Color3.new(c.R * k * 0.96, c.G * k * 0.98, c.B * k)
end

local function wetifyPart(d)
    if not d:IsA("BasePart") or d:IsA("Terrain") then return end
    if wetGround.Parts[d] or d.Transparency > 0.9 then return end
    if d:FindFirstChildOfClass("SurfaceAppearance") then return end
    local flatLarge = d.Size.Y <= 6 and d.Size.X >= 20 and d.Size.Z >= 20
    if not (WET_MATS[d.Material] or flatLarge) then return end
    if isCharacterDescendant(d) then return end
    wetGround.Parts[d] = { d.Color, d.Reflectance }
    pcall(function()
        d.Color = wetColor(d.Color, wetGround.S)
        d.Reflectance = math.clamp(math.max(d.Reflectance, 0.06 + 0.16 * wetGround.S), 0, 0.3)
    end)
end

local function restoreWetGround()
    wetGround.Token = wetGround.Token + 1
    if wetGround.Conn then wetGround.Conn:Disconnect(); wetGround.Conn = nil end
    for part, orig in pairs(wetGround.Parts) do
        if part and part.Parent then
            pcall(function()
                part.Color = orig[1]
                part.Reflectance = orig[2]
            end)
        end
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        for mat, col in pairs(wetGround.Terrain) do
            pcall(function() terrain:SetMaterialColor(mat, col) end)
        end
    end
    wetGround = { Parts = {}, Terrain = {}, Conn = nil, Token = wetGround.Token, S = 1 }
end
Season._RestoreWet = restoreWetGround

local function applyWetGround(strength)
    restoreWetGround()
    wetGround.S = strength or 1
    local token = wetGround.Token
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        for _, mat in ipairs(WET_TERRAIN) do
            pcall(function()
                local orig = terrain:GetMaterialColor(mat)
                wetGround.Terrain[mat] = orig
                terrain:SetMaterialColor(mat, wetColor(orig, wetGround.S))
            end)
        end
    end
    wetGround.Conn = workspace.DescendantAdded:Connect(wetifyPart)
    task.spawn(function()
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            if wetGround.Token ~= token then return end
            wetifyPart(d)
            n = n + 1
            if n % 1200 == 0 then task.wait() end
        end
    end)
end

-- ===== CHRISTMAS ZOO: 8 SNOWMAN + 5 RUSA BERJALAN + 1 RUDOLPH PENGIKUT =====
local XmasZoo = (function()
    local Z = { Folder = nil, Conn = nil, Animals = {}, Pet = nil, PetCF = nil, Params = nil, LastChar = nil }
    local rng = Random.new()
    local TAU = math.pi * 2
    local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

    local function mkPart(parent, name, size, color, mat, shape)
        local p = Instance.new("Part")
        p.Name, p.Size, p.Color = name, size, color
        p.Material = mat or Enum.Material.SmoothPlastic
        if shape then p.Shape = shape end
        p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Massless = false, false, false, false, true
        p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        p.Parent = parent
        return p
    end

    local function mkWeld(p0, p1, c0)
        local w = Instance.new("Weld")
        w.Part0, w.Part1, w.C0 = p0, p1, c0 or CFrame.new()
        w.Parent = p0
        return w
    end

    local function setFilter()
        local list = { Z.Folder }
        if Z.Pet then list[#list + 1] = Z.Pet end
        if LocalPlayer.Character then list[#list + 1] = LocalPlayer.Character end
        if seasonGiftsFolder then list[#list + 1] = seasonGiftsFolder end
        if Snow3D.folder then list[#list + 1] = Snow3D.folder end
        Z.Params.FilterDescendantsInstances = list
        Z.LastChar = LocalPlayer.Character
    end

    local function groundAt(x, z, refY)
        local res = workspace:Raycast(Vector3.new(x, refY + 10, z), Vector3.new(0, -140, 0), Z.Params)
        if res and res.Material ~= Enum.Material.Water then return res.Position.Y end
        return nil
    end

    local function findSpot(center, rmin, rmax)
        for _ = 1, 12 do
            local ang = rng:NextNumber(0, TAU)
            local r = rng:NextNumber(rmin, rmax)
            local x, z = center.X + math.cos(ang) * r, center.Z + math.sin(ang) * r
            local gy = groundAt(x, z, center.Y)
            if gy and math.abs(gy - center.Y) < 16 then return Vector3.new(x, gy, z) end
        end
        return nil
    end

    local function buildSnowman()
        local white, black = rgb(248, 250, 255), rgb(25, 25, 28)
        local m = Instance.new("Model")
        m.Name = "KurooSnowman"
        local base = mkPart(m, "Base", Vector3.new(3.4, 3.4, 3.4), white, Enum.Material.Snow, Enum.PartType.Ball)
        base.Anchored = true
        m.PrimaryPart = base
        local mid = mkPart(m, "Mid", Vector3.new(2.5, 2.5, 2.5), white, Enum.Material.Snow, Enum.PartType.Ball)
        mkWeld(base, mid, CFrame.new(0, 2.3, 0))
        local head = mkPart(m, "Head", Vector3.new(1.8, 1.8, 1.8), white, Enum.Material.Snow, Enum.PartType.Ball)
        mkWeld(base, head, CFrame.new(0, 4.1, 0))
        for _, s in ipairs({ -1, 1 }) do
            local eye = mkPart(m, "Eye", Vector3.new(0.2, 0.2, 0.2), black, nil, Enum.PartType.Ball)
            mkWeld(head, eye, CFrame.new(s * 0.32, 0.22, -0.8))
        end
        local nose = mkPart(m, "Nose", Vector3.new(0.9, 0.22, 0.22), rgb(255, 140, 30), nil, Enum.PartType.Cylinder)
        mkWeld(head, nose, CFrame.new(0, -0.05, -1.0) * CFrame.Angles(0, math.rad(90), 0))
        for i, y in ipairs({ 2.7, 2.3, 1.9 }) do
            local b = mkPart(m, "Button", Vector3.new(0.3, 0.3, 0.3), black, nil, Enum.PartType.Ball)
            mkWeld(base, b, CFrame.new(0, y, i == 2 and -1.2 or -1.15))
        end
        local scarf = mkPart(m, "Scarf", Vector3.new(0.4, 2.0, 2.0), rgb(210, 25, 38), Enum.Material.Fabric, Enum.PartType.Cylinder)
        mkWeld(base, scarf, CFrame.new(0, 3.45, 0) * CFrame.Angles(0, 0, math.rad(90)))
        local brim = mkPart(m, "Brim", Vector3.new(0.15, 1.9, 1.9), black, nil, Enum.PartType.Cylinder)
        mkWeld(base, brim, CFrame.new(0, 4.95, 0) * CFrame.Angles(0, 0, math.rad(90)))
        local crown = mkPart(m, "Crown", Vector3.new(1.0, 1.2, 1.2), black, nil, Enum.PartType.Cylinder)
        mkWeld(base, crown, CFrame.new(0, 5.5, 0) * CFrame.Angles(0, 0, math.rad(90)))
        for _, side in ipairs({ -1, 1 }) do
            local arm = mkPart(m, "Arm", Vector3.new(1.9, 0.18, 0.18), rgb(92, 62, 38), Enum.Material.Wood)
            mkWeld(base, arm, CFrame.new(side * 1.05, 2.7, 0) * CFrame.Angles(0, 0, side * math.rad(30)) * CFrame.new(side * 0.95, 0, 0))
        end
        return m
    end

    local function buildDeer()
        local brown, dark, cream = rgb(150, 105, 66), rgb(112, 76, 46), rgb(236, 224, 205)
        local fab, wood = Enum.Material.Fabric, Enum.Material.Wood
        local m = Instance.new("Model")
        m.Name = "KurooDeer"
        local body = mkPart(m, "Body", Vector3.new(1.4, 1.3, 2.8), brown, fab)
        body.Anchored = true
        m.PrimaryPart = body
        local neck = mkPart(m, "Neck", Vector3.new(0.6, 1.4, 0.6), brown, fab)
        mkWeld(body, neck, CFrame.new(0, 0.7, -1.25) * CFrame.Angles(math.rad(-35), 0, 0))
        local head = mkPart(m, "Head", Vector3.new(0.7, 0.7, 1.1), brown, fab)
        mkWeld(body, head, CFrame.new(0, 1.35, -2.1) * CFrame.Angles(math.rad(15), 0, 0))
        local nose = mkPart(m, "Nose", Vector3.new(0.28, 0.28, 0.28), rgb(20, 20, 20), nil, Enum.PartType.Ball)
        mkWeld(head, nose, CFrame.new(0, -0.05, -0.6))
        for _, s in ipairs({ -1, 1 }) do
            local ear = mkPart(m, "Ear", Vector3.new(0.12, 0.5, 0.28), dark, fab)
            mkWeld(head, ear, CFrame.new(s * 0.38, 0.4, 0.25) * CFrame.Angles(0, 0, -s * math.rad(35)))
            local ant = mkPart(m, "Antler", Vector3.new(0.1, 1.1, 0.1), rgb(205, 185, 150), wood)
            mkWeld(head, ant, CFrame.new(s * 0.22, 0.85, 0.1) * CFrame.Angles(0, 0, -s * math.rad(18)))
            local br = mkPart(m, "AntlerBranch", Vector3.new(0.08, 0.55, 0.08), rgb(205, 185, 150), wood)
            mkWeld(head, br, CFrame.new(s * 0.34, 0.95, -0.1) * CFrame.Angles(math.rad(-30), 0, -s * math.rad(50)))
        end
        local tail = mkPart(m, "Tail", Vector3.new(0.3, 0.4, 0.25), cream, fab)
        mkWeld(body, tail, CFrame.new(0, 0.4, 1.45))
        local legs = {}
        for _, dx in ipairs({ -0.5, 0.5 }) do
            for _, dz in ipairs({ -1.0, 1.0 }) do
                local leg = mkPart(m, "Leg", Vector3.new(0.32, 1.8, 0.32), dark, fab)
                legs[#legs + 1] = { W = mkWeld(body, leg), dx = dx, dz = dz, hy = -0.65, len = 1.8 }
            end
        end
        return m, legs, 2.45
    end

    local function buildPetRudolph()
        local m = Instance.new("Model")
        m.Name = "KurooRudolph"
        local body = mkPart(m, "Body", Vector3.new(1.5, 1.05, 2.1), rgb(125, 82, 50), Enum.Material.Fabric)
        body.Anchored = true
        local head = mkPart(m, "Head", Vector3.new(0.78, 0.78, 0.88), rgb(135, 90, 56), Enum.Material.Fabric)
        head.Anchored = true
        local nose = mkPart(m, "Nose", Vector3.new(0.3, 0.3, 0.3), rgb(230, 20, 30), Enum.Material.Neon, Enum.PartType.Ball)
        nose.Anchored = true
        local pl = Instance.new("PointLight")
        pl.Color, pl.Range, pl.Brightness = rgb(255, 50, 50), 6, 1.8
        pl.Parent = nose
        for i, side in ipairs({ -1, 1 }) do
            local ant = mkPart(m, "Antler" .. i, Vector3.new(0.14, 0.7, 0.14), rgb(95, 65, 38), Enum.Material.Wood)
            ant.Anchored = true
            ant:SetAttribute("Side", side)
        end
        for i, dx in ipairs({ -0.52, 0.52 }) do
            for j, dz in ipairs({ -0.75, 0.75 }) do
                local leg = mkPart(m, "Leg" .. i .. j, Vector3.new(0.22, 0.95, 0.22), rgb(100, 68, 42), Enum.Material.Fabric)
                leg.Anchored = true
                leg:SetAttribute("DX", dx)
                leg:SetAttribute("DZ", dz)
            end
        end
        m.PrimaryPart = body
        return m
    end

    local function poseAnimal(a)
        local bob = math.sin(a.Phase * 2) * 0.05 * a.Mv
        for _, l in ipairs(a.Legs) do
            local off = ((l.dx * l.dz) > 0) and 0 or math.pi
            local ang = math.sin(a.Phase + off) * a.Amp * a.Mv
            l.W.C0 = CFrame.new(l.dx, l.hy, l.dz) * CFrame.Angles(ang, 0, 0) * CFrame.new(0, -l.len / 2, 0)
        end
        a.Model:PivotTo(CFrame.new(a.Pos.X, a.Pos.Y + a.BodyH + bob, a.Pos.Z) * CFrame.Angles(0, a.Yaw, 0))
    end

    local function placeAnimal(a, center)
        local spot = findSpot(center, 22, 85)
        if not spot then return false end
        a.Pos, a.GroundY, a.Good = spot, spot.Y, spot
        a.Yaw = rng:NextNumber(0, TAU)
        a.State, a.Timer, a.Mv = "idle", rng:NextNumber(0.5, 3.5), 0
        return true
    end

    local function stepAnimal(a, dt, t, ppos)
        if not a.Model.Parent then return end
        if ppos and (a.Pos - ppos).Magnitude > 170 then
            if placeAnimal(a, ppos) then poseAnimal(a) end
            return
        end
        if a.State == "idle" then
            a.Timer = a.Timer - dt
            if a.Timer <= 0 then
                local picked = false
                for _ = 1, 6 do
                    local ang = rng:NextNumber(0, TAU)
                    local dist = rng:NextNumber(8, 24)
                    local tx, tz = a.Pos.X + math.cos(ang) * dist, a.Pos.Z + math.sin(ang) * dist
                    local gy = groundAt(tx, tz, a.Pos.Y)
                    if gy and math.abs(gy - a.Pos.Y) < 6 then
                        a.Target, a.State, picked = Vector3.new(tx, gy, tz), "walk", true
                        break
                    end
                end
                if not picked then a.Timer = 1.5 end
            end
        else
            local to = Vector3.new(a.Target.X - a.Pos.X, 0, a.Target.Z - a.Pos.Z)
            if to.Magnitude < 1.2 then
                a.State, a.Timer = "idle", rng:NextNumber(2.0, 6.0)
            else
                local dir = to.Unit
                local want = math.atan2(-dir.X, -dir.Z)
                local diff = (want - a.Yaw + math.pi) % TAU - math.pi
                a.Yaw = a.Yaw + math.clamp(diff, -3 * dt, 3 * dt)
                if math.abs(diff) < 1.2 then
                    local fx, fz = -math.sin(a.Yaw), -math.cos(a.Yaw)
                    a.Pos = Vector3.new(a.Pos.X + fx * a.Speed * dt, a.Pos.Y, a.Pos.Z + fz * a.Speed * dt)
                end
            end
        end
        if t - a.LastRay > 0.1 then
            a.LastRay = t
            local gy = groundAt(a.Pos.X, a.Pos.Z, a.Pos.Y)
            if gy and math.abs(gy - a.GroundY) < 7 then
                a.GroundY, a.Good = gy, a.Pos
            elseif a.Good then
                a.Pos, a.State, a.Timer = a.Good, "idle", 1
            end
        end
        a.Pos = Vector3.new(a.Pos.X, a.Pos.Y + (a.GroundY - a.Pos.Y) * math.min(dt * 10, 1), a.Pos.Z)
        a.Mv = a.Mv + (((a.State == "walk") and 1 or 0) - a.Mv) * math.min(dt * 8, 1)
        a.Phase = a.Phase + dt * a.Speed * 1.5 * (0.2 + 0.8 * a.Mv)
        poseAnimal(a)
    end

    local function updatePet(t, dt)
        local m = Z.Pet
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local body = m and m:FindFirstChild("Body")
        if not (root and body) then return end
        local targetCf = root.CFrame * CFrame.new(3.2, 0, 3.5)
        local cur = Z.PetCF or body.CFrame
        local alpha = 1 - math.exp(-dt * 3.2)
        local newPos = cur.Position:Lerp(targetCf.Position, alpha)
        local lookDir = targetCf.Position - newPos
        local flat = Vector3.new(lookDir.X, 0, lookDir.Z)
        local facing = flat.Magnitude > 0.1 and CFrame.lookAt(newPos, newPos + flat) or CFrame.new(newPos)
        local bob = math.sin(t * 4) * 0.08
        local finalCf = facing * CFrame.new(0, 1.5 + bob, 0)
        Z.PetCF = finalCf
        body.CFrame = finalCf
        local head = m:FindFirstChild("Head")
        if head then head.CFrame = finalCf * CFrame.new(0, 0.55, -1.25) end
        local nose = m:FindFirstChild("Nose")
        if nose then nose.CFrame = finalCf * CFrame.new(0, 0.5, -1.7) end
        for i = 1, 2 do
            local ant = m:FindFirstChild("Antler" .. i)
            if ant then
                local side = ant:GetAttribute("Side") or 1
                ant.CFrame = finalCf * CFrame.new(0.25 * side, 0.98, -1.25) * CFrame.Angles(math.rad(20 * side), 0, math.rad(25 * side))
            end
        end
        for i = 1, 2 do
            for j = 1, 2 do
                local leg = m:FindFirstChild("Leg" .. i .. j)
                if leg then
                    local dx, dz = leg:GetAttribute("DX") or 0, leg:GetAttribute("DZ") or 0
                    local step = math.sin(t * 6 + (dx + dz) * 2) * 0.15
                    leg.CFrame = finalCf * CFrame.new(dx, -0.52 + math.abs(step), dz)
                end
            end
        end
    end

    function Z.Stop()
        if Z.Conn then Z.Conn:Disconnect(); Z.Conn = nil end
        if Z.Folder then pcall(function() Z.Folder:Destroy() end); Z.Folder = nil end
        if Z.Pet then pcall(function() Z.Pet:Destroy() end); Z.Pet = nil end
        Z.Animals, Z.PetCF = {}, nil
    end

    function Z.Start()
        Z.Stop()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        Z.Folder = Instance.new("Folder")
        Z.Folder.Name = "KurooSnowZoo"
        Z.Folder.Parent = workspace
        Z.Params = RaycastParams.new()
        Z.Params.FilterType = Enum.RaycastFilterType.Exclude
        Z.Params.RespectCanCollide = true
        setFilter()

        local c = root.Position
        for _ = 1, 8 do
            local spot = findSpot(c, 12, 75)
            if spot then
                local sm = buildSnowman()
                local dx, dz = c.X - spot.X, c.Z - spot.Z
                sm:PivotTo(CFrame.new(spot.X, spot.Y + 1.6, spot.Z) * CFrame.Angles(0, math.atan2(-dx, -dz) + rng:NextNumber(-0.5, 0.5), 0))
                sm.Parent = Z.Folder
            end
        end
        for _ = 1, 5 do
            local m, legs, h = buildDeer()
            local a = { Model = m, Legs = legs, BodyH = h, Phase = 0, Mv = 0, LastRay = 0, Speed = 7.5, Amp = 0.6 }
            if placeAnimal(a, c) then
                m.Parent = Z.Folder
                poseAnimal(a)
                Z.Animals[#Z.Animals + 1] = a
            else
                m:Destroy()
            end
        end

        local t0 = os.clock()
        Z.Conn = RunService.Heartbeat:Connect(function(dt)
            dt = math.min(dt, 0.1)
            local now = os.clock()
            if LocalPlayer.Character ~= Z.LastChar then setFilter() end
            local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local ppos = r and r.Position
            for _, a in ipairs(Z.Animals) do
                pcall(stepAnimal, a, dt, now, ppos)
            end
        end)
    end
    return Z
end)()
Season._StopZoo = XmasZoo.Stop

local function applySeasonMode(modeName)
    seasonTaskId = seasonTaskId + 1
    local myTaskId = seasonTaskId

    if modeName == "Normal (OFF)" or modeName == "Default" then
        disableSeasonMode(false)
        notify("Season Mode", "Map dikembalikan ke kondisi normal.", 2)
        return
    end

    if modeName == "Christmas Winter" then
        clearSeasonGifts()
        pcall(XmasZoo.Stop)
        pcall(restoreWetGround)
        VisualEnv.SetCinematicBorder(false, false)
        activeSeasonMode = "Christmas Winter"
        Season.Active = "Christmas Winter"
        notify("Season Mode", "Mengaktifkan Christmas Winter (Sky + Salju 3D + Snowman + Rusa + Kado)...", 2.5)

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

        -- 2. Hujan Salju Kristal (Model Salju 2-Layer) + Suara Angin Dingin
        setWeatherMode("Snowfall (Salju)")
        SeasonAudio.Play("WinterWind")

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
                -- 5. Spawn ~15 kado Natal random + 8 Snowman + 5 Rusa berjalan + 1 Rudolph pengikut
                spawnRandomChristmasGifts(15)
                pcall(XmasZoo.Start)
                notify("Season Mode", "Christmas Winter aktif! (Salju 3D, Snowman, Rusa & Kado)", 2.5)
            end
        end)
    elseif modeName == "Musim Hujan" then
        clearSeasonGifts()
        pcall(XmasZoo.Stop)
        VisualEnv.SetCinematicBorder(false, false)
        restoreSeasonMap(true)
        activeSeasonMode = "Musim Hujan"
        Season.Active = "Musim Hujan"
        notify("Season Mode", "Mengaktifkan Musim Hujan (Mendung + Hujan Deras + Tanah Basah)...", 2.5)

        if not SkyShaderPresets["Musim Hujan"] then
            SkyShaderPresets["Musim Hujan"] = {
                ClockTime  = 15.0,
                Brightness = 1.05,
                Ambient    = Color3.fromRGB(80, 90, 105),
                Outdoor    = Color3.fromRGB(100, 110, 125),
                Exposure   = -0.3,
                Atmosphere = {
                    Density = 0.45,
                    Offset  = 0.1,
                    Color   = Color3.fromRGB(150, 160, 175),
                    Decay   = Color3.fromRGB(100, 110, 125),
                    Glare   = 0,
                    Haze    = 2.4,
                },
                Bloom = { Intensity = 0.3, Size = 22, Threshold = 1.0 },
                CC    = { Brightness = -0.02, Contrast = 0.12, Saturation = -0.3, TintColor = Color3.fromRGB(190, 203, 220) },
                SunRays = { Intensity = 0.0, Spread = 0.5 },
                Clouds = { Cover = 0.95, Density = 0.9, Color = Color3.fromRGB(120, 128, 140) },
            }
        end
        applySkyShaderPreset("Musim Hujan")
        setWeatherMode("Hujan (Rain)")
        applyWetGround(1.0)
        notify("Season Mode", "Musim Hujan aktif sepenuhnya!", 2.5)
    elseif modeName == "Musim Kabut" then
        clearSeasonGifts()
        pcall(XmasZoo.Stop)
        pcall(restoreWetGround)
        restoreSeasonMap(true)
        setWeatherMode("Normal")
        activeSeasonMode = "Musim Kabut"
        Season.Active = "Musim Kabut"
        notify("Season Mode", "Mengaktifkan Musim Kabut (Kabut Tebal + Hijau Gelap Sunset + Cinematic Border)...", 2.5)

        if not SkyShaderPresets["Musim Kabut"] then
            SkyShaderPresets["Musim Kabut"] = {
                ClockTime  = 17.65,
                Brightness = 1.65,
                Ambient    = Color3.fromRGB(24, 52, 38),
                Outdoor    = Color3.fromRGB(48, 76, 56),
                Exposure   = -0.22,
                Skybox = {
                    Bk = "rbxassetid://15502525195",
                    Dn = "rbxassetid://15502522797",
                    Ft = "rbxassetid://15502524520",
                    Lf = "rbxassetid://15502522129",
                    Rt = "rbxassetid://15502523711",
                    Up = "rbxassetid://15502526102",
                    StarCount = 2500,
                    SunSize   = 24,
                    MoonSize  = 11,
                },
                Atmosphere = {
                    Density = 0.62,
                    Offset  = 0.0,
                    Color   = Color3.fromRGB(132, 156, 130),
                    Decay   = Color3.fromRGB(198, 118, 66),
                    Glare   = 0.9,
                    Haze    = 4.5,
                },
                Bloom = { Intensity = 0.6, Size = 32, Threshold = 0.85 },
                CC    = { Brightness = -0.03, Contrast = 0.16, Saturation = -0.05, TintColor = Color3.fromRGB(224, 240, 222) },
                SunRays = { Intensity = 0.28, Spread = 0.95 },
                Clouds = { Cover = 0.72, Density = 0.8, Color = Color3.fromRGB(225, 172, 130) },
            }
        end
        applySkyShaderPreset("Musim Kabut")
        Lighting.FogColor = Color3.fromRGB(72, 92, 76)
        Lighting.FogStart = 12
        Lighting.FogEnd   = 240
        VisualEnv.SetCinematicBorder(true, false)
        SeasonAudio.Play("MistWind")
        notify("Season Mode", "Musim Kabut aktif! (Cinematic Border + Sunset Hijau Gelap + Angin Kabut)", 2.5)
    elseif modeName == "Musim Gugur (Autumn)" then
        clearSeasonGifts()
        pcall(XmasZoo.Stop)
        pcall(restoreWetGround)
        VisualEnv.SetCinematicBorder(false, false)
        restoreSeasonMap(true)
        activeSeasonMode = "Musim Gugur (Autumn)"
        Season.Active = "Musim Gugur (Autumn)"
        notify("Season Mode", "Mengaktifkan Musim Gugur (Golden Brown + Terrain Autumn + Daun Kering Gugur)...", 2.5)

        if not SkyShaderPresets["Musim Gugur (Autumn)"] then
            SkyShaderPresets["Musim Gugur (Autumn)"] = {
                ClockTime  = 15.2,
                Brightness = 2.2,
                Ambient    = Color3.fromRGB(118, 102, 82),
                Outdoor    = Color3.fromRGB(158, 138, 108),
                Exposure   = 0.05,
                Skybox = {
                    Bk = "rbxassetid://18603249071",
                    Dn = "rbxassetid://18603241716",
                    Ft = "rbxassetid://18603244510",
                    Lf = "rbxassetid://18603245276",
                    Rt = "rbxassetid://18603246382",
                    Up = "rbxassetid://18603261859",
                    StarCount = 2000,
                    SunSize   = 20,
                    MoonSize  = 11,
                },
                Atmosphere = {
                    Density = 0.28,
                    Offset  = 0.2,
                    Color   = Color3.fromRGB(224, 210, 188),
                    Decay   = Color3.fromRGB(178, 154, 124),
                    Glare   = 0.25,
                    Haze    = 1.4,
                },
                Bloom = { Intensity = 0.35, Size = 22, Threshold = 0.96 },
                CC    = { Brightness = 0.01, Contrast = 0.1, Saturation = -0.04, TintColor = Color3.fromRGB(252, 244, 232) },
                SunRays = { Intensity = 0.12, Spread = 0.75 },
                Clouds = { Cover = 0.52, Density = 0.6, Color = Color3.fromRGB(246, 238, 226) },
            }
        end
        applySkyShaderPreset("Musim Gugur (Autumn)")
        setWeatherMode("Daun Gugur (Autumn)")
        SeasonAudio.Play("MistWind")

        -- Ubah warna Terrain menjadi nuansa Golden Brown lembut & natural
        local autumnTerrainColors = {
            [Enum.Material.Grass]      = Color3.fromRGB(154, 128, 78),
            [Enum.Material.LeafyGrass] = Color3.fromRGB(164, 124, 72),
            [Enum.Material.Ground]     = Color3.fromRGB(126, 98, 68),
            [Enum.Material.Mud]        = Color3.fromRGB(108, 84, 58),
            [Enum.Material.Sand]       = Color3.fromRGB(182, 158, 118),
            [Enum.Material.Rock]       = Color3.fromRGB(128, 116, 100),
            [Enum.Material.Slate]      = Color3.fromRGB(122, 112, 98),
            [Enum.Material.Snow]       = Color3.fromRGB(218, 202, 178),
        }
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for mat, autCol in pairs(autumnTerrainColors) do
                if seasonTerrainSnapshots[mat] == nil then
                    local ok, orig = pcall(function() return terrain:GetMaterialColor(mat) end)
                    if ok and orig then
                        seasonTerrainSnapshots[mat] = orig
                    end
                end
                pcall(function()
                    terrain:SetMaterialColor(mat, autCol)
                end)
            end
        end

        -- Ubah Part rumput / daun / tanah di Workspace menjadi warna musim gugur lembut secara bertahap
        task.spawn(function()
            local foliageCols = {
                Color3.fromRGB(184, 118, 58),
                Color3.fromRGB(196, 154, 76),
                Color3.fromRGB(156, 86, 54),
                Color3.fromRGB(148, 112, 68),
            }
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
                    local lname = string.lower(inst.Name)
                    local isFoliage = lname:find("leaf", 1, true) or lname:find("leaves", 1, true)
                        or lname:find("foliage", 1, true) or lname:find("bush", 1, true)
                        or lname:find("tree", 1, true) or lname:find("daun", 1, true)
                        or lname:find("hedge", 1, true)
                    local isStone = (inst.Material == Enum.Material.Rock or inst.Material == Enum.Material.Slate)
                    pcall(function()
                        if isFoliage then
                            inst.Color = foliageCols[math.random(1, #foliageCols)]
                        elseif isStone then
                            inst.Color = Color3.fromRGB(130, 118, 102)
                        else
                            inst.Color = Color3.fromRGB(156, 126, 78)
                        end
                    end)
                end
                processed = processed + 1
                if processed % 350 == 0 then
                    task.wait()
                end
            end
            if seasonTaskId == myTaskId then
                notify("Season Mode", "Musim Gugur (Autumn) aktif sepenuhnya!", 2.5)
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
    Desc = "Ubah seluruh suasana map (Sky + Terrain + Efek Musim)",
    Options = {
        "Normal (OFF)",
        "Christmas Winter",
        "Musim Hujan",
        "Musim Kabut",
        "Musim Gugur (Autumn)",
    },
    Default = "Normal (OFF)",
    Callback = function(modeName)
        if isSyncingSeasonUI then return end
        Season.Apply(modeName)
    end,
})

sectionSeason:AddToggle({
    Name = "Season Ambient Sound",
    Desc = "Suara angin dingin (Christmas), hujan deras & angin kabut",
    Default = true,
    Callback = function(state)
        SeasonAudio.SetEnabled(state)
    end,
})

sectionSeason:AddSlider({
    Name = "Ambient Volume",
    Min = 0,
    Max = 100,
    Default = 45,
    Callback = function(val)
        SeasonAudio.SetVolume(val)
    end,
})

sectionSeason:AddButton({
    Name = "Reset Season Mode",
    Desc = "Kembalikan Terrain, Part, Sky & Efek Musim ke kondisi asli map",
    Callback = function()
        isSyncingSeasonUI = true
        Season.Disable(false)
        if seasonDropdown then pcall(function() seasonDropdown:Set("Normal (OFF)") end) end
        isSyncingSeasonUI = false
        notify("Season Mode", "Seluruh map dikembalikan ke kondisi normal.", 2)
    end,
})
end

local sectionBrightness = tabVisuals:AddSection({ Name = "Lighting, Fog & Darkness" })
local isSyncingEnvUI = false
local darknessSlider, fogSlider, brightnessSlider, cinematicBorderToggle

darknessSlider = sectionBrightness:AddSlider({
    Name = "Darkness (Kegelapan)",
    Desc = "Gelapkan map secara nyata (Exposure + Ambient + ColorCorrection)",
    Min = 0,
    Max = 100,
    Default = 0,
    Callback = function(val)
        if isSyncingEnvUI then return end
        VisualEnv.SetDarkness(val)
    end,
})

fogSlider = sectionBrightness:AddSlider({
    Name = "Fog Intensity (Kabut)",
    Desc = "Atur ketebalan kabut & jarak pandang secara real-time",
    Min = 0,
    Max = 100,
    Default = 0,
    Callback = function(val)
        if isSyncingEnvUI then return end
        VisualEnv.SetFog(val)
    end,
})

brightnessSlider = sectionBrightness:AddSlider({
    Name = "Brightness",
    Min = 0,
    Max = 10,
    Default = math.clamp(math.floor(originalBrightness + 0.5), 0, 10),
    Callback = function(val)
        if isSyncingEnvUI then return end
        setBrightness(val)
    end,
})

cinematicBorderToggle = sectionBrightness:AddToggle({
    Name = "Cinematic Border (Atas-Bawah)",
    Desc = "Tambahkan garis hitam sinematik atas & bawah layar",
    Default = false,
    Callback = function(state)
        if isSyncingEnvUI then return end
        VisualEnv.SetCinematicBorder(state, false)
    end,
})

sectionBrightness:AddButton({
    Name = "Reset Lighting, Fog & Darkness",
    Callback = function()
        isSyncingEnvUI = true
        VisualEnv.ResetAll(false)
        VisualEnv.SetCinematicBorder(false, false)
        resetBrightness()
        if darknessSlider        then pcall(function() darknessSlider:Set(0) end) end
        if fogSlider             then pcall(function() fogSlider:Set(0) end) end
        if brightnessSlider      then pcall(function() brightnessSlider:Set(math.clamp(math.floor(originalBrightness + 0.5), 0, 10)) end) end
        if cinematicBorderToggle then pcall(function() cinematicBorderToggle:Set(false) end) end
        isSyncingEnvUI = false
        notify("Lighting & Fog", "Kegelapan, kabut & brightness dikembalikan ke default.", 2)
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
        "DLSS / Ultra RTX",
        "Cinematic",
        "Senja",
        "Vibrant Anime",
        "Cyberpunk Neon",
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
        "Daun Gugur (Autumn)",
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
        pcall(function()
            SeasonAudio.Stop(true)
            VisualEnv.ResetAll(true)
            VisualEnv.SetCinematicBorder(false, true)
        end)
    end)
end