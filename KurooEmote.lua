--[[
    ============================================================
    KurooEmote - Universal Roblox Marketplace Emote Wheel
    Version     : 1.0.1
    Author      : Kuroo
    Description : Custom radial Emote Wheel (PC & Mobile) with
                  automatic Roblox Marketplace emote fetching,
                  live Marketplace keyword search, JSON local
                  cache & favorites, adjustable animation speed
                  (0.05x - 10x), and auto-stop on movement.
    ============================================================
]]

-- ============================================================
-- 1. SERVICES (Declared Once at Top)
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
-- 2. CLEANUP PREVIOUS INSTANCE (Singleton)
-- ============================================================
local env = (type(getgenv) == "function" and getgenv()) or _G
if type(env.KurooEmoteCleanup) == "function" then
    pcall(env.KurooEmoteCleanup)
end

-- ============================================================
-- 3. CONSTANTS & CONFIGURATION
-- ============================================================
local VERSION          = "1.0.1"
local FOLDER_NAME      = "KurooEmote"
local FAV_FILE         = FOLDER_NAME .. "/favorites.json"
local CACHE_FILE       = FOLDER_NAME .. "/emotes_cache.json"
local CACHE_MAX_AGE    = 60 * 60 * 24 -- Refresh cache every 24 hours
local MIN_VALID_CACHE  = 25           -- Ignore tiny/fallback-only caches
local SLOTS_PER_PAGE   = 8
local MIN_SPEED        = 0.05
local MAX_SPEED        = 10
local DEFAULT_SPEED    = 1

local COLORS = {
    WheelBg        = Color3.fromRGB(36, 37, 42),
    WheelStroke    = Color3.fromRGB(70, 72, 82),
    CenterBg       = Color3.fromRGB(16, 17, 21),
    CenterStroke   = Color3.fromRGB(58, 60, 70),
    Divider        = Color3.fromRGB(220, 224, 235),
    SlotIdle       = Color3.fromRGB(48, 50, 58),
    SlotHover      = Color3.fromRGB(78, 84, 102),
    SlotFavMode    = Color3.fromRGB(95, 80, 32),
    SlotUnfavMode  = Color3.fromRGB(110, 42, 46),
    PanelBg        = Color3.fromRGB(20, 21, 26),
    PanelStroke    = Color3.fromRGB(62, 65, 78),
    Accent         = Color3.fromRGB(0, 207, 255),
    Gold           = Color3.fromRGB(255, 204, 51),
    Danger         = Color3.fromRGB(245, 78, 86),
    Success        = Color3.fromRGB(64, 214, 128),
    TextPrimary    = Color3.fromRGB(245, 247, 252),
    TextSecondary  = Color3.fromRGB(168, 174, 190),
    TextMuted      = Color3.fromRGB(115, 120, 136),
}

-- Fallback starter emotes (used only while first fetch runs or if offline)
local FALLBACK_EMOTES = {
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
-- 4. HELPER UTILITIES
-- ============================================================
local LocalPlayer = Players.LocalPlayer

local function getCamera()
    return workspace.CurrentCamera
end

local function isMobileDevice()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getThumbnailUrl(assetId)
    return "rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=150&h=150"
end

local function clampSpeed(val)
    local num = tonumber(val)
    if not num or num ~= num then
        return DEFAULT_SPEED
    end
    return math.clamp(num, MIN_SPEED, MAX_SPEED)
end

local function formatSpeed(val)
    local rounded = math.floor(val * 100 + 0.5) / 100
    return tostring(rounded)
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then
            return res
        end
    end
    local ok, _ = pcall(function()
        return CoreGui.Name
    end)
    if ok then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ============================================================
-- 5. FILESYSTEM (JSON SAVE / LOAD)
-- ============================================================
local hasFS = (type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function")

local function ensureFolder()
    if not hasFS then return end
    if type(isfolder) == "function" and type(makefolder) == "function" then
        pcall(function()
            if not isfolder(FOLDER_NAME) then
                makefolder(FOLDER_NAME)
            end
        end)
    end
end

local function writeJsonFile(path, data)
    if not hasFS then return false end
    ensureFolder()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false end
    local writeOk = pcall(writefile, path, encoded)
    return writeOk
end

local function readJsonFile(path)
    if not hasFS then return nil end
    local existsOk, exists = pcall(isfile, path)
    if not existsOk or not exists then return nil end
    local readOk, raw = pcall(readfile, path)
    if not readOk or type(raw) ~= "string" or raw == "" then return nil end
    local decOk, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not decOk then return nil end
    return decoded
end

-- ============================================================
-- 6. HTTP REQUEST WRAPPER (MULTI-METHOD + VALIDATION)
-- ============================================================
local function getRequestFunc()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(http) == "table" and type(http.request) == "function" then return http.request end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    return nil
end

local function decodeCatalogJson(raw)
    if type(raw) ~= "string" or #raw < 2 then return nil end
    local decOk, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if decOk and type(data) == "table" and type(data.data) == "table" then
        return data
    end
    return nil
end

local function httpGetCatalogJson(url)
    local reqFn = getRequestFunc()
    local statusCode = nil

    -- Method 1: Executor request() (works reliably on Roblox domains & proxies)
    if reqFn then
        local reqOk, resp = pcall(reqFn, {
            Url = url,
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json",
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Roblox/WinInet",
            },
        })
        if reqOk and type(resp) == "table" then
            statusCode = tonumber(resp.StatusCode)
            if type(resp.Body) == "string" then
                local parsed = decodeCatalogJson(resp.Body)
                if parsed then
                    return parsed, statusCode
                end
            end
        end
    end

    -- Method 2: game:HttpGet fallback
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(res) == "string" then
        local parsed = decodeCatalogJson(res)
        if parsed then
            return parsed, 200
        end
    end

    return nil, statusCode
end

-- ============================================================
-- 7. STATE MANAGEMENT
-- ============================================================
local State = {
    IsOpen            = false,
    IsDestroyed       = false,
    ViewMode          = "All",      -- "All" or "Favorites"
    StarMode          = false,      -- true = Add Fav (in All) / Remove Fav (in Favorites)
    Speed             = DEFAULT_SPEED,
    SearchQuery       = "",
    CurrentPage       = 1,
    TotalPages        = 1,

    AllEmotes         = {},         -- Array of { id = number, name = string }
    AllEmoteSet       = {},         -- [id] = true
    Favorites         = {},         -- Array of { id = number, name = string }
    FavoriteSet       = {},         -- [id] = true
    FilteredList      = {},         -- Current filtered list displayed on wheel
    LiveSearchResults = {},         -- Live Roblox Marketplace keyword search results
    LiveSearchQuery   = "",         -- Normalized query matching LiveSearchResults
    IdLookupCache     = {},         -- [id] = name
    AnimIdCache       = {},         -- [assetId] = animationId (string)

    IsFetchingCatalog = false,
    SearchRequestId   = 0,

    CurrentTrack      = nil,
    ActiveEmoteId     = nil,
    Connections       = {},
    CharConnections   = {},
}

local function trackConn(conn)
    if conn then
        table.insert(State.Connections, conn)
    end
    return conn
end

local function clearCharConns()
    for _, conn in ipairs(State.CharConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(State.CharConnections)
end

-- Load Favorites from local JSON
local function loadFavorites()
    local data = readJsonFile(FAV_FILE)
    State.Favorites = {}
    State.FavoriteSet = {}
    if type(data) == "table" then
        for _, item in ipairs(data) do
            local id = tonumber(item.id)
            local name = tostring(item.name or ("Emote #" .. tostring(id)))
            if id and not State.FavoriteSet[id] then
                State.FavoriteSet[id] = true
                table.insert(State.Favorites, { id = id, name = name })
            end
        end
    end
end

local function saveFavorites()
    writeJsonFile(FAV_FILE, State.Favorites)
end

local function addEmoteToAll(id, name)
    id = tonumber(id)
    if not id or State.AllEmoteSet[id] then return false end
    State.AllEmoteSet[id] = true
    table.insert(State.AllEmotes, {
        id   = id,
        name = tostring(name or ("Emote #" .. tostring(id))),
    })
    return true
end

local function loadEmotesCache()
    local data = readJsonFile(CACHE_FILE)
    if type(data) == "table" and type(data.emotes) == "table" and #data.emotes >= MIN_VALID_CACHE then
        for _, item in ipairs(data.emotes) do
            addEmoteToAll(item.id, item.name)
        end
        local updatedAt = tonumber(data.updatedAt) or 0
        local isFresh = (os.time() - updatedAt) < CACHE_MAX_AGE
        return true, isFresh
    end
    return false, false
end

local function saveEmotesCache()
    if #State.AllEmotes < MIN_VALID_CACHE then return end
    writeJsonFile(CACHE_FILE, {
        version   = VERSION,
        updatedAt = os.time(),
        emotes    = State.AllEmotes,
    })
end

-- ============================================================
-- 8. DISABLE DEFAULT ROBLOX EMOTE WHEEL
-- ============================================================
local function disableDefaultEmotes()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
    end)
end

disableDefaultEmotes()

-- ============================================================
-- 9. ANIMATION PLAYBACK ENGINE (AUTO-STOP ON MOVEMENT)
-- ============================================================
local showToast -- Forward declaration

local function stopCurrentEmote(fadeTime)
    if State.CurrentTrack then
        pcall(function()
            State.CurrentTrack:Stop(fadeTime or 0.15)
        end)
        State.CurrentTrack = nil
        State.ActiveEmoteId = nil
    end
end

local function bindCharacterMovementStop(character)
    clearCharConns()
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    table.insert(State.CharConnections, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        if State.CurrentTrack and humanoid.MoveDirection.Magnitude > 0.05 then
            stopCurrentEmote(0.15)
        end
    end))

    table.insert(State.CharConnections, humanoid.Jumping:Connect(function(active)
        if active and State.CurrentTrack then
            stopCurrentEmote(0.1)
        end
    end))

    table.insert(State.CharConnections, humanoid.StateChanged:Connect(function(_, newState)
        if not State.CurrentTrack then return end
        if newState == Enum.HumanoidStateType.Climbing
            or newState == Enum.HumanoidStateType.Swimming
            or newState == Enum.HumanoidStateType.Seated
            or newState == Enum.HumanoidStateType.FallingDown
            or newState == Enum.HumanoidStateType.Ragdoll
            or newState == Enum.HumanoidStateType.Dead
            or newState == Enum.HumanoidStateType.Freefall
        then
            stopCurrentEmote(0.15)
        end
    end))

    table.insert(State.CharConnections, humanoid.Died:Connect(function()
        stopCurrentEmote(0)
    end))
end

if LocalPlayer.Character then
    bindCharacterMovementStop(LocalPlayer.Character)
end
trackConn(LocalPlayer.CharacterAdded:Connect(function(char)
    stopCurrentEmote(0)
    bindCharacterMovementStop(char)
end))

local function resolveAnimationId(assetId)
    assetId = tonumber(assetId)
    if not assetId then return nil end

    if State.AnimIdCache[assetId] then
        return State.AnimIdCache[assetId]
    end

    -- Method 1: Load asset via game:GetObjects (works for all public Marketplace emotes in standalone)
    local ok, objs = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)

    if ok and type(objs) == "table" and #objs > 0 then
        local foundAnimId = nil
        for _, obj in ipairs(objs) do
            if obj:IsA("Animation") and obj.AnimationId ~= "" then
                foundAnimId = obj.AnimationId
            else
                local anim = obj:FindFirstChildWhichIsA("Animation", true)
                if anim and anim.AnimationId ~= "" then
                    foundAnimId = anim.AnimationId
                end
            end
            pcall(function() obj:Destroy() end)
            if foundAnimId then break end
        end
        if foundAnimId then
            State.AnimIdCache[assetId] = foundAnimId
            return foundAnimId
        end
    end

    -- Method 2: Fallback if user entered a raw AnimationId directly
    return "rbxassetid://" .. tostring(assetId)
end

local function playEmote(emoteItem)
    if not emoteItem or not emoteItem.id then return end

    local character = LocalPlayer.Character
    if not character then
        showToast("Karakter belum siap!", COLORS.Danger)
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        showToast("Tidak bisa emote saat ini.", COLORS.Danger)
        return
    end

    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        showToast("Avatar R6 terdeteksi — Emote Marketplace membutuhkan R15.", COLORS.Gold)
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    stopCurrentEmote(0.1)

    task.spawn(function()
        local animId = resolveAnimationId(emoteItem.id)
        if not animId or State.IsDestroyed then
            showToast("Gagal memuat animasi emote.", COLORS.Danger)
            return
        end

        local curChar = LocalPlayer.Character
        local curHum = curChar and curChar:FindFirstChildOfClass("Humanoid")
        local curAnim = curHum and curHum:FindFirstChildOfClass("Animator")
        if not curHum or curHum.Health <= 0 or not curAnim then return end

        local anim = Instance.new("Animation")
        anim.AnimationId = animId

        local loadOk, track = pcall(function()
            return curAnim:LoadAnimation(anim)
        end)
        anim:Destroy()

        if loadOk and track then
            track.Priority = Enum.AnimationPriority.Action
            track:Play(0.1)
            track:AdjustSpeed(State.Speed)

            State.CurrentTrack = track
            State.ActiveEmoteId = emoteItem.id

            track.Stopped:Connect(function()
                if State.CurrentTrack == track then
                    State.CurrentTrack = nil
                    State.ActiveEmoteId = nil
                end
            end)
        else
            local nativeOk, nativeTrack = pcall(function()
                return curHum:PlayEmoteAndGetAnimTrackById(emoteItem.id)
            end)
            if nativeOk and nativeTrack then
                nativeTrack:AdjustSpeed(State.Speed)
                State.CurrentTrack = nativeTrack
                State.ActiveEmoteId = emoteItem.id
            else
                showToast("Gagal memutar emote: " .. tostring(emoteItem.name), COLORS.Danger)
            end
        end
    end)
end

-- ============================================================
-- 10. UI CONSTRUCTION (CUSTOM RADIAL WHEEL + TOPBAR BUTTON)
-- ============================================================
local GuiParent = getGuiParent()
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KurooEmote_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = GuiParent

-- ------------------------------------------------------------
-- 10A. Toast Notification Container
-- ------------------------------------------------------------
local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.AnchorPoint = Vector2.new(0.5, 0)
ToastContainer.Position = UDim2.new(0.5, 0, 0, 68)
ToastContainer.Size = UDim2.new(0, 360, 0, 200)
ToastContainer.BackgroundTransparency = 1
ToastContainer.ZIndex = 50
ToastContainer.Parent = ScreenGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ToastLayout.Padding = UDim.new(0, 6)
ToastLayout.Parent = ToastContainer

showToast = function(message, accentColor)
    if State.IsDestroyed or not ToastContainer.Parent then return end
    accentColor = accentColor or COLORS.Accent

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 0, 0, 34)
    toast.AutomaticSize = Enum.AutomaticSize.X
    toast.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
    toast.BackgroundTransparency = 0.08
    toast.BorderSizePixel = 0
    toast.ZIndex = 51
    toast.Parent = ToastContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1.4
    stroke.Transparency = 0.25
    stroke.Parent = toast

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = toast

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 0, 1, 0)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = COLORS.TextPrimary
    label.Text = tostring(message)
    label.ZIndex = 52
    label.Parent = toast

    toast.BackgroundTransparency = 1
    label.TextTransparency = 1
    stroke.Transparency = 1

    TweenService:Create(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.08,
    }):Play()
    TweenService:Create(label, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.18), { Transparency = 0.25 }):Play()

    task.delay(2.4, function()
        if not toast or not toast.Parent then return end
        local t = TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
        TweenService:Create(label, TweenInfo.new(0.22), { TextTransparency = 1 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.22), { Transparency = 1 }):Play()
        t:Play()
        t.Completed:Wait()
        if toast and toast.Parent then
            toast:Destroy()
        end
    end)
end

-- ------------------------------------------------------------
-- 10B. Topbar Circle Button (Smiley Icon, Auto-Scaled PC/Mobile)
-- ------------------------------------------------------------
local TopbarBtn = Instance.new("TextButton")
TopbarBtn.Name = "KurooEmoteTopbarBtn"
TopbarBtn.Text = ""
TopbarBtn.AutoButtonColor = false
TopbarBtn.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
TopbarBtn.BackgroundTransparency = 0.18
TopbarBtn.BorderSizePixel = 0
TopbarBtn.ZIndex = 40
TopbarBtn.Parent = ScreenGui

local TopbarCorner = Instance.new("UICorner")
TopbarCorner.CornerRadius = UDim.new(1, 0)
TopbarCorner.Parent = TopbarBtn

local TopbarStroke = Instance.new("UIStroke")
TopbarStroke.Color = Color3.fromRGB(95, 100, 118)
TopbarStroke.Thickness = 1.4
TopbarStroke.Transparency = 0.35
TopbarStroke.Parent = TopbarBtn

local SmileyLabel = Instance.new("TextLabel")
SmileyLabel.Name = "SmileyIcon"
SmileyLabel.BackgroundTransparency = 1
SmileyLabel.Size = UDim2.new(1, 0, 1, 0)
SmileyLabel.Position = UDim2.new(0, 0, 0, -1)
SmileyLabel.Font = Enum.Font.GothamBold
SmileyLabel.Text = "☺"
SmileyLabel.TextColor3 = COLORS.TextPrimary
SmileyLabel.TextScaled = false
SmileyLabel.TextSize = 24
SmileyLabel.ZIndex = 41
SmileyLabel.Parent = TopbarBtn

-- ------------------------------------------------------------
-- 10C. Main Overlay Root (Responsive UIScale)
-- ------------------------------------------------------------
local WheelRoot = Instance.new("Frame")
WheelRoot.Name = "WheelRoot"
WheelRoot.AnchorPoint = Vector2.new(0.5, 0.5)
WheelRoot.Position = UDim2.new(0.5, 0, 0.5, 8)
WheelRoot.Size = UDim2.new(0, 560, 0, 495)
WheelRoot.BackgroundTransparency = 1
WheelRoot.Visible = false
WheelRoot.ZIndex = 10
WheelRoot.Parent = ScreenGui

local RootScale = Instance.new("UIScale")
RootScale.Scale = 1
RootScale.Parent = WheelRoot

-- ------------------------------------------------------------
-- 10D. Watermark ("KurooEmote") Above Search Bar
-- ------------------------------------------------------------
local WatermarkLabel = Instance.new("TextLabel")
WatermarkLabel.Name = "Watermark"
WatermarkLabel.AnchorPoint = Vector2.new(0.5, 0)
WatermarkLabel.Position = UDim2.new(0.5, 0, 0, 0)
WatermarkLabel.Size = UDim2.new(0, 320, 0, 22)
WatermarkLabel.BackgroundTransparency = 1
WatermarkLabel.Font = Enum.Font.GothamBold
WatermarkLabel.TextSize = 15
WatermarkLabel.TextColor3 = COLORS.TextPrimary
WatermarkLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
WatermarkLabel.TextStrokeTransparency = 0.55
WatermarkLabel.RichText = true
WatermarkLabel.Text = '<font color="#00CFFF">Kuroo</font>Emote  <font size="11" color="#A8AEBE">v' .. VERSION .. "</font>"
WatermarkLabel.ZIndex = 15
WatermarkLabel.Parent = WheelRoot

-- ------------------------------------------------------------
-- 10E. Search Bar (Name / Emote ID) Above Emote Wheel
-- ------------------------------------------------------------
local SearchFrame = Instance.new("Frame")
SearchFrame.Name = "SearchFrame"
SearchFrame.AnchorPoint = Vector2.new(0.5, 0)
SearchFrame.Position = UDim2.new(0.5, 0, 0, 26)
SearchFrame.Size = UDim2.new(0, 310, 0, 36)
SearchFrame.BackgroundColor3 = COLORS.PanelBg
SearchFrame.BackgroundTransparency = 0.1
SearchFrame.BorderSizePixel = 0
SearchFrame.ZIndex = 15
SearchFrame.Parent = WheelRoot

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 18)
SearchCorner.Parent = SearchFrame

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = COLORS.PanelStroke
SearchStroke.Thickness = 1.3
SearchStroke.Parent = SearchFrame

local SearchIcon = Instance.new("TextLabel")
SearchIcon.BackgroundTransparency = 1
SearchIcon.Position = UDim2.new(0, 12, 0, 0)
SearchIcon.Size = UDim2.new(0, 20, 1, 0)
SearchIcon.Font = Enum.Font.GothamBold
SearchIcon.TextSize = 14
SearchIcon.TextColor3 = COLORS.TextSecondary
SearchIcon.Text = "🔍"
SearchIcon.ZIndex = 16
SearchIcon.Parent = SearchFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.BackgroundTransparency = 1
SearchBox.Position = UDim2.new(0, 36, 0, 0)
SearchBox.Size = UDim2.new(1, -68, 1, 0)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.TextColor3 = COLORS.TextPrimary
SearchBox.PlaceholderColor3 = COLORS.TextMuted
SearchBox.PlaceholderText = "Cari nama emote / masukkan ID..."
SearchBox.Text = ""
SearchBox.ClearTextOnFocus = false
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ZIndex = 16
SearchBox.Parent = SearchFrame

local ClearSearchBtn = Instance.new("TextButton")
ClearSearchBtn.Name = "ClearSearch"
ClearSearchBtn.AnchorPoint = Vector2.new(1, 0.5)
ClearSearchBtn.Position = UDim2.new(1, -8, 0.5, 0)
ClearSearchBtn.Size = UDim2.new(0, 22, 0, 22)
ClearSearchBtn.BackgroundColor3 = Color3.fromRGB(45, 47, 56)
ClearSearchBtn.BackgroundTransparency = 0.3
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.TextSize = 12
ClearSearchBtn.TextColor3 = COLORS.TextSecondary
ClearSearchBtn.Text = "×"
ClearSearchBtn.Visible = false
ClearSearchBtn.ZIndex = 17
ClearSearchBtn.Parent = SearchFrame

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(1, 0)
ClearCorner.Parent = ClearSearchBtn

-- ------------------------------------------------------------
-- 10F. Left Side Control: Speed Input (0.05 - 10)
-- ------------------------------------------------------------
local SpeedPanel = Instance.new("Frame")
SpeedPanel.Name = "SpeedPanel"
SpeedPanel.AnchorPoint = Vector2.new(1, 0.5)
SpeedPanel.Position = UDim2.new(0.5, -186, 0, 250)
SpeedPanel.Size = UDim2.new(0, 86, 0, 76)
SpeedPanel.BackgroundColor3 = COLORS.PanelBg
SpeedPanel.BackgroundTransparency = 0.12
SpeedPanel.BorderSizePixel = 0
SpeedPanel.ZIndex = 15
SpeedPanel.Parent = WheelRoot

local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 14)
SpeedCorner.Parent = SpeedPanel

local SpeedStroke = Instance.new("UIStroke")
SpeedStroke.Color = COLORS.PanelStroke
SpeedStroke.Thickness = 1.3
SpeedStroke.Parent = SpeedPanel

local SpeedTitle = Instance.new("TextLabel")
SpeedTitle.BackgroundTransparency = 1
SpeedTitle.Position = UDim2.new(0, 0, 0, 6)
SpeedTitle.Size = UDim2.new(1, 0, 0, 16)
SpeedTitle.Font = Enum.Font.GothamBold
SpeedTitle.TextSize = 11
SpeedTitle.TextColor3 = COLORS.TextSecondary
SpeedTitle.Text = "SPEED"
SpeedTitle.ZIndex = 16
SpeedTitle.Parent = SpeedPanel

local SpeedBox = Instance.new("TextBox")
SpeedBox.Name = "SpeedBox"
SpeedBox.AnchorPoint = Vector2.new(0.5, 0)
SpeedBox.Position = UDim2.new(0.5, 0, 0, 24)
SpeedBox.Size = UDim2.new(1, -18, 0, 28)
SpeedBox.BackgroundColor3 = Color3.fromRGB(32, 34, 42)
SpeedBox.BorderSizePixel = 0
SpeedBox.Font = Enum.Font.GothamBold
SpeedBox.TextSize = 14
SpeedBox.TextColor3 = COLORS.Accent
SpeedBox.PlaceholderColor3 = COLORS.TextMuted
SpeedBox.PlaceholderText = "1"
SpeedBox.Text = tostring(DEFAULT_SPEED)
SpeedBox.ClearTextOnFocus = false
SpeedBox.ZIndex = 16
SpeedBox.Parent = SpeedPanel

local SpeedBoxCorner = Instance.new("UICorner")
SpeedBoxCorner.CornerRadius = UDim.new(0, 8)
SpeedBoxCorner.Parent = SpeedBox

local SpeedHint = Instance.new("TextLabel")
SpeedHint.BackgroundTransparency = 1
SpeedHint.Position = UDim2.new(0, 0, 1, -18)
SpeedHint.Size = UDim2.new(1, 0, 0, 14)
SpeedHint.Font = Enum.Font.Gotham
SpeedHint.TextSize = 9
SpeedHint.TextColor3 = COLORS.TextMuted
SpeedHint.Text = "0.05 - 10x"
SpeedHint.ZIndex = 16
SpeedHint.Parent = SpeedPanel

-- ------------------------------------------------------------
-- 10G. Right Side Control: Star Icon Button (Fav / Unfav Mode)
-- ------------------------------------------------------------
local StarPanel = Instance.new("Frame")
StarPanel.Name = "StarPanel"
StarPanel.AnchorPoint = Vector2.new(0, 0.5)
StarPanel.Position = UDim2.new(0.5, 186, 0, 250)
StarPanel.Size = UDim2.new(0, 74, 0, 76)
StarPanel.BackgroundTransparency = 1
StarPanel.ZIndex = 15
StarPanel.Parent = WheelRoot

local StarBtn = Instance.new("TextButton")
StarBtn.Name = "StarBtn"
StarBtn.AnchorPoint = Vector2.new(0.5, 0)
StarBtn.Position = UDim2.new(0.5, 0, 0, 4)
StarBtn.Size = UDim2.new(0, 52, 0, 52)
StarBtn.BackgroundColor3 = COLORS.PanelBg
StarBtn.BackgroundTransparency = 0.1
StarBtn.AutoButtonColor = false
StarBtn.Font = Enum.Font.GothamBold
StarBtn.TextSize = 26
StarBtn.TextColor3 = COLORS.TextSecondary
StarBtn.Text = "★"
StarBtn.ZIndex = 16
StarBtn.Parent = StarPanel

local StarBtnCorner = Instance.new("UICorner")
StarBtnCorner.CornerRadius = UDim.new(1, 0)
StarBtnCorner.Parent = StarBtn

local StarBtnStroke = Instance.new("UIStroke")
StarBtnStroke.Color = COLORS.PanelStroke
StarBtnStroke.Thickness = 1.5
StarBtnStroke.Parent = StarBtn

local StarCaption = Instance.new("TextLabel")
StarCaption.Name = "StarCaption"
StarCaption.BackgroundTransparency = 1
StarCaption.Position = UDim2.new(0, 0, 1, -16)
StarCaption.Size = UDim2.new(1, 0, 0, 16)
StarCaption.Font = Enum.Font.GothamBold
StarCaption.TextSize = 10
StarCaption.TextColor3 = COLORS.TextSecondary
StarCaption.Text = "FAVORIT"
StarCaption.ZIndex = 16
StarCaption.Parent = StarPanel

-- ------------------------------------------------------------
-- 10H. Center Radial Emote Wheel (8 Sectors Matching Reference)
-- ------------------------------------------------------------
local WHEEL_SIZE = 344
local INNER_SIZE = 148
local SLOT_RADIUS = 120

local WheelCircle = Instance.new("Frame")
WheelCircle.Name = "WheelCircle"
WheelCircle.AnchorPoint = Vector2.new(0.5, 0.5)
WheelCircle.Position = UDim2.new(0.5, 0, 0, 250)
WheelCircle.Size = UDim2.new(0, WHEEL_SIZE, 0, WHEEL_SIZE)
WheelCircle.BackgroundColor3 = COLORS.WheelBg
WheelCircle.BackgroundTransparency = 0.14
WheelCircle.BorderSizePixel = 0
WheelCircle.ZIndex = 11
WheelCircle.Parent = WheelRoot

local WheelCorner = Instance.new("UICorner")
WheelCorner.CornerRadius = UDim.new(1, 0)
WheelCorner.Parent = WheelCircle

local WheelStroke = Instance.new("UIStroke")
WheelStroke.Color = COLORS.WheelStroke
WheelStroke.Thickness = 2
WheelStroke.Parent = WheelCircle

-- 8 Crisp White Radial Divider Lines (at 22.5 + 45*k degrees)
local dividerLength = (WHEEL_SIZE - INNER_SIZE) / 2 - 4
local dividerMidDist = (INNER_SIZE / 2) + (dividerLength / 2)

for i = 0, 7 do
    local angleDeg = 22.5 + (i * 45)
    local rad = math.rad(angleDeg - 90)
    local cx = (WHEEL_SIZE / 2) + math.cos(rad) * dividerMidDist
    local cy = (WHEEL_SIZE / 2) + math.sin(rad) * dividerMidDist

    local line = Instance.new("Frame")
    line.Name = "Divider_" .. tostring(i + 1)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.new(0, cx, 0, cy)
    line.Size = UDim2.new(0, 1.5, 0, dividerLength)
    line.Rotation = angleDeg
    line.BackgroundColor3 = COLORS.Divider
    line.BackgroundTransparency = 0.25
    line.BorderSizePixel = 0
    line.ZIndex = 12
    line.Parent = WheelCircle

    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(0.45, 0.15),
        NumberSequenceKeypoint.new(1, 0.05),
    })
    grad.Parent = line
end

-- 8 Emote Slot Buttons
local SlotButtons = {}
local HoveredSlotIdx = nil

for i = 1, SLOTS_PER_PAGE do
    local angleDeg = (i - 1) * 45
    local rad = math.rad(angleDeg - 90)
    local sx = (WHEEL_SIZE / 2) + math.cos(rad) * SLOT_RADIUS
    local sy = (WHEEL_SIZE / 2) + math.sin(rad) * SLOT_RADIUS

    local slotBtn = Instance.new("TextButton")
    slotBtn.Name = "Slot_" .. tostring(i)
    slotBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    slotBtn.Position = UDim2.new(0, sx, 0, sy)
    slotBtn.Size = UDim2.new(0, 74, 0, 74)
    slotBtn.BackgroundColor3 = COLORS.SlotIdle
    slotBtn.BackgroundTransparency = 0.55
    slotBtn.BorderSizePixel = 0
    slotBtn.AutoButtonColor = false
    slotBtn.Text = ""
    slotBtn.ZIndex = 14
    slotBtn.Parent = WheelCircle

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = slotBtn

    local sStroke = Instance.new("UIStroke")
    sStroke.Color = COLORS.Accent
    sStroke.Thickness = 2
    sStroke.Transparency = 1
    sStroke.Parent = slotBtn

    local thumb = Instance.new("ImageLabel")
    thumb.Name = "Thumb"
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(0.5, 0, 0.44, 0)
    thumb.Size = UDim2.new(0, 50, 0, 50)
    thumb.BackgroundTransparency = 1
    thumb.ScaleType = Enum.ScaleType.Fit
    thumb.Image = ""
    thumb.ZIndex = 15
    thumb.Parent = slotBtn

    local slotName = Instance.new("TextLabel")
    slotName.Name = "SlotName"
    slotName.AnchorPoint = Vector2.new(0.5, 1)
    slotName.Position = UDim2.new(0.5, 0, 1, -4)
    slotName.Size = UDim2.new(1, -8, 0, 14)
    slotName.BackgroundTransparency = 1
    slotName.Font = Enum.Font.GothamMedium
    slotName.TextSize = 9
    slotName.TextColor3 = COLORS.TextPrimary
    slotName.TextTruncate = Enum.TextTruncate.AtEnd
    slotName.Text = ""
    slotName.ZIndex = 16
    slotName.Parent = slotBtn

    local favBadge = Instance.new("TextLabel")
    favBadge.Name = "FavBadge"
    favBadge.AnchorPoint = Vector2.new(1, 0)
    favBadge.Position = UDim2.new(1, -2, 0, 2)
    favBadge.Size = UDim2.new(0, 18, 0, 18)
    favBadge.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    favBadge.BackgroundTransparency = 0.2
    favBadge.Font = Enum.Font.GothamBold
    favBadge.TextSize = 11
    favBadge.TextColor3 = COLORS.Gold
    favBadge.Text = "★"
    favBadge.Visible = false
    favBadge.ZIndex = 17
    favBadge.Parent = slotBtn

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(1, 0)
    badgeCorner.Parent = favBadge

    SlotButtons[i] = {
        Button   = slotBtn,
        Stroke   = sStroke,
        Thumb    = thumb,
        NameLbl  = slotName,
        FavBadge = favBadge,
        Emote    = nil,
    }
end

-- Inner Center Dark Circle
local CenterCircle = Instance.new("Frame")
CenterCircle.Name = "CenterCircle"
CenterCircle.AnchorPoint = Vector2.new(0.5, 0.5)
CenterCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
CenterCircle.Size = UDim2.new(0, INNER_SIZE, 0, INNER_SIZE)
CenterCircle.BackgroundColor3 = COLORS.CenterBg
CenterCircle.BackgroundTransparency = 0.04
CenterCircle.BorderSizePixel = 0
CenterCircle.ZIndex = 18
CenterCircle.Parent = WheelCircle

local CenterCorner = Instance.new("UICorner")
CenterCorner.CornerRadius = UDim.new(1, 0)
CenterCorner.Parent = CenterCircle

local CenterStroke = Instance.new("UIStroke")
CenterStroke.Color = COLORS.CenterStroke
CenterStroke.Thickness = 1.6
CenterStroke.Parent = CenterCircle

local CenterModeLbl = Instance.new("TextLabel")
CenterModeLbl.Name = "CenterMode"
CenterModeLbl.AnchorPoint = Vector2.new(0.5, 0)
CenterModeLbl.Position = UDim2.new(0.5, 0, 0, 18)
CenterModeLbl.Size = UDim2.new(1, -24, 0, 14)
CenterModeLbl.BackgroundTransparency = 1
CenterModeLbl.Font = Enum.Font.GothamBold
CenterModeLbl.TextSize = 10
CenterModeLbl.TextColor3 = COLORS.Accent
CenterModeLbl.Text = "ALL EMOTES"
CenterModeLbl.ZIndex = 19
CenterModeLbl.Parent = CenterCircle

local CenterEmoteName = Instance.new("TextLabel")
CenterEmoteName.Name = "CenterEmoteName"
CenterEmoteName.AnchorPoint = Vector2.new(0.5, 0.5)
CenterEmoteName.Position = UDim2.new(0.5, 0, 0.48, 0)
CenterEmoteName.Size = UDim2.new(1, -22, 0, 44)
CenterEmoteName.BackgroundTransparency = 1
CenterEmoteName.Font = Enum.Font.GothamBold
CenterEmoteName.TextSize = 13
CenterEmoteName.TextWrapped = true
CenterEmoteName.TextColor3 = COLORS.TextPrimary
CenterEmoteName.Text = "Pilih Emote"
CenterEmoteName.ZIndex = 19
CenterEmoteName.Parent = CenterCircle

-- Page Controls (< 1 / N >) inside bottom of center circle
local PageBar = Instance.new("Frame")
PageBar.Name = "PageBar"
PageBar.AnchorPoint = Vector2.new(0.5, 1)
PageBar.Position = UDim2.new(0.5, 0, 1, -16)
PageBar.Size = UDim2.new(0, 108, 0, 24)
PageBar.BackgroundTransparency = 1
PageBar.ZIndex = 19
PageBar.Parent = CenterCircle

local PrevBtn = Instance.new("TextButton")
PrevBtn.Name = "PrevBtn"
PrevBtn.AnchorPoint = Vector2.new(0, 0.5)
PrevBtn.Position = UDim2.new(0, 0, 0.5, 0)
PrevBtn.Size = UDim2.new(0, 24, 0, 24)
PrevBtn.BackgroundColor3 = Color3.fromRGB(34, 36, 44)
PrevBtn.AutoButtonColor = false
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.TextSize = 14
PrevBtn.TextColor3 = COLORS.TextPrimary
PrevBtn.Text = "<"
PrevBtn.ZIndex = 20
PrevBtn.Parent = PageBar

local PrevCorner = Instance.new("UICorner")
PrevCorner.CornerRadius = UDim.new(1, 0)
PrevCorner.Parent = PrevBtn

local PageLabel = Instance.new("TextLabel")
PageLabel.Name = "PageLabel"
PageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
PageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
PageLabel.Size = UDim2.new(0, 56, 1, 0)
PageLabel.BackgroundTransparency = 1
PageLabel.Font = Enum.Font.GothamMedium
PageLabel.TextSize = 11
PageLabel.TextColor3 = COLORS.TextSecondary
PageLabel.Text = "1 / 1"
PageLabel.ZIndex = 20
PageLabel.Parent = PageBar

local NextBtn = Instance.new("TextButton")
NextBtn.Name = "NextBtn"
NextBtn.AnchorPoint = Vector2.new(1, 0.5)
NextBtn.Position = UDim2.new(1, 0, 0.5, 0)
NextBtn.Size = UDim2.new(0, 24, 0, 24)
NextBtn.BackgroundColor3 = Color3.fromRGB(34, 36, 44)
NextBtn.AutoButtonColor = false
NextBtn.Font = Enum.Font.GothamBold
NextBtn.TextSize = 14
NextBtn.TextColor3 = COLORS.TextPrimary
NextBtn.Text = ">"
NextBtn.ZIndex = 20
NextBtn.Parent = PageBar

local NextCorner = Instance.new("UICorner")
NextCorner.CornerRadius = UDim.new(1, 0)
NextCorner.Parent = NextBtn

-- ------------------------------------------------------------
-- 10I. Bottom Button: Open / Toggle Favorites List
-- ------------------------------------------------------------
local FavViewBtn = Instance.new("TextButton")
FavViewBtn.Name = "FavViewBtn"
FavViewBtn.AnchorPoint = Vector2.new(0.5, 0)
FavViewBtn.Position = UDim2.new(0.5, 0, 0, 434)
FavViewBtn.Size = UDim2.new(0, 210, 0, 38)
FavViewBtn.BackgroundColor3 = COLORS.PanelBg
FavViewBtn.BackgroundTransparency = 0.08
FavViewBtn.AutoButtonColor = false
FavViewBtn.Font = Enum.Font.GothamBold
FavViewBtn.TextSize = 13
FavViewBtn.TextColor3 = COLORS.Gold
FavViewBtn.Text = "★  Favorites (0)"
FavViewBtn.ZIndex = 15
FavViewBtn.Parent = WheelRoot

local FavViewCorner = Instance.new("UICorner")
FavViewCorner.CornerRadius = UDim.new(0, 19)
FavViewCorner.Parent = FavViewBtn

local FavViewStroke = Instance.new("UIStroke")
FavViewStroke.Color = COLORS.Gold
FavViewStroke.Thickness = 1.4
FavViewStroke.Transparency = 0.35
FavViewStroke.Parent = FavViewBtn

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.AnchorPoint = Vector2.new(0.5, 0)
StatusLabel.Position = UDim2.new(0.5, 0, 0, 476)
StatusLabel.Size = UDim2.new(0, 340, 0, 16)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = COLORS.TextMuted
StatusLabel.Text = ""
StatusLabel.ZIndex = 15
StatusLabel.Parent = WheelRoot

-- ============================================================
-- 11. RESPONSIVE SCALING (PC & MOBILE AUTO-FIT)
-- ============================================================
local function updateResponsiveLayout()
    local cam = getCamera()
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local mobile = isMobileDevice() or (vp.X < 900)

    local scaleX = (vp.X * 0.94) / 560
    local scaleY = (vp.Y * 0.86) / 495
    local targetScale = math.clamp(math.min(scaleX, scaleY), 0.48, 1.05)
    RootScale.Scale = targetScale

    if mobile then
        local btnSize = math.clamp(math.floor(vp.Y * 0.085), 34, 42)
        TopbarBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
        TopbarBtn.Position = UDim2.new(0, 184, 0, 10)
        SmileyLabel.TextSize = math.floor(btnSize * 0.62)
    else
        TopbarBtn.Size = UDim2.new(0, 44, 0, 44)
        TopbarBtn.Position = UDim2.new(0, 224, 0, 12)
        SmileyLabel.TextSize = 26
    end
end

updateResponsiveLayout()
local function bindViewportListener()
    local cam = getCamera()
    if cam then
        trackConn(cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout))
    end
end
bindViewportListener()
trackConn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    updateResponsiveLayout()
    bindViewportListener()
end))

-- ============================================================
-- 12. UI RENDER & REFRESH LOGIC
-- ============================================================
local function updateStarVisuals()
    if State.ViewMode == "Favorites" then
        StarCaption.Text = "UNFAV"
        if State.StarMode then
            StarBtn.BackgroundColor3 = COLORS.Danger
            StarBtn.TextColor3 = COLORS.TextPrimary
            StarBtnStroke.Color = COLORS.Danger
            WheelStroke.Color = COLORS.Danger
            CenterModeLbl.Text = "★ TAP TO UNFAV"
            CenterModeLbl.TextColor3 = COLORS.Danger
        else
            StarBtn.BackgroundColor3 = COLORS.PanelBg
            StarBtn.TextColor3 = COLORS.TextSecondary
            StarBtnStroke.Color = COLORS.PanelStroke
            WheelStroke.Color = COLORS.Gold
            CenterModeLbl.Text = "★ FAVORITES"
            CenterModeLbl.TextColor3 = COLORS.Gold
        end
    else
        StarCaption.Text = "FAVORIT"
        if State.StarMode then
            StarBtn.BackgroundColor3 = COLORS.Gold
            StarBtn.TextColor3 = Color3.fromRGB(20, 20, 24)
            StarBtnStroke.Color = COLORS.Gold
            WheelStroke.Color = COLORS.Gold
            CenterModeLbl.Text = "★ TAP TO FAV"
            CenterModeLbl.TextColor3 = COLORS.Gold
        else
            StarBtn.BackgroundColor3 = COLORS.PanelBg
            StarBtn.TextColor3 = COLORS.TextSecondary
            StarBtnStroke.Color = COLORS.PanelStroke
            WheelStroke.Color = COLORS.WheelStroke
            CenterModeLbl.Text = "ALL EMOTES"
            CenterModeLbl.TextColor3 = COLORS.Accent
        end
    end
end

local function updateFavViewButton()
    if State.ViewMode == "Favorites" then
        FavViewBtn.Text = "←  All Emotes (" .. tostring(#State.AllEmotes) .. ")"
        FavViewBtn.TextColor3 = COLORS.Accent
        FavViewStroke.Color = COLORS.Accent
    else
        FavViewBtn.Text = "★  Favorites (" .. tostring(#State.Favorites) .. ")"
        FavViewBtn.TextColor3 = COLORS.Gold
        FavViewStroke.Color = COLORS.Gold
    end
end

local function updateCenterDisplay(emoteItem)
    if emoteItem then
        CenterEmoteName.Text = emoteItem.name
        CenterEmoteName.TextColor3 = COLORS.TextPrimary
    else
        if State.ViewMode == "Favorites" and #State.Favorites == 0 then
            CenterEmoteName.Text = "Belum ada Favorit"
            CenterEmoteName.TextColor3 = COLORS.TextMuted
        elseif #State.FilteredList == 0 then
            CenterEmoteName.Text = "Tidak ditemukan"
            CenterEmoteName.TextColor3 = COLORS.TextMuted
        else
            CenterEmoteName.Text = "Pilih Emote"
            CenterEmoteName.TextColor3 = COLORS.TextSecondary
        end
    end
end

local function renderWheelPage()
    local totalItems = #State.FilteredList
    State.TotalPages = math.max(1, math.ceil(totalItems / SLOTS_PER_PAGE))
    State.CurrentPage = math.clamp(State.CurrentPage, 1, State.TotalPages)

    PageLabel.Text = tostring(State.CurrentPage) .. " / " .. tostring(State.TotalPages)
    PrevBtn.TextTransparency = (State.CurrentPage <= 1) and 0.6 or 0
    NextBtn.TextTransparency = (State.CurrentPage >= State.TotalPages) and 0.6 or 0

    local startIdx = (State.CurrentPage - 1) * SLOTS_PER_PAGE

    for i = 1, SLOTS_PER_PAGE do
        local slot = SlotButtons[i]
        local item = State.FilteredList[startIdx + i]
        slot.Emote = item

        if item then
            slot.Button.Visible = true
            slot.Thumb.Image = getThumbnailUrl(item.id)
            slot.NameLbl.Text = item.name
            slot.FavBadge.Visible = (State.FavoriteSet[item.id] == true)
            slot.Button.BackgroundColor3 = COLORS.SlotIdle
            slot.Stroke.Transparency = 1
        else
            slot.Button.Visible = false
            slot.Thumb.Image = ""
            slot.NameLbl.Text = ""
            slot.FavBadge.Visible = false
        end
    end

    HoveredSlotIdx = nil
    updateStarVisuals()
    updateFavViewButton()
    updateCenterDisplay(nil)
end

local function rebuildFilteredList(resetPage)
    local source = (State.ViewMode == "Favorites") and State.Favorites or State.AllEmotes
    local query = string.lower(string.gsub(State.SearchQuery or "", "^%s*(.-)%s*$", "%1"))

    local result = {}
    if query == "" then
        for _, item in ipairs(source) do
            table.insert(result, item)
        end
    else
        local seen = {}
        local numericId = tonumber(query)
        if numericId and math.floor(numericId) == numericId and numericId > 0 and State.ViewMode == "All" then
            local matchedName = State.IdLookupCache[numericId]
            for _, item in ipairs(source) do
                if item.id == numericId then
                    matchedName = item.name
                    break
                end
            end

            seen[numericId] = true
            table.insert(result, {
                id   = numericId,
                name = matchedName or ("Emote #" .. tostring(numericId)),
            })

            if not matchedName then
                task.spawn(function()
                    local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, numericId)
                    if ok and type(info) == "table" and info.Name then
                        State.IdLookupCache[numericId] = info.Name
                        if not State.IsDestroyed and tonumber(State.SearchQuery) == numericId then
                            rebuildFilteredList(false)
                        end
                    end
                end)
            end
        end

        if State.ViewMode == "All" and State.LiveSearchQuery == query and #State.LiveSearchResults > 0 then
            for _, item in ipairs(State.LiveSearchResults) do
                if not seen[item.id] then
                    seen[item.id] = true
                    table.insert(result, item)
                end
            end
        end

        for _, item in ipairs(source) do
            if not seen[item.id] then
                if string.find(string.lower(item.name), query, 1, true)
                    or string.find(tostring(item.id), query, 1, true)
                then
                    seen[item.id] = true
                    table.insert(result, item)
                end
            end
        end
    end

    State.FilteredList = result
    if resetPage then
        State.CurrentPage = 1
    end
    renderWheelPage()
end

-- ============================================================
-- 13. OPEN / CLOSE WHEEL
-- ============================================================
local function setWheelOpen(open)
    if State.IsDestroyed then return end
    State.IsOpen = open
    WheelRoot.Visible = open

    if open then
        disableDefaultEmotes()
        TopbarStroke.Color = COLORS.Accent
        TopbarStroke.Transparency = 0.05
        SmileyLabel.TextColor3 = COLORS.Accent
        rebuildFilteredList(false)
    else
        TopbarStroke.Color = Color3.fromRGB(95, 100, 118)
        TopbarStroke.Transparency = 0.35
        SmileyLabel.TextColor3 = COLORS.TextPrimary
        if State.StarMode then
            State.StarMode = false
            updateStarVisuals()
        end
    end
end

-- ============================================================
-- 14. INTERACTION HANDLERS
-- ============================================================
trackConn(TopbarBtn.MouseButton1Click:Connect(function()
    setWheelOpen(not State.IsOpen)
end))

trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Period then
        setWheelOpen(not State.IsOpen)
    elseif input.KeyCode == Enum.KeyCode.Escape and State.IsOpen then
        setWheelOpen(false)
    end
end))

trackConn(WheelCircle.InputChanged:Connect(function(input)
    if not State.IsOpen then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        if input.Position.Z > 0 and State.CurrentPage > 1 then
            State.CurrentPage = State.CurrentPage - 1
            renderWheelPage()
        elseif input.Position.Z < 0 and State.CurrentPage < State.TotalPages then
            State.CurrentPage = State.CurrentPage + 1
            renderWheelPage()
        end
    end
end))

trackConn(PrevBtn.MouseButton1Click:Connect(function()
    if State.CurrentPage > 1 then
        State.CurrentPage = State.CurrentPage - 1
        renderWheelPage()
    end
end))

trackConn(NextBtn.MouseButton1Click:Connect(function()
    if State.CurrentPage < State.TotalPages then
        State.CurrentPage = State.CurrentPage + 1
        renderWheelPage()
    end
end))

local function applySpeedFromBox()
    local clamped = clampSpeed(SpeedBox.Text)
    State.Speed = clamped
    SpeedBox.Text = formatSpeed(clamped)
    if State.CurrentTrack then
        pcall(function()
            State.CurrentTrack:AdjustSpeed(State.Speed)
        end)
    end
end

trackConn(SpeedBox.FocusLost:Connect(function()
    applySpeedFromBox()
end))

trackConn(StarBtn.MouseButton1Click:Connect(function()
    State.StarMode = not State.StarMode
    updateStarVisuals()
    if State.StarMode then
        if State.ViewMode == "Favorites" then
            showToast("Mode Unfav aktif — klik emote untuk menghapus dari Favorit.", COLORS.Danger)
        else
            showToast("Mode Favorit aktif — klik emote yang ingin difavoritkan.", COLORS.Gold)
        end
    end
end))

trackConn(FavViewBtn.MouseButton1Click:Connect(function()
    State.StarMode = false
    if State.ViewMode == "All" then
        State.ViewMode = "Favorites"
    else
        State.ViewMode = "All"
    end
    rebuildFilteredList(true)
end))

-- Live Catalog Keyword Search (searches ALL tens of thousands of Marketplace emotes directly)
local function searchCatalogLive(keyword, reqId)
    local normQuery = string.lower(string.gsub(keyword or "", "^%s*(.-)%s*$", "%1"))
    if #normQuery < 2 then return end

    if not State.IsDestroyed and State.SearchRequestId == reqId then
        StatusLabel.Text = 'Mencari "' .. keyword .. '" di Marketplace...'
    end

    local encoded = HttpService:UrlEncode(keyword)
    local endpoints = {
        "https://catalog.roblox.com/v1/search/items/details?Category=12&Subcategory=39&Limit=30&Keyword=" .. encoded,
        "https://catalog.roproxy.com/v1/search/items/details?Category=12&Subcategory=39&Limit=30&Keyword=" .. encoded,
    }

    local foundList = {}
    local foundSet = {}
    local success = false

    for _, baseUrl in ipairs(endpoints) do
        local data = httpGetCatalogJson(baseUrl)
        if data and type(data.data) == "table" then
            success = true
            local cursor = data.nextPageCursor
            for _, item in ipairs(data.data) do
                local id = tonumber(item.id)
                local name = tostring(item.name or ("Emote #" .. tostring(id)))
                if id and not foundSet[id] then
                    foundSet[id] = true
                    table.insert(foundList, { id = id, name = name })
                    addEmoteToAll(id, name)
                end
            end

            local extraPages = 0
            while cursor and cursor ~= "" and extraPages < 2 and not State.IsDestroyed and State.SearchRequestId == reqId do
                task.wait(0.15)
                local nextData = httpGetCatalogJson(baseUrl .. "&Cursor=" .. HttpService:UrlEncode(cursor))
                if not nextData or type(nextData.data) ~= "table" then break end
                for _, item in ipairs(nextData.data) do
                    local id = tonumber(item.id)
                    local name = tostring(item.name or ("Emote #" .. tostring(id)))
                    if id and not foundSet[id] then
                        foundSet[id] = true
                        table.insert(foundList, { id = id, name = name })
                        addEmoteToAll(id, name)
                    end
                end
                cursor = nextData.nextPageCursor
                extraPages = extraPages + 1
            end
            break
        end
    end

    if not success then
        pcall(function()
            local params = CatalogSearchParams.new()
            params.AssetTypes = { Enum.AssetType.EmoteAnimation }
            params.SearchKeyword = keyword
            local pages = AvatarEditorService:SearchCatalog(params)
            if pages then
                local current = pages:GetCurrentPage()
                if type(current) == "table" then
                    for _, item in ipairs(current) do
                        local id = tonumber(item.Id)
                        local name = tostring(item.Name or ("Emote #" .. tostring(id)))
                        if id and not foundSet[id] then
                            foundSet[id] = true
                            table.insert(foundList, { id = id, name = name })
                            addEmoteToAll(id, name)
                        end
                    end
                end
            end
        end)
    end

    if #foundList > 0 then
        saveEmotesCache()
    end

    if not State.IsDestroyed and State.SearchRequestId == reqId then
        State.LiveSearchQuery = normQuery
        State.LiveSearchResults = foundList
        StatusLabel.Text = tostring(#State.AllEmotes) .. " Emote tersedia"
        rebuildFilteredList(true)
    end
end

trackConn(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local text = SearchBox.Text
    State.SearchQuery = text
    ClearSearchBtn.Visible = (#text > 0)
    if text == "" then
        State.LiveSearchQuery = ""
        State.LiveSearchResults = {}
    end
    rebuildFilteredList(true)

    local trimmed = string.gsub(text, "^%s*(.-)%s*$", "%1")
    if State.ViewMode == "All" and #trimmed >= 2 and not tonumber(trimmed) then
        State.SearchRequestId = State.SearchRequestId + 1
        local myReqId = State.SearchRequestId
        task.delay(0.35, function()
            if not State.IsDestroyed and State.SearchRequestId == myReqId then
                searchCatalogLive(trimmed, myReqId)
            end
        end)
    end
end))

trackConn(ClearSearchBtn.MouseButton1Click:Connect(function()
    SearchBox.Text = ""
end))

for i = 1, SLOTS_PER_PAGE do
    local slot = SlotButtons[i]

    trackConn(slot.Button.MouseEnter:Connect(function()
        if not slot.Emote then return end
        HoveredSlotIdx = i
        if State.StarMode then
            if State.ViewMode == "Favorites" then
                slot.Button.BackgroundColor3 = COLORS.SlotUnfavMode
                slot.Stroke.Color = COLORS.Danger
            else
                slot.Button.BackgroundColor3 = COLORS.SlotFavMode
                slot.Stroke.Color = COLORS.Gold
            end
        else
            slot.Button.BackgroundColor3 = COLORS.SlotHover
            slot.Stroke.Color = COLORS.Accent
        end
        slot.Stroke.Transparency = 0.1
        updateCenterDisplay(slot.Emote)
    end))

    trackConn(slot.Button.MouseLeave:Connect(function()
        slot.Button.BackgroundColor3 = COLORS.SlotIdle
        slot.Stroke.Transparency = 1
        if HoveredSlotIdx == i then
            HoveredSlotIdx = nil
            updateCenterDisplay(nil)
        end
    end))

    trackConn(slot.Button.MouseButton1Click:Connect(function()
        local item = slot.Emote
        if not item then return end

        updateCenterDisplay(item)

        if State.StarMode then
            if State.ViewMode == "Favorites" then
                if State.FavoriteSet[item.id] then
                    State.FavoriteSet[item.id] = nil
                    for idx, fav in ipairs(State.Favorites) do
                        if fav.id == item.id then
                            table.remove(State.Favorites, idx)
                            break
                        end
                    end
                    saveFavorites()
                    showToast('Emote "' .. item.name .. '" dihapus dari Favorit.', COLORS.Danger)
                    rebuildFilteredList(false)
                end
            else
                if State.FavoriteSet[item.id] then
                    showToast('Emote "' .. item.name .. '" sudah ada di Favorit!', COLORS.Gold)
                else
                    State.FavoriteSet[item.id] = true
                    table.insert(State.Favorites, { id = item.id, name = item.name })
                    saveFavorites()
                    slot.FavBadge.Visible = true
                    updateFavViewButton()
                    showToast('Emote "' .. item.name .. '" berhasil difavoritkan! ★', COLORS.Success)
                end
            end
        else
            applySpeedFromBox()
            playEmote(item)
            setWheelOpen(false)
        end
    end))
end

-- ============================================================
-- 15. AUTOMATIC ROBLOX MARKETPLACE EMOTE FETCHER
-- ============================================================
local function fetchMarketplaceEmotesAsync()
    if State.IsFetchingCatalog then return end
    State.IsFetchingCatalog = true

    task.spawn(function()
        local baseHosts = {
            "https://catalog.roblox.com/v1/search/items/details?Category=12&Subcategory=39&Limit=30",
            "https://catalog.roproxy.com/v1/search/items/details?Category=12&Subcategory=39&Limit=30",
        }
        local sortTypes = { 0, 2, 1, 3 } -- Relevance, BestSelling, MostFavorited, RecentlyUpdated
        local maxPagesPerSort = 34

        local workingHost = nil
        local fetchedFromApi = false

        StatusLabel.Text = "Memuat katalog emote Marketplace..."

        for _, host in ipairs(baseHosts) do
            local data = httpGetCatalogJson(host .. "&SortType=0")
            if data and type(data.data) == "table" and #data.data > 0 then
                workingHost = host
                break
            end
        end

        if workingHost then
            for _, sortType in ipairs(sortTypes) do
                if State.IsDestroyed then break end
                local cursor = ""
                local page = 0
                local baseUrl = workingHost .. "&SortType=" .. tostring(sortType)

                while page < maxPagesPerSort and not State.IsDestroyed do
                    local url = baseUrl
                    if cursor ~= "" then
                        url = baseUrl .. "&Cursor=" .. HttpService:UrlEncode(cursor)
                    end

                    local data, status = httpGetCatalogJson(url)
                    if not data and status == 429 then
                        task.wait(1.5)
                        data = httpGetCatalogJson(url)
                    end

                    if not data or type(data.data) ~= "table" or #data.data == 0 then
                        break
                    end

                    fetchedFromApi = true
                    for _, item in ipairs(data.data) do
                        addEmoteToAll(item.id, item.name)
                    end

                    page = page + 1
                    cursor = data.nextPageCursor or ""

                    if page == 1 or page % 3 == 0 then
                        if not State.IsDestroyed then
                            StatusLabel.Text = "Memuat emote Marketplace: " .. tostring(#State.AllEmotes) .. "..."
                            saveEmotesCache()
                            if State.IsOpen and State.ViewMode == "All" and State.SearchQuery == "" then
                                rebuildFilteredList(false)
                            end
                        end
                    end

                    if cursor == "" then break end
                    task.wait(0.22)
                end
            end
        else
            local aesSorts = {
                Enum.CatalogSortType.Relevance,
                Enum.CatalogSortType.BestSelling,
                Enum.CatalogSortType.MostFavorited,
                Enum.CatalogSortType.RecentlyCreated,
            }
            for _, sortEnum in ipairs(aesSorts) do
                if State.IsDestroyed then break end
                pcall(function()
                    local params = CatalogSearchParams.new()
                    params.AssetTypes = { Enum.AssetType.EmoteAnimation }
                    params.SortType = sortEnum
                    local pages = AvatarEditorService:SearchCatalog(params)
                    local p = 0
                    while pages and p < 30 and not State.IsDestroyed do
                        local current = pages:GetCurrentPage()
                        if type(current) == "table" and #current > 0 then
                            fetchedFromApi = true
                            for _, item in ipairs(current) do
                                addEmoteToAll(item.Id, item.Name)
                            end
                        else
                            break
                        end
                        p = p + 1
                        if p % 3 == 0 and not State.IsDestroyed then
                            StatusLabel.Text = "Memuat emote Marketplace: " .. tostring(#State.AllEmotes) .. "..."
                            saveEmotesCache()
                            if State.IsOpen and State.ViewMode == "All" and State.SearchQuery == "" then
                                rebuildFilteredList(false)
                            end
                        end
                        if pages.IsFinished then break end
                        local advOk = pcall(function()
                            pages:AdvanceToNextPageAsync()
                        end)
                        if not advOk then break end
                        task.wait(0.2)
                    end
                end)
            end
        end

        if fetchedFromApi then
            saveEmotesCache()
        elseif #State.AllEmotes == 0 then
            for _, item in ipairs(FALLBACK_EMOTES) do
                addEmoteToAll(item.id, item.name)
            end
        end

        State.IsFetchingCatalog = false
        if not State.IsDestroyed then
            StatusLabel.Text = tostring(#State.AllEmotes) .. " Emote tersedia"
            rebuildFilteredList(false)
        end
    end)
end

-- ============================================================
-- 16. INITIALIZATION & CLEANUP HOOK
-- ============================================================
loadFavorites()
local hasCache, isFresh = loadEmotesCache()

if hasCache then
    StatusLabel.Text = tostring(#State.AllEmotes) .. " Emote dimuat dari cache"
    rebuildFilteredList(true)
    if not isFresh then
        fetchMarketplaceEmotesAsync()
    end
else
    for _, item in ipairs(FALLBACK_EMOTES) do
        addEmoteToAll(item.id, item.name)
    end
    rebuildFilteredList(true)
    fetchMarketplaceEmotesAsync()
end

showToast("KurooEmote v" .. VERSION .. " aktif! Tekan ( . ) atau ikon ☺ di atas.", COLORS.Accent)

env.KurooEmoteCleanup = function()
    State.IsDestroyed = true
    stopCurrentEmote(0)
    clearCharConns()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(State.Connections)
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end
