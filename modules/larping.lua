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
-- ========== BODY PART VISUAL SYSTEM (HEADLESS & KORBLOX) ==========
local headlessEnabled = false
local BodyPartState = {
    HeadlessHorseman = false,
    KorbloxRight     = false,
    KorbloxLeft      = false,
}

local KORBLOX_RIGHT_ID       = 139607718
local KORBLOX_LEFT_ID        = 139607673
local KORBLOX_R6_RIGHT_MESH  = "rbxassetid://101851696"
local KORBLOX_R6_LEFT_MESH   = "rbxassetid://101851582"
local KORBLOX_R6_TEXTURE     = "rbxassetid://101851254"

local function clearTaggedVisuals(char, tagName)
    if not char then return end
    for _, child in ipairs(char:GetChildren()) do
        if child.Name == tagName then
            pcall(function() child:Destroy() end)
        end
    end
end

local function setPartHidden(part, hidden)
    if not part or not part:IsA("BasePart") then return end
    if hidden then
        if part:GetAttribute("KurooOrigTrans") == nil then
            part:SetAttribute("KurooOrigTrans", part.Transparency)
        end
        part.Transparency = 1
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("Decal") then
                if child:GetAttribute("KurooOrigTrans") == nil then
                    child:SetAttribute("KurooOrigTrans", child.Transparency)
                end
                child.Transparency = 1
            end
        end
    else
        local orig = part:GetAttribute("KurooOrigTrans")
        part.Transparency = (orig ~= nil) and orig or 0
        part:SetAttribute("KurooOrigTrans", nil)
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("Decal") then
                local origD = child:GetAttribute("KurooOrigTrans")
                child.Transparency = (origD ~= nil) and origD or 0
                child:SetAttribute("KurooOrigTrans", nil)
            end
        end
    end
end

local function weldVisualPart(targetPart, visualPart, parentContainer, offsetCFrame)
    visualPart.CanCollide = false
    visualPart.CanTouch = false
    visualPart.CanQuery = false
    visualPart.Massless = true
    visualPart.Anchored = false
    visualPart.CFrame = targetPart.CFrame * (offsetCFrame or CFrame.new())
    visualPart.Parent = parentContainer

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = targetPart
    weld.Part1 = visualPart
    weld.Parent = visualPart
end

local function applyHeadlessToChar(char, state)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        setPartHidden(head, state)
    end
end

local function applyKorbloxLegToChar(char, side, state)
    if not char then return end
    local tagName = (side == "Right") and "KurooKorbloxRight" or "KurooKorbloxLeft"
    clearTaggedVisuals(char, tagName)

    local hum = char:FindFirstChildOfClass("Humanoid")
    local isR15 = hum and (hum.RigType == Enum.HumanoidRigType.R15)
    local r15Parts = (side == "Right")
        and { "RightUpperLeg", "RightLowerLeg", "RightFoot" }
        or  { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" }
    local r6PartName = (side == "Right") and "Right Leg" or "Left Leg"

    if not state then
        for _, pName in ipairs(r15Parts) do
            setPartHidden(char:FindFirstChild(pName), false)
        end
        setPartHidden(char:FindFirstChild(r6PartName), false)
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = tagName
    folder.Parent = char

    local assetId = (side == "Right") and KORBLOX_RIGHT_ID or KORBLOX_LEFT_ID
    local ok, objs = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)

    if isR15 then
        -- Sembunyikan semua bagian kaki asli R15
        for _, pName in ipairs(r15Parts) do
            setPartHidden(char:FindFirstChild(pName), true)
        end

        local r15Container = nil
        if ok and type(objs) == "table" then
            for _, root in ipairs(objs) do
                r15Container = root:FindFirstChild("R15ArtistIntent")
                    or root:FindFirstChild("R15Fixed")
                    or root:FindFirstChild("R15")
                    or root
                if r15Container then break end
            end
        end

        local attachedAny = false
        if r15Container then
            for _, pName in ipairs(r15Parts) do
                local origPart = char:FindFirstChild(pName)
                local srcPart = r15Container:FindFirstChild(pName, true)
                if origPart and srcPart and srcPart:IsA("BasePart") then
                    local clonePart = srcPart:Clone()
                    clonePart.Name = "Korblox_" .. pName
                    for _, child in ipairs(clonePart:GetChildren()) do
                        if child:IsA("Motor6D") or child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Script") or child:IsA("LocalScript") then
                            child:Destroy()
                        end
                    end
                    weldVisualPart(origPart, clonePart, folder)
                    attachedAny = true
                end
            end
        end

        if ok and type(objs) == "table" then
            for _, root in ipairs(objs) do
                pcall(function() root:Destroy() end)
            end
        end

        -- Fallback mesh jika asset R15 gagal dimuat
        if not attachedAny then
            local upperLeg = char:FindFirstChild(r15Parts[1])
            if upperLeg then
                local fakeLeg = Instance.new("Part")
                fakeLeg.Name = "KorbloxFallbackLeg"
                fakeLeg.Size = Vector3.new(1, 2, 1)
                local mesh = Instance.new("SpecialMesh")
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.MeshId = (side == "Right") and KORBLOX_R6_RIGHT_MESH or KORBLOX_R6_LEFT_MESH
                mesh.TextureId = KORBLOX_R6_TEXTURE
                mesh.Parent = fakeLeg
                weldVisualPart(upperLeg, fakeLeg, folder, CFrame.new(0, -0.35, 0))
            end
        end
    else
        -- Mode R6
        local origLeg = char:FindFirstChild(r6PartName)
        if origLeg then
            setPartHidden(origLeg, true)
            local fakeLeg = Instance.new("Part")
            fakeLeg.Name = "KorbloxR6Leg"
            fakeLeg.Size = origLeg.Size
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = (side == "Right") and KORBLOX_R6_RIGHT_MESH or KORBLOX_R6_LEFT_MESH
            mesh.TextureId = KORBLOX_R6_TEXTURE
            mesh.Parent = fakeLeg
            weldVisualPart(origLeg, fakeLeg, folder)
        end
        if ok and type(objs) == "table" then
            for _, root in ipairs(objs) do
                pcall(function() root:Destroy() end)
            end
        end
    end
end

local function notifyKurooSync()
    if ctx.KurooSync and typeof(ctx.KurooSync.PushNow) == "function" then
        ctx.KurooSync.PushNow()
    end
end

local function setHeadless(state)
    BodyPartState.HeadlessHorseman = state
    headlessEnabled = state
    applyHeadlessToChar(LocalPlayer.Character, state)
    notifyKurooSync()
end

local function setKorbloxLeg(side, state)
    if side == "Right" then
        BodyPartState.KorbloxRight = state
    else
        BodyPartState.KorbloxLeft = state
    end
    applyKorbloxLegToChar(LocalPlayer.Character, side, state)
    notifyKurooSync()
end

local function resetAllBodyParts()
    BodyPartState.HeadlessHorseman = false
    BodyPartState.KorbloxRight = false
    BodyPartState.KorbloxLeft = false
    headlessEnabled = false
    local char = LocalPlayer.Character
    applyHeadlessToChar(char, false)
    applyKorbloxLegToChar(char, "Right", false)
    applyKorbloxLegToChar(char, "Left", false)
    notifyKurooSync()
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.6)
    if BodyPartState.HeadlessHorseman then
        applyHeadlessToChar(newChar, true)
    end
    if BodyPartState.KorbloxRight then
        applyKorbloxLegToChar(newChar, "Right", true)
    end
    if BodyPartState.KorbloxLeft then
        applyKorbloxLegToChar(newChar, "Left", true)
    end
end)

-- ========== LARPING VISUAL ITEM SYSTEM ==========
local PresetItems = loadRemoteData(KUROO_DATA_BASE .. "/larping_items.lua", {})

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
    elseif effectType == "InfernusFire" then
        local fire = Instance.new("Fire")
        fire.Name = "KurooInfernusFire"
        fire.Color = Color3.fromRGB(255, 65, 20)
        fire.SecondaryColor = Color3.fromRGB(255, 200, 40)
        fire.Heat = 12
        fire.Size = 6
        fire.Parent = handle
        local sp = Instance.new("Sparkles")
        sp.Name = "KurooInfernusEmbers"
        sp.SparkleColor = Color3.fromRGB(255, 110, 30)
        sp.Parent = handle
    elseif effectType == "FrigidusFrost" then
        local sp = Instance.new("Sparkles")
        sp.Name = "KurooFrigidusSparkles"
        sp.SparkleColor = Color3.fromRGB(165, 235, 255)
        sp.Parent = handle
        local smoke = Instance.new("Smoke")
        smoke.Name = "KurooFrigidusMist"
        smoke.Color = Color3.fromRGB(190, 240, 255)
        smoke.Opacity = 0.25
        smoke.RiseVelocity = 1.5
        smoke.Size = 1.5
        smoke.Parent = handle
    elseif effectType == "VoidSmoke" then
        local smoke = Instance.new("Smoke")
        smoke.Name = "KurooVoidSmoke"
        smoke.Color = Color3.fromRGB(35, 10, 60)
        smoke.Opacity = 0.5
        smoke.RiseVelocity = 2.5
        smoke.Size = 2
        smoke.Parent = handle
        local sp = Instance.new("Sparkles")
        sp.Name = "KurooVoidSparkles"
        sp.SparkleColor = Color3.fromRGB(155, 75, 255)
        sp.Parent = handle
    elseif effectType == "RedSparkles" then
        local sp = Instance.new("Sparkles")
        sp.Name = "KurooRedSparkles"
        sp.SparkleColor = Color3.fromRGB(255, 55, 75)
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
    local ok = AttachVisualItemToCharacter(LocalPlayer.Character, itemData, cfg, ActiveItems)
    if ok then notifyKurooSync() end
    return ok
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
        notifyKurooSync()
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

-- ========== Tab 4: Larping (Visual) ==========
local tabLarping = window:AddTab({ Name = "Larping (Visual)" })

-- Section 1: Body Part (Korblox Deathspeaker Kaki Kanan/Kiri & Headless Horseman)
local sectionLarpBody = tabLarping:AddSection({ Name = "Body Part" })
local isSyncingBodyUI = false
local togHeadlessHorseman, togKorbloxRight, togKorbloxLeft

togKorbloxRight = sectionLarpBody:AddToggle({
    Name    = "Korblox Deathspeaker (Kaki Kanan)",
    Default = false,
    Callback = function(state)
        if isSyncingBodyUI then return end
        setKorbloxLeg("Right", state)
        notify("Body Part", "Korblox Kaki Kanan: " .. (state and "ON" or "OFF"), 2)
    end,
})

togKorbloxLeft = sectionLarpBody:AddToggle({
    Name    = "Korblox Deathspeaker (Kaki Kiri)",
    Default = false,
    Callback = function(state)
        if isSyncingBodyUI then return end
        setKorbloxLeg("Left", state)
        notify("Body Part", "Korblox Kaki Kiri: " .. (state and "ON" or "OFF"), 2)
    end,
})

togHeadlessHorseman = sectionLarpBody:AddToggle({
    Name    = "Headless Horseman",
    Default = false,
    Callback = function(state)
        if isSyncingBodyUI then return end
        setHeadless(state)
        notify("Body Part", "Headless Horseman: " .. (state and "ON" or "OFF"), 2)
    end,
})

sectionLarpBody:AddButton({
    Name     = "Reset Semua Body Part",
    Callback = function()
        isSyncingBodyUI = true
        if togKorbloxRight     then togKorbloxRight:Set(false) end
        if togKorbloxLeft      then togKorbloxLeft:Set(false) end
        if togHeadlessHorseman then togHeadlessHorseman:Set(false) end
        isSyncingBodyUI = false
        resetAllBodyParts()
        notify("Body Part", "Semua Body Part di-reset ke asli.", 2)
    end,
})

-- Section 2: Items (Daftar Item Limited & Item Berefek)
local sectionLarpItems = tabLarping:AddSection({ Name = "Items" })
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

-- ========== KUROOHUB CROSS-PLAYER LARPING SYNC API ==========
do
    local syncedPeers = {} -- [Player] = { Hash = string, Entries = {}, State = table, CharConn = RBXScriptConnection }

    local function findPresetByNameOrId(name, assetId)
        if type(PresetItems) == "table" then
            for _, p in ipairs(PresetItems) do
                if (name and p.Name == name) or (assetId and p.AssetId == assetId) then
                    return p
                end
            end
        end
        return nil
    end

    local function clearPeerVisuals(plr)
        local rec = syncedPeers[plr]
        if not rec then return end
        for _, entry in pairs(rec.Entries) do
            if entry and entry.Model then
                pcall(function() entry.Model:Destroy() end)
            end
        end
        table.clear(rec.Entries)
        if plr.Character then
            pcall(applyHeadlessToChar, plr.Character, false)
            pcall(applyKorbloxLegToChar, plr.Character, "Right", false)
            pcall(applyKorbloxLegToChar, plr.Character, "Left", false)
        end
    end

    local function applyStateToPeerChar(plr, rec)
        local char = plr and plr.Character
        if not char then return end
        local st = rec.State
        if type(st) ~= "table" then return end

        local bp = type(st.bp) == "table" and st.bp or {}
        pcall(applyHeadlessToChar, char, bp.h == true)
        pcall(applyKorbloxLegToChar, char, "Right", bp.kr == true)
        pcall(applyKorbloxLegToChar, char, "Left", bp.kl == true)

        if type(st.items) == "table" then
            for _, it in ipairs(st.items) do
                if type(it) == "table" and it.id then
                    local preset = findPresetByNameOrId(it.name, tonumber(it.id))
                    local itemData = preset or {
                        Name       = tostring(it.name or ("Item_" .. tostring(it.id))),
                        AssetId    = tonumber(it.id),
                        IsGear     = it.gear == true,
                        EffectType = tostring(it.eff or "Native"),
                    }
                    local cfg = {
                        Scale       = tonumber(it.s) or 100,
                        PosX        = tonumber(it.px) or 0,
                        PosY        = tonumber(it.py) or 0,
                        PosZ        = tonumber(it.pz) or 0,
                        RotX        = tonumber(it.rx) or 0,
                        RotY        = tonumber(it.ry) or 0,
                        RotZ        = tonumber(it.rz) or 0,
                        ShowEffects = (it.fx ~= false),
                    }
                    pcall(AttachVisualItemToCharacter, char, itemData, cfg, rec.Entries)
                end
            end
        end
    end

    ctx.LarpingAPI = {
        GetLocalState = function()
            local itemsOut = {}
            for itemName, entry in pairs(ActiveItems) do
                if entry and entry.ItemData and entry.ItemData.AssetId then
                    local cfg = entry.Config or EnsureItemConfig(itemName)
                    table.insert(itemsOut, {
                        name = entry.ItemData.Name,
                        id   = entry.ItemData.AssetId,
                        gear = entry.ItemData.IsGear == true,
                        eff  = entry.ItemData.EffectType or "Native",
                        s    = cfg.Scale or 100,
                        px   = cfg.PosX or 0,
                        py   = cfg.PosY or 0,
                        pz   = cfg.PosZ or 0,
                        rx   = cfg.RotX or 0,
                        ry   = cfg.RotY or 0,
                        rz   = cfg.RotZ or 0,
                        fx   = cfg.ShowEffects ~= false,
                    })
                end
            end
            return {
                bp = {
                    h  = BodyPartState.HeadlessHorseman == true,
                    kr = BodyPartState.KorbloxRight == true,
                    kl = BodyPartState.KorbloxLeft == true,
                },
                items = itemsOut,
            }
        end,

        ApplyRemoteState = function(plr, state)
            if not plr or plr == LocalPlayer or not plr.Parent then return end
            local okH, hash = pcall(function()
                return HttpService:JSONEncode({ bp = state.bp, items = state.items })
            end)
            hash = okH and hash or tostring(os.clock())

            local rec = syncedPeers[plr]
            if rec and rec.Hash == hash then
                return
            end

            if not rec then
                rec = { Hash = "", Entries = {}, State = nil, CharConn = nil }
                syncedPeers[plr] = rec
                rec.CharConn = plr.CharacterAdded:Connect(function()
                    task.wait(0.6)
                    if syncedPeers[plr] then
                        applyStateToPeerChar(plr, syncedPeers[plr])
                    end
                end)
            else
                clearPeerVisuals(plr)
            end

            rec.Hash = hash
            rec.State = state
            applyStateToPeerChar(plr, rec)
        end,

        ClearRemotePlayer = function(plr)
            if not plr then return end
            local rec = syncedPeers[plr]
            if not rec then return end
            clearPeerVisuals(plr)
            if rec.CharConn then pcall(function() rec.CharConn:Disconnect() end) end
            syncedPeers[plr] = nil
        end,
    }
end

end
