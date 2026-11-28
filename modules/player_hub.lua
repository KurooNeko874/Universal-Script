return function(ctx)
    local Players         = ctx.Players
    local RunService      = ctx.RunService
    local HttpService     = ctx.HttpService
    local LocalPlayer     = ctx.LocalPlayer
    local notify          = ctx.notify
    local loadRemoteData  = ctx.loadRemoteData
    local KUROO_DATA_BASE = ctx.KUROO_DATA_BASE
    local window          = ctx.window

    local CoreGui = game:GetService("CoreGui")

    local DISCORD_INVITE = "https://discord.gg/3b2H9RXbS"
    local ICON_RAW_URL   = "https://raw.githubusercontent.com/KurooNeko874/Universal-Script/main/assets/kuroo-icon.png"

    -- Helper HTTP Request lintas executor
    local function getHttpRequest()
        return (typeof(request) == "function" and request)
            or (typeof(http_request) == "function" and http_request)
            or (syn and typeof(syn.request) == "function" and syn.request)
            or (fluxus and typeof(fluxus.request) == "function" and fluxus.request)
            or (http and typeof(http.request) == "function" and http.request)
            or nil
    end

    local function copyText(str)
        local fn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
        if typeof(fn) == "function" then
            pcall(fn, str)
            return true
        end
        return false
    end

    local function formatAccountAge(days)
        days = tonumber(days) or 0
        local years = math.floor(days / 365)
        local rem = days % 365
        local months = math.floor(rem / 30)
        if years > 0 then
            return string.format("%d Hari (%d Thn %d Bln)", days, years, months)
        elseif months > 0 then
            return string.format("%d Hari (%d Bln)", days, months)
        end
        return string.format("%d Hari", days)
    end

    -- Download & cache ikon bulat KurooHub dari GitHub sekali saja
    local cachedIconAsset = nil
    local function resolveKurooIcon()
        if cachedIconAsset ~= nil then return cachedIconAsset end
        cachedIconAsset = ""
        if typeof(getcustomasset) == "function" and typeof(writefile) == "function" then
            pcall(function()
                if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
                    if not isfolder("KurooUniversal") then makefolder("KurooUniversal") end
                end
                local path = "KurooUniversal/kuroo_tag_icon.png"
                local needDownload = true
                if typeof(isfile) == "function" and isfile(path) then
                    local okR, existing = pcall(readfile, path)
                    if okR and type(existing) == "string" and #existing > 500 then
                        needDownload = false
                    end
                end
                if needDownload then
                    local raw = game:HttpGet(ICON_RAW_URL)
                    if type(raw) == "string" and #raw > 500 then
                        writefile(path, raw)
                    end
                end
                local asset = getcustomasset(path)
                if type(asset) == "string" and asset ~= "" then
                    cachedIconAsset = asset
                end
            end)
        end
        return cachedIconAsset
    end

    -- ========== OVERHEAD CAPSULE TAG SYSTEM (KLIK = TELEPORT) ==========
    local tagEnabled = true
    local selfTagPreview = true
    local larpingSyncEnabled = true

    local tagFolder = Instance.new("Folder")
    tagFolder.Name = "KurooHubOverheadTags"
    local parentedTag = pcall(function() tagFolder.Parent = CoreGui end)
    if not parentedTag or not tagFolder.Parent then
        pcall(function() tagFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
    end

    local activeTags = {}       -- [Player] = { Gui = BillboardGui, CharConn = RBXScriptConnection }
    local kurooPeers = {}       -- [UserId] = { plr = Player, data = table, lastSeen = number }

    local function removeTag(plr)
        local rec = activeTags[plr]
        if not rec then return end
        if rec.CharConn then pcall(function() rec.CharConn:Disconnect() end) end
        if rec.Gui then pcall(function() rec.Gui:Destroy() end) end
        activeTags[plr] = nil
    end

    local function attachTagToCharacter(plr, char)
        if not plr or not char then return end
        local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 5)
        if not head or not head.Parent then return end

        local rec = activeTags[plr]
        if not rec then return end
        if rec.Gui then pcall(function() rec.Gui:Destroy() end) end

        local iconAsset = resolveKurooIcon()

        local bb = Instance.new("BillboardGui")
        bb.Name = "KurooTag_" .. tostring(plr.UserId)
        bb.Adornee = head
        bb.AlwaysOnTop = true
        bb.Active = true
        bb.ResetOnSpawn = false
        bb.LightInfluence = 0
        bb.MaxDistance = 300
        bb.StudsOffset = Vector3.new(0, 3.1, 0)
        bb.Size = UDim2.fromOffset(220, 34)
        bb.Parent = tagFolder

        local pill = Instance.new("TextButton")
        pill.Name = "Capsule"
        pill.AnchorPoint = Vector2.new(0.5, 0.5)
        pill.Position = UDim2.fromScale(0.5, 0.5)
        pill.AutomaticSize = Enum.AutomaticSize.X
        pill.Size = UDim2.fromOffset(0, 28)
        pill.BackgroundColor3 = Color3.fromRGB(9, 9, 11)
        pill.BackgroundTransparency = 0.12
        pill.AutoButtonColor = false
        pill.Text = ""
        pill.Parent = bb

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = pill

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(230, 0, 18)
        stroke.Thickness = 1.6
        stroke.Parent = pill

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 4)
        pad.PaddingRight = UDim.new(0, 10)
        pad.PaddingTop = UDim.new(0, 3)
        pad.PaddingBottom = UDim.new(0, 3)
        pad.Parent = pill

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.Padding = UDim.new(0, 6)
        layout.Parent = pill

        -- Ikon Bulat di sebelah kiri
        if iconAsset ~= "" then
            local img = Instance.new("ImageLabel")
            img.Name = "Icon"
            img.Size = UDim2.fromOffset(22, 22)
            img.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            img.BackgroundTransparency = 0
            img.Image = iconAsset
            img.ScaleType = Enum.ScaleType.Crop
            img.LayoutOrder = 1
            img.Parent = pill

            local imgCorner = Instance.new("UICorner")
            imgCorner.CornerRadius = UDim.new(1, 0)
            imgCorner.Parent = img
        else
            local badge = Instance.new("TextLabel")
            badge.Name = "IconFallback"
            badge.Size = UDim2.fromOffset(22, 22)
            badge.BackgroundColor3 = Color3.fromRGB(230, 0, 18)
            badge.Text = "K"
            badge.TextColor3 = Color3.fromRGB(255, 255, 255)
            badge.Font = Enum.Font.GothamBlack
            badge.TextSize = 13
            badge.LayoutOrder = 1
            badge.Parent = pill

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(1, 0)
            bCorner.Parent = badge
        end

        -- Nama Player di sebelah kanan ikon
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "PlayerName"
        nameLbl.AutomaticSize = Enum.AutomaticSize.X
        nameLbl.Size = UDim2.fromOffset(0, 22)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = plr.DisplayName
        nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.LayoutOrder = 2
        nameLbl.Parent = pill

        -- Hover effect ringan
        pill.MouseEnter:Connect(function()
            pill.BackgroundColor3 = Color3.fromRGB(28, 12, 16)
        end)
        pill.MouseLeave:Connect(function()
            pill.BackgroundColor3 = Color3.fromRGB(9, 9, 11)
        end)

        -- Klik kapsul = Teleport otomatis ke player tersebut!
        pill.MouseButton1Click:Connect(function()
            if plr == LocalPlayer then
                notify("KurooHub Tag", "Ini adalah tanda KurooHub milikmu!", 2)
                return
            end
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetChar = plr.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            if myRoot and targetRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3.5)
                notify("KurooHub Teleport", "Teleport ke " .. plr.DisplayName .. "!", 2)
            else
                notify("KurooHub Teleport", "Karakter target belum siap.", 2)
            end
        end)

        rec.Gui = bb
    end

    local function ensureTag(plr)
        if not plr or not tagEnabled then return end
        if plr == LocalPlayer and not selfTagPreview then return end
        if activeTags[plr] then
            if activeTags[plr].Gui and activeTags[plr].Gui.Parent then
                return
            end
        else
            local rec = { Gui = nil, CharConn = nil }
            activeTags[plr] = rec
            rec.CharConn = plr.CharacterAdded:Connect(function(newChar)
                task.wait(0.4)
                if activeTags[plr] and tagEnabled then
                    attachTagToCharacter(plr, newChar)
                end
            end)
        end
        if plr.Character then
            task.spawn(attachTagToCharacter, plr, plr.Character)
        end
    end

    local function refreshAllTags()
        if not tagEnabled then
            local toRemove = {}
            for p in pairs(activeTags) do table.insert(toRemove, p) end
            for _, p in ipairs(toRemove) do removeTag(p) end
            return
        end

        if selfTagPreview then
            ensureTag(LocalPlayer)
        else
            removeTag(LocalPlayer)
        end

        for uid, peer in pairs(kurooPeers) do
            if peer.plr and peer.plr.Parent then
                ensureTag(peer.plr)
            end
        end
    end

    -- ========== CROSS-PLAYER SYNC ENGINE (FIREBASE REALTIME DB REST) ==========
    local syncConfig = loadRemoteData(KUROO_DATA_BASE .. "/sync_config.lua", { FirebaseUrl = "" })
    local firebaseUrl = ""
    if type(syncConfig) == "table" and type(syncConfig.FirebaseUrl) == "string" then
        firebaseUrl = syncConfig.FirebaseUrl:gsub("/+$", "")
    end

    local httpReq = getHttpRequest()
    local syncRunning = true
    local lastPushHash = ""
    local peerCount = 0
    local statusParagraph = nil

    local function safeRoomPath()
        local job = tostring(game.JobId or "")
        if job == "" then job = "studio_local" end
        job = job:gsub("[^%w%-_]", "_")
        return string.format("%s/kuroohub_rooms/%s/%s", firebaseUrl, tostring(game.PlaceId), job)
    end

    local function updateSyncStatusLabel()
        if not statusParagraph then return end
        local ageText = formatAccountAge(LocalPlayer.AccountAge)
        local syncLine
        if firebaseUrl == "" then
            syncLine = "Menunggu URL Firebase (isi di data/sync_config.lua)"
        elseif not httpReq then
            syncLine = "Executor tidak mendukung HTTP Request"
        else
            syncLine = string.format("Terhubung • %d Sesama User KurooHub di Server Ini", peerCount)
        end
        local desc = string.format(
            "Nama: %s (@%s)\nUser ID: %d\nUmur Akun: %s\nKurooHub Sync: %s",
            LocalPlayer.DisplayName,
            LocalPlayer.Name,
            LocalPlayer.UserId,
            ageText,
            syncLine
        )
        pcall(function()
            if statusParagraph.SetDesc then
                statusParagraph:SetDesc(desc)
            end
        end)
    end

    local function buildLocalPayload()
        local larpState = { bp = { h = false, kr = false, kl = false }, items = {} }
        if larpingSyncEnabled and ctx.LarpingAPI and typeof(ctx.LarpingAPI.GetLocalState) == "function" then
            local ok, st = pcall(ctx.LarpingAPI.GetLocalState)
            if ok and type(st) == "table" then
                larpState = st
            end
        end
        return {
            u = LocalPlayer.UserId,
            n = LocalPlayer.DisplayName,
            v = "1.2.2",
            t = os.time(),
            bp = larpState.bp,
            items = larpState.items,
        }
    end

    local function pushLocalState(force)
        if not syncRunning or firebaseUrl == "" or not httpReq then return end
        local payload = buildLocalPayload()
        local okEnc, body = pcall(function() return HttpService:JSONEncode(payload) end)
        if not okEnc or type(body) ~= "string" then return end

        local url = safeRoomPath() .. "/" .. tostring(LocalPlayer.UserId) .. ".json"
        pcall(function()
            httpReq({
                Url = url,
                Method = "PUT",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end)
        lastPushHash = body
    end

    local function deleteLocalState()
        if firebaseUrl == "" or not httpReq then return end
        local url = safeRoomPath() .. "/" .. tostring(LocalPlayer.UserId) .. ".json"
        pcall(function()
            httpReq({
                Url = url,
                Method = "DELETE",
            })
        end)
    end

    local function pollRoomState()
        if not syncRunning or firebaseUrl == "" or not httpReq then return end
        local url = safeRoomPath() .. ".json"
        local okReq, res = pcall(function()
            return httpReq({ Url = url, Method = "GET" })
        end)
        if not okReq or type(res) ~= "table" or type(res.Body) ~= "string" then return end
        if res.Body == "null" or res.Body == "" then return end

        local okDec, roomData = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if not okDec or type(roomData) ~= "table" then return end

        local now = os.time()
        local seenUids = {}
        local count = 0

        for uidStr, entry in pairs(roomData) do
            if type(entry) == "table" then
                local uid = tonumber(entry.u) or tonumber(uidStr)
                local ts = tonumber(entry.t) or 0
                if uid and uid ~= LocalPlayer.UserId and (now - ts) <= 25 then
                    local plr = Players:GetPlayerByUserId(uid)
                    if plr and plr.Parent then
                        seenUids[uid] = true
                        count = count + 1
                        kurooPeers[uid] = { plr = plr, data = entry, lastSeen = now }

                        if tagEnabled then
                            ensureTag(plr)
                        end

                        if larpingSyncEnabled and ctx.LarpingAPI and typeof(ctx.LarpingAPI.ApplyRemoteState) == "function" then
                            pcall(ctx.LarpingAPI.ApplyRemoteState, plr, entry)
                        end
                    end
                end
            end
        end

        -- Bersihkan peer yang sudah keluar / offline
        for uid, peer in pairs(kurooPeers) do
            if not seenUids[uid] then
                if peer.plr then
                    removeTag(peer.plr)
                    if ctx.LarpingAPI and typeof(ctx.LarpingAPI.ClearRemotePlayer) == "function" then
                        pcall(ctx.LarpingAPI.ClearRemotePlayer, peer.plr)
                    end
                end
                kurooPeers[uid] = nil
            end
        end

        if count ~= peerCount then
            peerCount = count
            updateSyncStatusLabel()
        end
    end

    ctx.KurooSync = {
        PushNow = function()
            task.spawn(pushLocalState, true)
        end,
        IsConfigured = function()
            return firebaseUrl ~= "" and httpReq ~= nil
        end,
    }

    -- Bersihkan saat player keluar dari server
    local removingConn = Players.PlayerRemoving:Connect(function(plr)
        removeTag(plr)
        local uid = plr.UserId
        if kurooPeers[uid] then
            if ctx.LarpingAPI and typeof(ctx.LarpingAPI.ClearRemotePlayer) == "function" then
                pcall(ctx.LarpingAPI.ClearRemotePlayer, plr)
            end
            kurooPeers[uid] = nil
            peerCount = math.max(0, peerCount - 1)
            updateSyncStatusLabel()
        end
    end)

    -- ========== TAB 1 (PALING ATAS): PLAYER ==========
    local tabPlayer = window:AddTab({ Name = "Player", Icon = "user" })
    ctx.playerTab = tabPlayer

    local sectionProfile = tabPlayer:AddSection({ Name = "Player Profile" })
    statusParagraph = sectionProfile:AddParagraph({
        Title = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")",
        Desc = string.format(
            "Nama: %s (@%s)\nUser ID: %d\nUmur Akun: %s\nKurooHub Sync: Memuat...",
            LocalPlayer.DisplayName,
            LocalPlayer.Name,
            LocalPlayer.UserId,
            formatAccountAge(LocalPlayer.AccountAge)
        ),
    })

    local sectionDiscord = tabPlayer:AddSection({ Name = "Discord KurooHub" })
    sectionDiscord:AddParagraph({
        Title = "Komunitas Resmi KurooHub",
        Desc = "Punya ide fitur baru, mau request animasi/shader/item larping, atau nemu bug? Yuk gabung ke server Discord KurooHub! Dapatkan info update tercepat, diskusi bareng user lain, dan dukung pengembangan script ini.\n\nLink Invite: " .. DISCORD_INVITE,
    })
    sectionDiscord:AddButton({
        Name = "Join / Copy Link Discord KurooHub",
        Desc = "Salin link invite " .. DISCORD_INVITE .. " ke clipboard",
        Callback = function()
            if copyText(DISCORD_INVITE) then
                notify("Discord KurooHub", "Link Discord berhasil disalin! Paste di browser/Discord.", 3)
            else
                notify("Discord KurooHub", "Link: " .. DISCORD_INVITE, 4)
            end
        end,
    })

    local sectionSync = tabPlayer:AddSection({ Name = "KurooHub Tag & Sync" })
    sectionSync:AddToggle({
        Name = "Tampilkan Tag Kepala KurooHub",
        Desc = "Tampilkan kapsul ikon bulat + nama di atas kepala sesama user KurooHub (klik = Teleport)",
        Default = true,
        Callback = function(state)
            tagEnabled = state
            refreshAllTags()
            notify("KurooHub Tag", state and "Tag kepala KurooHub diaktifkan." or "Tag kepala KurooHub disembunyikan.", 2)
        end,
    })

    sectionSync:AddToggle({
        Name = "Preview Tag di Kepala Sendiri",
        Desc = "Tampilkan kapsul KurooHub di atas kepalamu sendiri",
        Default = true,
        Callback = function(state)
            selfTagPreview = state
            refreshAllTags()
        end,
    })

    sectionSync:AddToggle({
        Name = "Auto-Sync Larping Antar User",
        Desc = "Item Larping, Headless & Korblox otomatis terlihat oleh sesama user KurooHub di map yang sama",
        Default = true,
        Callback = function(state)
            larpingSyncEnabled = state
            if not state then
                for _, peer in pairs(kurooPeers) do
                    if peer.plr and ctx.LarpingAPI and typeof(ctx.LarpingAPI.ClearRemotePlayer) == "function" then
                        pcall(ctx.LarpingAPI.ClearRemotePlayer, peer.plr)
                    end
                end
            end
            task.spawn(pushLocalState, true)
            notify("KurooHub Sync", state and "Larping Sync aktif." or "Larping Sync dimatikan.", 2)
        end,
    })

    -- Inisialisasi awal
    updateSyncStatusLabel()
    task.defer(function()
        resolveKurooIcon()
        refreshAllTags()
    end)

    -- Background Sync Loop (Heartbeat & Poll setiap 4 detik)
    if firebaseUrl ~= "" and httpReq then
        task.spawn(function()
            task.wait(1.5)
            while syncRunning do
                pcall(pushLocalState, false)
                pcall(pollRoomState)
                task.wait(4)
            end
        end)
    end

    window:OnUnload(function()
        syncRunning = false
        if removingConn then pcall(function() removingConn:Disconnect() end) end
        local toRemove = {}
        for p in pairs(activeTags) do table.insert(toRemove, p) end
        for _, p in ipairs(toRemove) do removeTag(p) end
        for _, peer in pairs(kurooPeers) do
            if peer.plr and ctx.LarpingAPI and typeof(ctx.LarpingAPI.ClearRemotePlayer) == "function" then
                pcall(ctx.LarpingAPI.ClearRemotePlayer, peer.plr)
            end
        end
        table.clear(kurooPeers)
        if tagFolder then pcall(function() tagFolder:Destroy() end) end
        task.spawn(deleteLocalState)
    end)
end
