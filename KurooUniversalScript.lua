local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/KurooNeko874/KurooUI/main/KurooUI.lua"))()

-- ========== SERVICES & CORE REFERENCES ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local function getCamera()
    return workspace.CurrentCamera
end

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 2,
        })
    end)
end

-- ========== REJOIN SERVER ==========
local function rejoinGame()
    print("Rejoin Server")
    TeleportService:Teleport(game.PlaceId)
end

-- ========== DATABASE ANIMATIONS ==========
local AnimDB = {
    Full = {
        "Bubbly", "Cartoony", "Zombie", "Ghost", "Cowboy", "Ninja", "Robot", 
        "Pirate", "Knight", "Mage", "Vampire", "Werewolf", "Sneaky", "Stylish",
        "Confident", "Elder", "Toy", "Superhero"
    },
    Idle = {
        ["Bubbly"] = {"910004836", "910009958"},
        ["Cartoony"] = {"742637544", "742638445"},
        ["Zombie"] = {"616158929", "616160636"},
        ["Ghost"] = {"616006778", "616008087"},
        ["Cowboy"] = {"1014390418", "1014398616"},
        ["Ninja"] = {"656117400", "656118341"},
        ["Robot"] = {"616088211", "616089559"},
        ["Pirate"] = {"750781874", "750782770"},
        ["Knight"] = {"657595757", "657568135"},
        ["Mage"] = {"707742142", "707855907"},
        ["Vampire"] = {"1083445855", "1083450166"},
        ["Werewolf"] = {"1083195517", "1083214717"},
        ["Sneaky"] = {"1132473842", "1132477671"},
        ["Stylish"] = {"616136790", "616138447"},
        ["Confident"] = {"1069977950", "1069987858"},
        ["Elder"] = {"10921101664", "10921102574"},
        ["Toy"] = {"782841498", "782845736"},
        ["Superhero"] = {"10921288909", "10921290167"},
        ["Levitation"] = {"616006778", "616008087"},
        ["Princess"] = {"941003647", "941013098"},
        ["Popstar"] = {"1212900985", "1150842221"},
        ["R6"] = {"12521158637","12521162526"},
        ["R15 Reanimated"] = {"4211217646", "4211218409"},
        ["Realistic"] = {"17172918855", "17173014241"},
        ["Soldier"] = {"3972151362", "3972151362"},
        ["Stylized Female"] = {"4708191566", "4708192150"},
        ["Udzal"] = {"3303162274", "3303162549"},
        ["Astronaut"] = {"891621366", "891633237"},
        ["MrToilet"] = {"4417977954", "4417978624"},
        ["Catwalk Glam"] = {"133806214992291","94970088341563"},
        ["Drooling Zombie"] = {"3489171152", "3489171152"},
        ["Sway"] = {"560832030", "560833564"},
        ["OldSchool"] = {"10921230744", "10921232093"},
        ["Patrol"] = {"1149612882", "1150842221"},
    },
    Walk = {
        ["Bubbly"] = "910034870",
        ["Zombie"] = "616168032",
        ["Ghost"] = "616013216",
        ["Cowboy"] = "1014421541",
        ["Ninja"] = "656121766",
        ["Robot"] = "616095330",
        ["Pirate"] = "750785693",
        ["Knight"] = "10921127095",
        ["Mage"] = "707897309",
        ["Vampire"] = "1083473930",
        ["Werewolf"] = "1083178339",
        ["Sneaky"] = "1132510133",
        ["Stylish"] = "616146177",
        ["Confident"] = "1070017263",
        ["Elder"] = "10921111375",
        ["Toy"] = "10921306285",
        ["Superhero"] = "10921298616",
        ["Levitation"] = "616013216",
        ["Princess"] = "941028902",
        ["Popstar"] = "1212980338",
        ["R6"] = "12518152696",
        ["R15 Reanimated"] = "4211223236",
        ["Stylized Female"] = "4708193840",
        ["Udzal"] = "3303162967",
        ["Astronaut"] = "891667138",
        ["Catwalk Glam"] = "109168724482748",
        ["Drooling Zombie"] = "3489174223",
        ["OldSchool"] = "10921244891",
        ["Patrol"] = "1151231493",
        ["Cool Boy"] = "79127340077185",
    },
    Run = {
        ["Bubbly"] = "10921057244",
        ["Zombie"] = "616163682",
        ["Ghost"] = "616013216",
        ["Cowboy"] = "1014401683",
        ["Ninja"] = "656118852",
        ["Robot"] = "10921250460",
        ["Pirate"] = "750783738",
        ["Knight"] = "10921121197",
        ["Mage"] = "10921148209",
        ["Vampire"] = "10921320299",
        ["Werewolf"] = "10921336997",
        ["Sneaky"] = "1132494274",
        ["Stylish"] = "10921276116",
        ["Confident"] = "1070001516",
        ["Elder"] = "10921104374",
        ["Toy"] = "10921306285",
        ["Superhero"] = "10921291831",
        ["Levitation"] = "616010382",
        ["Princess"] = "941015281",
        ["Popstar"] = "1212980348",
        ["R6"] = "12518152696",
        ["R15 Reanimated"] = "4211220381",
        ["Stylized Female"] = "4708192705",
        ["Heavy Run"] = "3236836670",
        ["Astronaut"] = "10921039308",
        ["Catwalk Glam"] = "81024476153754",
        ["Drooling Zombie"] = "3489173414",
        ["OldSchool"] = "10921240218",
        ["Patrol"] = "1150967949",
    },
    Jump = {
        ["Bubbly"] = "910016857",
        ["Zombie"] = "616161997",
        ["Ghost"] = "616008936",
        ["Cowboy"] = "1014394726",
        ["Ninja"] = "656117878",
        ["Robot"] = "616090535",
        ["Pirate"] = "750782230",
        ["Knight"] = "910016857",
        ["Mage"] = "10921149743",
        ["Vampire"] = "1083455352",
        ["Werewolf"] = "1083218792",
        ["Sneaky"] = "1132489853",
        ["Stylish"] = "616139451",
        ["Confident"] = "1069984524",
        ["Elder"] = "10921107367",
        ["Toy"] = "10921308158",
        ["Superhero"] = "10921294559",
        ["Levitation"] = "616008936",
        ["Princess"] = "941008832",
        ["Popstar"] = "1212954642",
        ["R6"] = "12520880485",
        ["R15 Reanimated"] = "4211219390",
        ["Stylized Female"] = "4708188025",
        ["Astronaut"] = "891627522",
        ["Catwalk Glam"] = "116936326516985",
        ["OldSchool"] = "10921242013",
        ["Patrol"] = "1148811837",
    },
    Fall = {
        ["Bubbly"] = "910001910",
        ["Zombie"] = "616157476",
        ["Cowboy"] = "1014384571",
        ["Ninja"] = "656115606",
        ["Robot"] = "616087089",
        ["Pirate"] = "750782230",
        ["Knight"] = "10921122579",
        ["Mage"] = "707829716",
        ["Vampire"] = "1083443587",
        ["Werewolf"] = "1083189019",
        ["Sneaky"] = "1132469004",
        ["Stylish"] = "616134815",
        ["Confident"] = "1069973677",
        ["Elder"] = "10921105765",
        ["Toy"] = "782846423",
        ["Superhero"] = "10921293373",
        ["Levitation"] = "616005863",
        ["Princess"] = "941000007",
        ["Popstar"] = "1212900995",
        ["R6"] = "12520972571",
        ["R15 Reanimated"] = "4211216152",
        ["Stylized Female"] = "4708186162",
        ["Astronaut"] = "891617961",
        ["Catwalk Glam"] = "92294537340807",
        ["OldSchool"] = "10921241244",
        ["Patrol"] = "1148863382",
    },
    Climb = {
        ["Bubbly"] = "742636889",
        ["Zombie"] = "616156119",
        ["Ghost"] = "616003713",
        ["Cowboy"] = "1014380606",
        ["Ninja"] = "656114359",
        ["Robot"] = "616086039",
        ["Knight"] = "10921125160",
        ["Mage"] = "707826056",
        ["Vampire"] = "1083439238",
        ["Sneaky"] = "1132461372",
        ["Stylish"] = "10921271391",
        ["Confident"] = "1069946257",
        ["Elder"] = "845392038",
        ["Toy"] = "10921300839",
        ["Superhero"] = "10921286911",
        ["Levitation"] = "10921132092",
        ["Princess"] = "940996062",
        ["Popstar"] = "1213044953",
        ["R6"] = "12520982150",
        ["R15 Reanimated"] = "4211214992",
        ["Stylized Female"] = "4708184253",
        ["Astronaut"] = "10921032124",
        ["Catwalk Glam"] = "119377220967554",
        ["OldSchool"] = "10921229866",
        ["Patrol"] = "1148811837",
    },
    Swim = {
        ["Bubbly"] = "910028158",
        ["Zombie"] = "616165109",
        ["Cowboy"] = "1014406523",
        ["Ninja"] = "656118341",
        ["Robot"] = "10921253142",
        ["Pirate"] = "750784579",
        ["Knight"] = "10921125160",
        ["Mage"] = "707876443",
        ["Vampire"] = "10921324408",
        ["Werewolf"] = "10921340419",
        ["Sneaky"] = "1132500520",
        ["Stylish"] = "10921281000",
        ["Confident"] = "1070009914",
        ["Elder"] = "10921108971",
        ["Toy"] = "10921309319",
        ["Superhero"] = "10921295495",
        ["Popstar"] = "1212998578",
        ["Princess"] = "941018893",
        ["R6"] = "12518152696",
        ["Astronaut"] = "891663592",
        ["Catwalk Glam"] = "134591743181628",
        ["OldSchool"] = "10921243048",
        ["Patrol"] = "1151204998",
        ["Levitation"] = "10921138209",
    },
    SwimIdle = {
        ["Bubbly"] = "910030921",
        ["Zombie"] = "616165109",
        ["Cowboy"] = "1014411816",
        ["Ninja"] = "656118341",
        ["Robot"] = "10921253767",
        ["Pirate"] = "750785176",
        ["Knight"] = "10921125935",
        ["Mage"] = "707894699",
        ["Vampire"] = "10921325443",
        ["Werewolf"] = "10921341319",
        ["Sneaky"] = "1132506407",
        ["Stylish"] = "10921281964",
        ["Confident"] = "1070012133",
        ["Elder"] = "10921110146",
        ["Toy"] = "10921310341",
        ["Superhero"] = "10921297391",
        ["Popstar"] = "1212998578",
        ["Princess"] = "941025398",
        ["R6"] = "12518152696",
        ["Astronaut"] = "891663592",
        ["Catwalk Glam"] = "98854111361360",
        ["OldSchool"] = "10921244018",
        ["Patrol"] = "1151221899",
        ["Levitation"] = "10921139478",
    }
}

-- ========== FUNGSI APPLY ANIMATION ==========
local function preloadAnimation(animId)
    if not animId then return end
    local ids = (type(animId) == "table") and animId or {animId}
    local assets = {}
    for _, id in ipairs(ids) do
        if id and tostring(id) ~= "" then
            local a = Instance.new("Animation")
            a.AnimationId = "rbxassetid://" .. tostring(id)
            table.insert(assets, a)
        end
    end
    pcall(function()
        if #assets > 0 then
            ContentProvider:PreloadAsync(assets)
        end
    end)
end

local function getAnimObject(folder, possibleNames)
    for _, name in ipairs(possibleNames) do
        local obj = folder:FindFirstChild(name)
        if obj and obj:IsA("Animation") then
            return obj
        end
    end
    return folder:FindFirstChildOfClass("Animation")
end

local function reloadAnimator(humanoid)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            pcall(function()
                if track.IsPlaying then
                    track:Stop(0.15)
                end
            end)
        end
    end
    task.wait(0.05)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    humanoid:Move(Vector3.new(0.1, 0, 0), true)
    task.wait(0.05)
    humanoid:Move(Vector3.new(), true)
end

local function setAnimId(animate, animType, animId)
    if animType == "Idle" then
        if animate:FindFirstChild("idle") and type(animId) == "table" then
            local a1 = getAnimObject(animate.idle, {"Animation1", "IdleAnim"})
            local a2 = getAnimObject(animate.idle, {"Animation2"})
            if a1 then a1.AnimationId = "rbxassetid://" .. tostring(animId[1]) end
            if a2 then a2.AnimationId = "rbxassetid://" .. tostring(animId[2]) end
        end
    elseif animType == "Walk" then
        local folder = animate:FindFirstChild("walk")
        if folder then
            local anim = getAnimObject(folder, {"WalkAnim", "Animation"})
            if anim then anim.AnimationId = "rbxassetid://" .. tostring(animId) end
        end
    elseif animType == "Run" then
        local folder = animate:FindFirstChild("run")
        if folder then
            local anim = getAnimObject(folder, {"RunAnim", "Animation"})
            if anim then anim.AnimationId = "rbxassetid://" .. tostring(animId) end
        end
    elseif animType == "Jump" then
        local folder = animate:FindFirstChild("jump")
        if folder then
            local anim = getAnimObject(folder, {"JumpAnim", "Animation"})
            if anim then anim.AnimationId = "rbxassetid://" .. tostring(animId) end
        end
    elseif animType == "Fall" then
        local folder = animate:FindFirstChild("fall")
        if folder then
            local anim = getAnimObject(folder, {"FallAnim", "Animation"})
            if anim then anim.AnimationId = "rbxassetid://" .. tostring(animId) end
        end
    elseif animType == "Climb" then
        local folder = animate:FindFirstChild("climb")
        if folder then
            local anim = getAnimObject(folder, {"ClimbAnim", "Animation"})
            if anim then anim.AnimationId = "rbxassetid://" .. tostring(animId) end
        end
    elseif animType == "Swim" then
        local folder = animate:FindFirstChild("swim")
        if folder then
            local anim = getAnimObject(folder, {"Swim", "SwimAnim", "Animation"})
            if anim then anim.AnimationId = "rbxassetid://" .. tostring(animId) end
        end
    elseif animType == "SwimIdle" then
        local folder = animate:FindFirstChild("swimidle")
        if folder then
            local anim = getAnimObject(folder, {"SwimIdle", "Animation"})
            if anim then anim.AnimationId = "rbxassetid://" .. tostring(animId) end
        end
    end
end

local function applyAnim(animType, animId)
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local animate = char:FindFirstChild("Animate")
    if not humanoid or not animate then return false end
    preloadAnimation(animId)

    local success = pcall(setAnimId, animate, animType, animId)
    if not success then return false end

    animate.Disabled = true
    task.wait(0.1)
    animate.Disabled = false
    reloadAnimator(humanoid)
    return true
end

local function applyFull(name)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local animate = char:FindFirstChild("Animate")
    if not humanoid or not animate then return end

    local types = {"Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim", "SwimIdle"}
    for _, t in ipairs(types) do
        local id = AnimDB[t] and AnimDB[t][name]
        if id then
            preloadAnimation(id)
            pcall(setAnimId, animate, t, id)
        end
    end

    animate.Disabled = true
    task.wait(0.1)
    animate.Disabled = false
    reloadAnimator(humanoid)
    notify("Animation", name .. " applied!", 1)
end

-- ========== DETEKSI DEVICE ==========
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

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
        local speed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and freecam.speed * 2 or freecam.speed

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end

        cam.CFrame = CFrame.new(cam.CFrame.Position + (rot:VectorToWorldSpace(move * speed * dt))) * rot
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

-- ========== BRIGHTNESS SYSTEM ==========
local originalBrightness = Lighting.Brightness

local function setBrightness(val)
    Lighting.Brightness = val
end

local function resetBrightness()
    Lighting.Brightness = originalBrightness
end

-- ========== SPECTATE SYSTEM ==========
local spectateTarget = nil
local isSpectating = false

local function trimString(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function findPlayerByPrefix(query, excludeSelf)
    local q = string.lower(trimString(query))
    if q == "" then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if not (excludeSelf and player == LocalPlayer) then
            if string.sub(string.lower(player.Name), 1, #q) == q
                or string.sub(string.lower(player.DisplayName), 1, #q) == q then
                return player
            end
        end
    end
    return nil
end

local function spectatePlayer(targetUsername)
    local cam = getCamera()
    if not cam then return end

    local cleaned = trimString(targetUsername)
    if cleaned == "" then
        cam.CameraType = Enum.CameraType.Custom
        if LocalPlayer.Character then
            cam.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
        spectateTarget = nil
        isSpectating = false
        notify("Spectate Mode", "Spectate dihentikan.", 2)
        return
    end

    local foundPlayer = findPlayerByPrefix(cleaned, false)
    if foundPlayer and foundPlayer.Character and foundPlayer.Character:FindFirstChildOfClass("Humanoid") then
        spectateTarget = foundPlayer
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = foundPlayer.Character:FindFirstChildOfClass("Humanoid")
        isSpectating = true
        notify("Spectate Mode", "Spectating: " .. foundPlayer.Name, 2)
    else
        notify("Spectate Error", "Player tidak ditemukan!", 2)
    end
end

Players.PlayerRemoving:Connect(function(player)
    if spectateTarget == player then
        spectatePlayer("")
    end
end)

-- ========== SYNC EMOTE SYSTEM (REALTIME SYNC) ==========
local syncTarget = nil
local syncAnimConnection = nil
local syncHeartbeatConnection = nil
local syncCharConnection = nil
local currentSyncedTrack = nil
local currentSyncedAnimId = nil
local currentTargetTrack = nil

local PRIORITY_RANK = {
    [Enum.AnimationPriority.Core] = 1,
    [Enum.AnimationPriority.Idle] = 2,
    [Enum.AnimationPriority.Movement] = 3,
    [Enum.AnimationPriority.Action] = 4,
    [Enum.AnimationPriority.Action2] = 5,
    [Enum.AnimationPriority.Action3] = 6,
    [Enum.AnimationPriority.Action4] = 7,
}

local function getPrimaryTrack(animator)
    if not animator then return nil end
    local bestTrack = nil
    local bestRank = -1
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.IsPlaying and track.Animation and track.Animation.AnimationId ~= "" then
            local rank = PRIORITY_RANK[track.Priority] or 0
            if rank >= bestRank then
                bestRank = rank
                bestTrack = track
            end
        end
    end
    return bestTrack
end

local function clearSyncedTrack()
    if currentSyncedTrack then
        pcall(function()
            currentSyncedTrack:Stop(0)
            currentSyncedTrack:Destroy()
        end)
        currentSyncedTrack = nil
    end
    currentSyncedAnimId = nil
    currentTargetTrack = nil
end

local function stopSyncEmote(silent)
    if syncAnimConnection then
        syncAnimConnection:Disconnect()
        syncAnimConnection = nil
    end
    if syncHeartbeatConnection then
        syncHeartbeatConnection:Disconnect()
        syncHeartbeatConnection = nil
    end
    if syncCharConnection then
        syncCharConnection:Disconnect()
        syncCharConnection = nil
    end
    clearSyncedTrack()

    local myChar = LocalPlayer.Character
    if myChar then
        local animateScript = myChar:FindFirstChild("Animate")
        if animateScript then
            animateScript.Disabled = false
        end
    end

    local hadTarget = syncTarget ~= nil
    syncTarget = nil
    if not silent and hadTarget then
        notify("Sync Emote", "Sync dihentikan.", 2)
    end
end

local function syncEmotePlayer(targetUsername)
    stopSyncEmote(true)

    local cleaned = trimString(targetUsername)
    if cleaned == "" then
        notify("Sync Emote", "Sync dihentikan.", 2)
        return
    end

    local foundPlayer = findPlayerByPrefix(cleaned, true)
    if not foundPlayer or not foundPlayer.Character then
        notify("Sync Error", "Player tidak ditemukan!", 2)
        return
    end

    local function getAnimators()
        local tChar = foundPlayer.Character
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
        local tAnim = tHum and tHum:FindFirstChildOfClass("Animator")

        local mChar = LocalPlayer.Character
        local mHum = mChar and mChar:FindFirstChildOfClass("Humanoid")
        local mAnim = mHum and mHum:FindFirstChildOfClass("Animator")
        return tAnim, mAnim, mChar
    end

    local targetAnimator, myAnimator, myChar = getAnimators()
    if not targetAnimator or not myAnimator then
        notify("Sync Error", "Animator tidak ditemukan!", 2)
        return
    end

    syncTarget = foundPlayer

    local animateScript = myChar:FindFirstChild("Animate")
    if animateScript then
        animateScript.Disabled = true
    end

    for _, track in ipairs(myAnimator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end

    local function playSyncedTrack(targetTrack, mAnim)
        if not targetTrack or not targetTrack.Animation then return end
        local animId = targetTrack.Animation.AnimationId
        if animId == "" then return end

        clearSyncedTrack()

        local animObj = Instance.new("Animation")
        animObj.AnimationId = animId

        local ok, loaded = pcall(function()
            return mAnim:LoadAnimation(animObj)
        end)
        if not ok or not loaded then return end

        currentSyncedTrack = loaded
        currentSyncedAnimId = animId
        currentTargetTrack = targetTrack

        pcall(function()
            currentSyncedTrack.Priority = Enum.AnimationPriority.Action4
        end)
        currentSyncedTrack.Looped = targetTrack.Looped
        currentSyncedTrack:Play(0, 1, targetTrack.Speed)
        pcall(function()
            currentSyncedTrack.TimePosition = targetTrack.TimePosition
        end)
    end

    local function bindTargetAnimator(tAnim)
        if syncAnimConnection then
            syncAnimConnection:Disconnect()
            syncAnimConnection = nil
        end
        if not tAnim then return end
        syncAnimConnection = tAnim.AnimationPlayed:Connect(function(newTrack)
            local _, mAnim = getAnimators()
            if mAnim then
                playSyncedTrack(newTrack, mAnim)
            end
        end)
    end

    bindTargetAnimator(targetAnimator)

    -- Re-bind otomatis kalau target respawn
    syncCharConnection = foundPlayer.CharacterAdded:Connect(function(newChar)
        local hum = newChar:WaitForChild("Humanoid", 5)
        local anim = hum and hum:WaitForChild("Animator", 5)
        if syncTarget == foundPlayer and anim then
            clearSyncedTrack()
            bindTargetAnimator(anim)
        end
    end)

    -- Loop realtime: samakan animasi aktif, speed, dan TimePosition secara terus-menerus
    syncHeartbeatConnection = RunService.Heartbeat:Connect(function()
        if syncTarget ~= foundPlayer then return end
        local tAnim, mAnim = getAnimators()
        if not tAnim or not mAnim then return end

        local activeTrack = getPrimaryTrack(tAnim)
        if not activeTrack then
            if currentSyncedTrack then
                clearSyncedTrack()
            end
            return
        end

        local animId = activeTrack.Animation.AnimationId
        if animId ~= currentSyncedAnimId or not currentSyncedTrack or not currentSyncedTrack.IsPlaying then
            playSyncedTrack(activeTrack, mAnim)
            return
        end

        currentTargetTrack = activeTrack
        currentSyncedTrack.Looped = activeTrack.Looped

        -- Sinkronkan kecepatan
        if math.abs(currentSyncedTrack.Speed - activeTrack.Speed) > 0.01 then
            currentSyncedTrack:AdjustSpeed(activeTrack.Speed)
        end

        -- Koreksi drift TimePosition secara realtime
        if math.abs(currentSyncedTrack.TimePosition - activeTrack.TimePosition) > 0.08 then
            pcall(function()
                currentSyncedTrack.TimePosition = activeTrack.TimePosition
            end)
        end
    end)

    notify("Sync Emote", "Realtime sync dengan: " .. foundPlayer.Name, 2)
end

Players.PlayerRemoving:Connect(function(player)
    if syncTarget == player then
        stopSyncEmote()
    end
end)

-- ========== HEADLESS VISUAL SYSTEM (FIXED) ==========
local headlessEnabled = false

local function applyHeadlessToChar(char, state)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = state and 1 or 0
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") then
                child.Transparency = state and 1 or 0
            end
        end
    end
end

local function setHeadless(state)
    headlessEnabled = state
    applyHeadlessToChar(LocalPlayer.Character, state)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if headlessEnabled then
        setHeadless(true)
    end
end)

-- ========== LARPING VISUAL ITEM SYSTEM ==========
local PresetItems = {
    {
        Name       = "8-Bit Royal Crown",
        AssetId    = 10159600649,
        MeshId     = "rbxassetid://10138606900",
        TextureId  = "rbxassetid://10138606949",
        EffectType = "8BitCrown",
    },
    {
        Name       = "Spec Beta Biograft Energy Sword",
        AssetId    = 14876573,
        MeshId     = "rbxassetid://11996935",
        TextureId  = "rbxassetid://14876424",
        EffectType = "DiamondSparkles",
        IsGear     = true,
    },
    {
        Name       = "St Patrick's Day Fairy",
        AssetId    = 226189871,
        MeshId     = "rbxassetid://226143404",
        TextureId  = "rbxassetid://226143506",
        EffectType = "GreenSparkles",
    },
    {
        Name       = "Winter Fairy",
        AssetId    = 141742418,
        MeshId     = "rbxassetid://128216670",
        TextureId  = "rbxassetid://141740743",
        EffectType = "CyanSparkles",
    },
    {
        Name       = "8-Bit HP Bar",
        AssetId    = 10159610478,
        EffectType = "Native",
    },
    {
        Name       = "8-Bit Extra Life",
        AssetId    = 10159606132,
        EffectType = "Native",
    },
    {
        Name       = "8-Bit Tabby Cat",
        AssetId    = 10159617728,
        EffectType = "Native",
    },
    {
        Name       = "8-Bit Roblox Coin",
        AssetId    = 10159622004,
        EffectType = "Native",
    },
    {
        Name       = "Fiery Horns of the Netherworld",
        AssetId    = 215718515,
        EffectType = "OrangeFire",
    },
    {
        Name       = "Frozen Horns of the Frigid Planes",
        AssetId    = 74891470,
        EffectType = "BlueFire",
    },
    {
        Name       = "Poisoned Horns of the Toxic Wasteland",
        AssetId    = 1744060292,
        EffectType = "GreenFire",
    },
    {
        Name       = "Sparkle Time Fedora",
        AssetId    = 1285307,
        EffectType = "Sparkles",
    },
    {
        Name       = "Valkyrie Helm",
        AssetId    = 1365767,
        EffectType = "None",
    },
    {
        Name       = "Dominus Empyreus",
        AssetId    = 21070012,
        EffectType = "None",
    },
}

local ActiveItems = {}        -- [itemName] = entry (untuk LocalPlayer)
local ItemConfigs = {}        -- [itemName] = transform config
local SelectedLarpItem = "8-Bit Royal Crown"
local OtherPlayerItems = {}   -- [Player] = { Entries = { [itemName] = entry }, Headless = bool, CharConn = RBXScriptConnection }

local function GetDefaultTransform()
    return {
        Scale       = 100,
        PosX        = 0,
        PosY        = 0,
        PosZ        = 0,
        RotX        = 0,
        RotY        = 0,
        RotZ        = 0,
        ShowEffects = true,
    }
end

local function CloneTransform(cfg)
    return {
        Scale       = cfg.Scale,
        PosX        = cfg.PosX,
        PosY        = cfg.PosY,
        PosZ        = cfg.PosZ,
        RotX        = cfg.RotX,
        RotY        = cfg.RotY,
        RotZ        = cfg.RotZ,
        ShowEffects = cfg.ShowEffects,
    }
end

local function EnsureItemConfig(itemName)
    if not ItemConfigs[itemName] then
        ItemConfigs[itemName] = GetDefaultTransform()
    end
    return ItemConfigs[itemName]
end

local function EnsureSpecialEffect(handle, effectType)
    local hasNativeEffect = false
    for _, desc in ipairs(handle:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Fire") or desc:IsA("Sparkles") or desc:IsA("Smoke") then
            desc.Enabled = true
            hasNativeEffect = true
        end
    end

    if hasNativeEffect then
        return
    end

    if effectType == "8BitCrown" then
        local att = handle:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", handle)
        local pe = Instance.new("ParticleEmitter")
        pe.Name = "Kuroo8BitParticles"
        pe.Texture = "rbxassetid://241685484"
        pe.Rate = 15
        pe.Lifetime = NumberRange.new(2.5, 2.5)
        pe.Speed = NumberRange.new(1.5, 2.2)
        pe.EmissionDirection = Enum.NormalId.Top
        pe.Rotation = NumberRange.new(0, 0)
        pe.RotSpeed = NumberRange.new(-10, 10)
        pe.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(0.5, 0.45),
            NumberSequenceKeypoint.new(1, 0.2),
        })
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.15, 0),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        pe.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(131, 253, 255)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(0, 213, 255)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 122, 34)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(59, 153, 26)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(198, 42, 11)),
        })
        pe.LightEmission = 0.8
        pe.LockedToPart = true
        pe.Parent = att
    elseif effectType == "DiamondSparkles" then
        local sp = Instance.new("Sparkles")
        sp.Name = "KurooDiamondSparkles"
        sp.SparkleColor = Color3.fromRGB(200, 245, 255)
        sp.Parent = handle
    elseif effectType == "GreenSparkles" then
        local sp = Instance.new("Sparkles")
        sp.Name = "KurooGreenSparkles"
        sp.SparkleColor = Color3.fromRGB(60, 255, 90)
        sp.Parent = handle
    elseif effectType == "CyanSparkles" then
        local sp = Instance.new("Sparkles")
        sp.Name = "KurooCyanSparkles"
        sp.SparkleColor = Color3.fromRGB(140, 230, 255)
        sp.Parent = handle
    elseif effectType == "OrangeFire" then
        local fire = Instance.new("Fire")
        fire.Name = "KurooFire"
        fire.Color = Color3.fromRGB(255, 140, 0)
        fire.SecondaryColor = Color3.fromRGB(255, 50, 0)
        fire.Heat = 9
        fire.Size = 5
        fire.Parent = handle
    elseif effectType == "BlueFire" then
        local fire = Instance.new("Fire")
        fire.Name = "KurooBlueFire"
        fire.Color = Color3.fromRGB(0, 170, 255)
        fire.SecondaryColor = Color3.fromRGB(180, 235, 255)
        fire.Heat = 9
        fire.Size = 5
        fire.Parent = handle
    elseif effectType == "GreenFire" then
        local fire = Instance.new("Fire")
        fire.Name = "KurooGreenFire"
        fire.Color = Color3.fromRGB(65, 255, 65)
        fire.SecondaryColor = Color3.fromRGB(0, 140, 0)
        fire.Heat = 9
        fire.Size = 5
        fire.Parent = handle
    elseif effectType == "Sparkles" then
        local sp = Instance.new("Sparkles")
        sp.Name = "KurooSparkles"
        sp.SparkleColor = Color3.fromRGB(255, 230, 120)
        sp.Parent = handle
    end
end

local function ApplyEntryTransform(entry)
    if not entry or not entry.Handle or not entry.Handle.Parent then
        return
    end

    local cfg = entry.Config
    local scaleMultiplier = math.max(cfg.Scale / 100, 0.05)

    local offsetX = cfg.PosX / 10
    local offsetY = cfg.PosY / 10
    local offsetZ = cfg.PosZ / 10

    local rotCFrame = CFrame.Angles(
        math.rad(cfg.RotX),
        math.rad(cfg.RotY),
        math.rad(cfg.RotZ)
    )

    if entry.Weld then
        entry.Weld.C0 = entry.BaseC0 * CFrame.new(offsetX, offsetY, offsetZ) * rotCFrame
    end

    local mesh = entry.Handle:FindFirstChildOfClass("SpecialMesh")
    if mesh and entry.BaseMeshScale then
        mesh.Scale = entry.BaseMeshScale * scaleMultiplier
    elseif entry.BaseSize then
        entry.Handle.Size = entry.BaseSize * scaleMultiplier
    end

    for _, desc in ipairs(entry.Handle:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Fire") or desc:IsA("Sparkles") or desc:IsA("Smoke") or desc:IsA("PointLight") or desc:IsA("Beam") or desc:IsA("Trail") then
            desc.Enabled = cfg.ShowEffects
        end
    end
end

local function ApplyItemTransform(itemName)
    local entry = ActiveItems[itemName]
    if entry then
        ApplyEntryTransform(entry)
    end
end

-- Memasang item visual ke karakter mana pun (LocalPlayer maupun player lain)
local function AttachVisualItemToCharacter(char, itemData, cfg, registryTable)
    if not char then return false end
    local head = char:FindFirstChild("Head")
    if not head then return false end

    if registryTable[itemData.Name] and registryTable[itemData.Name].Model then
        pcall(function()
            registryTable[itemData.Name].Model:Destroy()
        end)
        registryTable[itemData.Name] = nil
    end

    local loadedAsset = nil
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(itemData.AssetId))
    end)

    if ok and objects and #objects > 0 then
        loadedAsset = objects[1]
    end

    local containerModel = Instance.new("Model")
    containerModel.Name = "KurooLarp_" .. itemData.Name

    local handle = nil
    if loadedAsset then
        if loadedAsset:IsA("Accessory") or loadedAsset:IsA("Hat") or loadedAsset:IsA("Tool") or loadedAsset:IsA("Model") then
            handle = loadedAsset:FindFirstChild("Handle", true) or loadedAsset:FindFirstChildWhichIsA("BasePart", true)
            if loadedAsset:IsA("Tool") and handle then
                handle.Parent = containerModel
            else
                loadedAsset.Parent = containerModel
            end
        elseif loadedAsset:IsA("BasePart") then
            handle = loadedAsset
            loadedAsset.Parent = containerModel
        end
    end

    if not handle then
        handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1, 1, 1)
        handle.Parent = containerModel

        local sm = Instance.new("SpecialMesh")
        sm.MeshType = Enum.MeshType.FileMesh
        sm.MeshId = itemData.MeshId or ""
        sm.TextureId = itemData.TextureId or ""
        sm.Parent = handle
    end

    for _, desc in ipairs(containerModel:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("TouchTransmitter") or desc:IsA("Sound") then
            desc:Destroy()
        elseif desc:IsA("BasePart") then
            desc.CanCollide = false
            desc.CanTouch = false
            desc.CanQuery = false
            desc.Massless = true
            desc.Anchored = false
        end
    end

    local targetPart = head
    local baseC0 = CFrame.new(0, 0.6, 0)

    if itemData.IsGear or (loadedAsset and loadedAsset:IsA("Tool")) then
        local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or head
        targetPart = rightHand
        local grip = (loadedAsset and loadedAsset:IsA("Tool") and loadedAsset.Grip) or CFrame.new(0, 0, -1.5) * CFrame.Angles(math.rad(-90), 0, 0)
        baseC0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0) * grip:Inverse()
    else
        local itemAttachment = handle:FindFirstChildOfClass("Attachment")
        if itemAttachment then
            local charAttachment = char:FindFirstChild(itemAttachment.Name, true)
            if charAttachment and charAttachment:IsA("Attachment") and charAttachment.Parent and charAttachment.Parent:IsA("BasePart") then
                targetPart = charAttachment.Parent
                baseC0 = charAttachment.CFrame * itemAttachment.CFrame:Inverse()
            else
                baseC0 = CFrame.new(0, 0.5, 0) * itemAttachment.CFrame:Inverse()
            end
        elseif loadedAsset and (loadedAsset:IsA("Accessory") or loadedAsset:IsA("Hat")) then
            local okAp, ap = pcall(function() return loadedAsset.AttachmentPoint end)
            if okAp and typeof(ap) == "CFrame" then
                baseC0 = CFrame.new(0, 0.5, 0) * ap:Inverse()
            end
        end
    end

    if loadedAsset and loadedAsset:IsA("Tool") then
        pcall(function() loadedAsset:Destroy() end)
    end

    EnsureSpecialEffect(handle, itemData.EffectType or "Native")

    local weld = Instance.new("Weld")
    weld.Name = "KurooLarpWeld"
    weld.Part0 = targetPart
    weld.Part1 = handle
    weld.C0 = baseC0
    weld.Parent = handle

    containerModel.Parent = char

    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
    local entry = {
        Model         = containerModel,
        Handle        = handle,
        Weld          = weld,
        BaseC0        = baseC0,
        BaseSize      = handle.Size,
        BaseMeshScale = mesh and mesh.Scale or nil,
        Config        = cfg,
        ItemData      = itemData,
    }

    registryTable[itemData.Name] = entry
    ApplyEntryTransform(entry)
    return true
end

local function AttachVisualItem(itemData)
    local cfg = EnsureItemConfig(itemData.Name)
    return AttachVisualItemToCharacter(LocalPlayer.Character, itemData, cfg, ActiveItems)
end

local function RemoveVisualItem(itemName)
    local entry = ActiveItems[itemName]
    if entry then
        if entry.Model then
            pcall(function()
                entry.Model:Destroy()
            end)
        end
        ActiveItems[itemName] = nil
    end
end

-- Auto re-equip item visual saat LocalPlayer respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("Head", 10)
    task.wait(0.5)
    local itemsToRestore = {}
    for _, entry in pairs(ActiveItems) do
        if entry.ItemData then
            table.insert(itemsToRestore, entry.ItemData)
        end
    end
    for _, itemData in ipairs(itemsToRestore) do
        AttachVisualItem(itemData)
    end
end)

-- ========== APPLY / RESET LARPING ITEM KE PLAYER LAIN ==========
local function clearOtherPlayerItems(targetPlayer, silent)
    if not targetPlayer then return end
    local data = OtherPlayerItems[targetPlayer]
    if data then
        if data.CharConn then
            data.CharConn:Disconnect()
            data.CharConn = nil
        end
        for _, entry in pairs(data.Entries) do
            if entry.Model then
                pcall(function() entry.Model:Destroy() end)
            end
        end
        if data.Headless and targetPlayer.Character then
            applyHeadlessToChar(targetPlayer.Character, false)
        end
        OtherPlayerItems[targetPlayer] = nil
    end

    -- Bersihkan juga sisa model KurooLarp_ jika ada
    if targetPlayer.Character then
        for _, child in ipairs(targetPlayer.Character:GetChildren()) do
            if child:IsA("Model") and string.sub(child.Name, 1, 10) == "KurooLarp_" then
                pcall(function() child:Destroy() end)
            end
        end
    end

    if not silent then
        notify("Larping Player", "Item di " .. targetPlayer.Name .. " berhasil di-reset!", 2)
    end
end

local function applyLarpingToPlayer(targetUsername)
    local targetPlayer = findPlayerByPrefix(targetUsername, true)
    if not targetPlayer then
        notify("Larping Error", "Player tidak ditemukan!", 2)
        return
    end
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
        notify("Larping Error", "Karakter " .. targetPlayer.Name .. " belum siap!", 2)
        return
    end

    -- Ambil snapshot semua item aktif beserta modifikasinya saat ini
    local snapshotItems = {}
    for _, entry in pairs(ActiveItems) do
        if entry.ItemData then
            table.insert(snapshotItems, {
                ItemData = entry.ItemData,
                Config   = CloneTransform(entry.Config),
            })
        end
    end

    if #snapshotItems == 0 and not headlessEnabled then
        notify("Larping Info", "Belum ada item aktif di karaktermu untuk di-apply!", 2)
        return
    end

    -- Bersihkan item lama di target sebelum memasang yang baru
    clearOtherPlayerItems(targetPlayer, true)

    local playerData = {
        Entries  = {},
        Snapshot = snapshotItems,
        Headless = headlessEnabled,
        CharConn = nil,
    }
    OtherPlayerItems[targetPlayer] = playerData

    for _, item in ipairs(snapshotItems) do
        AttachVisualItemToCharacter(targetPlayer.Character, item.ItemData, item.Config, playerData.Entries)
    end

    if playerData.Headless then
        applyHeadlessToChar(targetPlayer.Character, true)
    end

    -- Otomatis pasang ulang jika player target respawn
    playerData.CharConn = targetPlayer.CharacterAdded:Connect(function(newChar)
        newChar:WaitForChild("Head", 10)
        task.wait(0.5)
        if OtherPlayerItems[targetPlayer] ~= playerData then return end
        playerData.Entries = {}
        for _, item in ipairs(playerData.Snapshot) do
            AttachVisualItemToCharacter(newChar, item.ItemData, item.Config, playerData.Entries)
        end
        if playerData.Headless then
            applyHeadlessToChar(newChar, true)
        end
    end)

    notify("Larping Player", "Berhasil apply ke " .. targetPlayer.Name .. " (" .. #snapshotItems .. " item)", 2)
end

local function resetLarpingOnPlayer(targetUsername)
    local targetPlayer = findPlayerByPrefix(targetUsername, true)
    if not targetPlayer then
        notify("Larping Error", "Player tidak ditemukan!", 2)
        return
    end
    clearOtherPlayerItems(targetPlayer, false)
end

local function resetAllOtherPlayersLarping()
    local count = 0
    for player, _ in pairs(OtherPlayerItems) do
        clearOtherPlayerItems(player, true)
        count = count + 1
    end
    notify("Larping Player", "Semua item di " .. count .. " player lain telah di-reset!", 2)
end

Players.PlayerRemoving:Connect(function(player)
    if OtherPlayerItems[player] then
        clearOtherPlayerItems(player, true)
    end
end)

--====================================================================================================================
-- UI SETUP
--====================================================================================================================

local window = UI:CreateWindow({
    Title = "Kuroo Universal Script",
    W = 650,
    H = 500,
    Theme = "Solar",
})

-- ========== Tab 1: Main ==========
local tab1 = window:AddTab({ Name = "Main 🚀" })
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

-- ========== Tab 1: Main (Spectate Section) ==========
local spectateSection = tab1:AddSection({ Name = "Spectate Player" })

local spectateInput = spectateSection:AddInput({
    Name        = "Target Username",
    Placeholder = "Ketik username...",
    Callback    = function(text)
        spectatePlayer(text)
    end,
})

spectateSection:AddButton({
    Name     = "Spectate Target",
    Callback = function()
        spectatePlayer(spectateInput:Get())
    end,
})

spectateSection:AddButton({
    Name     = "Stop Spectate",
    Callback = function()
        spectatePlayer("")
    end,
})

-- ========== Tab 1: Main (Sync Emote Section) ==========
local syncSection = tab1:AddSection({ Name = "Sync Emote Player" })

local syncInput = syncSection:AddInput({
    Name        = "Target Username",
    Placeholder = "Masukkan username...",
    Callback    = function(text)
        syncEmotePlayer(text)
    end,
})

syncSection:AddButton({
    Name     = "Sync Emote",
    Callback = function()
        syncEmotePlayer(syncInput:Get())
    end,
})

syncSection:AddButton({
    Name     = "Stop Sync",
    Callback = function()
        stopSyncEmote()
    end,
})

-- ========== Tab 2: Animations ==========
local animTab = window:AddTab({ Name = "Animations 🎭" })

local function sortedKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

local allSec = animTab:AddSection({ Name = "🎬 ALL ANIMATIONS" })
for _, name in ipairs(AnimDB.Full) do
    allSec:AddButton({
        Name = name,
        Callback = function()
            applyFull(name)
        end,
    })
end

local animCategories = {
    { key = "Idle",     label = "💤 IDLE" },
    { key = "Walk",     label = "🚶 WALK" },
    { key = "Run",      label = "🏃 RUN" },
    { key = "Jump",     label = "🦘 JUMP" },
    { key = "Fall",     label = "💨 FALL" },
    { key = "Climb",    label = "🧗 CLIMB" },
    { key = "Swim",     label = "🏊 SWIM" },
    { key = "SwimIdle", label = "🌊 SWIM IDLE" },
}

for _, cat in ipairs(animCategories) do
    local sec = animTab:AddSection({ Name = cat.label })
    for _, name in ipairs(sortedKeys(AnimDB[cat.key])) do
        local id = AnimDB[cat.key][name]
        sec:AddButton({
            Name = name,
            Callback = function()
                applyAnim(cat.key, id)
                notify(cat.key, name, 1)
            end,
        })
    end
end

-- ========== Tab 3: Visuals ==========
local tabVisuals = window:AddTab({ Name = "Visuals 👁️" })

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

local sectionTheme = tabVisuals:AddSection({ Name = "UI Theme" })
sectionTheme:AddDropdown({
    Name = "Theme Preset",
    Options = {
        "Cyan",
        "Yellow",
        "Emerald",
        "Ruby",
        "Bloody",
        "Darkness",
        "Sakura",
        "Solar",
        "Frost",
        "Toxic",
        "Monochrome",
    },
    Default = "Solar",
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

-- ========== Tab 4: Larping (Visual) ==========
local tabLarping = window:AddTab({ Name = "Larping (Visual) ✨" })

local sectionLarpItems = tabLarping:AddSection({ Name = "Daftar Item Limited (Visual)" })
local larpItemToggles = {}
local larpItemDropdown = nil
local isSyncingLarpUI = false

local larpEffectToggle, larpScaleSlider, larpPosXSlider, larpPosYSlider, larpPosZSlider
local larpRotXSlider, larpRotYSlider, larpRotZSlider

local function syncLarpSlidersToItem(itemName)
    if not itemName then return end
    local cfg = EnsureItemConfig(itemName)
    isSyncingLarpUI = true
    if larpEffectToggle then larpEffectToggle:Set(cfg.ShowEffects) end
    if larpScaleSlider  then larpScaleSlider:Set(cfg.Scale) end
    if larpPosXSlider   then larpPosXSlider:Set(cfg.PosX) end
    if larpPosYSlider   then larpPosYSlider:Set(cfg.PosY) end
    if larpPosZSlider   then larpPosZSlider:Set(cfg.PosZ) end
    if larpRotXSlider   then larpRotXSlider:Set(cfg.RotX) end
    if larpRotYSlider   then larpRotYSlider:Set(cfg.RotY) end
    if larpRotZSlider   then larpRotZSlider:Set(cfg.RotZ) end
    isSyncingLarpUI = false
end

sectionLarpItems:AddToggle({
    Name = "Headless Visual",
    Default = false,
    Callback = function(state)
        setHeadless(state)
        notify("Headless", state and "ON" or "OFF", 2)
    end,
})

local larpDropdownOptions = {}
for _, item in ipairs(PresetItems) do
    EnsureItemConfig(item.Name)
    table.insert(larpDropdownOptions, item.Name)
    larpItemToggles[item.Name] = sectionLarpItems:AddToggle({
        Name     = item.Name,
        Default  = false,
        Callback = function(state)
            if state then
                local success = AttachVisualItem(item)
                if success then
                    SelectedLarpItem = item.Name
                    if larpItemDropdown then
                        pcall(function() larpItemDropdown:Set(item.Name) end)
                    end
                    syncLarpSlidersToItem(item.Name)
                end
            else
                RemoveVisualItem(item.Name)
            end
        end,
    })
end

sectionLarpItems:AddButton({
    Name     = "Lepas Semua Item Aktif",
    Callback = function()
        for name, tog in pairs(larpItemToggles) do
            if ActiveItems[name] then
                RemoveVisualItem(name)
            end
            if tog and tog:Get() then
                tog:Set(false)
            end
        end
        notify("Larping Visual", "Semua item aktif dilepas.", 2)
    end,
})

-- Section: Pengaturan Item (Posisi, Ukuran, Rotasi, Efek)
local sectionLarpAdjust = tabLarping:AddSection({ Name = "Pengaturan Item (Ukuran, Posisi, Rotasi & Efek)" })

larpItemDropdown = sectionLarpAdjust:AddDropdown({
    Name     = "Nama Item yang Diatur",
    Options  = larpDropdownOptions,
    Default  = SelectedLarpItem,
    Callback = function(val)
        SelectedLarpItem = val
        syncLarpSlidersToItem(val)
    end,
})

larpEffectToggle = sectionLarpAdjust:AddToggle({
    Name     = "Tampilkan Efek Partikel / Api / Sparkles",
    Default  = true,
    Callback = function(state)
        if isSyncingLarpUI or not SelectedLarpItem then return end
        local cfg = EnsureItemConfig(SelectedLarpItem)
        cfg.ShowEffects = state
        ApplyItemTransform(SelectedLarpItem)
    end,
})

larpScaleSlider = sectionLarpAdjust:AddSlider({
    Name     = "Ukuran Item / Scale (%)",
    Min      = 20,
    Max      = 300,
    Default  = 100,
    Callback = function(val)
        if isSyncingLarpUI or not SelectedLarpItem then return end
        local cfg = EnsureItemConfig(SelectedLarpItem)
        cfg.Scale = val
        ApplyItemTransform(SelectedLarpItem)
    end,
})

larpPosXSlider = sectionLarpAdjust:AddSlider({
    Name     = "Posisi Kiri / Kanan (X)",
    Min      = -50,
    Max      = 50,
    Default  = 0,
    Callback = function(val)
        if isSyncingLarpUI or not SelectedLarpItem then return end
        local cfg = EnsureItemConfig(SelectedLarpItem)
        cfg.PosX = val
        ApplyItemTransform(SelectedLarpItem)
    end,
})

larpPosYSlider = sectionLarpAdjust:AddSlider({
    Name     = "Posisi Atas / Bawah (Y)",
    Min      = -50,
    Max      = 50,
    Default  = 0,
    Callback = function(val)
        if isSyncingLarpUI or not SelectedLarpItem then return end
        local cfg = EnsureItemConfig(SelectedLarpItem)
        cfg.PosY = val
        ApplyItemTransform(SelectedLarpItem)
    end,
})

larpPosZSlider = sectionLarpAdjust:AddSlider({
    Name     = "Posisi Depan / Belakang (Z)",
    Min      = -50,
    Max      = 50,
    Default  = 0,
    Callback = function(val)
        if isSyncingLarpUI or not SelectedLarpItem then return end
        local cfg = EnsureItemConfig(SelectedLarpItem)
        cfg.PosZ = val
        ApplyItemTransform(SelectedLarpItem)
    end,
})

larpRotXSlider = sectionLarpAdjust:AddSlider({
    Name     = "Kemiringan Depan / Belakang (Pitch X)",
    Min      = -180,
    Max      = 180,
    Default  = 0,
    Callback = function(val)
        if isSyncingLarpUI or not SelectedLarpItem then return end
        local cfg = EnsureItemConfig(SelectedLarpItem)
        cfg.RotX = val
        ApplyItemTransform(SelectedLarpItem)
    end,
})

larpRotYSlider = sectionLarpAdjust:AddSlider({
    Name     = "Putaran Kiri / Kanan (Yaw Y)",
    Min      = -180,
    Max      = 180,
    Default  = 0,
    Callback = function(val)
        if isSyncingLarpUI or not SelectedLarpItem then return end
        local cfg = EnsureItemConfig(SelectedLarpItem)
        cfg.RotY = val
        ApplyItemTransform(SelectedLarpItem)
    end,
})

larpRotZSlider = sectionLarpAdjust:AddSlider({
    Name     = "Kemiringan Samping (Roll Z)",
    Min      = -180,
    Max      = 180,
    Default  = 0,
    Callback = function(val)
        if isSyncingLarpUI or not SelectedLarpItem then return end
        local cfg = EnsureItemConfig(SelectedLarpItem)
        cfg.RotZ = val
        ApplyItemTransform(SelectedLarpItem)
    end,
})

sectionLarpAdjust:AddButton({
    Name     = "Reset Posisi & Ukuran Item Terpilih",
    Callback = function()
        if not SelectedLarpItem then return end
        ItemConfigs[SelectedLarpItem] = GetDefaultTransform()
        if ActiveItems[SelectedLarpItem] then
            ActiveItems[SelectedLarpItem].Config = ItemConfigs[SelectedLarpItem]
            ApplyItemTransform(SelectedLarpItem)
        end
        syncLarpSlidersToItem(SelectedLarpItem)
        notify("Larping Visual", "Transform " .. SelectedLarpItem .. " di-reset.", 2)
    end,
})

-- Section: Apply Larping Item ke Player Lain
local sectionLarpOther = tabLarping:AddSection({ Name = "Apply Item ke Player Lain" })

local larpTargetInput = sectionLarpOther:AddInput({
    Name        = "Target Username",
    Placeholder = "Ketik username player...",
    Callback    = function(text)
        applyLarpingToPlayer(text)
    end,
})

sectionLarpOther:AddButton({
    Name     = "Apply Item ke Player",
    Callback = function()
        applyLarpingToPlayer(larpTargetInput:Get())
    end,
})

sectionLarpOther:AddButton({
    Name     = "Reset Item di Player Target",
    Callback = function()
        resetLarpingOnPlayer(larpTargetInput:Get())
    end,
})

sectionLarpOther:AddButton({
    Name     = "Reset Item di Semua Player Lain",
    Callback = function()
        resetAllOtherPlayersLarping()
    end,
})