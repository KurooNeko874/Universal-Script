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
-- ========== COMBAT: WALKSPEED SYSTEM (JALAN / NORMAL / LARI + HOLD) ==========
local wsEnabled = false
local wsHoldMode = true -- true = tahan Ctrl/Shift, false = tekan sekali (toggle)
local wsWalkSpeed = 8    -- Jalan (1 - 10)
local wsNormalSpeed = 30 -- Normal (10 - 35, default 30)
local wsSprintSpeed = 50 -- Lari (35 - 100)
local wsToggleState = "Normal" -- "Normal" | "Walk" | "Sprint" (dipakai saat Hold Mode OFF)
local defaultWalkSpeed = 16

local function getTargetWalkSpeed()
    if wsHoldMode then
        if not UserInputService:GetFocusedTextBox() then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                return wsWalkSpeed
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                return wsSprintSpeed
            end
        end
        return wsNormalSpeed
    else
        if wsToggleState == "Walk" then
            return wsWalkSpeed
        elseif wsToggleState == "Sprint" then
            return wsSprintSpeed
        end
        return wsNormalSpeed
    end
end

local function applyCurrentWalkSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if wsEnabled then
        local target = getTargetWalkSpeed()
        if hum.WalkSpeed ~= target then
            hum.WalkSpeed = target
        end
    else
        hum.WalkSpeed = defaultWalkSpeed
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not wsEnabled or wsHoldMode then return end
    if UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        wsToggleState = (wsToggleState == "Walk") and "Normal" or "Walk"
        applyCurrentWalkSpeed()
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        wsToggleState = (wsToggleState == "Sprint") and "Normal" or "Sprint"
        applyCurrentWalkSpeed()
    end
end)

RunService.Heartbeat:Connect(function()
    if wsEnabled then
        applyCurrentWalkSpeed()
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    local hum = newChar:WaitForChild("Humanoid", 10)
    if hum then
        defaultWalkSpeed = hum.WalkSpeed
        task.wait(0.2)
        if wsEnabled then
            applyCurrentWalkSpeed()
        end
    end
end)

-- ========== Tab 2: Combat ==========
local combatTab = window:AddTab({ Name = "Combat" })
local wsSection = combatTab:AddSection({ Name = "WalkSpeed Settings" })

wsSection:AddToggle({
    Name = "Enable WalkSpeed",
    Default = false,
    Callback = function(state)
        if state then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                defaultWalkSpeed = hum.WalkSpeed
            end
        end
        wsEnabled = state
        wsToggleState = "Normal"
        applyCurrentWalkSpeed()
        notify("WalkSpeed", state and "ON" or "OFF (Reset ke Default)", 2)
    end,
})

wsSection:AddToggle({
    Name = "Hold Mode (Tahan Ctrl / Shift)",
    Default = true,
    Callback = function(state)
        wsHoldMode = state
        wsToggleState = "Normal"
        if wsEnabled then
            applyCurrentWalkSpeed()
        end
        notify("WalkSpeed Hold", state and "ON: Tahan Ctrl/Shift" or "OFF: Tekan sekali (Toggle)", 2)
    end,
})

wsSection:AddSlider({
    Name = "Jalan (Ctrl)",
    Min = 1,
    Max = 10,
    Default = wsWalkSpeed,
    Callback = function(val)
        wsWalkSpeed = val
        if wsEnabled then
            applyCurrentWalkSpeed()
        end
    end,
})

wsSection:AddSlider({
    Name = "Normal",
    Min = 10,
    Max = 35,
    Default = wsNormalSpeed,
    Callback = function(val)
        wsNormalSpeed = val
        if wsEnabled then
            applyCurrentWalkSpeed()
        end
    end,
})

wsSection:AddSlider({
    Name = "Lari (Shift)",
    Min = 35,
    Max = 100,
    Default = wsSprintSpeed,
    Callback = function(val)
        wsSprintSpeed = val
        if wsEnabled then
            applyCurrentWalkSpeed()
        end
    end,
})
end
