-- JobSystem.server.lua
-- ServerScriptService
-- Manages job assignment, salary, and Teams.

local Players      = game:GetService("Players")
local Teams        = game:GetService("Teams")
local RS           = game:GetService("ReplicatedStorage")

-- Wait for DataStore to initialise _G.PlayerData
repeat task.wait(0.1) until _G.PlayerData

local GameConfig   = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))
local RE           = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- ── Build Teams ───────────────────────────────────────────────────────────────
local function getOrCreateTeam(job)
    local team = Teams:FindFirstChild(job.name)
    if not team then
        team           = Instance.new("Team")
        team.Name      = job.name
        team.TeamColor = BrickColor.new(job.color)
        team.AutoAssignable = false
        team.Parent    = Teams
    end
    return team
end

-- Civilian team
local civilianTeam = Teams:FindFirstChild("Civilian")
if not civilianTeam then
    civilianTeam = Instance.new("Team")
    civilianTeam.Name      = "Civilian"
    civilianTeam.TeamColor = BrickColor.new("Light stone grey")
    civilianTeam.AutoAssignable = true
    civilianTeam.Parent   = Teams
end

local jobTeams = {}
for _, job in ipairs(GameConfig.Jobs) do
    jobTeams[job.id] = getOrCreateTeam(job)
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function countJobMembers(jobId)
    local count = 0
    local team  = jobTeams[jobId]
    if team then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Team == team then
                count = count + 1
            end
        end
    end
    return count
end

local function findJobConfig(jobId)
    for _, job in ipairs(GameConfig.Jobs) do
        if job.id == jobId then return job end
    end
    return nil
end

-- ── Remote: AssignJob ─────────────────────────────────────────────────────────
RE.AssignJob.OnServerEvent:Connect(function(player, jobId)
    local data = _G.PlayerData.get(player)
    if not data then return end

    local job = findJobConfig(jobId)
    if not job then
        RE.Notify:FireClient(player, "Unknown job: " .. tostring(jobId), "error")
        return
    end

    if countJobMembers(jobId) >= job.maxSlots then
        RE.Notify:FireClient(player, "No slots available for " .. job.name, "warn")
        return
    end

    -- Leave current job team first
    if player.Team and player.Team ~= civilianTeam then
        player.Team = civilianTeam
    end

    data.job    = jobId
    player.Team = jobTeams[jobId]

    RE.UpdateHUD:FireClient(player, { job = jobId })
    RE.Notify:FireClient(player, "You are now a " .. job.name .. "!", "info")
    print("[JobSystem]", player.Name, "assigned to", job.name)
end)

-- ── Remote: LeaveJob ──────────────────────────────────────────────────────────
RE.LeaveJob.OnServerEvent:Connect(function(player)
    local data = _G.PlayerData.get(player)
    if not data then return end

    data.job    = nil
    player.Team = civilianTeam

    RE.UpdateHUD:FireClient(player, { job = nil })
    RE.Notify:FireClient(player, "You left your job.", "info")
end)

-- ── Remote: GetJobInfo ────────────────────────────────────────────────────────
RE.GetJobInfo.OnServerInvoke = function(player)
    local list = {}
    for _, job in ipairs(GameConfig.Jobs) do
        list[#list + 1] = {
            id       = job.id,
            name     = job.name,
            salary   = job.salary,
            color    = job.color,
            maxSlots = job.maxSlots,
            current  = countJobMembers(job.id),
        }
    end
    return list
end

-- ── Salary payment loop ───────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(GameConfig.SalaryInterval)
        for _, player in ipairs(Players:GetPlayers()) do
            local data = _G.PlayerData.get(player)
            if data and data.job then
                local job = findJobConfig(data.job)
                if job then
                    local multiplier = 1
                    if data.hasPremium then multiplier = 2 end
                    local pay = job.salary * multiplier
                    _G.PlayerData.addCash(player, pay)
                    RE.Notify:FireClient(player, "Salary: +$" .. pay, "salary")
                end
            end
        end
    end
end)

-- Restore team on rejoin
Players.PlayerAdded:Connect(function(player)
    task.wait(2)
    local data = _G.PlayerData.get(player)
    if data and data.job then
        local team = jobTeams[data.job]
        if team then
            player.Team = team
        end
    end
end)

print("[JobSystem] Initialized.")
