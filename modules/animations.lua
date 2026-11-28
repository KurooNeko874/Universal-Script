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
local AnimDB = loadRemoteData(KUROO_DATA_BASE .. "/animations.lua", { Full = {}, Idle = {}, Walk = {}, Run = {}, Jump = {}, Fall = {}, Climb = {}, Swim = {}, SwimIdle = {} })

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

-- ========== AUTO APPLY ANIMATION (RESPAWN & REJOIN) ==========
local AUTO_ANIM_FILE = "KurooUniversal_AutoAnim.json"
local autoApplyAnim = false
local savedAnimState = {} -- [animType] = animId

local function saveAutoAnimData()
    if typeof(writefile) ~= "function" then return end
    pcall(function()
        local payload = HttpService:JSONEncode({
            autoApply = autoApplyAnim,
            anims = savedAnimState,
        })
        writefile(AUTO_ANIM_FILE, payload)
    end)
end

local function loadAutoAnimData()
    if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return end
    pcall(function()
        if not isfile(AUTO_ANIM_FILE) then return end
        local raw = readfile(AUTO_ANIM_FILE)
        local decoded = HttpService:JSONDecode(raw)
        if type(decoded) == "table" then
            if type(decoded.autoApply) == "boolean" then
                autoApplyAnim = decoded.autoApply
            end
            if type(decoded.anims) == "table" then
                savedAnimState = decoded.anims
            end
        end
    end)
end

loadAutoAnimData()

local function applyAnim(animType, animId)
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local animate = char:FindFirstChild("Animate")
    if not humanoid or not animate then return false end
    preloadAnimation(animId)

    local success = pcall(setAnimId, animate, animType, animId)
    if not success then return false end

    savedAnimState[animType] = animId
    saveAutoAnimData()

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
            savedAnimState[t] = id
        end
    end
    saveAutoAnimData()

    animate.Disabled = true
    task.wait(0.1)
    animate.Disabled = false
    reloadAnimator(humanoid)
    notify("Animation", name .. " applied!", 1)
end

local function reapplySavedAnimations(char)
    if not char or next(savedAnimState) == nil then return end
    local humanoid = char:WaitForChild("Humanoid", 10)
    local animate = char:WaitForChild("Animate", 10)
    if not humanoid or not animate then return end
    task.wait(0.25)

    for animType, animId in pairs(savedAnimState) do
        preloadAnimation(animId)
        pcall(setAnimId, animate, animType, animId)
    end

    animate.Disabled = true
    task.wait(0.1)
    animate.Disabled = false
    reloadAnimator(humanoid)
end

-- Auto apply saat respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if autoApplyAnim then
        task.spawn(reapplySavedAnimations, newChar)
    end
end)

-- Auto apply saat baru join / rejoin jika sebelumnya aktif
if autoApplyAnim and next(savedAnimState) ~= nil then
    task.spawn(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        reapplySavedAnimations(char)
    end)
end

-- ========== Tab 3: Animations ==========
local animTab = window:AddTab({ Name = "Animations" })

-- Section: All Emote (KurooEmote ON/OFF — Auto-Save State)
local emoteSec = animTab:AddSection({ Name = "All Emote" })
local KUROO_EMOTE_URL = "https://raw.githubusercontent.com/KurooNeko874/Universal-Script/refs/heads/main/KurooEmote.lua"
local ALL_EMOTE_CONFIG_FILE = "KurooUniversal_AllEmote.json"
local kurooEmoteEnabled = false
local kurooEmoteReqId = 0

local function saveAllEmoteState(state)
    if type(writefile) ~= "function" then return end
    pcall(function()
        writefile(ALL_EMOTE_CONFIG_FILE, HttpService:JSONEncode({
            enabled = state == true,
        }))
    end)
end

local function loadAllEmoteState()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return false end
    local saved = false
    pcall(function()
        if not isfile(ALL_EMOTE_CONFIG_FILE) then return end
        local decoded = HttpService:JSONDecode(readfile(ALL_EMOTE_CONFIG_FILE))
        if type(decoded) == "table" and type(decoded.enabled) == "boolean" then
            saved = decoded.enabled
        end
    end)
    return saved
end

kurooEmoteEnabled = loadAllEmoteState()

local function cleanupKurooEmote()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.KurooEmoteCleanup) == "function" then
        pcall(env.KurooEmoteCleanup)
        env.KurooEmoteCleanup = nil
    end
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
    end)
end

local function setKurooEmoteEnabled(state, isAutoStart)
    kurooEmoteEnabled = state
    saveAllEmoteState(state)
    kurooEmoteReqId = kurooEmoteReqId + 1
    local myReqId = kurooEmoteReqId

    if state then
        if not isAutoStart then
            notify("All Emote", "Memuat KurooEmote...", 2)
        end
        task.spawn(function()
            local ok, err = pcall(function()
                local src = game:HttpGet(KUROO_EMOTE_URL)
                if not kurooEmoteEnabled or kurooEmoteReqId ~= myReqId then return end
                local fn = loadstring(src)
                if type(fn) == "function" then
                    fn()
                end
            end)

            if not kurooEmoteEnabled or kurooEmoteReqId ~= myReqId then
                cleanupKurooEmote()
                return
            end

            if not ok then
                notify("All Emote", "Gagal memuat KurooEmote.", 3)
                warn("[KurooEmote] Load error:", err)
            end
        end)
    else
        cleanupKurooEmote()
        if not isAutoStart then
            notify("All Emote", "KurooEmote dimatikan.", 2)
        end
    end
end

emoteSec:AddToggle({
    Name = "All Emote",
    Default = kurooEmoteEnabled,
    Callback = function(state)
        setKurooEmoteEnabled(state, false)
    end,
})

if kurooEmoteEnabled then
    setKurooEmoteEnabled(true, true)
end

local autoAnimSec = animTab:AddSection({ Name = "Auto Apply Animation" })
autoAnimSec:AddToggle({
    Name = "Auto Apply (Respawn / Rejoin)",
    Default = autoApplyAnim,
    Callback = function(state)
        autoApplyAnim = state
        saveAutoAnimData()
        notify("Auto Apply Anim", state and "ON: Animasi otomatis dipasang ulang" or "OFF", 2)
    end,
})

local function sortedKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

local allSec = animTab:AddSection({ Name = "ALL ANIMATIONS" })
for _, name in ipairs(AnimDB.Full) do
    allSec:AddButton({
        Name = name,
        Callback = function()
            applyFull(name)
        end,
    })
end

local animCategories = {
    { key = "Idle",     label = "IDLE" },
    { key = "Walk",     label = "WALK" },
    { key = "Run",      label = "RUN" },
    { key = "Jump",     label = "JUMP" },
    { key = "Fall",     label = "FALL" },
    { key = "Climb",    label = "CLIMB" },
    { key = "Swim",     label = "SWIM" },
    { key = "SwimIdle", label = "SWIM IDLE" },
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
end
