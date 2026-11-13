-- ==========================================
-- ROBLOX MOBILE FLY CHEAT (Android/iOS)
-- ==========================================
-- Features: Touch-based controls, smooth flight, auto-rotate, boost system
-- Compatible with most Roblox games on mobile devices
-- ==========================================

local flyCheat = {}
flyCheat.isFlying = false
flyCheat.autoRotate = true
flyCheat.baseSpeed = 50
flyCheat.maxForce = 400000
flyCheat.stiffness = 15000
flyCheat.damping = 20

-- Touch input tracking
local touchStartPos = Vector3.new(0, 0, 0)
local touchEndPos = Vector3.new(0, 0, 0)
local isTouching = false
local touchStartTime = 0
local lastTouchTime = 0

-- Movement vectors
local moveX = 0
local moveY = 0
local moveZ = 0

-- Speed multipliers
local currentSpeedMultiplier = 1.0
local boostActive = false

-- ==========================================
-- INITIALIZATION
-- ==========================================
local function initFlyCheat()
    -- Wait for character to load
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Create a hidden LocalScript container
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Store original properties
    flyCheat.rootPart = rootPart
    flyCheat.humanoid = character.Humanoid
    
    -- Create invisible touch controller for mobile
    local touchController = Instance.new("LocalScript")
    touchController.Name = "FlyTouchController"
    touchController.Parent = player
    
    -- ==========================================
    -- TOUCH INPUT HANDLING (Mobile Controls)
    -- ==========================================
    
    -- Touch Start: Record starting position and time
    touchController.OnTouchBegan = function()
        isTouching = true
        touchStartPos = touchController.Position
        touchStartTime = tick()
        lastTouchTime = 0
        
        -- Visual feedback (optional)
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FlyIndicator"
        screenGui.Parent = player:WaitForChild("PlayerGui")
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(0.1, 0.1)
        frame.Position = UDim2.fromScale(0.5, 0.9)
        frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        frame.Parent = screenGui
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.Text = "TOUCH & DRAG TO FLY"
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.BackgroundTransparency = 0.8
        textLabel.Parent = frame
        
        flyCheat.isFlying = true
    end
    
    -- Touch Moved: Calculate movement direction and distance
    touchController.OnTouchMoved = function()
        if not isTouching then return end
        
        local currentTime = tick()
        
        -- Calculate delta time for smooth movement
        local deltaTime = currentTime - lastTouchTime
        lastTouchTime = currentTime
        
        -- Calculate movement vector based on touch displacement
        local deltaX = (touchController.Position.X - touchStartPos.X) * 0.15
        local deltaY = (touchController.Position.Y - touchStartPos.Y) * 0.15
        
        -- Convert to 3D movement vectors
        moveX = math.clamp(deltaX, -2, 2)
        moveY = math.clamp(deltaY, -2, 2)
        
        -- Calculate vertical movement (up/down based on touch Y position)
        local touchHeight = (touchController.Position.Y - touchStartPos.Y) * 0.1
        moveZ = math.clamp(touchHeight, -3, 3)
    end
    
    -- Touch Ended: Reset and handle boost/stop
    touchController.OnTouchEnded = function()
        isTouching = false
        
        -- Calculate total touch duration for boost detection
        local touchDuration = tick() - touchStartTime
        
        -- Long press = boost (hold for 0.5+ seconds)
        if touchDuration >= 0.5 then
            currentSpeedMultiplier = math.min(currentSpeedMultiplier + 0.2, 3.0)
            boostActive = true
            
            -- Visual feedback
            local screenGui = player:WaitForChild("PlayerGui")
            local frame = screenGui:FindFirstChild("FlyIndicator")
            if frame then
                frame.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            end
        else
            -- Short tap = normal speed
            currentSpeedMultiplier = math.max(currentSpeedMultiplier - 0.1, 0.5)
            boostActive = false
            
            local screenGui = player:WaitForChild("PlayerGui")
            local frame = screenGui:FindFirstChild("FlyIndicator")
            if frame then
                frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
        end
        
        -- Reset movement vectors
        moveX = 0
        moveY = 0
        moveZ = 0
    end
    
    -- ==========================================
    -- FLYING MECHANICS (BodyPosition + BodyGyro)
    -- ==========================================
    
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.Name = "FlyBodyPosition"
    bodyPosition.Parent = rootPart
    
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyBodyGyro"
    bodyGyro.Parent = rootPart
    
    -- ==========================================
    -- MAIN FLY LOOP
    -- ==========================================
    
    local function flyLoop()
        if not flyCheat.isFlying then return end
        
        -- Calculate target position based on touch input
        local targetPosition = rootPart.CFrame * CFrame.new(0, 0, 0)
        
        -- Apply horizontal movement (X and Y axes)
        if moveX ~= 0 or moveY ~= 0 then
            local forwardVector = rootPart.CFrame.LookVector
            local rightVector = rootPart.CFrame.RightVector
            
            -- Calculate new position based on touch input
            targetPosition = CFrame.new(
                rootPart.Position.X + (forwardVector.X * moveX * currentSpeedMultiplier),
                rootPart.Position.Y,
                rootPart.Position.Z + (forwardVector.Z * moveX * currentSpeedMultiplier)
            )
            
            -- Add vertical movement from touch Y position
            targetPosition = CFrame.new(
                targetPosition.X,
                rootPart.Position.Y + (moveY * 0.5 * currentSpeedMultiplier),
                targetPosition.Z
            )
        end
        
        -- Apply smooth flight using BodyPosition
        bodyPosition.Position = targetPosition
        bodyPosition.Velocity = Vector3.new(0, 0, 0)
        bodyPosition.Stiffness = flyCheat.stiffness
        bodyPosition.MaxForce = Vector3.new(flyCheat.maxForce, flyCheat.maxForce, flyCheat.maxForce)
        
        -- Apply auto-rotation if enabled
        if flyCheat.autoRotate then
            local targetOrientation = rootPart.CFrame * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), 0)
            
            -- Calculate rotation based on movement direction
            if moveX ~= 0 or moveY ~= 0 or moveZ ~= 0 then
                local movementVector = Vector3.new(moveX, moveY, moveZ).Unit
                
                -- Rotate to face movement direction (with some offset for better control)
                local rotationOffset = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(-45))
                
                targetOrientation = rootPart.CFrame * CFrame.lookAt(rootPart.Position, rootPart.Position + movementVector * 20) * rotationOffset
            end
            
            bodyGyro.CFrame = targetOrientation
            bodyGyro.P = flyCheat.stiffness
            bodyGyro.MaxTorque = Vector3.new(flyCheat.maxForce, flyCheat.maxForce, flyCheat.maxForce)
        else
            -- Manual rotation (face camera direction)
            local camera = game.Players.LocalPlayer.Camera
            if camera then
                local lookAtPos = rootPart.Position + camera.CFrame.LookVector * 50
                bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, lookAtPos)
            end
            
            bodyGyro.P = flyCheat.stiffness
            bodyGyro.MaxTorque = Vector3.new(flyCheat.maxForce, flyCheat.maxForce, flyCheat.maxForce)
        end
        
        -- Apply damping for smooth movement
        rootPart.Velocity = rootPart.Velocity * (1 - (flyCheat.damping / 1000))
        
        wait(0.05) -- 20 FPS for mobile performance
    end
    
    -- ==========================================
    -- TOUCH CONTROLS UI (On-Screen Buttons)
    -- ==========================================
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlyControls"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Create touch-sensitive frame for movement
    local touchFrame = Instance.new("Frame")
    touchFrame.Size = UDim2.fromScale(0.8, 0.6)
    touchFrame.Position = UDim2.fromScale(0.1, 0.1)
    touchFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    touchFrame.BackgroundTransparency = 0.5
    touchFrame.Parent = screenGui
    
    -- Add touch detection to the frame
    local function onTouch(frame, action)
        if action == "Began" then
            isTouching = true
            touchStartPos = frame.Position
            lastTouchTime = tick()
        elseif action == "Moved" then
            if isTouching then
                local deltaX = (frame.Position.X - touchStartPos.X) * 0.15
                local deltaY = (frame.Position.Y - touchStartPos.Y) * 0.15
                
                moveX = math.clamp(deltaX, -2, 2)
                moveY = math.clamp(deltaY, -2, 2)
                
                local touchHeight = (frame.Position.Y - touchStartPos.Y) * 0.1
                moveZ = math.clamp(touchHeight, -3, 3)
            end
        elseif action == "Ended" then
            isTouching = false
            
            -- Calculate touch duration for boost
            local touchDuration = tick() - lastTouchTime
            if touchDuration >= 0.5 then
                currentSpeedMultiplier = math.min(currentSpeedMultiplier + 0.2, 3.0)
                boostActive = true
            else
                currentSpeedMultiplier = math.max(currentSpeedMultiplier - 0.1, 0.5)
                boostActive = false
            end
            
            moveX = 0
            moveY = 0
            moveZ = 0
        end
    end
    
    touchFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            onTouch(touchFrame, "Began")
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            onTouch(touchFrame, "Began")
        end
    end)
    
    touchFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            onTouch(touchFrame, "Moved")
        end
    end)
    
    touchFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            onTouch(touchFrame, "Ended")
        end
    end)
    
    -- ==========================================
    -- VISUAL INDICATORS
    -- ==========================================
    
    local indicatorGui = Instance.new("ScreenGui")
    indicatorGui.Name = "FlyIndicator"
    indicatorGui.Parent = player:WaitForChild("PlayerGui")
    
    local indicatorFrame = Instance.new("Frame")
    indicatorFrame.Size = UDim2.fromScale(0.1, 0.1)
    indicatorFrame.Position = UDim2.fromScale(0.5, 0.9)
    indicatorFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    indicatorFrame.Parent = indicatorGui
    
    local indicatorText = Instance.new("TextLabel")
    indicatorText.Size = UDim2.fromScale(1, 1)
    indicatorText.Text = "FLYING"
    indicatorText.TextColor3 = Color3.fromRGB(255, 255, 255)
    indicatorText.BackgroundTransparency = 0.8
    indicatorText.Parent = indicatorFrame
    
    -- ==========================================
    -- CLEANUP ON CHARACTER CHANGE
    -- ==========================================
    
    local function cleanup()
        if flyCheat.rootPart then
            for _, child in ipairs(flyCheat.rootPart:GetChildren()) do
                if child:IsA("BodyPosition") or child:IsA("BodyGyro") then
                    child:Destroy()
                end
            end
            
            -- Destroy touch controller
            local controller = flyCheat.rootPart.Parent:FindFirstChild("FlyTouchController")
            if controller then controller:Destroy() end
            
            -- Destroy UI elements
            for _, gui in ipairs(player:GetGuiObjects()) do
                if gui.Name == "FlyControls" or gui.Name == "FlyIndicator" then
                    gui:Destroy()
                end
            end
        end
        
        flyCheat.isFlying = false
    end
    
    -- ==========================================
    -- MAIN LOOP
    -- ==========================================
    
    local function mainLoop()
        if flyCheat.isFlying and flyCheat.rootPart then
            flyLoop()
        else
            cleanup()
        end
        
        wait(0.05)
    end
    
    -- Start the main loop
    game:GetService("RunService").Heartbeat:Connect(mainLoop)
    
    print("[Fly Cheat Mobile] Initialized successfully!")
    print("[Fly Cheat Mobile] Touch & drag to fly")
    print("[Fly Cheat Mobile] Long press for boost (0.5s+)")
end

-- ==========================================
-- WAIT FOR CHARACTER AND START
-- ==========================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Initialize the fly cheat when character loads
character.ChildAdded:Connect(function(child)
    if child.Name == "HumanoidRootPart" then
        initFlyCheat()
    end
end)

-- Fallback: initialize immediately if HumanoidRootPart already exists
if character:FindFirstChild("HumanoidRootPart") then
    initFlyCheat()
end

print("[Fly Cheat Mobile] Ready! Touch & drag to fly.")