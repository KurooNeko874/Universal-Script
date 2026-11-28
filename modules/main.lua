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
    window:OnUnload(function()
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