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

-- ========== HELPER: LIVE PLAYER DIRECTORY (AVATAR + LIVE SEARCH) ==========
local function attachLivePlayerList(tabWrapper, inputObj, headerTitle)
    local parentContainer = tabWrapper and tabWrapper._raw and tabWrapper._raw.UIElements and tabWrapper._raw.UIElements.ContainerFrame
    if not parentContainer then return end

    local listHolder = Instance.new("Frame")
    listHolder.Name = "KurooPlayerList"
    listHolder.Size = UDim2.new(1, 0, 0, 0)
    listHolder.AutomaticSize = Enum.AutomaticSize.Y
    listHolder.BackgroundTransparency = 1
    listHolder.LayoutOrder = 999
    listHolder.Parent = parentContainer

    local holderLayout = Instance.new("UIListLayout")
    holderLayout.Padding = UDim.new(0, 6)
    holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
    holderLayout.Parent = listHolder

    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "PlayerCountHeader"
    countLabel.Size = UDim2.new(1, 0, 0, 22)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = (headerTitle or "Daftar Player") .. " (0)"
    countLabel.TextColor3 = Color3.fromHex("#E60012")
    countLabel.TextSize = 13
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.LayoutOrder = 0
    countLabel.Parent = listHolder

    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "EmptyNotice"
    emptyLabel.Size = UDim2.new(1, 0, 0, 32)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "Tidak ada player yang cocok."
    emptyLabel.TextColor3 = Color3.fromHex("#A8A8B3")
    emptyLabel.TextSize = 13
    emptyLabel.Font = Enum.Font.GothamMedium
    emptyLabel.Visible = false
    emptyLabel.LayoutOrder = 1
    emptyLabel.Parent = listHolder

    local selectedName = ""
    local currentQuery = ""
    local cardRefs = {}
    local isSelectingFromCard = false

    local function updateSelectedHighlight()
        for plrName, info in pairs(cardRefs) do
            local isSel = (plrName == selectedName)
            if info.Stroke then
                info.Stroke.Thickness = isSel and 2 or 1
                info.Stroke.Transparency = isSel and 0 or 0.6
            end
            if info.Badge then
                info.Badge.BackgroundColor3 = isSel and Color3.fromHex("#E60012") or Color3.fromHex("#22222A")
                info.Badge.Text = isSel and "Dipilih" or "Pilih"
            end
        end
    end

    local function rebuildPlayerCards(filterText)
        currentQuery = string.lower(tostring(filterText or "")):gsub("^%s+", ""):gsub("%s+$", "")

        for _, child in ipairs(listHolder:GetChildren()) do
            if child:IsA("TextButton") and child.Name:sub(1, 8) == "PlrCard_" then
                child:Destroy()
            end
        end
        table.clear(cardRefs)

        local matches = {}
        local seenIds = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not seenIds[plr.UserId] then
                seenIds[plr.UserId] = true
                local uLow = string.lower(plr.Name)
                local dLow = string.lower(plr.DisplayName or "")
                if currentQuery == "" then
                    table.insert(matches, { plr = plr, rank = 1 })
                elseif uLow:sub(1, #currentQuery) == currentQuery or dLow:sub(1, #currentQuery) == currentQuery then
                    table.insert(matches, { plr = plr, rank = 0 }) -- Prefix match paling atas
                elseif uLow:find(currentQuery, 1, true) or dLow:find(currentQuery, 1, true) then
                    table.insert(matches, { plr = plr, rank = 1 }) -- Substring match
                end
            end
        end

        table.sort(matches, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            return string.lower(a.plr.Name) < string.lower(b.plr.Name)
        end)

        countLabel.Text = (headerTitle or "Daftar Player") .. " (" .. tostring(#matches) .. ")"
        emptyLabel.Visible = (#matches == 0)

        for idx, entry in ipairs(matches) do
            local plr = entry.plr
            local card = Instance.new("TextButton")
            card.Name = "PlrCard_" .. plr.Name
            card.Size = UDim2.new(1, 0, 0, 52)
            card.BackgroundColor3 = Color3.fromHex("#16161B")
            card.BackgroundTransparency = 0.08
            card.Text = ""
            card.AutoButtonColor = false
            card.LayoutOrder = idx + 1
            card.Parent = listHolder

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = card

            local stroke = Instance.new("UIStroke")
            stroke.Thickness = 1
            stroke.Transparency = 0.6
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Color = Color3.fromHex("#E60012")
            stroke.Parent = card

            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(0, 38, 0, 38)
            avatar.Position = UDim2.new(0, 8, 0.5, 0)
            avatar.AnchorPoint = Vector2.new(0, 0.5)
            avatar.BackgroundColor3 = Color3.fromHex("#0D0D11")
            avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(plr.UserId) .. "&w=100&h=100"
            avatar.Parent = card

            local avCorner = Instance.new("UICorner")
            avCorner.CornerRadius = UDim.new(1, 0)
            avCorner.Parent = avatar

            local avStroke = Instance.new("UIStroke")
            avStroke.Thickness = 1.5
            avStroke.Color = Color3.fromHex("#E60012")
            avStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            avStroke.Parent = avatar

            local dispLbl = Instance.new("TextLabel")
            dispLbl.Size = UDim2.new(1, -126, 0, 18)
            dispLbl.Position = UDim2.new(0, 54, 0, 8)
            dispLbl.BackgroundTransparency = 1
            dispLbl.Text = plr.DisplayName
            dispLbl.TextColor3 = Color3.fromHex("#FFFFFF")
            dispLbl.TextSize = 14
            dispLbl.Font = Enum.Font.GothamSemibold
            dispLbl.TextXAlignment = Enum.TextXAlignment.Left
            dispLbl.TextTruncate = Enum.TextTruncate.AtEnd
            dispLbl.Parent = card

            local userLbl = Instance.new("TextLabel")
            userLbl.Size = UDim2.new(1, -126, 0, 16)
            userLbl.Position = UDim2.new(0, 54, 0, 27)
            userLbl.BackgroundTransparency = 1
            userLbl.Text = "@" .. plr.Name
            userLbl.TextColor3 = Color3.fromHex("#A8A8B3")
            userLbl.TextSize = 12
            userLbl.Font = Enum.Font.GothamMedium
            userLbl.TextXAlignment = Enum.TextXAlignment.Left
            userLbl.TextTruncate = Enum.TextTruncate.AtEnd
            userLbl.Parent = card

            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 62, 0, 24)
            badge.Position = UDim2.new(1, -10, 0.5, 0)
            badge.AnchorPoint = Vector2.new(1, 0.5)
            badge.BackgroundColor3 = Color3.fromHex("#22222A")
            badge.Text = "Pilih"
            badge.TextColor3 = Color3.fromHex("#FFFFFF")
            badge.TextSize = 12
            badge.Font = Enum.Font.GothamBold
            badge.Parent = card

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 6)
            bCorner.Parent = badge

            cardRefs[plr.Name] = { Card = card, Stroke = stroke, Badge = badge }

            card.MouseEnter:Connect(function()
                card.BackgroundColor3 = Color3.fromHex("#202028")
            end)
            card.MouseLeave:Connect(function()
                card.BackgroundColor3 = Color3.fromHex("#16161B")
            end)
            card.MouseButton1Click:Connect(function()
                selectedName = plr.Name
                isSelectingFromCard = true
                inputObj:Set(plr.Name, true)
                isSelectingFromCard = false
                updateSelectedHighlight()
            end)
        end

        updateSelectedHighlight()
    end

    -- Hook live search ke TextBox input
    task.defer(function()
        local tb = inputObj.GetTextBox and inputObj:GetTextBox()
        if tb then
            window:AddConnection(tb:GetPropertyChangedSignal("Text"):Connect(function()
                if isSelectingFromCard then return end
                rebuildPlayerCards(tb.Text)
            end))
        end
    end)

    -- Auto-update saat ada player join / leave
    window:AddConnection(Players.PlayerAdded:Connect(function()
        task.defer(function() rebuildPlayerCards(currentQuery) end)
    end))
    window:AddConnection(Players.PlayerRemoving:Connect(function()
        task.defer(function() rebuildPlayerCards(currentQuery) end)
    end))

    rebuildPlayerCards("")
    return rebuildPlayerCards
end

-- ========== Tab 2: Spectate ==========
local spectateTab = window:AddTab({ Name = "Spectate" })
local spectateSection = spectateTab:AddSection({ Name = "Spectate Player" })

local spectateInput = spectateSection:AddInput({
    Name        = "Cari / Target Username",
    Placeholder = "Ketik nama player (misal: pi)...",
    Callback    = function(text)
        -- Enter di input hanya memilih / tidak langsung error kalau kosong
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

attachLivePlayerList(spectateTab, spectateInput, "Daftar Player (Klik untuk Pilih)")

-- ========== Tab 3: Sync ==========
local syncTab = window:AddTab({ Name = "Sync" })
local syncSection = syncTab:AddSection({ Name = "Sync Emote Player" })

local syncInput = syncSection:AddInput({
    Name        = "Cari / Target Username",
    Placeholder = "Ketik nama player (misal: pi)...",
    Callback    = function(text)
        -- Enter di input tidak memaksa sync sebelum klik tombol
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

attachLivePlayerList(syncTab, syncInput, "Daftar Player (Klik untuk Pilih)")

    window:OnUnload(function()
        pcall(function() if stopSyncEmote then stopSyncEmote() end end)
        pcall(function() if spectatePlayer then spectatePlayer("") end end)
    end)
end