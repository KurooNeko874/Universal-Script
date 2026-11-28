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
-- ========== Tab 8: Server (Join Friend di Map Ini) ==========
do
local serverTab = window:AddTab({ Name = "Server" })
local serverSection = serverTab:AddSection({ Name = "Friend Server (Map Ini)" })

local refreshFriendServersFn = nil

serverSection:AddButton({
    Name = "Refresh Friend Servers",
    Desc = "Perbarui daftar teman yang sedang bermain di server lain pada map ini",
    Callback = function()
        if refreshFriendServersFn then
            refreshFriendServersFn(true)
        end
    end,
})

serverSection:AddButton({
    Name = "Copy Server JobId Saat Ini",
    Desc = "Salin ID server kamu sekarang ke clipboard",
    Callback = function()
        if type(setclipboard) == "function" then
            setclipboard(tostring(game.JobId))
            notify("Server", "JobId server berhasil disalin!", 2)
        else
            notify("Server", "JobId: " .. tostring(game.JobId), 3)
        end
    end,
})

do
    local parentContainer = serverTab._raw and serverTab._raw.UIElements and serverTab._raw.UIElements.ContainerFrame
    if parentContainer then
        local srvHolder = Instance.new("Frame")
        srvHolder.Name = "KurooFriendServerList"
        srvHolder.Size = UDim2.new(1, 0, 0, 0)
        srvHolder.AutomaticSize = Enum.AutomaticSize.Y
        srvHolder.BackgroundTransparency = 1
        srvHolder.LayoutOrder = 999
        srvHolder.Parent = parentContainer

        local srvLayout = Instance.new("UIListLayout")
        srvLayout.Padding = UDim.new(0, 6)
        srvLayout.SortOrder = Enum.SortOrder.LayoutOrder
        srvLayout.Parent = srvHolder

        local headerLbl = Instance.new("TextLabel")
        headerLbl.Size = UDim2.new(1, 0, 0, 22)
        headerLbl.BackgroundTransparency = 1
        headerLbl.Text = "Friend di Map Ini (Memuat...)"
        headerLbl.TextColor3 = Color3.fromHex("#E60012")
        headerLbl.TextSize = 13
        headerLbl.Font = Enum.Font.GothamBold
        headerLbl.TextXAlignment = Enum.TextXAlignment.Left
        headerLbl.LayoutOrder = 0
        headerLbl.Parent = srvHolder

        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0, 36)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = "Belum ada teman online di server lain pada map ini."
        emptyLbl.TextColor3 = Color3.fromHex("#A8A8B3")
        emptyLbl.TextSize = 13
        emptyLbl.Font = Enum.Font.GothamMedium
        emptyLbl.Visible = false
        emptyLbl.LayoutOrder = 1
        emptyLbl.Parent = srvHolder

        local isFetching = false

        refreshFriendServersFn = function(showNotif)
            if isFetching then return end
            isFetching = true
            headerLbl.Text = "Friend di Map Ini (Memuat...)"

            task.spawn(function()
                local ok, onlineFriends = pcall(function()
                    return LocalPlayer:GetFriendsOnline(200)
                end)

                for _, child in ipairs(srvHolder:GetChildren()) do
                    if child:IsA("Frame") and child.Name:sub(1, 8) == "SrvCard_" then
                        child:Destroy()
                    end
                end

                if not ok or type(onlineFriends) ~= "table" then
                    headerLbl.Text = "Friend di Map Ini (Gagal memuat)"
                    emptyLbl.Text = "Gagal mengambil daftar teman online. Coba klik Refresh lagi."
                    emptyLbl.Visible = true
                    isFetching = false
                    return
                end

                local sameMapFriends = {}
                local seenIds = {}
                for _, f in ipairs(onlineFriends) do
                    local uid = f.VisitorId
                    local placeId = tonumber(f.PlaceId)
                    local jobId = f.GameId
                    if f.IsOnline
                        and uid
                        and not seenIds[uid]
                        and placeId == game.PlaceId
                        and type(jobId) == "string"
                        and jobId ~= ""
                        and jobId ~= game.JobId
                    then
                        seenIds[uid] = true
                        table.insert(sameMapFriends, f)
                    end
                end

                table.sort(sameMapFriends, function(a, b)
                    return string.lower(a.DisplayName or a.UserName or "") < string.lower(b.DisplayName or b.UserName or "")
                end)

                headerLbl.Text = "Friend di Map Ini (" .. tostring(#sameMapFriends) .. ")"
                emptyLbl.Text = "Belum ada teman online di server lain pada map ini."
                emptyLbl.Visible = (#sameMapFriends == 0)

                for idx, f in ipairs(sameMapFriends) do
                    local uid = f.VisitorId
                    local uname = tostring(f.UserName or "Unknown")
                    local dname = tostring(f.DisplayName or uname)
                    local targetJobId = tostring(f.GameId)
                    local shortJob = string.sub(targetJobId, 1, 8)

                    local card = Instance.new("Frame")
                    card.Name = "SrvCard_" .. tostring(uid)
                    card.Size = UDim2.new(1, 0, 0, 56)
                    card.BackgroundColor3 = Color3.fromHex("#16161B")
                    card.BackgroundTransparency = 0.08
                    card.LayoutOrder = idx + 1
                    card.Parent = srvHolder

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = card

                    local stroke = Instance.new("UIStroke")
                    stroke.Thickness = 1
                    stroke.Transparency = 0.55
                    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    stroke.Color = Color3.fromHex("#E60012")
                    stroke.Parent = card

                    local avatar = Instance.new("ImageLabel")
                    avatar.Size = UDim2.new(0, 40, 0, 40)
                    avatar.Position = UDim2.new(0, 8, 0.5, 0)
                    avatar.AnchorPoint = Vector2.new(0, 0.5)
                    avatar.BackgroundColor3 = Color3.fromHex("#0D0D11")
                    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(uid) .. "&w=100&h=100"
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
                    dispLbl.Size = UDim2.new(1, -134, 0, 18)
                    dispLbl.Position = UDim2.new(0, 56, 0, 8)
                    dispLbl.BackgroundTransparency = 1
                    dispLbl.Text = dname
                    dispLbl.TextColor3 = Color3.fromHex("#FFFFFF")
                    dispLbl.TextSize = 14
                    dispLbl.Font = Enum.Font.GothamSemibold
                    dispLbl.TextXAlignment = Enum.TextXAlignment.Left
                    dispLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    dispLbl.Parent = card

                    local subLbl = Instance.new("TextLabel")
                    subLbl.Size = UDim2.new(1, -134, 0, 16)
                    subLbl.Position = UDim2.new(0, 56, 0, 29)
                    subLbl.BackgroundTransparency = 1
                    subLbl.Text = "@" .. uname .. "  |  #" .. shortJob
                    subLbl.TextColor3 = Color3.fromHex("#A8A8B3")
                    subLbl.TextSize = 12
                    subLbl.Font = Enum.Font.GothamMedium
                    subLbl.TextXAlignment = Enum.TextXAlignment.Left
                    subLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    subLbl.Parent = card

                    local joinBtn = Instance.new("TextButton")
                    joinBtn.Size = UDim2.new(0, 68, 0, 30)
                    joinBtn.Position = UDim2.new(1, -10, 0.5, 0)
                    joinBtn.AnchorPoint = Vector2.new(1, 0.5)
                    joinBtn.BackgroundColor3 = Color3.fromHex("#E60012")
                    joinBtn.Text = "Join"
                    joinBtn.TextColor3 = Color3.fromHex("#FFFFFF")
                    joinBtn.TextSize = 13
                    joinBtn.Font = Enum.Font.GothamBold
                    joinBtn.AutoButtonColor = false
                    joinBtn.Parent = card

                    local jCorner = Instance.new("UICorner")
                    jCorner.CornerRadius = UDim.new(0, 6)
                    jCorner.Parent = joinBtn

                    joinBtn.MouseEnter:Connect(function()
                        joinBtn.BackgroundColor3 = Color3.fromHex("#FF1E2D")
                    end)
                    joinBtn.MouseLeave:Connect(function()
                        joinBtn.BackgroundColor3 = Color3.fromHex("#E60012")
                    end)
                    joinBtn.MouseButton1Click:Connect(function()
                        joinBtn.Text = "..."
                        notify("Server", "Pindah ke server " .. dname .. "...", 3)
                        local tpOk, tpErr = pcall(function()
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, LocalPlayer)
                        end)
                        if not tpOk then
                            joinBtn.Text = "Join"
                            notify("Server Error", "Gagal join server: " .. tostring(tpErr), 3)
                        end
                    end)
                end

                if showNotif then
                    notify("Server", "Ditemukan " .. tostring(#sameMapFriends) .. " teman di server lain.", 2)
                end
                isFetching = false
            end)
        end

        refreshFriendServersFn(false)
    end
end
end
end
