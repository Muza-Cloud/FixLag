-- | made by m7za | --

-- | services | --
local Players    = game:GetService("Players")
local Lighting   = game:GetService("Lighting")
local Workspace  = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- | engine & graphics | --
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
pcall(function() settings().Network.IncomingReplicationLag = 0 end)
pcall(function() settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Throttle30Hz end)

-- | skybox & lighting | --
local SKY_IDS = {
    Bk = "rbxassetid://92959017845968", Ft = "rbxassetid://129304841254693",
    Lf = "rbxassetid://129249062260004", Rt = "rbxassetid://117319232583147",
    Up = "rbxassetid://121193772599100", Dn = "rbxassetid://115022734343595"
}

local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
for side, id in pairs(SKY_IDS) do 
    pcall(function() sky["Skybox" .. side] = id end)
end

pcall(function()
    sky.SunAngularSize = 0
    sky.MoonAngularSize = 0
    sky.CelestialBodiesShown = false
end)

pcall(function()
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = false
    Lighting.Brightness = 0.8
    Lighting.ExposureCompensation = -0.2
    Lighting.FogStart, Lighting.FogEnd = 9e9, 9e9
end)

local function cleanLightingChild(v)
    pcall(function()
        if v:IsA("PostEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BlurEffect") then
            v.Enabled = false
        elseif v:IsA("Atmosphere") then
            v.Density, v.Haze, v.Glare = 0, 0, 0
        elseif v:IsA("Sky") and v ~= sky then
            v:Destroy()
        end
    end)
end

for _, v in ipairs(Lighting:GetChildren()) do cleanLightingChild(v) end
Lighting.ChildAdded:Connect(cleanLightingChild)

-- | thrown & debris | --
local function clearThrownFolder()
    local thrown = Workspace:FindFirstChild("Thrown")
    if thrown then
        for _, child in ipairs(thrown:GetChildren()) do
            pcall(function() child:Destroy() end)
        end
        thrown.ChildAdded:Connect(function(child)
            task.defer(function()
                pcall(function() child:Destroy() end)
            end)
        end)
    end
end
clearThrownFolder()

-- | tree cleanUp | --
local function clearTrees()
    task.spawn(function()
        local map = Workspace:WaitForChild("Map", 5) or Workspace:FindFirstChild("Map")
        if map then
            for _, child in ipairs(map:GetChildren()) do
                if child.Name:lower():find("tree") then
                    pcall(function() child:Destroy() end)
                end
            end
            map.ChildAdded:Connect(function(child)
                if child.Name:lower():find("tree") then
                    task.defer(function()
                        pcall(function() child:Destroy() end)
                    end)
                end
            end)
        end
    end)
end
clearTrees()

-- | world object optimization | --
local function optimizeObject(v)
    if not v or not v.Parent or not v:IsDescendantOf(game) then return end

    pcall(function()
        local parent = v.Parent
        if not parent then return end

        -- | remove trees | --
        if parent.Name == "Map" and v.Name:lower():find("tree") then
            v:Destroy()
            return
        end

        -- | skip sub-objects | --
        local thrown = Workspace:FindFirstChild("Thrown")
        if (thrown and v:IsDescendantOf(thrown)) or parent.Name:lower():find("tree") then
            return
        end

        -- | remove debris | --
        if v.Name:lower():find("debris") then
            v:Destroy()
            return
        end

        -- | basepart optimization | --
        if v:IsA("BasePart") then
            v.CastShadow = false
            local char = LocalPlayer.Character
            if not (char and v:IsDescendantOf(char)) then
                v.CanTouch = false
                v.CanQuery = false
            end
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("SurfaceAppearance") then
            v:Destroy()
        elseif v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Fire") or v:IsA("Clouds") then
            v.Enabled = false
        end
    end)
end

task.spawn(function()
    local descendants = Workspace:GetDescendants()
    for i = 1, #descendants do
        optimizeObject(descendants[i])
        if i % 500 == 0 then task.wait() end
    end
end)

Workspace.DescendantAdded:Connect(function(v)
    task.defer(function()
        optimizeObject(v)
    end)
end)

-- | character effects cleanUp | --
local function applyCharacterEffects(char)
    if not char then return end
    local function hideEffect(v)
        pcall(function()
            if v:IsA("Trail") or v:IsA("ParticleEmitter") then
                v.Enabled = false
            end
        end)
    end
    for _, v in ipairs(char:GetDescendants()) do hideEffect(v) end
    char.DescendantAdded:Connect(function(v)
        task.defer(function() hideEffect(v) end)
    end)
end

if LocalPlayer.Character then applyCharacterEffects(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(applyCharacterEffects)

-- | fps & ping | --
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("FPSPingCounter") then 
    pcall(function() playerGui.FPSPingCounter:Destroy() end)
end

local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "FPSPingCounter"
screenGui.ResetOnSpawn = false

local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 300, 0, 30)
label.Position = UDim2.new(0.5, 0, 0, 10)
label.AnchorPoint = Vector2.new(0.5, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.Code
label.TextSize = 16
label.TextStrokeTransparency = 0.4

local fps, ping, lastTime = 60, 0, tick()
RunService.RenderStepped:Connect(function()
    local now = tick()
    local curFPS = 1 / math.max(now - lastTime, 0.0001)
    lastTime = now
    fps = fps + (curFPS - fps) * 0.1

    pcall(function() ping = LocalPlayer:GetNetworkPing() * 1000 end)

    label.Text = string.format("FPS: %d | PING: %d ms", math.floor(fps), math.floor(ping))
    label.TextColor3 = Color3.fromHSV((now * 0.4) % 1, 0.8, 1)
end)

-- | disable camera shake | --
if getrawmetatable and setreadonly then
    pcall(function()
        local meta = getrawmetatable(game)
        local oldIndex = meta.__index
        setreadonly(meta, false)
        meta.__index = newcclosure(function(obj, key)
            if key == "CamShakeCF" and obj == _G then return CFrame.new() end
            if key == "CameraOffset" and obj:IsA("Humanoid") then return Vector3.new(0, 0, 0) end
            return oldIndex(obj, key)
        end)
        setreadonly(meta, true)
    end)
end
