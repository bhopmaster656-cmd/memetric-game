-- ServerScriptService/TaxManager.server.lua
-- Collects property taxes and handles loan repayment at the bank.
-- Note: Most tax logic is handled in EconomyManager.
-- This script adds the Bank ProximityPrompt for loan repayment.

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

local NotifyPlayer = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("NotifyPlayer")

-- Wait for downtown to be built
task.delay(6, function()
    local downtown = Workspace:FindFirstChild("Downtown")
    if not downtown then return end

    -- Find Bank model
    local bank = downtown:FindFirstChild("Bank")
    if not bank then return end
    local bankBody = bank:FindFirstChild("Body")
    if not bankBody then return end

    -- Loan repayment prompt
    local repayPrompt = Instance.new("ProximityPrompt")
    repayPrompt.ActionText = "Repay Loan"
    repayPrompt.ObjectText = "Bank"
    repayPrompt.HoldDuration = 1
    repayPrompt.MaxActivationDistance = 15
    repayPrompt.Parent = bankBody

    repayPrompt.Triggered:Connect(function(player)
        local PDM = _G.PDM
        if not PDM then return end
        local data = PDM.GetData(player)
        if not data then return end

        if data.LoanAmount <= 0 then
            NotifyPlayer:FireClient(player, "🏦 You have no outstanding loans.", "blue")
            return
        end

        local amount = data.LoanAmount
        if PDM.SubtractMoney(player, amount) then
            data.LoanAmount = 0
            NotifyPlayer:FireClient(player, "✅ Loan of $" .. amount .. " fully repaid!", "green")
        else
            NotifyPlayer:FireClient(player, "❌ Not enough money to repay loan ($" .. amount .. " needed).", "red")
        end
    end)

    -- Request loan prompt
    local loanPrompt = Instance.new("ProximityPrompt")
    loanPrompt.ActionText   = "Request Loan"
    loanPrompt.ObjectText   = "Bank — $1,000 Loan"
    loanPrompt.HoldDuration = 2
    loanPrompt.MaxActivationDistance = 15
    loanPrompt.Parent = bankBody

    loanPrompt.Triggered:Connect(function(player)
        local PDM = _G.PDM
        if not PDM then return end
        local data = PDM.GetData(player)
        if not data then return end

        if data.LoanAmount > 0 then
            NotifyPlayer:FireClient(player, "🏦 Already have a loan of $" .. data.LoanAmount, "red")
            return
        end

        local defaultLoan = 1000
        data.LoanAmount = defaultLoan
        PDM.AddMoney(player, defaultLoan)
        NotifyPlayer:FireClient(player, "🏦 Loan of $" .. defaultLoan .. " approved! Repay at the bank.", "green")
    end)

    -- Town Hall profession change prompt
    local townHall = downtown:FindFirstChild("Town Hall")
    if townHall then
        local thBody = townHall:FindFirstChild("Body")
        if thBody then
            local profPrompt = Instance.new("ProximityPrompt")
            profPrompt.ActionText = "Change Profession"
            profPrompt.ObjectText = "Town Hall"
            profPrompt.HoldDuration = 0.5
            profPrompt.MaxActivationDistance = 15
            profPrompt.Parent = thBody
            profPrompt.Triggered:Connect(function(player)
                -- Fire client to open profession GUI
                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("OpenShop"):FireClient(player, "Profession")
            end)
        end
    end

    -- Government Store shop prompt
    local govStore = downtown:FindFirstChild("Government Store")
    if govStore then
        local gsBody = govStore:FindFirstChild("Body")
        if gsBody then
            local shopPrompt = Instance.new("ProximityPrompt")
            shopPrompt.ActionText = "Open Shop"
            shopPrompt.ObjectText = "Government Store"
            shopPrompt.HoldDuration = 0.5
            shopPrompt.MaxActivationDistance = 15
            shopPrompt.Parent = gsBody
            shopPrompt.Triggered:Connect(function(player)
                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("OpenShop"):FireClient(player, "GovStore")
            end)
        end
    end

    -- Café food shop prompt
    local cafe = downtown:FindFirstChild("Café")
    if cafe then
        local cafeBody = cafe:FindFirstChild("Body")
        if cafeBody then
            local cafePrompt = Instance.new("ProximityPrompt")
            cafePrompt.ActionText = "Order Food"
            cafePrompt.ObjectText = "Café"
            cafePrompt.HoldDuration = 0.5
            cafePrompt.MaxActivationDistance = 15
            cafePrompt.Parent = cafeBody
            cafePrompt.Triggered:Connect(function(player)
                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("OpenShop"):FireClient(player, "Cafe")
            end)
        end
    end

    -- Market/Auction prompt
    local auctionSign = Instance.new("Part")
    auctionSign.Name  = "AuctionHouse"
    auctionSign.Anchored = true
    auctionSign.Size  = Vector3.new(10, 6, 2)
    auctionSign.CFrame= CFrame.new(0, 3, -30)
    auctionSign.BrickColor = BrickColor.new("Bright orange")
    auctionSign.Material = Enum.Material.SmoothPlastic
    auctionSign.Parent= downtown

    local auctionPrompt = Instance.new("ProximityPrompt")
    auctionPrompt.ActionText = "Open Market"
    auctionPrompt.ObjectText = "Central Market"
    auctionPrompt.HoldDuration = 0.5
    auctionPrompt.MaxActivationDistance = 20
    auctionPrompt.Parent = auctionSign
    auctionPrompt.Triggered:Connect(function(player)
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("OpenShop"):FireClient(player, "Market")
    end)

    print("[TaxManager] Bank, Town Hall, Market prompts ready")
end)

print("[TaxManager] Ready")
