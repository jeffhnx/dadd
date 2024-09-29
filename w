-- Variables
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = game.Workspace.CurrentCamera
local espEnabled = false -- ESP starts off
local highlightObjects = {}
local targetPlayerToAim = nil -- The player you want to aim at
local aimbotEnabled = false -- Aimbot tracking status

-- Function to create a rainbow effect
local function getRainbowColor(t)
    local r = math.sin(t) * 0.5 + 0.5
    local g = math.sin(t + 2 * math.pi / 3) * 0.5 + 0.5
    local b = math.sin(t + 4 * math.pi / 3) * 0.5 + 0.5
    return Color3.new(r, g, b)
end

-- Function to create or update the highlight object (ESP)
local function highlightPlayer(targetPlayer)
    if not highlightObjects[targetPlayer.Name] then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = targetPlayer.Character
        highlight.FillTransparency = 0.5 -- Semi-transparent glow
        highlight.OutlineTransparency = 0 -- Visible outline
        highlightObjects[targetPlayer.Name] = highlight
        highlight.Parent = targetPlayer.Character
        
        -- Create ESP box
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        box.Size = targetPlayer.Character:GetExtentsSize() + Vector3.new(0.5, 0.5, 0.5) -- Slightly larger than the player
        box.Color3 = Color3.new(1, 0, 0) -- Color of the box (red)
        box.Transparency = 0.5 -- Semi-transparent box
        box.ZIndex = 10 -- Render priority
        box.Parent = targetPlayer.Character
    end
end

-- Function to update ESP colors (rainbow glow effect)
local function updateESPColors()
    local t = tick()
    for _, highlight in pairs(highlightObjects) do
        if highlight and highlight.Parent then
            highlight.FillColor = getRainbowColor(t)
            highlight.OutlineColor = getRainbowColor(t + 0.5)
        end
    end
end

-- Function to aim at a specific player's head
local function aimAtPlayerHead(targetPlayer)
    if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local targetHead = targetPlayer.Character.Head
        -- Raycast to check if there's a direct line of sight (no walls in the way)
        local origin = camera.CFrame.Position
        local direction = (targetHead.Position - origin).unit * (targetHead.Position - origin).magnitude
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {player.Character} -- Ignore local player's character

        local result = game.Workspace:Raycast(origin, direction, raycastParams)
        if result and result.Instance:IsDescendantOf(targetPlayer.Character) then
            camera.CFrame = CFrame.new(camera.CFrame.Position, targetHead.Position) -- Aim at the target head
        end
    end
end

-- Toggle ESP on/off with "E"
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent then
        if input.KeyCode == Enum.KeyCode.E then
            espEnabled = not espEnabled
            if espEnabled then
                -- Highlight all players for ESP
                local players = game.Players:GetPlayers()
                for _, targetPlayer in pairs(players) do
                    if targetPlayer ~= player and targetPlayer.Character then
                        highlightPlayer(targetPlayer)
                    end
                end
            else
                -- Clear highlights
                for _, highlight in pairs(highlightObjects) do
                    if highlight then
                        highlight:Destroy()
                    end
                end
                highlightObjects = {}
            end
        end
    end
end)

-- Detect holding right-click for aimbot (track player head)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimbotEnabled = true -- Enable aimbot (tracking starts)
        end
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotEnabled = false -- Disable aimbot (tracking stops)
        targetPlayerToAim = nil -- Clear target
    end
end)

-- Update ESP and aimbot every frame
game:GetService("RunService").RenderStepped:Connect(function()
    -- Update ESP colors
    if espEnabled then
        updateESPColors()
    end

    -- Aim at the specified player's head
    if aimbotEnabled then
        local players = game.Players:GetPlayers()
        for _, target in ipairs(players) do
            if target ~= player and target.Character and target.Character:FindFirstChild("Head") then
                aimAtPlayerHead(target) -- Aim at each player's head
            end
        end
    end
end)
