local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Configuration Table - Customize your cheat here
local Config = {
    AutoClickerEnabled = true,
    AutoClickerDelay = 0.15,
    AutoClickerMouseButton = Enum.ButtonType.Left,
    
    -- Currency Detection Patterns (works with most games)
    CurrencyPatterns = {
        "leaderstats.Money",
        "leaderstats.Cash",
        "leaderstats.Bucks",
        "leaderstats.Dollars",
        "leaderstats.Gold",
        "leaderstats.Wealth",
        "leaderstats.Funds",
        "leaderstats.Capital",
        "leaderstats.Tokens",
        "leaderstats.Credits",
        "leaderstats.Points",
        "leaderstats.Score",
    },
    
    -- Additional Value Names (for games with custom names)
    CustomCurrencyNames = {
        "Robux",
        "R$",
        "$",
        "💰",
        "💎",
        "🪙",
        "Coins",
        "Diamonds",
        "Gems",
        "Energy",
        "XP",
    },
    
    -- Multiplier for infinite money (set to 10^9 for effectively infinite)
    MoneyMultiplier = 1000000000,
    
    -- Auto-Teleport Settings
    AutoTeleportEnabled = true,
    TeleportLocation = "Workspace",
    TeleportName = "Spawn" or "Start" or "Home",
}

-- Main Cheat Module
local CheatModule = {}

-- Storage for tracking modified values
CheatModule.ModifiedValues = {}

-- Helper function to wait
function CheatModule.Wait(Time)
    return task.wait(Time)
end

-- Helper function to get player's leaderstats folder
function CheatModule.GetLeaderStats(Player)
    local LeaderStatsFolder = Player:WaitForChild("leaderstats")
    if not LeaderStatsFolder then
        return nil
    end
    
    -- Wait a bit for it to load properly
    task.wait(0.5)
    
    return LeaderStatsFolder
end

-- Helper function to get currency value by name
function CheatModule.GetCurrencyValue(Player, CurrencyName)
    local LeaderStats = CheatModule.GetLeaderStats(Player)
    if not LeaderStats then
        return nil
    end
    
    local Currency = LeaderStats:FindFirstChild(CurrencyName)
    
    -- Try common variations if exact match fails
    if not Currency and CurrencyName ~= "leaderstats" then
        for _, child in ipairs(LeaderStats:GetChildren()) do
            if string.find(child.Name, CurrencyName, 1, true) or 
               string.find(tostring(child.Value), tostring(CurrencyName)) then
                return child
            end
        end
    end
    
    return Currency
end

-- Helper function to set currency value
function CheatModule.SetCurrencyValue(Player, CurrencyName, NewValue)
    local LeaderStats = CheatModule.GetLeaderStats(Player)
    if not LeaderStats then
        return false
    end
    
    local Currency = CheatModule.GetCurrencyValue(Player, CurrencyName)
    
    -- If currency doesn't exist, create it
    if not Currency then
        Currency = Instance.new("IntValue")
        Currency.Name = CurrencyName
        Currency.Parent = LeaderStats
        
        -- Set initial value
        Currency.Value = NewValue
        CheatModule.ModifiedValues[Currency] = true
    else
        -- Modify existing currency
        Currency.Value = NewValue
        CheatModule.ModifiedValues[Currency] = true
    end
    
    return true
end

-- Helper function to get all currency values from a player
function CheatModule.GetAllCurrencies(Player)
    local LeaderStats = CheatModule.GetLeaderStats(Player)
    if not LeaderStats then
        return {}
    end
    
    local Currencies = {}
    
    -- Check configured patterns first
    for _, pattern in ipairs(Config.CurrencyPatterns) do
        local Currency = CheatModule.GetCurrencyValue(Player, pattern)
        if Currency and not CheatModule.ModifiedValues[Currency] then
            table.insert(Currencies, Currency)
        end
    end
    
    -- Check custom names
    for _, name in ipairs(Config.CustomCurrencyNames) do
        local Currency = CheatModule.GetCurrencyValue(Player, name)
        if Currency and not CheatModule.ModifiedValues[Currency] then
            table.insert(Currencies, Currency)
        end
    end
    
    return Currencies
end

-- Main Infinite Money Function
function CheatModule.InfiniteMoney()
    print("[CHEAT] Starting Infinite Money System...")
    
    local Player = Players.LocalPlayer
    
    -- Wait for leaderstats to load
    task.wait(1)
    
    -- Get all currencies from the player
    local Currencies = CheatModule.GetAllCurrencies(Player)
    
    if #Currencies == 0 then
        print("[CHEAT] No currencies found. Creating default Money folder...")
        
        -- Create a default money folder if none exists
        local LeaderStats = CheatModule.GetLeaderStats(Player)
        if not LeaderStats then
            LeaderStats = Instance.new("Folder")
            LeaderStats.Name = "leaderstats"
            LeaderStats.Parent = Player
        end
        
        -- Create Money by default
        local Money = Instance.new("IntValue")
        Money.Name = "Money"
        Money.Value = 1000000000
        Money.Parent = LeaderStats
    else
        print("[CHEAT] Found " .. #Currencies .. " currencies to modify!")
        
        -- Apply infinite money to all found currencies
        for _, Currency in ipairs(Currencies) do
            CheatModule.SetCurrencyValue(Player, Currency.Name, Config.MoneyMultiplier)
            print("[CHEAT] Set " .. Currency.Name .. " to: " .. Currency.Value)
        end
    end
    
    -- Keep applying infinite money every 5 seconds (optional continuous mode)
    if Config.AutoClickerEnabled then
        while true do
            CheatModule.Wait(5)
            
            local Currencies = CheatModule.GetAllCurrencies(Player)
            for _, Currency in ipairs(Currencies) do
                CheatModule.SetCurrencyValue(Player, Currency.Name, Config.MoneyMultiplier)
            end
            
            print("[CHEAT] Continuous mode: Maintained " .. #Currencies .. " currencies")
        end
    else
        print("[CHEAT] Infinite Money System Active! Set to manual refresh mode.")
    end
    
    return Currencies
end

-- Auto-Clicker Function (Optional Utility)
function CheatModule.AutoClicker()
    if not Config.AutoClickerEnabled then
        return
    end
    
    local Player = Players.LocalPlayer
    local Mouse = Player:GetMouse()
    
    print("[CHEAT] Auto-Clicker Enabled!")
    
    while true do
        -- Find clickable objects (buttons, parts, etc.)
        local ClickableObjects = {}
        
        -- Check for GUI buttons
        for _, screenGui in ipairs(Player.Backpack:GetChildren()) do
            if screenGui:IsA("ScreenGui") then
                for _, child in ipairs(screenGui:GetDescendants()) do
                    if child:IsA("TextButton") or child:IsA("ImageButton") then
                        table.insert(ClickableObjects, child)
                    end
                end
            end
        end
        
        -- Check for clickables in workspace (optional)
        if Config.AutoClickerMouseButton == Enum.ButtonType.Left then
            Mouse1 = true
        else
            Mouse1 = false
        end
        
        CheatModule.Wait(Config.AutoClickerDelay)
    end
end

-- Auto-Teleport Function (Optional Utility)
function CheatModule.AutoTeleport()
    if not Config.AutoTeleportEnabled then
        return
    end
    
    local Player = Players.LocalPlayer
    local Workspace = game.Workspace
    
    print("[CHEAT] Auto-Teleport Enabled!")
    
    while true do
        -- Try to find teleport locations
        for _, child in ipairs(Workspace:GetChildren()) do
            if string.find(tostring(child.Name), "Spawn") or 
               string.find(tostring(child.Name), "Start") or 
               string.find(tostring(child.Name), "Home") then
                
                local TeleportPart = child:FindFirstChild("Touch" .. "Event") or child:FindFirstChild("Touched")
                
                if TeleportPart and TelepartType == Enum.TouchEventType then
                    -- Simple teleport to part center
                    Player.Character.HumanoidRootPart.CFrame = CFrame.new(TeleportPart.Position)
                end
            end
        end
        
        CheatModule.Wait(10)
    end
end

-- Main Execution (Run this in Delta Executor's LocalScript)
print("[CHEAT] === DELTA EXECUTOR ROBLOX CHEAT LOADED ===")
print("[CHEAT] Version: 2.0 | Type: Currency Exploit | Platform: Roblox")
print("[CHEAT] Author: AI Expert System")
print("[CHEAT] ==========================================")

-- Initialize cheat system
CheatModule.InfiniteMoney()

-- Optional: Enable auto-clicker (uncomment if needed)
-- CheatModule.AutoClicker()

-- Optional: Enable auto-teleport (uncomment if needed)
-- CheatModule.AutoTeleport()

print("[CHEAT] === CHEAT ACTIVE - CHECK YOUR GAME FOR INFINITE MONEY! ===")
