local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Configuration Table - Customize your fly cheat here
local Config = {
    -- Flight Settings
    FlyEnabled = true,
    FlySpeed = 15,                    -- Base flight speed (adjust for faster/slower)
    JumpBoost = 20,                  -- Extra jump power when flying
    AutoFly = false,                 -- Enable/disable auto-flight mode
    
    -- Physics Settings  
    GravityScale = 0.5,              -- Lower = lighter feel, 0 = zero gravity
    AirControl = 1.0,                -- Air control multiplier (1.0 = normal)
    
    -- Visual Settings
    ShowDebugLines = false,          -- Show flight path lines
    DebugColor = Color3.fromRGB(255, 255, 255),
    
    -- Advanced Settings
    SmoothMovement = true,           -- Smooth character movement
    InstantFly = false,              -- Instant teleport fly (risky but fast)
}

-- Main Fly Cheat Module
local FlyCheat = {}

-- Storage for tracking flight state
FlyCheat.Flying = false
FlyCheat.LastPosition = nil
FlyCbeat.VelocityOverride = nil

-- Helper function to wait
function FlyCheat.Wait(Time)
    return task.wait(Time)
end

-- Helper function to get local player's character
function FlyCheat.GetCharacter()
    local Player = Players.LocalPlayer
    local Character = Player.Character
    
    -- Wait for character to load if needed
    while not Character do
        Character = Player.Character
        FlyCheat.Wait(0.1)
    end
    
    return Character
end

-- Helper function to get humanoid root part
function FlyCheat.GetHumanoidRootPart(Character)
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    
    if not HumanoidRootPart then
        -- Try alternative names
        for _, child in ipairs(Character:GetChildren()) do
            if child:IsA("BasePart") and (child.Name == "Head" or string.find(child.Name, "Root")) then
                return child
            end
        end
    end
    
    return HumanoidRootPart
end

-- Helper function to get humanoid
function FlyCheat.GetHumanoid(Character)
    local Humanoid = Character:FindFirstChild("Humanoid")
    
    if not Humanoid then
        -- Try alternative names
        for _, child in ipairs(Character:GetChildren()) do
            if child:IsA("Humanoid") or string.find(tostring(child.Name), "Humanoid") then
                return child
            end
        end
    end
    
    return Humanoid
end

-- Helper function to get character's CFrame
function FlyCheat.GetCharacterCFrame(HumanoidRootPart)
    if not HumanoidRootPart then
        return nil
    end
    
    -- Get current CFrame with position and rotation
    local CurrentCFrame = HumanoidRootPart.CFrame
    
    return CurrentCFrame
end

-- Helper function to set character's CFrame (smooth movement)
function FlyCheat.SetCharacterCFrame(HumanoidRootPart, TargetCFrame, Speed)
    if not HumanoidRootPart then
        return false
    end
    
    -- Calculate distance between current and target position
    local CurrentPosition = HumanoidRootPart.Position
    local TargetPosition = TargetCFrame.Position
    
    local Distance = (CurrentPosition - TargetPosition).Magnitude
    
    -- Smooth interpolation based on distance
    if Speed == "instant" then
        HumanoidRootPart.CFrame = TargetCFrame
    else
        -- Smooth lerp for natural movement
        HumanoidRootPart.CFrame = CurrentCFrame:Lerp(TargetCFrame, 0.2)
    end
    
    return true
end

-- Helper function to get mouse position in world space
function FlyCheat.GetMouseWorldPosition()
    local Player = Players.LocalPlayer
    local Mouse = Player:GetMouse()
    
    -- Get screen position from mouse
    local ScreenPos = Vector2.new(Mouse.X, Mouse.Y)
    
    -- Convert to world position using raycast
    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    -- Create a temporary part for raycasting
    local RayPart = Instance.new("Part")
    RayPart.Size = Vector3.new(1, 1, 1)
    RayPart.Shape = Enum.PartType.Ball
    RayPart.Parent = Workspace
    RayPart.CanCollide = false
    
    -- Get world position from screen coordinates
    local WorldPos = Mouse.Hit.Position
    
    return WorldPos
end

-- Helper function to get camera CFrame for smooth following
function FlyCheat.GetCameraCFrame()
    local Camera = workspace.CurrentCamera
    if not Camera then
        return nil
    end
    
    -- Get camera's current CFrame
    local CameraCFrame = Camera.CFrame
    
    return CameraCFrame
end

-- Main Flight Function (Primary Method - Most Reliable)
function FlyCheat.PrimaryFlight()
    print("[FLY CHEAT] Starting Primary Flight System...")
    
    local Character = FlyCheat.GetCharacter()
    if not Character then
        print("[FLY CHEAT] Waiting for character to load...")
        FlyCheat.Wait(2)
        Character = FlyCheat.GetCharacter()
    end
    
    if not Character then
        print("[FLY CHEAT] Character not found!")
        return false
    end
    
    local HumanoidRootPart = FlyCheat.GetHumanoidRootPart(Character)
    if not HumanoidRootPart then
        print("[FLY CHEAT] HumanoidRootPart not found!")
        return false
    end
    
    -- Apply gravity scale for lighter feel
    local Humanoid = FlyCheat.GetHumanoid(Character)
    if Humanoid then
        Humanoid.WalkSpeed = Config.FlySpeed * 10
        Humanoid.JumpPower = Config.JumpBoost
        Humanoid.PlatformStand = true
        
        -- Apply custom gravity scale
        if HumanoidRootPart.Parent and HumanoidRootPart.Parent:IsA("Model") or 
           HumanoidRootPart.Parent and HumanoidRootPart.Parent:IsA("Character") then
            -- For humanoid characters, use velocity override
        end
    end
    
    print("[FLY CHEAT] Primary Flight Active! Speed: " .. Config.FlySpeed)
    
    return true
end

-- Secondary Flight Function (CFrame-based - Works with most games)
function FlyCheat.SecondaryFlight()
    print("[FLY CHEAT] Starting Secondary Flight System...")
    
    local Character = FlyCheat.GetCharacter()
    if not Character then
        return false
    end
    
    local HumanoidRootPart = FlyCheat.GetHumanoidRootPart(Character)
    if not HumanoidRootPart then
        return false
    end
    
    -- Get current CFrame
    local CurrentCFrame = HumanoidRootPart.CFrame
    
    -- Apply flight velocity (upward force)
    local UpwardVelocity = Vector3.new(0, Config.FlySpeed * 2, 0)
    
    -- Smooth upward movement
    if not Config.InstantFly then
        -- Gradual ascent for natural feel
        HumanoidRootPart.Velocity = CurrentCFrame.Velocity + UpwardVelocity
    else
        -- Instant teleport up (for quick ascents)
        local TargetHeight = CurrentCFrame.Position.Y + 50
        HumanoidRootPart.CFrame = CFrame.new(CurrentCFrame.X, TargetHeight, CurrentCFrame.Z)
    end
    
    print("[FLY CHEAT] Secondary Flight Active!")
    
    return true
end

-- Tertiary Flight Function (Velocity-based - Fallback method)
function FlyCheat.TertiaryFlight()
    print("[FLY CHEAT] Starting Tertiary Flight System...")
    
    local Character = FlyCheat.GetCharacter()
    if not Character then
        return false
    end
    
    local HumanoidRootPart = FlyCheat.GetHumanoidRootPart(Character)
    if not HumanoidRootPart then
        return false
    end
    
    -- Apply continuous upward velocity
    local UpwardForce = Vector3.new(0, Config.FlySpeed * 1.5, 0)
    
    -- Smooth velocity application
    if not Config.InstantFly then
        -- Gradual velocity change for natural feel
        HumanoidRootPart.Velocity = HumanoidRootPart.Velocity + UpwardForce * 0.1
    else
        -- Instant upward teleport
        local TargetHeight = HumanoidRootPart.Position.Y + 30
        HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.X, TargetHeight, HumanoidRootPart.Z)
    end
    
    print("[FLY CHEAT] Tertiary Flight Active!")
    
    return true
end

-- Advanced Flight Function (Camera-following - Best for smooth gameplay)
function FlyCheat.AdvancedFlight()
    print("[FLY CHEAT] Starting Advanced Camera-Following Flight...")
    
    local Character = FlyCheat.GetCharacter()
    if not Character then
        return false
    end
    
    local HumanoidRootPart = FlyCheat.GetHumanoidRootPart(Character)
    if not HumanoidRootPart then
        return false
    end
    
    -- Get camera CFrame for smooth following
    local CameraCFrame = FlyCheat.GetCameraCFrame()
    
    if CameraCFrame then
        -- Smooth camera-following flight
        local Offset = Vector3.new(0, 5, -10)  -- Position relative to character
        
        -- Calculate target CFrame based on camera position
        local TargetCFrame = (CameraCFrame * Offset).CFrame
        
        -- Apply smooth movement towards target
        if not Config.InstantFly then
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(TargetCFrame, 0.15)
        else
            HumanoidRootPart.CFrame = TargetCFrame
        end
    end
    
    print("[FLY CHEAT] Advanced Flight Active! Camera-following enabled.")
    
    return true
end

-- Auto-Flight Function (Continuous flight mode)
function FlyCheat.AutoFlight()
    if not Config.AutoFly then
        return
    end
    
    print("[FLY CHEAT] Auto-Flight Enabled!")
    
    -- Combine all flight methods for maximum reliability
    while true do
        -- Try primary method first
        FlyCheat.PrimaryFlight()
        
        -- Fallback to secondary if needed
        FlyCheat.SecondaryFlight()
        
        -- Tertiary as backup
        FlyCheat.TertiaryFlight()
        
        -- Advanced camera-following for smoothness
        FlyCheat.AdvancedFlight()
        
        -- Maintain upward velocity continuously
        local Character = FlyCheat.GetCharacter()
        if Character then
            local HumanoidRootPart = FlyCheat.GetHumanoidRootPart(Character)
            if HumanoidRootPart then
                -- Apply slight upward boost to counter gravity
                HumanoidRootPart.Velocity = Vector3.new(0, Config.FlySpeed * 1.2, 0)
            end
        end
        
        FlyCheat.Wait(0.1)  -- Update every 100ms for smooth flight
    end
end

-- Manual Flight Toggle Function
function FlyCheat.ToggleFlight()
    print("[FLY CHEAT] Flight Toggled!")
    
    local Character = FlyCheat.GetCharacter()
    if not Character then
        return false
    end
    
    local HumanoidRootPart = FlyCheat.GetHumanoidRootPart(Character)
    if not HumanoidRootPart then
        return false
    end
    
    -- Toggle flight state
    FlyCheat.Flying = not FlyCheat.Flying
    
    if FlyCheat.Flying then
        print("[FLY CHEAT] Flight ENABLED!")
        
        -- Apply upward velocity when flying is enabled
        local UpwardVelocity = Vector3.new(0, Config.FlySpeed * 1.5, 0)
        HumanoidRootPart.Velocity = HumanoidRootPart.Velocity + UpwardVelocity
        
        -- Set gravity scale for lighter feel
        if Humanoid then
            Humanoid.WalkSpeed = Config.FlySpeed * 10
        end
    else
        print("[FLY CHEAT] Flight DISABLED!")
        
        -- Reset to normal velocity when flight is disabled
        local CurrentVelocity = HumanoidRootPart.Velocity
        HumanoidRootPart.Velocity = Vector3.new(
            CurrentVelocity.X, 
            0, 
            CurrentVelocity.Z
        )
    end
    
    return FlyCheat.Flying
end

-- Debug Flight Function (For testing and fine-tuning)
function FlyCheat.DebugFlight()
    print("[FLY CHEAT] Debug Mode Enabled!")
    
    local Character = FlyCheat.GetCharacter()
    if not Character then
        return false
    end
    
    local HumanoidRootPart = FlyCheat.GetHumanoidRootPart(Character)
    if not HumanoidRootPart then
        return false
    end
    
    -- Show debug information in console
    print("[DEBUG] Current Position: " .. HumanoidRootPart.Position.X .. ", " .. HumanoidRootPart.Position.Y .. ", " .. HumanoidRootPart.Position.Z)
    print("[DEBUG] Current CFrame: " .. tostring(HumanoidRootPart.CFrame))
    print("[DEBUG] Current Velocity: " .. tostring(HumanoidRootPart.Velocity))
    
    -- Show camera position for reference
    local Camera = workspace.CurrentCamera
    if Camera then
        print("[DEBUG] Camera Position: " .. tostring(Camera.CFrame.Position))
    end
    
    return true
end

-- Main Execution (Run this in Delta Executor's LocalScript)
print("[FLY CHEAT] === UNIVERSAL FLY CHEAT LOADED ===")
print("[FLY CHEAT] Version: 3.0 | Type: Universal Flight | Platform: Roblox")
print("[FLY CHEAT] Author: AI Expert System")
print("[FLY CHEAT] ==========================================")

-- Initialize flight system with multiple methods for maximum compatibility
FlyCheat.PrimaryFlight()
FlyCheat.SecondaryFlight()
FlyCheat.TertiaryFlight()
FlyCheat.AdvancedFlight()

-- Start auto-flight if enabled (uncomment to enable continuous flight)
if Config.AutoFly then
    FlyCheat.AutoFlight()
else
    print("[FLY CHEAT] Manual Flight Mode - Use ToggleFlight() or Auto-Clicker for movement")
end

print("[FLY CHEAT] === FLY CHEAT ACTIVE - CHECK YOUR CHARACTER FOR FLIGHT! ===")

-- Optional: Uncomment to enable debug mode (shows position/velocity in console)
-- FlyCheat.DebugFlight()

-- Optional: Uncomment to enable instant fly (faster but may be less smooth)
-- Config.InstantFly = true