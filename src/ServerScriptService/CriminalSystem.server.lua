-- ServerScriptService/CriminalSystem.server.lua
-- Handles reputation, crime, arrests, jail, and bail.

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ArrestPlayer = RemoteEvents:WaitForChild("ArrestPlayer")
local NotifyPlayer = RemoteEvents:WaitForChild("NotifyPlayer")
local OpenShop     = RemoteEvents:WaitForChild("OpenShop")

-- ─── Crime Recording ─────────────────────────────────────────────────────────
-- criminalRecord[userId] = list of { crimeType, timestamp }
local criminalRecord = {}

local function recordCrime(player, crimeType)
    local uid = player.UserId
    if not criminalRecord[uid] then criminalRecord[uid] = {} end
    table.insert(criminalRecord[uid], { crimeType=crimeType, timestamp=os.time() })
end

-- ─── Commit Crime ─────────────────────────────────────────────────────────────
-- Called by other systems (building manager for theft, etc.)
local CriminalSystem = {}

function CriminalSystem.CommitCrime(player, crimeType)
    local PDM = _G.PDM
    if not PDM then return end
    local data = PDM.GetData(player)
    if not data then return end

    local severity = GameConfig.CrimeSeverity[crimeType] or 1
    PDM.AddReputation(player, -severity * 5)
    recordCrime(player, crimeType)

    -- Alert nearby Sheriffs
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local otherData = PDM.GetData(other)
            if otherData and otherData.Profession == "Sheriff" then
                NotifyPlayer:FireClient(other, "🚨 Crime reported: " .. crimeType .. " by " .. player.Name, "red")
            end
        end
    end

    NotifyPlayer:FireClient(player, "⚠️ You committed: " .. crimeType .. " (reputation -" .. severity * 5 .. ")", "red")
end

-- ─── Arrest ───────────────────────────────────────────────────────────────────
ArrestPlayer.OnServerEvent:Connect(function(sheriff, targetName)
    local PDM = _G.PDM
    if not PDM then return end

    local sheriffData = PDM.GetData(sheriff)
    if not sheriffData or sheriffData.Profession ~= "Sheriff" then
        NotifyPlayer:FireClient(sheriff, "❌ Only Sheriffs can make arrests.", "red")
        return
    end

    local target = Players:FindFirstChild(targetName)
    if not target then
        NotifyPlayer:FireClient(sheriff, "❌ Player not found.", "red")
        return
    end

    -- Proximity check
    local sheriffChar = sheriff.Character
    local targetChar  = target.Character
    if sheriffChar and targetChar then
        local sRoot = sheriffChar:FindFirstChild("HumanoidRootPart")
        local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if sRoot and tRoot then
            local dist = (sRoot.Position - tRoot.Position).Magnitude
            if dist > GameConfig.ArrestRange then
                NotifyPlayer:FireClient(sheriff, "❌ Too far away to arrest.", "red")
                return
            end
        end
    end

    local targetData = PDM.GetData(target)
    if not targetData then return end

    -- Check if target has committed crimes
    local hasCrimes = criminalRecord[target.UserId] and #criminalRecord[target.UserId] > 0
    if not hasCrimes and targetData.Reputation >= 0 then
        NotifyPlayer:FireClient(sheriff, "⚠️ This player has no outstanding crimes.", "yellow")
        return
    end

    -- Calculate jail time based on crimes
    local totalSeverity = 0
    if criminalRecord[target.UserId] then
        for _, crime in ipairs(criminalRecord[target.UserId]) do
            totalSeverity = totalSeverity + (GameConfig.CrimeSeverity[crime.crimeType] or 1)
        end
    end
    local jailTime = math.max(GameConfig.JailTime, totalSeverity * GameConfig.JailTime)

    -- Fine target (10% of money)
    local fine = math.floor(targetData.Money * 0.1)
    PDM.SubtractMoney(target, fine)
    PDM.AddMoney(sheriff, math.floor(fine * 0.2))  -- Sheriff gets 20% of fine

    -- Clear crime record
    criminalRecord[target.UserId] = {}

    PDM.AddReputation(sheriff, 5)
    PDM.AddReputation(target,  -10)

    -- Jail the target
    PDM.Jail(target, jailTime)

    NotifyPlayer:FireClient(sheriff, "✅ Arrested " .. targetName .. " (jail: " .. jailTime .. "s, fine: $" .. fine .. ")", "green")
end)

-- ─── Bail Out ─────────────────────────────────────────────────────────────────
-- Players can pay bail to get out of jail early
-- This is called via a proximity prompt on the jail cell in future

-- ─── Litter Detection (example environmental crime) ─────────────────────────
-- When a player leaves trash, reputation decreases. 
-- Other systems can call CriminalSystem.CommitCrime directly.

_G.CriminalSystem = CriminalSystem

print("[CriminalSystem] Ready")
