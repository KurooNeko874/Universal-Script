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
-- ========== REJOIN SERVER ==========
local function rejoinGame()
    print("Rejoin Server")
    TeleportService:Teleport(game.PlaceId)
end

-- ========== CLICK TELEPORT (KHUSUS PC) ==========
local tpEnabled = false

if not isMobile then
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if tpEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local cam = getCamera()
            if not cam then return end
            local mouseLocation = UserInputService:GetMouseLocation()
            local ray = cam:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if hit and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end)
end

-- ========== FREECAM (KHUSUS PC, KEYBIND BISA DIUBAH) ==========
local freecam = { active = false, speed = 50, sensitivity = 0.2, angles = Vector2.new(0, 0), fov = 70 }
local isRightClicking = false

local function toggleFreecam()
    if isMobile then return end
    local cam = getCamera()
    if not cam then return end

    freecam.active = not freecam.active
    if freecam.active then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        freecam.fov = cam.FieldOfView
        local rx, ry = cam.CFrame:ToEulerAnglesYXZ()
        freecam.angles = Vector2.new(math.deg(ry), math.deg(rx))

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = true
        end
        cam.CameraType = Enum.CameraType.Scriptable
        notify("Freecam", "ON", 2)
    else
        isRightClicking = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
        end
        cam.CameraType = Enum.CameraType.Custom
        cam.FieldOfView = 70
        notify("Freecam", "OFF", 2)
    end
end

if not isMobile then
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if freecam.active and input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightClicking = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightClicking = false
            if freecam.active then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not freecam.active then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local cam = getCamera()
            if cam then
                freecam.fov = math.clamp(freecam.fov - (input.Position.Z * 5), 10, 120)
                cam.FieldOfView = freecam.fov
            end
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if not freecam.active then return end
        local cam = getCamera()
        if not cam then return end

        if isRightClicking then
            local delta = UserInputService:GetMouseDelta()
            freecam.angles = freecam.angles - (delta * freecam.sensitivity)
            freecam.angles = Vector2.new(freecam.angles.X, math.clamp(freecam.angles.Y, -80, 80))
        end

        local rot = CFrame.fromEulerAnglesYXZ(math.rad(freecam.angles.Y), math.rad(freecam.angles.X), 0)
        local move = Vector3.new()
        local vertical = 0
        local speed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and freecam.speed * 2 or freecam.speed

        if not UserInputService:GetFocusedTextBox() then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then vertical = vertical + 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then vertical = vertical - 1 end
        end

        local worldMove = rot:VectorToWorldSpace(move * speed * dt) + Vector3.new(0, vertical * speed * dt, 0)
        cam.CFrame = CFrame.new(cam.CFrame.Position + worldMove) * rot
    end)
end

-- ========== ANTI-AFK (RINGAN, BERBASIS EVENT IDLED) ==========
local antiAfkEnabled = false
local antiAfkConnection = nil

local function startAntiAfk()
    if antiAfkConnection then return end
    antiAfkConnection = LocalPlayer.Idled:Connect(function()
        if not antiAfkEnabled then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

local function stopAntiAfk()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
end

-- ========== ESP SYSTEM UNIVERSAL ==========
local espEnabled = false
local espData = { highlights = {}, nameTags = {} }
local espConnection = nil
local playerAddedConnection = nil

local function addESP(player)
    if player == LocalPlayer then return end
    if espData.highlights[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "UniversalESP"
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.2
    highlight.OutlineColor = Color3.fromRGB(0, 150, 255)
    highlight.FillColor = Color3.fromRGB(0, 150, 255)

    local nameTag = nil
    if typeof(Drawing) == "table" or typeof(Drawing) == "userdata" then
        local ok, tag = pcall(function()
            local t = Drawing.new("Text")
            t.Size = 14
            t.Center = true
            t.Outline = true
            t.OutlineColor = Color3.fromRGB(0, 0, 0)
            t.Color = Color3.fromRGB(255, 255, 255)
            t.Font = 2
            return t
        end)
        if ok then nameTag = tag end
    end

    espData.highlights[player] = highlight
    espData.nameTags[player] = nameTag

    if player.Character then highlight.Parent = player.Character end
    player.CharacterAdded:Connect(function(character)
        if espEnabled then highlight.Parent = character end
    end)
end

local function updateESP()
    if not espEnabled then return end
    local cam = getCamera()
    if not cam then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for player, highlight in pairs(espData.highlights) do
        local nameTag = espData.nameTags[player]
        local character = player.Character

        if character and character:FindFirstChild("Head") then
            local head = character.Head
            local headPos, onScreen = cam:WorldToViewportPoint(head.Position)
            local distanceText = ""
            if myRoot and character:FindFirstChild("HumanoidRootPart") then
                local distance = (myRoot.Position - character.HumanoidRootPart.Position).Magnitude
                distanceText = string.format(" [%.0fm]", distance)
            end

            if nameTag then
                if onScreen then
                    nameTag.Visible = true
                    nameTag.Position = Vector2.new(headPos.X, headPos.Y - 35)
                    nameTag.Text = player.Name .. distanceText
                else
                    nameTag.Visible = false
                end
            end
            highlight.Enabled = true
        else
            if nameTag then nameTag.Visible = false end
            highlight.Enabled = false
        end
    end
end

local function clearESP()
    for _, highlight in pairs(espData.highlights) do
        pcall(function() highlight:Destroy() end)
    end
    for _, nameTag in pairs(espData.nameTags) do
        pcall(function() nameTag:Remove() end)
    end
    espData.highlights = {}
    espData.nameTags = {}
end

-- ========== Tab 1: Main ==========
local tab1 = window:AddTab({ Name = "Main" })
local section1 = tab1:AddSection({ Name = "Main Section" })

section1:AddToggle({
    Name = "ESP",
    Default = false,
    Callback = function(state)
        espEnabled = state
        if state then
            for _, player in ipairs(Players:GetPlayers()) do
                addESP(player)
            end
            playerAddedConnection = Players.PlayerAdded:Connect(function(player)
                if espEnabled then addESP(player) end
            end)
            espConnection = RunService.RenderStepped:Connect(updateESP)
            notify("ESP", "ON", 2)
        else
            if espConnection then espConnection:Disconnect(); espConnection = nil end
            if playerAddedConnection then playerAddedConnection:Disconnect(); playerAddedConnection = nil end
            clearESP()
            notify("ESP", "OFF", 2)
        end
    end,
})

section1:AddToggle({
    Name = "Anti AFK",
    Default = false,
    Callback = function(state)
        antiAfkEnabled = state
        if state then
            startAntiAfk()
            notify("Anti AFK", "ON", 2)
        else
            stopAntiAfk()
            notify("Anti AFK", "OFF", 2)
        end
    end,
})

-- Khusus PC: Teleport (Ctrl + Klik) & Freecam (tidak ditampilkan di Mobile)
if not isMobile then
    section1:AddToggle({
        Name = "Teleport (Ctrl + Klik)",
        Default = false,
        Callback = function(state)
            tpEnabled = state
        end,
    })

    section1:AddButton({
        Name = "Toggle Freecam",
        Callback = function()
            toggleFreecam()
        end,
    })

    section1:AddKeybind({
        Name = "Freecam Keybind",
        Default = Enum.KeyCode.B,
        Callback = function()
            toggleFreecam()
        end,
    })
end

section1:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        rejoinGame()
    end,
})

    ctx.mainTab = tab1

-- ========== MOVEMENT (ADMIN FLY, NOCLIP, INFINITE JUMP) & FPS BOOSTER ==========
local ExtraMain = {}
do
    local flyEnabled = false
    local flySpeed = 60
    local flyConn = nil
    local flyBV = nil
    local flyBG = nil
    local flyDisabledAnimate = nil

    local function stopFly()
        flyEnabled = false
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
        if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
        if flyDisabledAnimate and flyDisabledAnimate.Parent then
            pcall(function() flyDisabledAnimate.Disabled = false end)
        end
        flyDisabledAnimate = nil
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum.PlatformStand = false end)
        end
    end

    local function startFly()
        stopFly()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then
            notify("Fly", "Karakter belum siap!", 2)
            return false
        end

        flyEnabled = true
        -- Pose diam berdiri tegak seperti Admin Map (PlatformStand + stop semua animasi)
        pcall(function() hum.PlatformStand = true end)
        local animScript = char:FindFirstChild("Animate")
        if animScript and animScript:IsA("LocalScript") and not animScript.Disabled then
            pcall(function() animScript.Disabled = true end)
            flyDisabledAnimate = animScript
        end
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
                pcall(function() tr:Stop(0) end)
            end
        end

        local bv = Instance.new("BodyVelocity")
        bv.Name = "KurooAdminFlyBV"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = root
        flyBV = bv

        local bg = Instance.new("BodyGyro")
        bg.Name = "KurooAdminFlyBG"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.D = 1200
        bg.CFrame = root.CFrame
        bg.Parent = root
        flyBG = bg

        flyConn = RunService.RenderStepped:Connect(function()
            if not flyEnabled then return end
            local c = LocalPlayer.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local cam = getCamera()
            if not r or not h or not cam or not flyBV or not flyBV.Parent or not flyBG or not flyBG.Parent then
                stopFly()
                return
            end

            -- Pastikan karakter tetap diam tegak (dummy/admin pose)
            if not h.PlatformStand then
                pcall(function() h.PlatformStand = true end)
            end

            -- Kunci orientasi tetap tegak menghadap arah horizontal kamera (tidak miring/nungging)
            local lookFlat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
            if lookFlat.Magnitude > 0.01 then
                flyBG.CFrame = CFrame.lookAt(r.Position, r.Position + lookFlat.Unit)
            end

            local moveVec = Vector3.zero
            if not UserInputService:GetFocusedTextBox() then
                if isMobile then
                    -- Mobile: gunakan joystick MoveDirection diproyeksikan ke arah kamera 3D
                    local md = h.MoveDirection
                    if md.Magnitude > 0.05 then
                        local camFlatLook = lookFlat.Magnitude > 0.01 and lookFlat.Unit or Vector3.new(0, 0, -1)
                        local camFlatRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
                        camFlatRight = camFlatRight.Magnitude > 0.01 and camFlatRight.Unit or Vector3.new(1, 0, 0)
                        local fwdAmt = md:Dot(camFlatLook)
                        local rightAmt = md:Dot(camFlatRight)
                        moveVec = (cam.CFrame.LookVector * fwdAmt) + (cam.CFrame.RightVector * rightAmt)
                    end
                else
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
                        moveVec = moveVec + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                        moveVec = moveVec - Vector3.new(0, 1, 0)
                    end
                end
            end

            if moveVec.Magnitude > 0.01 then
                local mult = (not isMobile and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)) and 1.8 or 1.0
                flyBV.Velocity = moveVec.Unit * (flySpeed * mult)
            else
                flyBV.Velocity = Vector3.zero
            end
        end)
        return true
    end

    -- Noclip
    local noclipEnabled = false
    local noclipConn = nil

    local function setNoclip(state)
        noclipEnabled = state
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if state then
            noclipConn = RunService.Stepped:Connect(function()
                if not noclipEnabled then return end
                local c = LocalPlayer.Character
                if not c then return end
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end)
        else
            local c = LocalPlayer.Character
            if c then
                for _, name in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head" }) do
                    local p = c:FindFirstChild(name)
                    if p and p:IsA("BasePart") then
                        pcall(function() p.CanCollide = true end)
                    end
                end
            end
        end
    end

    -- Infinite Jump & JumpPower
    local infJumpEnabled = false
    local customJumpPower = nil
    local defaultJumpPower = 50
    do
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and h.JumpPower > 0 then defaultJumpPower = math.floor(h.JumpPower + 0.5) end
    end

    local infJumpConn = UserInputService.JumpRequest:Connect(function()
        if not infJumpEnabled then return end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then
            pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end)

    local function applyJumpPower(val)
        customJumpPower = val
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then
            pcall(function()
                h.UseJumpPower = true
                h.JumpPower = val
            end)
        end
    end

    local charJumpConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        stopFly()
        if customJumpPower then
            local h = newChar:WaitForChild("Humanoid", 5)
            if h then
                task.wait(0.2)
                pcall(function()
                    h.UseJumpPower = true
                    h.JumpPower = customJumpPower
                end)
            end
        end
    end)

    -- FPS Booster / Anti-Lag (100% Reversible)
    local fpsBoostEnabled = false
    local fpsSnapshots = {
        GlobalShadows = nil,
        WaterWaveSize = nil,
        WaterWaveSpeed = nil,
        PartShadows = {},
        Effects = {},
    }

    local function setFpsBooster(state)
        fpsBoostEnabled = state
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if state then
            if fpsSnapshots.GlobalShadows == nil then
                fpsSnapshots.GlobalShadows = Lighting.GlobalShadows
            end
            pcall(function() Lighting.GlobalShadows = false end)
            if terrain then
                if fpsSnapshots.WaterWaveSize == nil then
                    fpsSnapshots.WaterWaveSize = terrain.WaterWaveSize
                    fpsSnapshots.WaterWaveSpeed = terrain.WaterWaveSpeed
                end
                pcall(function()
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                end)
            end
            task.spawn(function()
                local processed = 0
                for _, inst in ipairs(workspace:GetDescendants()) do
                    if not fpsBoostEnabled then return end
                    if inst:IsA("BasePart") and inst.CastShadow then
                        fpsSnapshots.PartShadows[inst] = true
                        pcall(function() inst.CastShadow = false end)
                    elseif (inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles"))
                        and inst.Enabled and not string.find(inst.Name, "Kuroo", 1, true) then
                        fpsSnapshots.Effects[inst] = true
                        pcall(function() inst.Enabled = false end)
                    end
                    processed = processed + 1
                    if processed % 400 == 0 then task.wait() end
                end
            end)
        else
            if fpsSnapshots.GlobalShadows ~= nil then
                pcall(function() Lighting.GlobalShadows = fpsSnapshots.GlobalShadows end)
                fpsSnapshots.GlobalShadows = nil
            end
            if terrain and fpsSnapshots.WaterWaveSize ~= nil then
                pcall(function()
                    terrain.WaterWaveSize = fpsSnapshots.WaterWaveSize
                    terrain.WaterWaveSpeed = fpsSnapshots.WaterWaveSpeed
                end)
                fpsSnapshots.WaterWaveSize = nil
                fpsSnapshots.WaterWaveSpeed = nil
            end
            for part in pairs(fpsSnapshots.PartShadows) do
                if part and part.Parent then pcall(function() part.CastShadow = true end) end
            end
            table.clear(fpsSnapshots.PartShadows)
            for eff in pairs(fpsSnapshots.Effects) do
                if eff and eff.Parent then pcall(function() eff.Enabled = true end) end
            end
            table.clear(fpsSnapshots.Effects)
        end
    end

    -- UI Sections di Tab Main
    local sectionMove = tab1:AddSection({ Name = "Movement & Admin Fly" })
    local flyToggle
    flyToggle = sectionMove:AddToggle({
        Name = "Admin Fly (Pose Diam)",
        Desc = isMobile and "Terbang bebas pakai joystick (karakter diam tegak seperti Admin)" or "WASD + Space/E (Naik) + Ctrl/Q (Turun) + Shift (Boost)",
        Default = false,
        Callback = function(state)
            if state then
                if startFly() then
                    notify("Admin Fly", "ON (Speed: " .. tostring(flySpeed) .. ")", 2)
                end
            else
                stopFly()
                notify("Admin Fly", "OFF", 2)
            end
        end,
    })

    sectionMove:AddSlider({
        Name = "Fly Speed",
        Min = 20,
        Max = 250,
        Default = 60,
        Callback = function(val)
            flySpeed = val
        end,
    })

    sectionMove:AddToggle({
        Name = "Noclip (Tembus Tembok)",
        Desc = "Lewati dinding, pagar & pintu tanpa mentok",
        Default = false,
        Callback = function(state)
            setNoclip(state)
            notify("Noclip", state and "ON" or "OFF", 2)
        end,
    })

    sectionMove:AddToggle({
        Name = "Infinite Jump",
        Desc = "Lompat berkali-kali di udara tanpa batas",
        Default = false,
        Callback = function(state)
            infJumpEnabled = state
            notify("Infinite Jump", state and "ON" or "OFF", 2)
        end,
    })

    local jpSlider = sectionMove:AddSlider({
        Name = "JumpPower",
        Min = 50,
        Max = 250,
        Default = math.clamp(defaultJumpPower, 50, 250),
        Callback = function(val)
            applyJumpPower(val)
        end,
    })

    sectionMove:AddButton({
        Name = "Reset JumpPower",
        Callback = function()
            applyJumpPower(defaultJumpPower)
            customJumpPower = nil
            if jpSlider then pcall(function() jpSlider:Set(math.clamp(defaultJumpPower, 50, 250)) end) end
            notify("JumpPower", "Dikembalikan ke default (" .. tostring(defaultJumpPower) .. ")", 2)
        end,
    })

    local sectionPerf = tab1:AddSection({ Name = "Performance" })
    sectionPerf:AddToggle({
        Name = "FPS Booster / Anti-Lag",
        Desc = "Matikan shadow & efek berat map agar lebih lancar (bisa dimatikan lagi)",
        Default = false,
        Callback = function(state)
            setFpsBooster(state)
            notify("FPS Booster", state and "Aktif! Grafik diringankan." or "Dimatikan, grafik dikembalikan.", 2)
        end,
    })

    -- ========== ALL EMOTE & ANIMASI (DEFAULT OFF, PERSISTENT SAAT DI-ON KAN) ==========
    local KUROO_EMOTE_URL = "https://raw.githubusercontent.com/KurooNeko874/Universal-Script/refs/heads/main/KurooEmote.lua"
    local EMOTE_CFG_FILE  = "KurooUniversal_AllEmote.json"
    local emoteReqId      = 0

    local function loadEmotePref()
        if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return false end
        local val = false
        pcall(function()
            if not isfile(EMOTE_CFG_FILE) then return end
            local dec = HttpService:JSONDecode(readfile(EMOTE_CFG_FILE))
            if type(dec) == "table" and type(dec.enabled) == "boolean" then
                val = dec.enabled
            end
        end)
        return val
    end

    local function saveEmotePref(state)
        if typeof(writefile) ~= "function" then return end
        pcall(function()
            writefile(EMOTE_CFG_FILE, HttpService:JSONEncode({ enabled = state == true }))
        end)
    end

    local function stopKurooEmote()
        emoteReqId = emoteReqId + 1
        local env = (typeof(getgenv) == "function" and getgenv()) or _G
        if type(env.KurooEmoteCleanup) == "function" then
            pcall(env.KurooEmoteCleanup)
        end
    end

    local function startKurooEmote()
        emoteReqId = emoteReqId + 1
        local myId = emoteReqId
        task.spawn(function()
            local ok, src = pcall(function() return game:HttpGet(KUROO_EMOTE_URL) end)
            if not ok or type(src) ~= "string" or emoteReqId ~= myId then return end
            local fn = loadstring(src)
            if type(fn) == "function" and emoteReqId == myId then
                pcall(fn)
            end
        end)
    end

    local savedEmoteOn = loadEmotePref()
    local sectionEmote = tab1:AddSection({ Name = "All Emote & Animasi" })
    sectionEmote:AddToggle({
        Name = "All Emote & Animasi",
        Desc = "Aktifkan roda KurooEmote (62K+ Emote & 12K+ Animasi Marketplace). Jika ON, otomatis aktif saat execute berikutnya.",
        Default = savedEmoteOn,
        Callback = function(state)
            saveEmotePref(state)
            if state then
                startKurooEmote()
                notify("All Emote & Animasi", "Memuat KurooEmote & Animation Wheel...", 2)
            else
                stopKurooEmote()
                notify("All Emote & Animasi", "KurooEmote dimatikan.", 2)
            end
        end,
    })

    if savedEmoteOn then
        task.delay(0.5, startKurooEmote)
    end

    ExtraMain.Cleanup = function()
        stopFly()
        setNoclip(false)
        infJumpEnabled = false
        stopKurooEmote()
        if infJumpConn then pcall(function() infJumpConn:Disconnect() end) end
        if charJumpConn then pcall(function() charJumpConn:Disconnect() end) end
        if fpsBoostEnabled then setFpsBooster(false) end
        if customJumpPower then applyJumpPower(defaultJumpPower) end
    end
end

    window:OnUnload(function()
        pcall(function()
            if ExtraMain and ExtraMain.Cleanup then ExtraMain.Cleanup() end
        end)
        pcall(function()
            espEnabled = false
            if espConnection then espConnection:Disconnect(); espConnection = nil end
            if playerAddedConnection then playerAddedConnection:Disconnect(); playerAddedConnection = nil end
            if clearESP then clearESP() end
        end)
        pcall(function()
            antiAfkEnabled = false
            if stopAntiAfk then stopAntiAfk() end
        end)
        pcall(function()
            if freecam and freecam.active and toggleFreecam then toggleFreecam() end
        end)
    end)
end