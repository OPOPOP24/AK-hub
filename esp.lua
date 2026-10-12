-- ============================================
-- ESP SYSTEM
-- Key: IRUEGDJDJD
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Camera = Workspace.CurrentCamera
if not Camera then
    repeat task.wait() Camera = Workspace.CurrentCamera until Camera
end

local SECRET_KEY = "IRUEGDJDJD"
local keyVerified = false

local ESP_TRANS         = 0.3
local ESP_OUTLINE_TRANS = 0
local CACHE_TTL         = 8

local GUN_KEYWORDS = {"gun", "pistol", "revolver", "handgun"}

local Config = {
    ESPEnabled = false,
    ESPName = false,
    ESPRole = false,
    ESPDistance = false,
}

local ESPObjects = {}
local roleCache = {}
local watchedChars = {}
local watchedPlayers = {}

local ROLE_COLOR = {
    murder    = Color3.fromRGB(255, 60, 60),
    sheriff   = Color3.fromRGB(60, 120, 255),
    detective = Color3.fromRGB(160, 110, 60),
    citizen   = Color3.fromRGB(80, 220, 80),
}

local function hasKnife(c)
    if not c then return false end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if n:find("knife") or n:find("dagger") or n:find("blade") then
                return true
            end
        end
    end
    return false
end

local function hasGunTool(c, b)
    local function chk(x)
        if not x then return false end
        for _, t in ipairs(x:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                for _, kw in ipairs(GUN_KEYWORDS) do
                    if n:find(kw) then return true end
                end
            end
        end
        return false
    end
    return chk(c) or chk(b)
end

local function hasDet(c, b)
    local function chk(x)
        if not x then return false end
        for _, t in ipairs(x:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("detective") or n:find("magnif") or n:find("camera") then
                    return true
                end
            end
        end
        return false
    end
    return chk(c) or chk(b)
end

local function getRoleLive(plr)
    local c = plr.Character
    if not c then return "citizen" end
    local b = plr:FindFirstChildOfClass("Backpack")
    if hasKnife(c) or hasKnife(b) then return "murder" end
    if hasDet(c, b) then return "detective" end
    if hasGunTool(c, b) then return "sheriff" end
    return "citizen"
end

local function updateCache(plr)
    local r = getRoleLive(plr)
    if r ~= "citizen" then
        roleCache[plr] = { role = r, time = tick() }
    end
end

local function getCachedRole(plr)
    local data = roleCache[plr]
    if not data then return nil end
    if tick() - data.time > CACHE_TTL then
        roleCache[plr] = nil
        return nil
    end
    return data.role
end

local function getRole(plr)
    return getRoleLive(plr)
end

local function getRoleColor(plr)
    local r = getRole(plr)
    return ROLE_COLOR[r] or Color3.fromRGB(255, 255, 255)
end

local function getRoleText(plr)
    local r = getRole(plr)
    if r == "murder" then return "Murderer"
    elseif r == "sheriff" then return "Sheriff"
    elseif r == "detective" then return "Detective"
    else return "Citizen" end
end

local function createESP(plr)
    if not keyVerified or not Config.ESPEnabled then return end
    if ESPObjects[plr] then
        pcall(function() ESPObjects[plr].folder:Destroy() end)
        ESPObjects[plr] = nil
    end
    local c = plr.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local head = c:FindFirstChild("Head")
    if not hrp then return end

    local color = getRoleColor(plr)

    local folder = Instance.new("Folder")
    folder.Name = "ESPSystem"
    folder.Parent = Workspace

    local hl = Instance.new("Highlight")
    hl.Adornee = c
    hl.FillColor = color
    hl.FillTransparency = ESP_TRANS
    hl.OutlineColor = color
    hl.OutlineTransparency = ESP_OUTLINE_TRANS
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = folder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 60)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = head or hrp
    bb.Parent = folder

    local rl = Instance.new("TextLabel")
    rl.Size = UDim2.new(1, 0, 0, 22)
    rl.BackgroundTransparency = 1
    rl.Text = getRoleText(plr)
    rl.TextColor3 = color
    rl.TextStrokeTransparency = 0
    rl.TextStrokeColor3 = Color3.new()
    rl.Font = Enum.Font.GothamBlack
    rl.TextSize = 16
    rl.Parent = bb

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, 0, 0, 18)
    nl.Position = UDim2.new(0, 0, 0, 22)
    nl.BackgroundTransparency = 1
    nl.Text = plr.Name
    nl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nl.TextStrokeTransparency = 0
    nl.TextStrokeColor3 = Color3.new()
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 13
    nl.Parent = bb

    local dl = Instance.new("TextLabel")
    dl.Size = UDim2.new(1, 0, 0, 16)
    dl.Position = UDim2.new(0, 0, 0, 40)
    dl.BackgroundTransparency = 1
    dl.Text = "0m"
    dl.TextColor3 = Color3.fromRGB(255, 255, 255)
    dl.TextStrokeTransparency = 0
    dl.TextStrokeColor3 = Color3.new()
    dl.Font = Enum.Font.Gotham
    dl.TextSize = 12
    dl.Parent = bb

    ESPObjects[plr] = {folder=folder, hl=hl, bb=bb, rl=rl, nl=nl, dl=dl}
end

local function removeESP(plr)
    if ESPObjects[plr] then
        pcall(function() ESPObjects[plr].folder:Destroy() end)
        ESPObjects[plr] = nil
    end
end

local lastESPUpdate = 0
local function updateESP()
    if not keyVerified or not Config.ESPEnabled then return end
    local now = tick()
    if now - lastESPUpdate < 0.1 then return end
    lastESPUpdate = now

    local camPos = Camera.CFrame.Position
    for plr, d in pairs(ESPObjects) do
        if not d.folder or not d.folder.Parent then
            ESPObjects[plr] = nil
            continue
        end
        local c = plr.Character
        if not c then
            d.hl.Enabled = false
            d.bb.Enabled = false
            continue
        end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then
            d.hl.Enabled = false
            d.bb.Enabled = false
            continue
        end
        d.hl.Enabled = true
        d.bb.Enabled = true
        local color = getRoleColor(plr)
        d.hl.FillColor = color
        d.hl.FillTransparency = ESP_TRANS
        d.hl.OutlineColor = color
        if d.hl.Adornee ~= c then d.hl.Adornee = c end

        d.rl.Visible = Config.ESPRole
        d.rl.Text = getRoleText(plr)
        d.rl.TextColor3 = color
        d.nl.Visible = Config.ESPName
        d.nl.Text = plr.Name
        d.dl.Visible = Config.ESPDistance
        d.dl.Text = math.floor((camPos - hrp.Position).Magnitude) .. "m"
    end
end

local function watchCharacter(plr)
    if plr == LocalPlayer then return end

    local function bindCharacter(char)
        if not char then return end
        if watchedChars[char] then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if not hum then
            task.wait(0.3)
            hum = char:FindFirstChildWhichIsA("Humanoid")
            if not hum then return end
        end
        watchedChars[char] = true

        roleCache[plr] = nil

        task.spawn(function()
            for i = 1, 10 do
                task.wait(0.3)
                if not char.Parent or hum.Health <= 0 then break end
                updateCache(plr)
                local cached = getCachedRole(plr)
                if cached == "sheriff" then
                    task.wait(1)
                    updateCache(plr)
                end
            end
        end)

        local function onToolChange(ch)
            if ch:IsA("Tool") then
                task.wait(0.1)
                updateCache(plr)
            end
        end
        char.ChildAdded:Connect(onToolChange)
        char.ChildRemoved:Connect(onToolChange)

        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp then
            bp.ChildAdded:Connect(onToolChange)
            bp.ChildRemoved:Connect(onToolChange)
        end

        task.spawn(function()
            while char.Parent and hum.Health > 0 do
                task.wait(1.5)
                updateCache(plr)
            end
        end)
    end

    if plr.Character then
        task.spawn(bindCharacter, plr.Character)
    end

    if not watchedPlayers[plr] then
        watchedPlayers[plr] = true
        plr.CharacterAdded:Connect(function(char)
            task.wait(0.4)
            bindCharacter(char)
            if keyVerified and Config.ESPEnabled then
                createESP(plr)
            end
        end)
    end
end

local function createKeySystem()
    local old = LocalPlayer.PlayerGui:FindFirstChild("ESPKeyUI")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ESPKeyUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 260, 0, 150)
    frame.Position = UDim2.new(0.5, -130, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local fs = Instance.new("UIStroke", frame) fs.Color = Color3.fromRGB(60, 60, 65) fs.Thickness = 1

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
    title.Text = "ESP SYSTEM"
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(1, -24, 0, 34)
    input.Position = UDim2.new(0, 12, 0, 45)
    input.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    input.Text = ""
    input.PlaceholderText = "Key"
    input.TextColor3 = Color3.fromRGB(240, 240, 240)
    input.PlaceholderColor3 = Color3.fromRGB(100, 100, 105)
    input.Font = Enum.Font.Gotham
    input.TextSize = 12
    input.ClearTextOnFocus = false
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -24, 0, 34)
    btn.Position = UDim2.new(0, 12, 0, 88)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.Text = "Confirm"
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1, -24, 0, 18)
    status.Position = UDim2.new(0, 12, 0, 127)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(200, 80, 80)
    status.Font = Enum.Font.Gotham
    status.TextSize = 10

    local function tryUnlock()
        if input.Text == SECRET_KEY then
            status.Text = "OK"
            status.TextColor3 = Color3.fromRGB(100, 220, 120)
            task.wait(0.4)

            keyVerified = true
            gui.Enabled = false

            for _, plr in ipairs(Players:GetPlayers()) do
                watchCharacter(plr)
            end

            if _G.createESPUI then _G.createESPUI() end
        else
            status.Text = "Wrong key"
            status.TextColor3 = Color3.fromRGB(200, 80, 80)
            local o = frame.Position
            for i = 1, 3 do
                frame.Position = o + UDim2.new(0, 6, 0, 0)
                task.wait(0.05)
                frame.Position = o - UDim2.new(0, 6, 0, 0)
                task.wait(0.05)
            end
            frame.Position = o
            input.Text = ""
        end
    end

    btn.MouseButton1Click:Connect(tryUnlock)
    input.FocusLost:Connect(function(e) if e then tryUnlock() end end)
end

local function createESPUI()
    local old = LocalPlayer.PlayerGui:FindFirstChild("ESPHub")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ESPHub"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local icon = Instance.new("TextButton", gui)
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(1, -55, 0, 130)
    icon.Text = "E"
    icon.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 18
    icon.BorderSizePixel = 0
    icon.Draggable = true
    Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
    local is = Instance.new("UIStroke", icon) is.Color = Color3.fromRGB(60, 60, 65) is.Thickness = 1

    local W, H = 200, 170
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, W, 0, H)
    frame.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Active = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local fs = Instance.new("UIStroke", frame) fs.Color = Color3.fromRGB(60, 60, 65) fs.Thickness = 1

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 26)
    title.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
    title.Text = "ESP SYSTEM"
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -24, 0, 3)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 10
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

    local content = Instance.new("Frame", frame)
    content.Size = UDim2.new(1, -14, 1, -34)
    content.Position = UDim2.new(0, 7, 0, 30)
    content.BackgroundTransparency = 1
    local cl = Instance.new("UIListLayout", content)
    cl.FillDirection = Enum.FillDirection.Vertical
    cl.Padding = UDim.new(0, 4)
    cl.SortOrder = Enum.SortOrder.LayoutOrder

    local function makeTog(p, text, def, cb)
        local on = def
        local b = Instance.new("TextButton", p)
        b.Size = UDim2.new(1, 0, 0, 26)
        b.BackgroundColor3 = on and Color3.fromRGB(45, 45, 50) or Color3.fromRGB(25, 25, 28)
        b.Text = text
        b.TextColor3 = on and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(140, 140, 145)
        b.Font = Enum.Font.Gotham
        b.TextSize = 11
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        local st = Instance.new("UIStroke", b)
        st.Color = on and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(40, 40, 45)
        st.Thickness = 1

        b.MouseButton1Click:Connect(function()
            on = not on
            b.BackgroundColor3 = on and Color3.fromRGB(45, 45, 50) or Color3.fromRGB(25, 25, 28)
            b.TextColor3 = on and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(140, 140, 145)
            st.Color = on and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(40, 40, 45)
            cb(on)
        end)
    end

    makeTog(content, "ESP", false, function(v)
        Config.ESPEnabled = v
        if v and keyVerified then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then createESP(plr) end
            end
        else
            for plr, _ in pairs(ESPObjects) do removeESP(plr) end
        end
    end)
    makeTog(content, "Role", false, function(v) Config.ESPRole = v end)
    makeTog(content, "Name", false, function(v) Config.ESPName = v end)
    makeTog(content, "Distance", false, function(v) Config.ESPDistance = v end)

    icon.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)
    closeBtn.MouseButton1Click:Connect(function() frame.Visible = false end)
end

_G.createESPUI = createESPUI

Players.PlayerAdded:Connect(function(plr)
    if keyVerified then
        watchCharacter(plr)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
    roleCache[plr] = nil
    watchedPlayers[plr] = nil
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        if keyVerified and Config.ESPEnabled then
            updateESP()
        end
    end)
end)

task.spawn(function()
    repeat task.wait(0.5) until keyVerified
    for _, plr in ipairs(Players:GetPlayers()) do
        watchCharacter(plr)
        if plr.Character and plr ~= LocalPlayer and Config.ESPEnabled then
            createESP(plr)
        end
    end
end)

task.wait(1)
createKeySystem()

print("ESP System loaded")
