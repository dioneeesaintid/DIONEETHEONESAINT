-- DIONEE PREMIUM | Final Premium By DIONEE
-- v4.3 Fix - +1 Speed Keyboard Escape | Candy & Chocolate
-- Map Auto-Detect + Single Zone Win TP Farm + Live Win Counter
-- Educational only - violates Roblox ToS
-- NO KILL AURA / NO TREADMILL SPEED HACK

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "DIONEE PREMIUM | Final Premium By DIONEE",
   LoadingTitle = "DIONEE PREMIUM v4.3 Fix",
   LoadingSubtitle = "By DIONEE",
   ConfigurationSaving = {Enabled = false},
   DisableRayfieldPrompts = true,
   KeySystem = false
})

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ===== REMOTES =====
local remotes = RS:WaitForChild("Remotes")
local checkpointTpRemote = remotes:WaitForChild("RequestCheckpointTp")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local claimGiftRemote = remotes:WaitForChild("ClaimGift")
local verifyGroupRemote = remotes:WaitForChild("VerifyGroup")
local buyAuraRemote = remotes:WaitForChild("BuyAura")
local buyTrailRemote = remotes:WaitForChild("BuyTrail")
local equipPetRemote = remotes:FindFirstChild("EquipBest") or remotes:FindFirstChild("EquipPet") or remotes:FindFirstChild("Equip") or remotes:FindFirstChild("PetEquip", true)

local winRemote = nil
for _,v in ipairs(remotes:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        local n = v.Name:lower()
        if n:find("win") or n:find("finish") or n:find("complete") or n:find("reward") or n:find("givewin") then
            winRemote = v break
        end
    end
end

-- ===== STATE =====
getgenv().AutoFarmTP = false
getgenv().AutoWin = false
getgenv().AutoWinMode = "Single Zone"
getgenv().AutoWinReturnToFarm = true
getgenv().AutoWinStartCF = nil
getgenv().WinDelay = 1.2
getgenv().AutoRebirth = false
getgenv().AutoRebirthAtWins = true
getgenv().RebirthWinsThreshold = 5000
getgenv().AutoClaim = false
getgenv().AutoCollect = false
getgenv().SpeedIncrement = false
getgenv().GodMode = false
getgenv().AntiFling = true
getgenv().AntiVoid = true
getgenv().AutoEquipBest = false
getgenv().AntiDetectHop = false
getgenv().FarmCheckpoint = 11
getgenv().WalkSpeed = 16
getgenv().JumpPower = 50
getgenv().IncrementRate = 0.3
getgenv().IncrementAmount = 1
getgenv().ESPPlayers = false
getgenv().ESPItems = false
getgenv().AutoCollectESP = false

-- Map / Win pad state
getgenv().CurrentMap = "Unknown"
getgenv().CachedWinZone = nil

local function getWins()
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local w = ls:FindFirstChild("Wins") or ls:FindFirstChild("wins") or ls:FindFirstChild("Win")
        if w then return tonumber(w.Value) or 0 end
    end
    return 0
end

local startWins = getWins()
local totalNetWins = 0
local sessionStartTime = tick()

local function serverHop()
    pcall(function()
        Rayfield:Notify({Title = "DIONEE", Content = "Hopping server...", Duration = 2})
        TeleportService:Teleport(game.PlaceId, LP)
    end)
end

-- ===== MAP AUTO-DETECT =====
local function detectMap()
    local mapName = "Unknown"
    local mapContainers = {"Map", "Maps", "World", "Worlds", "Stages", "Areas", "Levels"}
    for _,containerName in ipairs(mapContainers) do
        local container = workspace:FindFirstChild(containerName)
        if container then
            for _,child in ipairs(container:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") then
                    mapName = child.Name
                    break
                end
            end
            if mapName ~= "Unknown" then break end
        end
    end
    if mapName == "Unknown" then
        for _,v in ipairs(workspace:GetDescendants()) do
            local n = v.Name:lower()
            if n:find("candy") then mapName = "Candy World"; break end
            if n:find("chocolate") or n:find("choco") then mapName = "Chocolate World"; break end
            if n:find("lava") then mapName = "Lava World"; break end
            if n:find("ice") or n:find("snow") then mapName = "Ice World"; break end
            if n:find("desert") or n:find("sand") then mapName = "Desert World"; break end
            if n:find("forest") or n:find("jungle") then mapName = "Forest World"; break end
        end
    end
    getgenv().CurrentMap = mapName
    return mapName
end

local function findWinZones()
    local zones = {}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.CanTouch then
            local n = v.Name:lower()
            local size = v.Size
            local isBig = size.X > 8 or size.Z > 8
            local isWinName = n:find("win") or n:find("finish") or n:find("end") or n:find("goal") or n:find("complete") or n:find("reward")
            local col = v.Color
            local isYellow = col.R > 0.8 and col.G > 0.8 and col.B < 0.4
            if isWinName or (isBig and isYellow) then
                table.insert(zones, v)
            end
        end
    end
    return zones
end

local function refreshMapScan()
    getgenv().CachedWinZone = nil
    local mapName = detectMap()
    local zones = findWinZones()
    if #zones > 0 then
        getgenv().CachedWinZone = zones[1]
    end
    return mapName, #zones, zones[1]
end

-- ========== FARM TAB ==========
local FarmTab = Window:CreateTab("Farm", 4483362458)

local winCounterLabel = FarmTab:CreateParagraph({Title = "Wins: 0", Content = "Session: +0 | Rate: 0/min | Rebirths: 0"})
local mapInfoLabel = FarmTab:CreateParagraph({Title = "Map: Detecting...", Content = "Win Pad: Scanning..."})

task.spawn(function()
    local lastWins = getWins()
    local rebirths = 0
    while true do
        task.wait(0.5)
        local current = getWins()
        if current < lastWins - 5000 then
            rebirths = rebirths + 1
        end
        lastWins = current
        totalNetWins = current - startWins
        if totalNetWins < 0 then
            startWins = current
            totalNetWins = 0
        end
        local elapsed = (tick() - sessionStartTime) / 60
        local rate = elapsed > 0 and math.floor(totalNetWins / elapsed * 10) / 10 or 0
        pcall(function()
            winCounterLabel:Set({
                Title = "Wins: "..current,
                Content = "Session: +"..totalNetWins.." | Rate: "..rate.."/min | Rebirths: "..rebirths
            })
            local padStatus = getgenv().CachedWinZone and getgenv().CachedWinZone.Parent and "Found ✓" or "Not found"
            local winState = getgenv().AutoWin and "Auto Win: ON" or "Auto Win: OFF"
            mapInfoLabel:Set({
                Title = "Map: "..getgenv().CurrentMap.." | "..winState,
                Content = "Win Pad: "..padStatus.." | Use Refresh Map if you changed worlds"
            })
        end)
    end
end)

FarmTab:CreateSection("Auto Win")
local autoCollectToggle
FarmTab:CreateToggle({
   Name = "Auto Win",
   CurrentValue = false,
   Flag = "AutoWin",
   Callback = function(v)
      getgenv().AutoWin = v
      if v and not getgenv().AutoWinStartCF then
         local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
         if hrp then getgenv().AutoWinStartCF = hrp.CFrame end
      end
      if v then
        getgenv().AutoCollect = true
        if autoCollectToggle then pcall(function() autoCollectToggle:Set(true) end) end
      end
   end,
})
FarmTab:CreateDropdown({
   Name = "Win Mode",
   Options = {"Single Zone", "Touch Only", "Remote Only"},
   CurrentOption = {"Single Zone"},
   Flag = "AutoWinMode",
   Callback = function(v) getgenv().AutoWinMode = v[1] end,
})
FarmTab:CreateToggle({
   Name = "Return to Farm After Win",
   CurrentValue = true,
   Flag = "AutoWinReturnToFarm",
   Callback = function(v) getgenv().AutoWinReturnToFarm = v end,
})
FarmTab:CreateButton({
   Name = "Set Farm Start Here",
   Callback = function()
      local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
      if hrp then
         getgenv().AutoWinStartCF = hrp.CFrame
         Rayfield:Notify({Title = "Farm Start Set", Content = "Auto Win will return here", Duration = 2})
      end
   end,
})
FarmTab:CreateButton({
   Name = "Refresh Map Scan",
   Callback = function()
      local mapName, count = refreshMapScan()
      if count > 0 then
         Rayfield:Notify({Title = "Map Found", Content = mapName.." | Win pads: "..count, Duration = 3})
      else
         Rayfield:Notify({Title = "Map: "..mapName, Content = "No win pad found", Duration = 3})
      end
   end,
})
FarmTab:CreateSlider({
   Name = "Win Delay",
   Range = {5, 30},
   Increment = 1,
   Suffix = " /10s",
   CurrentValue = 12,
   Flag = "WinDelay",
   Callback = function(v) getgenv().WinDelay = v/10 end,
})

FarmTab:CreateSection("Checkpoint Farm")
FarmTab:CreateToggle({
   Name = "Auto Checkpoint TP",
   CurrentValue = false,
   Flag = "AutoFarmTP",
   Callback = function(v)
      getgenv().AutoFarmTP = v
      if v then
        getgenv().AutoCollect = true
        if autoCollectToggle then pcall(function() autoCollectToggle:Set(true) end) end
      end
   end,
})
FarmTab:CreateSlider({
   Name = "Farm Checkpoint",
   Range = {1, 13},
   Increment = 1,
   Suffix = "",
   CurrentValue = 11,
   Flag = "FarmCheckpoint",
   Callback = function(v) getgenv().FarmCheckpoint = v end,
})

FarmTab:CreateSection("Rebirth")
FarmTab:CreateToggle({Name = "Auto Rebirth", CurrentValue = false, Flag = "AutoRebirth", Callback = function(v) getgenv().AutoRebirth = v end})
FarmTab:CreateToggle({Name = "Auto Rebirth at X Wins", CurrentValue = true, Flag = "AutoRebirthAtWins", Callback = function(v) getgenv().AutoRebirthAtWins = v end})
FarmTab:CreateInput({
   Name = "Rebirth at Wins",
   PlaceholderText = "5000",
   RemoveTextAfterFocusLost = false,
   Callback = function(v) local n = tonumber(v); if n then getgenv().RebirthWinsThreshold = n end end,
})

FarmTab:CreateSection("Auto Collect")
FarmTab:CreateToggle({Name = "Auto Claim Gifts", CurrentValue = false, Flag = "AutoClaim", Callback = function(v) getgenv().AutoClaim = v end})
autoCollectToggle = FarmTab:CreateToggle({Name = "Auto Collect +1", CurrentValue = false, Flag = "AutoCollect", Callback = function(v) getgenv().AutoCollect = v end})

-- ========== PLAYER TAB ==========
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("Movement Speed")
local speedSlider = PlayerTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 9999},
   Increment = 10,
   Suffix = " speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(v) getgenv().WalkSpeed = v end,
})

PlayerTab:CreateSection("Speed Increment")
PlayerTab:CreateToggle({
   Name = "+1 Speed Per Walk",
   CurrentValue = false,
   Flag = "SpeedIncrement",
   Callback = function(v) getgenv().SpeedIncrement = v end,
})
PlayerTab:CreateSlider({
   Name = "Increment Amount",
   Range = {1, 10},
   Increment = 1,
   Suffix = "",
   CurrentValue = 1,
   Flag = "IncrementAmount",
   Callback = function(v) getgenv().IncrementAmount = v end,
})
PlayerTab:CreateSlider({
   Name = "Increment Speed",
   Range = {1, 10},
   Increment = 1,
   Suffix = " (fast-slow)",
   CurrentValue = 3,
   Flag = "IncrementRate",
   Callback = function(v) getgenv().IncrementRate = v/10 end,
})

PlayerTab:CreateSection("Jump")
PlayerTab:CreateSlider({
   Name = "JumpPower",
   Range = {50, 300},
   Increment = 5,
   Suffix = "",
   CurrentValue = 50,
   Flag = "JumpPower",
   Callback = function(v) getgenv().JumpPower = v end,
})

PlayerTab:CreateSection("Protection")
PlayerTab:CreateToggle({
   Name = "God Mode / Anti Kill",
   CurrentValue = false,
   Flag = "GodMode",
   Callback = function(v)
      getgenv().GodMode = v
      local char = LP.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if v and hum then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        hum.BreakJointsOnDeath = false
        if not char:FindFirstChildOfClass("ForceField") then Instance.new("ForceField", char) end
      end
   end,
})
PlayerTab:CreateToggle({Name = "Anti Fling / Anti Ragdoll", CurrentValue = true, Flag = "AntiFling", Callback = function(v) getgenv().AntiFling = v end})
PlayerTab:CreateToggle({Name = "Anti Void / Anti Fall", CurrentValue = true, Flag = "AntiVoid", Callback = function(v) getgenv().AntiVoid = v end})

-- Player loop - speed / jump / godmode / anti-fling
local lastSafeCF = CFrame.new()
task.spawn(function()
    local lastInc = tick()
    while true do
        task.wait(0.05)
        pcall(function()
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                if hrp.Position.Y > 5 then lastSafeCF = hrp.CFrame end

                if getgenv().SpeedIncrement and tick() - lastInc >= getgenv().IncrementRate then
                    getgenv().WalkSpeed = getgenv().WalkSpeed + getgenv().IncrementAmount
                    if speedSlider then pcall(function() speedSlider:Set(math.clamp(getgenv().WalkSpeed,16,9999)) end) end
                    lastInc = tick()
                end

                if hum.WalkSpeed ~= getgenv().WalkSpeed then
                    hum.WalkSpeed = getgenv().WalkSpeed
                end

                hum.UseJumpPower = true
                if hum.JumpPower ~= getgenv().JumpPower then
                    hum.JumpPower = getgenv().JumpPower
                end

                if getgenv().AntiFling then
                    for _,v in ipairs(char:GetDescendants()) do
                        if v:IsA("BodyVelocity") or v:IsA("BodyAngularVelocity") then
                            v:Destroy()
                        end
                    end
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hum.PlatformStand = false
                end

                if getgenv().AntiVoid and hrp.Position.Y < -30 then
                    hrp.CFrame = lastSafeCF + Vector3.new(0,5,0)
                    hum.Health = hum.MaxHealth
                end

                if getgenv().GodMode then
                    hum.MaxHealth = math.huge
                    if hum.Health < math.huge then hum.Health = math.huge end
                    hum.BreakJointsOnDeath = false
                    if not char:FindFirstChildOfClass("ForceField") then Instance.new("ForceField", char) end
                end
            end
        end)
    end
end)

-- GodMode reapply on character add
local function applyGodModeToHumanoid(hum, char)
    if not getgenv().GodMode or not hum then return end
    hum.MaxHealth = math.huge
    hum.Health = math.huge
    hum.BreakJointsOnDeath = false
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    if not char:FindFirstChildOfClass("ForceField") then Instance.new("ForceField", char) end
    if not hum:FindFirstChild("GodModeConn") then
        local conn = Instance.new("BindableEvent")
        conn.Name = "GodModeConn"
        conn.Parent = hum
        hum.HealthChanged:Connect(function(h)
            if getgenv().GodMode and h < math.huge then
                hum.Health = math.huge
            end
        end)
    end
end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.UseJumpPower = true
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if hum.WalkSpeed ~= getgenv().WalkSpeed then hum.WalkSpeed = getgenv().WalkSpeed end
        end)
        hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if hum.UseJumpPower ~= true then hum.UseJumpPower = true end
            if hum.JumpPower ~= getgenv().JumpPower then hum.JumpPower = getgenv().JumpPower end
        end)
        applyGodModeToHumanoid(hum, char)
    end
    task.wait(1)
    refreshMapScan()
end)

-- ========== ESP TAB ==========
local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("ESP Toggles")
ESPTab:CreateToggle({Name = "ESP Players", CurrentValue = false, Flag = "ESPPlayers", Callback = function(v) getgenv().ESPPlayers = v end})
ESPTab:CreateToggle({Name = "ESP Items / Win Pad", CurrentValue = false, Flag = "ESPItems", Callback = function(v) getgenv().ESPItems = v end})
ESPTab:CreateToggle({Name = "Auto Collect ESP Items", CurrentValue = false, Flag = "AutoCollectESP", Callback = function(v) getgenv().AutoCollectESP = v end})

ESPTab:CreateSection("ESP Tools")
ESPTab:CreateButton({
   Name = "Refresh Map Scan",
   Callback = function()
      local mapName, count = refreshMapScan()
      Rayfield:Notify({Title = "Map Scan", Content = mapName.." | Win pads: "..count, Duration = 3})
   end,
})
ESPTab:CreateButton({Name = "Clear ESP", Callback = function() for _,v in ipairs(workspace:GetDescendants()) do if v.Name == "DioneeESP" then v:Destroy() end end end})

task.spawn(function()
    while true do
        task.wait(0.6)
        local function addESP(target, color, text)
            if not target or not target.Parent or target:FindFirstChild("DioneeESP") then return end
            local bill = Instance.new("BillboardGui")
            bill.Name = "DioneeESP"; bill.AlwaysOnTop = true
            bill.Size = UDim2.new(0,120,0,30); bill.StudsOffset = Vector3.new(0,2.5,0); bill.Adornee = target
            local label = Instance.new("TextLabel", bill)
            label.BackgroundTransparency = 1; label.Size = UDim2.new(1,0,1,0)
            label.Text = text; label.TextColor3 = color; label.TextStrokeTransparency = 0
            label.Font = Enum.Font.GothamBold; label.TextScaled = true
            bill.Parent = target
            local hl = Instance.new("Highlight")
            hl.Name = "DioneeESP"; hl.FillTransparency = 0.6; hl.OutlineTransparency = 0
            hl.FillColor = color; hl.OutlineColor = color; hl.Adornee = target; hl.Parent = target
        end
        if getgenv().ESPItems then
            for _,v in ipairs(findWinZones()) do
                addESP(v, Color3.fromRGB(255,220,60), "WIN ZONE")
            end
        end
        if getgenv().ESPPlayers then
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    addESP(plr.Character.HumanoidRootPart, Color3.fromRGB(255,60,60), plr.Name)
                end
            end
        end
        if getgenv().AutoCollectESP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LP.Character.HumanoidRootPart
            local nearest, ndist = nil, 9999
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v:FindFirstChild("DioneeESP") then
                    local d = (v.Position - hrp.Position).Magnitude
                    if d < ndist and d < 60 then nearest, ndist = v, d end
                end
            end
            if nearest then pcall(function() firetouchinterest(hrp, nearest, 0); firetouchinterest(hrp, nearest, 1) end) end
        end
    end
end)

-- ========== TELEPORTS / SHOP / SETTINGS ==========
local TPTab = Window:CreateTab("Teleports", 4483362458)
local function doCheckpoint(n) pcall(function() checkpointTpRemote:FireServer(n, "wins") end) end
TPTab:CreateButton({Name = "Checkpoint 1", Callback = function() doCheckpoint(1) end})
TPTab:CreateButton({Name = "Checkpoint 5", Callback = function() doCheckpoint(5) end})
TPTab:CreateButton({Name = "Checkpoint 11", Callback = function() doCheckpoint(11) end})
TPTab:CreateButton({Name = "Checkpoint 13 Finish", Callback = function() doCheckpoint(13) end})

local ShopTab = Window:CreateTab("Shop", 4483362458)
ShopTab:CreateToggle({Name = "Auto Equip Best Pet", CurrentValue = false, Flag = "AutoEquipBest", Callback = function(v) getgenv().AutoEquipBest = v end})
ShopTab:CreateInput({Name = "Aura Name", PlaceholderText = "GlowAura", RemoveTextAfterFocusLost = false, Callback = function(v) getgenv().AuraName = v end})
ShopTab:CreateToggle({Name = "Auto Buy Aura", CurrentValue = false, Flag = "AutoBuyAura", Callback = function(v) getgenv().AutoBuyAura = v end})
ShopTab:CreateInput({Name = "Trail Name", PlaceholderText = "GreenTrail", RemoveTextAfterFocusLost = false, Callback = function(v) getgenv().TrailName = v end})
ShopTab:CreateToggle({Name = "Auto Buy Trail", CurrentValue = false, Flag = "AutoBuyTrail", Callback = function(v) getgenv().AutoBuyTrail = v end})

local SettingsTab = Window:CreateTab("Settings", 4483362458)
SettingsTab:CreateParagraph({Title = "DIONEE PREMIUM v4.3 Fix", Content = "Final Premium By DIONEE | Map Auto-Detect + Win TP Farm"})
SettingsTab:CreateButton({
   Name = "Refresh Map Scan",
   Callback = function()
      local mapName, count = refreshMapScan()
      Rayfield:Notify({Title = "Map Scan", Content = mapName.." | Win pads: "..count, Duration = 3})
   end,
})
SettingsTab:CreateToggle({Name = "Anti-Detect / Auto Server Hop", CurrentValue = false, Flag = "AntiDetectHop", Callback = function(v) getgenv().AntiDetectHop = v end})
SettingsTab:CreateButton({Name = "Server Hop Now", Callback = serverHop})
SettingsTab:CreateButton({Name = "Unload UI", Callback = function() Rayfield:Destroy() end})

-- ===== AUTO WIN - SINGLE ZONE, MAP-AWARE =====
task.spawn(function()
    while true do
        task.wait(getgenv().WinDelay or 1.2)
        if not getgenv().AutoWin then continue end
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then continue end

        local hrp = LP.Character.HumanoidRootPart

        if not getgenv().CachedWinZone or not getgenv().CachedWinZone.Parent then
            refreshMapScan()
        end
        local zone = getgenv().CachedWinZone

        if not zone then
            if winRemote then
                pcall(function() winRemote:FireServer() end)
            end
            pcall(function() checkpointTpRemote:FireServer(13, "wins") end)
            continue
        end

        local farmPos = getgenv().AutoWinStartCF or hrp.CFrame
        local winsBefore = getWins()
        local mode = getgenv().AutoWinMode or "Single Zone"

        if mode == "Single Zone" or mode == "Touch Only" then
            pcall(function()
                local size = zone.Size
                local center = zone.CFrame
                local points = {
                    center,
                    center * CFrame.new(size.X*0.3, 0, size.Z*0.3),
                    center * CFrame.new(-size.X*0.3, 0, size.Z*0.3),
                    center * CFrame.new(size.X*0.3, 0, -size.Z*0.3),
                    center * CFrame.new(-size.X*0.3, 0, -size.Z*0.3),
                }
                for _,p in ipairs(points) do
                    hrp.CFrame = p + Vector3.new(0,3,0)
                    task.wait(0.08)
                    firetouchinterest(hrp, zone, 0)
                    task.wait(0.15)
                    firetouchinterest(hrp, zone, 1)
                end
            end)
        end

        if mode == "Single Zone" or mode == "Remote Only" then
            if winRemote then
                pcall(function() winRemote:FireServer() end)
            end
            pcall(function()
                checkpointTpRemote:FireServer(13, "wins")
                checkpointTpRemote:FireServer(12, "wins")
                checkpointTpRemote:FireServer(11, "wins")
            end)
        end

        task.wait(0.2)

        if getgenv().AutoWinReturnToFarm and farmPos then
            pcall(function() hrp.CFrame = farmPos end)
        end

        task.wait(0.15)
        local winsAfter = getWins()
        if winsAfter > winsBefore then
            Rayfield:Notify({Title = "+1 Win", Content = "Wins: "..winsAfter, Duration = 1.2})
        end
    end
end)

-- farm misc (AutoFarmTP, AutoRebirth, AutoClaim, AutoBuy, AutoEquip, AntiDetectHop)
task.spawn(function()
    while true do
        task.wait(0.8)
        if getgenv().AutoFarmTP then
            pcall(function() checkpointTpRemote:FireServer(getgenv().FarmCheckpoint, "wins") end)
        end

        if getgenv().AutoRebirthAtWins then
            pcall(function()
                local wins = getWins()
                if wins >= getgenv().RebirthWinsThreshold then
                    rebirthRemote:FireServer()
                    task.wait(0.5)
                end
            end)
        elseif getgenv().AutoRebirth then
            pcall(function()
                rebirthRemote:FireServer()
                task.wait(0.5)
            end)
        end

        if getgenv().AutoClaim then
            pcall(function()
                claimGiftRemote:FireServer()
                verifyGroupRemote:InvokeServer()
            end)
        end

        if getgenv().AutoBuyAura then
            pcall(function() buyAuraRemote:InvokeServer(getgenv().AuraName, "Wins") end)
        end
        if getgenv().AutoBuyTrail then
            pcall(function() buyTrailRemote:InvokeServer(getgenv().TrailName, "Wins") end)
        end

        if getgenv().AutoEquipBest and equipPetRemote then
            pcall(function()
                equipPetRemote:FireServer("Best")
                equipPetRemote:InvokeServer("Best")
            end)
        end

        if getgenv().AntiDetectHop then
            if #Players:GetPlayers() < 2 then
                serverHop()
            end
        end
    end
end)

-- auto collect +1 (optimized)
task.spawn(function()
    while true do
        task.wait(0.35)
        if getgenv().AutoCollect and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LP.Character.HumanoidRootPart
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("TouchTransmitter") and v.Parent and v.Parent:IsA("BasePart") then
                    local p = v.Parent
                    local dist = (p.Position - hrp.Position).Magnitude
                    if dist < 30 then
                        pcall(function() firetouchinterest(hrp, p, 0); firetouchinterest(hrp, p, 1) end)
                    end
                end
            end
        end
    end
end)

-- anti afk
pcall(function()
    local vu = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

-- initial map scan
task.spawn(function()
    task.wait(1.5)
    local mapName, count = refreshMapScan()
    Rayfield:Notify({
       Title = "DIONEE PREMIUM v4.3 Fix",
       Content = "By DIONEE | Map: "..mapName.." | Win pads: "..count,
       Duration = 4,
       Image = 4483362458
    })
end)
