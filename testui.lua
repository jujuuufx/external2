-- Services 
local InputService  = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local GuiService    = game:GetService("GuiService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local Players       = game:GetService("Players")

local lp            = Players.LocalPlayer
local mouse         = lp:GetMouse()

-- Short aliases
local vec2          = Vector2.new
local dim2          = UDim2.new
local dim           = UDim.new
local rect          = Rect.new
local dim_offset    = UDim2.fromOffset
local rgb           = Color3.fromRGB
local hex           = Color3.fromHex

-- Modern Font Setup
local Fonts = {
    Bold = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold),
    Medium = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
    SemiBold = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
}

-- Library init / globals
getgenv().External = getgenv().External or {}
local External = getgenv().External

External.Directory    = "External_Loader"
External.Folders      = {"/configs"}
External.Flags        = {}
External.ConfigFlags  = {}
External.Connections  = {}
External.Notifications= {Notifs = {}}
External.__index      = External

local Flags          = External.Flags
local ConfigFlags    = External.ConfigFlags
local Notifications  = External.Notifications

-- Same exact color theme
local themes = {
    preset = {
        accent       = rgb(155, 89, 182),
        accent_light = rgb(180, 110, 200),
        background   = rgb(6, 6, 8),
        background_alt= rgb(10, 10, 14),
        section      = rgb(12, 12, 16),
        element      = rgb(18, 18, 24),
        element_hover= rgb(24, 24, 32),
        outline      = rgb(30, 30, 40),
        outline_bright= rgb(50, 50, 65),
        text         = rgb(240, 240, 245),
        subtext      = rgb(140, 140, 150),
        subtext_dim  = rgb(100, 100, 110),
        tab_active   = rgb(22, 22, 30),
        tab_inactive = rgb(12, 12, 16),
        success      = rgb(0, 255, 128),
        warning      = rgb(255, 180, 0),
        error        = rgb(255, 50, 80),
    },
    utility = {}
}

for property, _ in themes.preset do
    themes.utility[property] = {
        BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, Color = {}, ScrollBarImageColor3 = {}
    }
end

local Keys = {
    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC", [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2", [Enum.UserInputType.MouseButton3] = "MB3"
}

for _, path in External.Folders do
    pcall(function() makefolder(External.Directory .. path) end)
end

-- Optimized Helpers
function External:Tween(Object, Properties, Info)
    if not Object then return end
    local tweenInfo = Info or TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(Object, tweenInfo, Properties)
    tween:Play()
    return tween
end

function External:TrackConnection(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(External.Connections, conn)
    return conn
end

function External:DisconnectAll()
    for _, conn in ipairs(External.Connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(External.Connections)
end

function External:AddHoverEffect(button, hoverProps, normalProps)
    if not button then return end
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), hoverProps):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), normalProps or {}):Play()
    end)
end

function External:Create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do ins[prop] = value end
    if ins:IsA("TextButton") or ins:IsA("ImageButton") then ins.AutoButtonColor = false end
    return ins
end

function External:Themify(instance, theme, property)
    if not themes.utility[theme] then return end
    table.insert(themes.utility[theme][property], instance)
    instance[property] = themes.preset[theme]
end

function External:RefreshTheme(theme, color3)
    themes.preset[theme] = color3
    for property, instances in themes.utility[theme] do
        for _, object in instances do
            object[property] = color3
        end
    end
end

function External:Resizify(Parent)
    local UIS = game:GetService("UserInputService")
    local Resizing = External:Create("TextButton", {
        AnchorPoint = vec2(1, 1), Position = dim2(1, 0, 1, 0), Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1, Text = "", Parent = Parent, ZIndex = 999,
    })
    
    local grip = External:Create("ImageLabel", {
        Parent = Resizing, AnchorPoint = vec2(1, 1), Position = dim2(1, -4, 1, -4), Size = dim2(0, 12, 0, 12),
        BackgroundTransparency = 1, Image = "rbxthumb://type=Asset&id=110733736723338&w=150&h=150", ImageColor3 = themes.preset.subtext, ImageTransparency = 0.5
    })

    local IsResizing, StartInputPos, StartSize = false, nil, nil
    local MIN_SIZE = vec2(600, 400)

    Resizing.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = true; StartInputPos = input.Position; StartSize = Parent.AbsoluteSize
        end
    end)
    Resizing.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then IsResizing = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if IsResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - StartInputPos
            Parent.Size = UDim2.fromOffset(math.max(MIN_SIZE.X, StartSize.X + delta.X), math.max(MIN_SIZE.Y, StartSize.Y + delta.Y))
        end
    end)
end

-- window
function External:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or properties.Prefix or "Exter", 
        Subtitle = properties.Subtitle or properties.subtitle or properties.Suffix or "nal",
        Size = properties.Size or properties.size or dim2(0, 720, 0, 500), 
        TabInfo = nil, Items = {}, Tweening = false, IsSwitchingTab = false;
    }

    External:DisconnectAll()
    if External.Gui then External.Gui:Destroy() end
    if External.Other then External.Other:Destroy() end
    if External.ToggleGui then External.ToggleGui:Destroy() end

    External.Gui = External:Create("ScreenGui", { Parent = CoreGui, Name = "ORGGUI", Enabled = true, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    External.Other = External:Create("ScreenGui", { Parent = CoreGui, Name = "ORGOther", Enabled = false, IgnoreGuiInset = true })
    
    local Items = Cfg.Items
    local uiVisible = true

    Items.Wrapper = External:Create("Frame", {
        Parent = External.Gui, Position = dim2(0.5, -Cfg.Size.X.Offset / 2, 0.5, -Cfg.Size.Y.Offset / 2),
        Size = Cfg.Size, BackgroundTransparency = 1, BorderSizePixel = 0
    })

    local uiScale = External:Create("UIScale", { Parent = Items.Wrapper, Scale = 1 })
    local function UpdateScale()
        local viewportSize = External.Gui.AbsoluteSize
        if viewportSize.X > 0 and viewportSize.Y > 0 then
            local scaleX = math.min(1, viewportSize.X / (Cfg.Size.X.Offset + 30))
            local scaleY = math.min(1, viewportSize.Y / (Cfg.Size.Y.Offset + 30))
            uiScale.Scale = math.min(scaleX, scaleY)
        end
    end
    UpdateScale()
    External:TrackConnection(External.Gui:GetPropertyChangedSignal("AbsoluteSize"), UpdateScale)
    
    Items.Window = External:Create("Frame", {
        Parent = Items.Wrapper, Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 1
    })
    External:Themify(Items.Window, "background", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 8) })
    External:Themify(External:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.AccentBar = External:Create("Frame", {
        Parent = Items.Window, Size = dim2(1, 0, 0, 2),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 10
    })
    External:Themify(Items.AccentBar, "accent", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.AccentBar, CornerRadius = dim(0, 8) })

    -- Floating Sidebar
    Items.Sidebar = External:Create("Frame", {
        Parent = Items.Window, Position = dim2(0, 12, 0, 12), Size = dim2(0, 56, 1, -24),
        BackgroundColor3 = themes.preset.section, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 2
    })
    External:Themify(Items.Sidebar, "section", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Sidebar, CornerRadius = dim(0, 8) })
    External:Themify(External:Create("UIStroke", { Parent = Items.Sidebar, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.TabHolder = External:Create("ScrollingFrame", {
        Parent = Items.Sidebar, Size = dim2(1, 0, 1, 0), CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, 
        BackgroundTransparency = 1, ScrollBarThickness = 0, ZIndex = 4
    })
    External:Create("UIListLayout", { 
        Parent = Items.TabHolder, FillDirection = Enum.FillDirection.Vertical, 
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = dim(0, 8) 
    })
    External:Create("UIPadding", { Parent = Items.TabHolder, PaddingTop = dim(0, 12), PaddingBottom = dim(0, 12) })

    -- Floating Header
    Items.Header = External:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 80, 0, 12), Size = dim2(1, -92, 0, 48), 
        BackgroundColor3 = themes.preset.section, BackgroundTransparency = 0.1, Active = true, ZIndex = 2 
    })
    External:Themify(Items.Header, "section", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Header, CornerRadius = dim(0, 8) })
    External:Themify(External:Create("UIStroke", { Parent = Items.Header, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.LogoText = External:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0.5), Position = dim2(0, 16, 0.5, 0),
        Size = dim2(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Fonts.Bold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    External:Themify(Items.LogoText, "text", "TextColor3")

    Items.SubLogoText = External:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Subtitle, TextColor3 = themes.preset.accent,
        AnchorPoint = vec2(0, 0.5), Position = dim2(0, 20 + Items.LogoText.TextBounds.X, 0.5, 0),
        Size = dim2(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Fonts.SemiBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    External:Themify(Items.SubLogoText, "accent", "TextColor3")
    
    Items.LogoText:GetPropertyChangedSignal("TextBounds"):Connect(function()
        Items.SubLogoText.Position = dim2(0, 20 + Items.LogoText.TextBounds.X, 0.5, 0)
    end)

    -- User Profile
    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    local isAnonymous = false
    
    Items.AvatarFrame = External:Create("Frame", {
        Parent = Items.Header, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -16, 0.5, 0), 
        Size = dim2(0, 30, 0, 30), BackgroundColor3 = themes.preset.element, BorderSizePixel = 0, ZIndex = 5
    })
    External:Themify(Items.AvatarFrame, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.AvatarFrame, CornerRadius = dim(1, 0) }) 
    External:Themify(External:Create("UIStroke", { Parent = Items.AvatarFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
    
    Items.Avatar = External:Create("ImageLabel", { 
        Parent = Items.AvatarFrame, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0), 
        Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Image = headshot, ZIndex = 6 
    })
    External:Create("UICorner", { Parent = Items.Avatar, CornerRadius = dim(1, 0) })

    Items.Username = External:Create("TextLabel", {
        Parent = Items.Header, Text = lp.Name, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(1, 0.5), Position = dim2(1, -54, 0.5, 0), Size = dim2(0, 140, 0, 14),
        BackgroundTransparency = 1, FontFace = Fonts.SemiBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5
    })
    External:Themify(Items.Username, "text", "TextColor3")
    
    function Cfg.SetAnonymous(enabled)
        isAnonymous = enabled
        if enabled then
            Items.Avatar.Image = "rbxthumb://type=Asset&id=10723377240&w=48&h=48"
            Items.Username.Text = "Anonymous"
            Items.AvatarFrame.BackgroundColor3 = themes.preset.background_alt
        else
            Items.Avatar.Image = headshot
            Items.Username.Text = lp.Name
            Items.AvatarFrame.BackgroundColor3 = themes.preset.element
        end
        External:Themify(Items.AvatarFrame, enabled and "background_alt" or "element", "BackgroundColor3")
    end

    Items.SettingsBtn = External:Create("ImageButton", {
        Parent = Items.Header, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -210, 0.5, 0),
        Size = dim2(0, 18, 0, 18), BackgroundTransparency = 1, Image = "rbxassetid://10734950309", ImageColor3 = themes.preset.subtext, ZIndex = 5
    })
    External:Themify(Items.SettingsBtn, "subtext", "ImageColor3")
    External:AddHoverEffect(Items.SettingsBtn, {ImageColor3 = themes.preset.accent}, {ImageColor3 = themes.preset.subtext})
    
    Items.Username:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Items.SettingsBtn.Position = dim2(1, -70 - Items.Username.TextBounds.X, 0.5, 0)
    end)
    Items.SettingsBtn.Position = dim2(1, -70 - Items.Username.TextBounds.X, 0.5, 0)

    Items.SettingsBtn.MouseButton1Click:Connect(function()
        if Cfg.SettingsTabOpen then Cfg.SettingsTabOpen() end
    end)

    Items.PageHolder = External:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 80, 0, 72), Size = dim2(1, -92, 1, -84), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Optimized Window Dragging
    local Dragging, DragInput, DragStart, StartPos
    Items.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true; DragStart = input.Position; StartPos = Items.Wrapper.Position
        end
    end)
    Items.Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - DragStart
            Items.Wrapper.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)
    External:Resizify(Items.Wrapper)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        if bool == nil then uiVisible = not uiVisible else uiVisible = bool end
        Items.Wrapper.Visible = uiVisible
    end

    if InputService.TouchEnabled then
        External.ToggleGui = External:Create("ScreenGui", { Parent = CoreGui, Name = "ExtneralToggle", IgnoreGuiInset = true })
        local ToggleButton = External:Create("ImageButton", {
            Name = "ToggleButton", Parent = External.ToggleGui, Position = UDim2.new(1, -80, 0, 150), Size = UDim2.new(0, 50, 0, 50),
            BackgroundTransparency = 0.2, BackgroundColor3 = themes.preset.element, Image = "rbxthumb://type=Asset&id=99047291822954&w=150&h=150", ZIndex = 10000,
        })
        External:Create("UICorner", { Parent = ToggleButton, CornerRadius = dim(0, 16) })
        External:Themify(ToggleButton, "element", "BackgroundColor3")
        External:Themify(External:Create("UIStroke", { Parent = ToggleButton, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

        local isTDrag, tDragStart, tStartPos, hasTDragged = false, nil, nil, false
        ToggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = true; hasTDragged = false; tDragStart = input.Position; tStartPos = ToggleButton.Position
            end
        end)
        ToggleButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = false; if not hasTDragged then Cfg.ToggleMenu() end
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if isTDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - tDragStart
                if delta.Magnitude > 5 then hasTDragged = true; ToggleButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y) end
            end
        end)
    end

    return setmetatable(Cfg, External)
end

function External:Tab(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Tab", 
        Icon = properties.Icon or properties.icon or "",
        Hidden = properties.Hidden or properties.hidden or false, 
        Items = {} 
    }
    if tonumber(Cfg.Icon) then Cfg.Icon = "rbxassetid://" .. tostring(Cfg.Icon) end
    local Items = Cfg.Items

    if not Cfg.Hidden then
        Items.Button = External:Create("TextButton", { 
            Parent = self.Items.TabHolder, Size = dim2(0, 38, 0, 38), 
            BackgroundColor3 = themes.preset.tab_active, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5 
        })
        External:Themify(Items.Button, "tab_active", "BackgroundColor3")
        External:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0.5, 0) })

        Items.IconImg = External:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 18, 0, 18), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 6 
        })
        External:Themify(Items.IconImg, "subtext", "ImageColor3")
    end

    Items.Pages = External:Create("CanvasGroup", { Parent = External.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    External:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 12) })
    External:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 2), PaddingBottom = dim(0, 2), PaddingRight = dim(0, 2), PaddingLeft = dim(0, 2) })

    Items.Left = External:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -6, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    External:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 12) })
    External:Create("UIPadding", { Parent = Items.Left, PaddingBottom = dim(0, 12) })

    Items.Right = External:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -6, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    External:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 12) })
    External:Create("UIPadding", { Parent = Items.Right, PaddingBottom = dim(0, 12) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        local buttonTween = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if oldTab and oldTab.Button then
            External:Tween(oldTab.Button, {BackgroundTransparency = 1}, buttonTween)
            External:Tween(oldTab.IconImg, {ImageColor3 = themes.preset.subtext}, buttonTween)
        end

        if Items.Button then 
            External:Tween(Items.Button, {BackgroundTransparency = 0}, buttonTween)
            External:Tween(Items.IconImg, {ImageColor3 = themes.preset.accent}, buttonTween)
        end
        
        task.spawn(function()
            if oldTab then
                External:Tween(oldTab.Pages, {GroupTransparency = 1, Size = dim2(0.95, 0, 0.95, 0)}, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.15)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = External.Other
            end

            Items.Pages.Size = dim2(0.95, 0, 0.95, 0)
            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.PageHolder
            Items.Pages.Visible = true

            External:Tween(Items.Pages, {GroupTransparency = 0, Size = dim2(1, 0, 1, 0)}, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            task.wait(0.2)
            
            Items.Pages.GroupTransparency = 0 
            self.IsSwitchingTab = false
        end)
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, External)
end

function External:SubTab(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "SubTab", 
        Items = {} 
    }
    local Items = Cfg.Items

    -- self is the Tab object
    if not self.SubTabsInitialized then
        self.SubTabsInitialized = true
        self.CurrentSubTab = nil
        self.SubTabBtns = {}
        
        if self.Items.Left then self.Items.Left:Destroy() end
        if self.Items.Right then self.Items.Right:Destroy() end
        for _, child in ipairs(self.Items.Pages:GetChildren()) do
            if child:IsA("UIListLayout") or child:IsA("UIPadding") then child:Destroy() end
        end

        External:Create("UIListLayout", { Parent = self.Items.Pages, FillDirection = Enum.FillDirection.Vertical, Padding = dim(0, 8) })
        External:Create("UIPadding", { Parent = self.Items.Pages, PaddingTop = dim(0, 2), PaddingBottom = dim(0, 2), PaddingRight = dim(0, 2), PaddingLeft = dim(0, 2) })

        self.Items.SubTabBar = External:Create("ScrollingFrame", {
            Parent = self.Items.Pages, Size = dim2(1, 0, 0, 30), BackgroundTransparency = 1,
            ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X
        })
        External:Create("UIListLayout", { Parent = self.Items.SubTabBar, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 15), VerticalAlignment = Enum.VerticalAlignment.Center })
        External:Create("UIPadding", { Parent = self.Items.SubTabBar, PaddingLeft = dim(0, 4), PaddingRight = dim(0, 4) })

        self.Items.SubContent = External:Create("Frame", {
            Parent = self.Items.Pages, Size = dim2(1, 0, 1, -38), BackgroundTransparency = 1, ClipsDescendants = true
        })
    end

    Items.Button = External:Create("TextButton", {
        Parent = self.Items.SubTabBar, Size = dim2(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, FontFace = Fonts.SemiBold, TextSize = 14
    })
    External:Themify(Items.Button, "subtext", "TextColor3")

    Items.Indicator = External:Create("Frame", {
        Parent = Items.Button, AnchorPoint = vec2(0.5, 1), Position = dim2(0.5, 0, 1, 0),
        Size = dim2(0, 0, 0, 2), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, BackgroundTransparency = 1
    })
    External:Themify(Items.Indicator, "accent", "BackgroundColor3")

    Items.Pages = External:Create("CanvasGroup", { Parent = External.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    External:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 12) })
    
    Items.Left = External:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -6, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    External:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 12) })
    External:Create("UIPadding", { Parent = Items.Left, PaddingBottom = dim(0, 12) })

    Items.Right = External:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -6, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    External:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 12) })
    External:Create("UIPadding", { Parent = Items.Right, PaddingBottom = dim(0, 12) })

    function Cfg.OpenSubTab()
        if self.IsSwitchingSubTab or self.CurrentSubTab == Cfg.Items then return end
        local oldTab = self.CurrentSubTab
        self.IsSwitchingSubTab = true
        self.CurrentSubTab = Cfg.Items

        local buttonTween = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if oldTab and oldTab.Button then
            External:Tween(oldTab.Button, {TextColor3 = themes.preset.subtext}, buttonTween)
            External:Tween(oldTab.Indicator, {Size = dim2(0, 0, 0, 2), BackgroundTransparency = 1}, buttonTween)
        end

        if Items.Button then 
            External:Tween(Items.Button, {TextColor3 = themes.preset.accent}, buttonTween)
            External:Tween(Items.Indicator, {Size = dim2(1, 4, 0, 2), BackgroundTransparency = 0}, buttonTween)
        end
        
        task.spawn(function()
            if oldTab then
                External:Tween(oldTab.Pages, {GroupTransparency = 1, Size = dim2(0.95, 0, 0.95, 0)}, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.15)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = External.Other
            end

            Items.Pages.Size = dim2(0.95, 0, 0.95, 0)
            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.SubContent
            Items.Pages.Visible = true

            External:Tween(Items.Pages, {GroupTransparency = 0, Size = dim2(1, 0, 1, 0)}, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            task.wait(0.2)
            
            Items.Pages.GroupTransparency = 0 
            self.IsSwitchingSubTab = false
        end)
    end

    Items.Button.MouseButton1Down:Connect(Cfg.OpenSubTab)
    if not self.CurrentSubTab then Cfg.OpenSubTab() end
    return setmetatable(Cfg, External)
end

function External:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Side = properties.Side or properties.side or "Left", 
        Icon = properties.Icon or properties.icon or "rbxassetid://10723415903", 
        RightIcon = properties.RightIcon or properties.righticon or "", 
        Items = {} 
    }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = External:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = themes.preset.section, BackgroundTransparency = 0.1, BorderSizePixel = 0, ClipsDescendants = true 
    })
    External:Themify(Items.Section, "section", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 8) })
    External:Themify(External:Create("UIStroke", { Parent = Items.Section, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Header = External:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 36), BackgroundTransparency = 1 })
    
    Items.Dot = External:Create("Frame", { 
        Parent = Items.Header, Position = dim2(0, 12, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 6, 0, 6), 
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0 
    })
    External:Themify(Items.Dot, "accent", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Dot, CornerRadius = dim(1, 0) })

    Items.Title = External:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 26, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -38, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Fonts.Bold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left 
    })
    External:Themify(Items.Title, "text", "TextColor3")

    Items.Separator = External:Create("Frame", {
        Parent = Items.Header, Position = dim2(0, 12, 1, -1), Size = dim2(1, -24, 0, 1),
        BackgroundColor3 = themes.preset.outline, BorderSizePixel = 0
    })
    External:Themify(Items.Separator, "outline", "BackgroundColor3")

    Items.Container = External:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 36), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    External:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    External:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 10), PaddingLeft = dim(0, 12), PaddingRight = dim(0, 12) })

    return setmetatable(Cfg, External)
end

function External:ScriptCard(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Script", 
        Description = properties.Description or properties.description or "Utility", 
        Icon = properties.Icon or properties.icon or "rbxassetid://10723343306", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = External:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 52), BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    External:Themify(Items.Container, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Container, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.Container, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.IconFrame = External:Create("Frame", {
        Parent = Items.Container, Position = dim2(0, 10, 0.5, 0), AnchorPoint = vec2(0, 0.5),
        Size = dim2(0, 32, 0, 32), BackgroundColor3 = themes.preset.background, BorderSizePixel = 0
    })
    External:Themify(Items.IconFrame, "background", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.IconFrame, CornerRadius = dim(0, 6) })

    Items.Icon = External:Create("ImageLabel", {
        Parent = Items.IconFrame, Position = dim2(0.5, 0, 0.5, 0), AnchorPoint = vec2(0.5, 0.5),
        Size = dim2(0, 16, 0, 16), BackgroundTransparency = 1, Image = Cfg.Icon, ImageColor3 = themes.preset.accent
    })
    External:Themify(Items.Icon, "accent", "ImageColor3")

    Items.Title = External:Create("TextLabel", {
        Parent = Items.Container, Position = dim2(0, 52, 0, 10), Size = dim2(1, -120, 0, 16),
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text,
        FontFace = Fonts.Bold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
    })
    External:Themify(Items.Title, "text", "TextColor3")

    Items.Desc = External:Create("TextLabel", {
        Parent = Items.Container, Position = dim2(0, 52, 0, 28), Size = dim2(1, -120, 0, 14),
        BackgroundTransparency = 1, Text = Cfg.Description, TextColor3 = themes.preset.subtext,
        FontFace = Fonts.Medium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
    })
    External:Themify(Items.Desc, "subtext", "TextColor3")

    Items.LoadBtn = External:Create("TextButton", {
        Parent = Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -10, 0.5, 0),
        Size = dim2(0, 56, 0, 28), BackgroundColor3 = themes.preset.accent, Text = "RUN",
        TextColor3 = rgb(255, 255, 255), FontFace = Fonts.Bold, TextSize = 12, AutoButtonColor = false
    })
    External:Themify(Items.LoadBtn, "accent", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.LoadBtn, CornerRadius = dim(0, 6) })

    External:AddHoverEffect(Items.Container, {BackgroundColor3 = themes.preset.element_hover}, {BackgroundColor3 = themes.preset.element})
    External:AddHoverEffect(Items.LoadBtn, {BackgroundColor3 = themes.preset.accent_light}, {BackgroundColor3 = themes.preset.accent})

    Items.LoadBtn.MouseButton1Click:Connect(function()
        External:Tween(Items.LoadBtn, {BackgroundTransparency = 0.4, Size = dim2(0, 52, 0, 26)}, TweenInfo.new(0.1))
        task.wait(0.1)
        External:Tween(Items.LoadBtn, {BackgroundTransparency = 0, Size = dim2(0, 56, 0, 28)}, TweenInfo.new(0.15))
        Cfg.Callback()
    end)

    return setmetatable(Cfg, External)
end

function External:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Toggle", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = External:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 34), 
        BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false
    })
    External:Themify(Items.Button, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.Button, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.SwitchBG = External:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -10, 0.5, 0), Size = dim2(0, 34, 0, 18), 
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0 
    })
    External:Themify(Items.SwitchBG, "background", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.SwitchBG, CornerRadius = dim(1, 0) })
    External:Themify(External:Create("UIStroke", { Parent = Items.SwitchBG, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.SwitchKnob = External:Create("Frame", {
        Parent = Items.SwitchBG, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 3, 0.5, 0), Size = dim2(0, 12, 0, 12),
        BackgroundColor3 = themes.preset.subtext, BorderSizePixel = 0
    })
    External:Themify(Items.SwitchKnob, "subtext", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.SwitchKnob, CornerRadius = dim(1, 0) })

    Items.Title = External:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 12, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -54, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Left 
    })
    External:Themify(Items.Title, "subtext", "TextColor3")

    local State = false
    function Cfg.set(bool)
        State = bool
        External:Tween(Items.SwitchBG, {BackgroundColor3 = State and themes.preset.accent or themes.preset.background}, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
        External:Tween(Items.SwitchKnob, {Position = State and dim2(0, 19, 0.5, 0) or dim2(0, 3, 0.5, 0), BackgroundColor3 = State and rgb(255, 255, 255) or themes.preset.subtext}, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
        External:Tween(Items.Title, {TextColor3 = State and themes.preset.text or themes.preset.subtext}, TweenInfo.new(0.1))
        
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end

    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, External)
end

function External:Button(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Button", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = External:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 34), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Fonts.SemiBold, AutoButtonColor = false 
    })
    External:Themify(Items.Button, "element", "BackgroundColor3")
    External:Themify(Items.Button, "text", "TextColor3")
    External:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.Button, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    External:AddHoverEffect(Items.Button, {BackgroundColor3 = themes.preset.element_hover, TextColor3 = themes.preset.accent}, {BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.text})

    Items.Button.MouseButton1Click:Connect(function()
        External:Tween(Items.Button, {BackgroundColor3 = themes.preset.accent, TextColor3 = rgb(255, 255, 255)}, TweenInfo.new(0.1))
        task.wait(0.1)
        External:Tween(Items.Button, {BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.text}, TweenInfo.new(0.15))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, External)
end

function External:Slider(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Slider", 
        Flag = properties.Flag or properties.flag, 
        Min = properties.Min or properties.min or 0, 
        Max = properties.Max or properties.max or 100, 
        Default = properties.Default or properties.default or properties.Value or properties.value or 0, 
        Increment = properties.Increment or properties.increment or 1, 
        Suffix = properties.Suffix or properties.suffix or "", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.ContainerBox = External:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 48), BackgroundColor3 = themes.preset.element 
    })
    External:Themify(Items.ContainerBox, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.ContainerBox, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.ContainerBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Title = External:Create("TextLabel", { 
        Parent = Items.ContainerBox, Position = dim2(0, 12, 0, 8), Size = dim2(1, -24, 0, 16), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Left 
    })
    External:Themify(Items.Title, "text", "TextColor3")

    local initialFormattedValue = Cfg.Increment < 1 and string.format("%." .. math.max(1, string.len(tostring(Cfg.Increment):match("%.(%d+)") or "")) .. "f", Cfg.Default) or string.format("%.0f", Cfg.Default)
    
    Items.Val = External:Create("TextLabel", { 
        Parent = Items.ContainerBox, Position = dim2(0, 12, 0, 8), Size = dim2(1, -24, 0, 16), 
        BackgroundTransparency = 1, Text = initialFormattedValue..Cfg.Suffix, TextColor3 = themes.preset.accent, TextSize = 13, FontFace = Fonts.Bold, TextXAlignment = Enum.TextXAlignment.Right 
    })
    External:Themify(Items.Val, "accent", "TextColor3")

    Items.Track = External:Create("TextButton", { 
        Parent = Items.ContainerBox, Position = dim2(0, 12, 0, 32), Size = dim2(1, -24, 0, 6), 
        BackgroundColor3 = themes.preset.background, Text = "", AutoButtonColor = false 
    })
    External:Themify(Items.Track, "background", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(1, 0) })
    
    Items.Fill = External:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.accent })
    External:Themify(Items.Fill, "accent", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(1, 0) })
    
    Items.Knob = External:Create("Frame", {Parent = Items.Fill, AnchorPoint = vec2(0.5, 0.5), Position = dim2(1, 0, 0.5, 0), Size = dim2(0, 12, 0, 12), BackgroundColor3 = rgb(255,255,255)})
    External:Create("UICorner", { Parent = Items.Knob, CornerRadius = dim(1, 0) })
    
    local Value = Cfg.Default
    function Cfg.set(val)
        Value = math.clamp(math.round(val / Cfg.Increment) * Cfg.Increment, Cfg.Min, Cfg.Max)
        local formattedValue = Cfg.Increment < 1 and string.format("%." .. math.max(1, string.len(tostring(Cfg.Increment):match("%.(%d+)") or "")) .. "f", Value) or string.format("%.0f", Value)
        Items.Val.Text = formattedValue .. Cfg.Suffix
        External:Tween(Items.Fill, {Size = dim2((Value - Cfg.Min) / (Cfg.Max - Cfg.Min), 0, 1, 0)}, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
        if Cfg.Flag then Flags[Cfg.Flag] = Value end
        Cfg.Callback(Value)
    end

    local Dragging = false
    Items.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Dragging = true; Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1)) 
        end
    end)
    InputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1))
        end
    end)

    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, External)
end

function External:Textbox(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "", 
        Placeholder = properties.Placeholder or properties.placeholder or "Enter text...", 
        Default = properties.Default or properties.default or "", 
        Flag = properties.Flag or properties.flag, 
        Numeric = properties.Numeric or properties.numeric or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.ContainerBox = External:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 34), BackgroundColor3 = themes.preset.element 
    })
    External:Themify(Items.ContainerBox, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.ContainerBox, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.ContainerBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Input = External:Create("TextBox", { 
        Parent = Items.ContainerBox, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 13, FontFace = Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
    })
    External:Themify(Items.Input, "text", "TextColor3")

    function Cfg.set(val)
        if Cfg.Numeric and tonumber(val) == nil and val ~= "" then return end
        Items.Input.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end
    
    Items.Input.FocusLost:Connect(function() Cfg.set(Items.Input.Text) end)
    if Cfg.Default ~= "" then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, External)
end

function External:Dropdown(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Dropdown", 
        Flag = properties.Flag or properties.flag, 
        Options = properties.Options or properties.options or properties.items or {}, 
        Default = properties.Default or properties.default, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    
    Items.ContainerBox = External:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 34), BackgroundColor3 = themes.preset.element 
    })
    External:Themify(Items.ContainerBox, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.ContainerBox, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.ContainerBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Main = External:Create("TextButton", { 
        Parent = Items.ContainerBox, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false 
    })
    External:AddHoverEffect(Items.Main, {BackgroundColor3 = themes.preset.element_hover}, {BackgroundColor3 = themes.preset.element})

    Items.Title = External:Create("TextLabel", { 
        Parent = Items.Main, Position = dim2(0, 12, 0, 0), Size = dim2(0, 100, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Left 
    })
    External:Themify(Items.Title, "subtext", "TextColor3")

    Items.SelectedText = External:Create("TextLabel", { 
        Parent = Items.Main, Position = dim2(0, 112, 0, 0), Size = dim2(1, -140, 1, 0), 
        BackgroundTransparency = 1, Text = "...", TextColor3 = themes.preset.text, TextSize = 13, FontFace = Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Right 
    })
    External:Themify(Items.SelectedText, "text", "TextColor3")
    
    Items.Icon = External:Create("ImageLabel", { 
        Parent = Items.Main, Position = dim2(1, -20, 0.5, 0), AnchorPoint = vec2(0, 0.5), 
        Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Image = "rbxassetid://10723415903", ImageColor3 = themes.preset.subtext, Rotation = -90 
    })

    Items.DropFrame = External:Create("Frame", { 
        Parent = External.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    External:Themify(Items.DropFrame, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.DropFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.SearchBar = External:Create("Frame", {
        Parent = Items.DropFrame, Position = dim2(0, 6, 0, 6), Size = dim2(1, -12, 0, 24),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 202
    })
    External:Themify(Items.SearchBar, "background", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.SearchBar, CornerRadius = dim(0, 4) })
    External:Themify(External:Create("UIStroke", { Parent = Items.SearchBar, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.SearchIcon = External:Create("ImageLabel", {
        Parent = Items.SearchBar, Position = dim2(0, 6, 0.5, 0), AnchorPoint = vec2(0, 0.5),
        Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1,
        Image = "rbxassetid://132302594577680", ImageColor3 = themes.preset.subtext, ZIndex = 203
    })
    External:Themify(Items.SearchIcon, "subtext", "ImageColor3")

    Items.SearchInput = External:Create("TextBox", {
        Parent = Items.SearchBar, Position = dim2(0, 24, 0, 0), Size = dim2(1, -30, 1, 0),
        BackgroundTransparency = 1, Text = "", PlaceholderText = "Search...",
        TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext,
        TextSize = 12, FontFace = Fonts.Medium,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 203
    })
    External:Themify(Items.SearchInput, "text", "TextColor3")

    Items.Scroll = External:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, Size = dim2(1, 0, 1, -40), Position = dim2(0, 0, 0, 36), 
        BackgroundTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0, ZIndex = 201 
    })
    External:Create("UIListLayout", { Parent = Items.Scroll, SortOrder = Enum.SortOrder.LayoutOrder })

    local Open = false
    local isTweening = false

    -- REMOVED RenderStepped - Fixed Lag!
    local function UpdatePosition()
        if Items.DropFrame.Visible then
            local absPos = Items.Main.AbsolutePosition
            local absSize = Items.Main.AbsoluteSize
            Items.DropFrame.Position = dim2(0, absPos.X, 0, absPos.Y + absSize.Y + 6)
            Items.DropFrame.Size = dim2(0, absSize.X, 0, Items.DropFrame.AbsoluteSize.Y)
        end
    end

    Items.Main:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdatePosition)
    Items.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdatePosition)

    local function ToggleDropdown()
        if isTweening then return end
        Open = not Open
        isTweening = true

        if Open then
            Items.DropFrame.Visible = true
            UpdatePosition()
            Items.DropFrame.Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)
            local targetHeight = math.clamp(#Cfg.Options * 26 + 40, 0, 180)
            External:Tween(Items.Icon, {Rotation = 90}, TweenInfo.new(0.2))
            local tw = External:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            External:Tween(Items.Icon, {Rotation = -90}, TweenInfo.new(0.2))
            local tw = External:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)}, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    Items.Main.MouseButton1Click:Connect(ToggleDropdown)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, Items.DropFrame.AbsoluteSize
                local p1, s1 = Items.Main.AbsolutePosition, Items.Main.AbsoluteSize
                
                if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and 
                   not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    ToggleDropdown()
                end
            end
        end
    end)

    local OptionBtns = {}
    local function ApplyFilter(query)
        local q = query:lower()
        local visible = 0
        for _, entry in ipairs(OptionBtns) do
            local matches = q == "" or tostring(entry.opt):lower():find(q, 1, true) ~= nil
            entry.btn.Visible = matches
            if matches then visible = visible + 1 end
        end
        Items.Scroll.CanvasSize = dim2(0, 0, 0, visible * 26)
    end

    function Cfg.RefreshOptions(newList)
        Cfg.Options = newList or Cfg.Options
        for _, entry in ipairs(OptionBtns) do entry.btn:Destroy() end
        table.clear(OptionBtns)
        for _, opt in ipairs(Cfg.Options) do
            local btn = External:Create("TextButton", { 
                Parent = Items.Scroll, Size = dim2(1, 0, 0, 26), BackgroundTransparency = 1, 
                Text = "   " .. tostring(opt), TextColor3 = themes.preset.text, TextSize = 13, 
                FontFace = Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202 
            })
            External:Themify(btn, "text", "TextColor3")
            External:AddHoverEffect(btn, {TextColor3 = themes.preset.accent}, {TextColor3 = themes.preset.text})
            btn.MouseButton1Click:Connect(function() Cfg.set(opt); ToggleDropdown() end)
            table.insert(OptionBtns, { btn = btn, opt = opt })
        end
        ApplyFilter(Items.SearchInput.Text)
    end

    Items.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        ApplyFilter(Items.SearchInput.Text)
    end)

    function Cfg.set(val)
        Items.SelectedText.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end

    Cfg.RefreshOptions(Cfg.Options)
    if Cfg.Default then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, External)
end

function External:Label(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Label", 
        Wrapped = properties.Wrapped or properties.wrapped or false, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.ContainerBox = External:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 36 or 34), 
        BackgroundColor3 = themes.preset.element 
    })
    External:Themify(Items.ContainerBox, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.ContainerBox, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.ContainerBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Title = External:Create("TextLabel", { 
        Parent = Items.ContainerBox, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextWrapped = Cfg.Wrapped, 
        FontFace = Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center 
    })
    External:Themify(Items.Title, "subtext", "TextColor3")
    
    function Cfg.set(val) Items.Title.Text = tostring(val) end

    Cfg.Items.Container = Items.ContainerBox 
    return setmetatable(Cfg, External)
end

function External:Colorpicker(properties)
    local Cfg = { 
        Color = properties.Color or properties.color or rgb(255, 255, 255), 
        Callback = properties.Callback or properties.callback or function() end, 
        Flag = properties.Flag or properties.flag, 
        Items = {} 
    }
    local Items = Cfg.Items

    local attachParent = self.Items.ContainerBox or self.Items.Button or self.Items.Container
    
    local btn = External:Create("TextButton", { 
        Parent = attachParent, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -10, 0.5, 0), 
        Size = dim2(0, 40, 0, 18), BackgroundColor3 = Cfg.Color, Text = "" 
    })
    External:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 4)})
    External:Create("UIStroke", {Parent = btn, Color = rgb(0,0,0), Thickness = 1, Transparency = 0.5})

    local h, s, v = Color3.toHSV(Cfg.Color)
    
    Items.DropFrame = External:Create("Frame", { 
        Parent = External.Gui, Size = dim2(0, 160, 0, 0), BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    External:Themify(Items.DropFrame, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.DropFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.SVMap = External:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 8, 0, 8), Size = dim2(1, -16, 1, -38), AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 201 })
    External:Create("UICorner", { Parent = Items.SVMap, CornerRadius = dim(0, 4) })
    Items.SVImage = External:Create("ImageLabel", { Parent = Items.SVMap, Size = dim2(1, 0, 1, 0), Image = "rbxassetid://4155801252", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 202 })
    External:Create("UICorner", { Parent = Items.SVImage, CornerRadius = dim(0, 4) })
    
    Items.SVKnob = External:Create("Frame", { Parent = Items.SVMap, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 8, 0, 8), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    External:Create("UICorner", { Parent = Items.SVKnob, CornerRadius = dim(1, 0) })
    External:Create("UIStroke", { Parent = Items.SVKnob, Color = rgb(0,0,0) })

    Items.HueBar = External:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 8, 1, -22), Size = dim2(1, -16, 0, 14), AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = rgb(255, 255, 255), ZIndex = 201 })
    External:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(0, 4) })
    External:Create("UIGradient", { Parent = Items.HueBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255,0,0)), ColorSequenceKeypoint.new(0.167, rgb(255,0,255)), ColorSequenceKeypoint.new(0.333, rgb(0,0,255)), ColorSequenceKeypoint.new(0.5, rgb(0,255,255)), ColorSequenceKeypoint.new(0.667, rgb(0,255,0)), ColorSequenceKeypoint.new(0.833, rgb(255,255,0)), ColorSequenceKeypoint.new(1, rgb(255,0,0))}) })
    
    Items.HueKnob = External:Create("Frame", { Parent = Items.HueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 6, 1, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    External:Create("UIStroke", { Parent = Items.HueKnob, Color = rgb(0,0,0) })
    External:Create("UICorner", { Parent = Items.HueKnob, CornerRadius = dim(0, 3) })

    local Open = false
    local isTweening = false

    -- REMOVED RenderStepped - Fixed Lag!
    local function UpdatePickerPos()
        if Items.DropFrame.Visible then
            Items.DropFrame.Position = dim2(0, btn.AbsolutePosition.X - 160 + btn.AbsoluteSize.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 8)
        end
    end
    btn:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdatePickerPos)
    btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdatePickerPos)

    local function Toggle() 
        if isTweening then return end
        Open = not Open
        isTweening = true
        
        if Open then
            Items.DropFrame.Visible = true
            UpdatePickerPos()
            local tw = External:Tween(Items.DropFrame, {Size = dim2(0, 160, 0, 150)}, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            local tw = External:Tween(Items.DropFrame, {Size = dim2(0, 160, 0, 0)}, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    btn.MouseButton1Click:Connect(Toggle)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0 = Items.DropFrame.AbsolutePosition
                local s0 = dim2(0, 160, 0, 150)
                local p1, s1 = btn.AbsolutePosition, btn.AbsoluteSize
                if not (mx >= p0.X and mx <= p0.X + s0.X.Offset and my >= p0.Y and my <= p0.Y + s0.Y.Offset) and not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    Toggle()
                end
            end
        end
    end)

    function Cfg.set(color3)
        Cfg.Color = color3
        btn.BackgroundColor3 = color3
        if Cfg.Flag then Flags[Cfg.Flag] = color3 end
        Cfg.Callback(color3)
    end

    local svDragging, hueDragging = false, false
    Items.SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = true end end)
    Items.HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end end)
    InputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = false; hueDragging = false end end)

    InputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then
                local x = math.clamp((input.Position.X - Items.SVMap.AbsolutePosition.X) / Items.SVMap.AbsoluteSize.X, 0, 1)
                local y = math.clamp((input.Position.Y - Items.SVMap.AbsolutePosition.Y) / Items.SVMap.AbsoluteSize.Y, 0, 1)
                s, v = x, 1 - y
                Items.SVKnob.Position = dim2(x, 0, y, 0)
                Cfg.set(Color3.fromHSV(h, s, v))
            elseif hueDragging then
                local x = math.clamp((input.Position.X - Items.HueBar.AbsolutePosition.X) / Items.HueBar.AbsoluteSize.X, 0, 1)
                h = 1 - x
                Items.HueKnob.Position = dim2(x, 0, 0.5, 0)
                Items.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                Cfg.set(Color3.fromHSV(h, s, v))
            end
        end
    end)

    Items.SVKnob.Position = dim2(s, 0, 1 - v, 0)
    Items.HueKnob.Position = dim2(1 - h, 0, 0.5, 0)
    
    Cfg.set(Cfg.Color)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, External)
end

function External:Keybind(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Keybind", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or Enum.KeyCode.Unknown, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local attachParent = self.Items.ContainerBox or self.Items.Button or self.Items.Container
    local KeyBtn = External:Create("TextButton", { 
        Parent = attachParent, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -10, 0.5, 0), 
        Size = dim2(0, 40, 0, 20), BackgroundColor3 = themes.preset.background, TextColor3 = themes.preset.text, 
        Text = Keys[Cfg.Default] or "None", TextSize = 12, FontFace = Fonts.SemiBold 
    })
    External:Themify(KeyBtn, "background", "BackgroundColor3")
    External:Themify(KeyBtn, "text", "TextColor3")

    External:Create("UICorner", {Parent = KeyBtn, CornerRadius = dim(0, 4)})
    External:Themify(External:Create("UIStroke", { Parent = KeyBtn, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    local binding = false
    KeyBtn.MouseButton1Click:Connect(function() binding = true; KeyBtn.Text = "..." end)
    
    InputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not binding then return end
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                binding = false; Cfg.set(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                binding = false; Cfg.set(input.UserInputType)
            end
        elseif (input.KeyCode == Cfg.Default or input.UserInputType == Cfg.Default) and not binding then
            Cfg.Callback()
        end
    end)
    
    function Cfg.set(val)
        if not val or type(val) == "boolean" then return end
        Cfg.Default = val
        local keyName = Keys[val] or (typeof(val) == "EnumItem" and val.Name) or tostring(val)
        KeyBtn.Text = keyName
        if Cfg.Flag then Flags[Cfg.Flag] = val end
    end
    
    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, External)
end

function Notifications:RefreshNotifications()
    local offset = 20
    for _, v in ipairs(Notifications.Notifs) do
        local ySize = math.max(v.AbsoluteSize.Y, 36)
        External:Tween(v, {Position = dim_offset(20, offset)}, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        offset += (ySize + 8)
    end
end

function Notifications:Create(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Notification"; 
        Lifetime = properties.LifeTime or properties.lifetime or 2.5; 
        Items = {}; 
    }
    local Items = Cfg.Items
   
    Items.Outline = External:Create("Frame", { 
        Parent = External.Gui; Position = dim_offset(-500, 20); Size = dim2(0, 280, 0, 0); AutomaticSize = Enum.AutomaticSize.Y; 
        BackgroundColor3 = themes.preset.element; BorderSizePixel = 0; ZIndex = 300, ClipsDescendants = true 
    })
    External:Themify(Items.Outline, "element", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 6) })
    External:Themify(External:Create("UIStroke", { Parent = Items.Outline, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.LeftAccent = External:Create("Frame", {
        Parent = Items.Outline, Size = dim2(0, 3, 1, 0),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 304
    })
    External:Themify(Items.LeftAccent, "accent", "BackgroundColor3")
    External:Create("UICorner", { Parent = Items.LeftAccent, CornerRadius = dim(0, 6) })
   
    Items.Name = External:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Name; TextColor3 = themes.preset.text; FontFace = Fonts.Medium;
        BackgroundTransparency = 1; Size = dim2(1, 0, 1, 0); AutomaticSize = Enum.AutomaticSize.None; TextWrapped = true; 
        TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 302
    })
    External:Themify(Items.Name, "text", "TextColor3")
   
    External:Create("UIPadding", { Parent = Items.Name; PaddingTop = dim(0, 10); PaddingBottom = dim(0, 10); PaddingRight = dim(0, 12); PaddingLeft = dim(0, 14); })
   
    Items.TimeBar = External:Create("Frame", { 
        Parent = Items.Outline, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 2), 
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 303 
    })
    External:Themify(Items.TimeBar, "accent", "BackgroundColor3")
    table.insert(Notifications.Notifs, Items.Outline)
   
    task.spawn(function()
        RunService.RenderStepped:Wait()
        Items.Outline.Position = dim_offset(-Items.Outline.AbsoluteSize.X - 20, 20)
        Notifications:RefreshNotifications()
        External:Tween(Items.TimeBar, {Size = dim2(0, 0, 0, 2)}, TweenInfo.new(Cfg.Lifetime, Enum.EasingStyle.Linear))
        task.wait(Cfg.Lifetime)
        External:Tween(Items.Outline, {Position = dim_offset(-Items.Outline.AbsoluteSize.X - 50, Items.Outline.Position.Y.Offset)}, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.25)
        local idx = table.find(Notifications.Notifs, Items.Outline)
        if idx then table.remove(Notifications.Notifs, idx) end
        Items.Outline:Destroy()
        Notifications:RefreshNotifications()
    end)
end

function External:GetConfig()
    local g = {}
    for Idx, Value in Flags do g[Idx] = Value end
    return HttpService:JSONEncode(g)
end

function External:LoadConfig(JSON)
    local g = HttpService:JSONDecode(JSON)
    for Idx, Value in g do
        if Idx == "config_Name_list" or Idx == "config_Name_text" then continue end
        local Function = ConfigFlags[Idx]
        if Function then Function(Value) end
    end
end

local ConfigHolder
function External:UpdateConfigList()
    if not ConfigHolder then return end
    local List = {}
    for _, file in listfiles(External.Directory .. "/configs") do
        local Name = file:gsub(External.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(External.Directory .. "\\configs\\", "")
        List[#List + 1] = Name
    end
    ConfigHolder.RefreshOptions(List)
end

function External:Configs(window)
    local Text

    local Tab = window:Tab({ Name = "", Hidden = true })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs", Side = "Left", Icon = "rbxassetid://10723415903"})

    ConfigHolder = Section:Dropdown({
        Name = "Available Configs",
        Options = {},
        Callback = function(option) if Text then Text.set(option) end end,
        Flag = "config_Name_list"
    })

    External:UpdateConfigList()

    Text = Section:Textbox({ Name = "Config Name:", Flag = "config_Name_text", Default = "" })

    Section:Button({
        Name = "Save Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            writefile(External.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg", External:GetConfig())
            External:UpdateConfigList()
            Notifications:Create({Name = "Saved Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Load Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            External:LoadConfig(readfile(External.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
            External:UpdateConfigList()
            Notifications:Create({Name = "Loaded Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Delete Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            delfile(External.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg")
            External:UpdateConfigList()
            Notifications:Create({Name = "Deleted Config: " .. Flags["config_Name_text"]})
        end
    })

    local SectionRight = Tab:Section({Name = "Theme Settings", Side = "Right", Icon = "rbxassetid://10734950309"})

    SectionRight:Toggle({
        Name = "Anonymous Mode",
        Default = false,
        Callback = function(enabled)
            if window.SetAnonymous then window.SetAnonymous(enabled) end
        end
    })

    SectionRight:Label({Name = "Accent Color"}):Colorpicker({ Callback = function(color3) External:RefreshTheme("accent", color3) end, Color = themes.preset.accent })
    SectionRight:Label({Name = "Background Color"}):Colorpicker({ Callback = function(color3) External:RefreshTheme("background", color3) end, Color = themes.preset.background })
    SectionRight:Label({Name = "Section Color"}):Colorpicker({ Callback = function(color3) External:RefreshTheme("section", color3) end, Color = themes.preset.section })
    SectionRight:Label({Name = "Element Color"}):Colorpicker({ Callback = function(color3) External:RefreshTheme("element", color3) end, Color = themes.preset.element })
    SectionRight:Label({Name = "Text Color"}):Colorpicker({ Callback = function(color3) External:RefreshTheme("text", color3) end, Color = themes.preset.text })

    window.Tweening = true
    SectionRight:Label({Name = "Menu Bind"}):Keybind({
        Name = "Menu Bind",
        Callback = function(bool) if window.Tweening then return end window.ToggleMenu(bool) end,
        Default = Enum.KeyCode.RightShift
    })

    task.delay(1, function() window.Tweening = false end)

    local ServerSection = Tab:Section({Name = "Server", Side = "Right", Icon = "rbxassetid://10734944415"})

    ServerSection:Button({ Name = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) end })

    ServerSection:Button({
        Name = "Join Lowest Server",
        Callback = function()
            local lowestServer, lowestPlayers = nil, math.huge
            local cursor = ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local success, data = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
                if success and data and data.data then
                    for _, server in ipairs(data.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers and server.playing < lowestPlayers then
                            lowestPlayers, lowestServer = server.playing, server
                        end
                    end
                    cursor = data.nextPageCursor
                else cursor = nil end
            until not cursor
            if lowestServer then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, lowestServer.id, Players.LocalPlayer) end
        end
    })

    ServerSection:Button({
        Name = "Server Hop",
        Callback = function()
            local servers, cursor = {}, ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local success, data = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
                if success and data and data.data then
                    for _, server in ipairs(data.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then table.insert(servers, server) end
                    end
                    cursor = data.nextPageCursor
                else cursor = nil end
            until not cursor or #servers > 0
            if #servers > 0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)].id, Players.LocalPlayer) end
        end
    })

    local MiscSection = Tab:Section({Name = "Miscellaneous", Side = "Right", Icon = "rbxassetid://10723377240"})
    
    MiscSection:Button({
        Name = "Copy Discord Link",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/joinexternal")
                Notifications:Create({Name = "Copied Discord link to clipboard!"})
            end
        end
    })

    MiscSection:Button({
        Name = "Unload UI",
        Callback = function()
            External:DisconnectAll()
            if External.Gui then External.Gui:Destroy() end
            if External.Other then External.Other:Destroy() end
            if External.ToggleGui then External.ToggleGui:Destroy() end
            Notifications:Create({Name = "UI Unloaded!"})
        end
    })
end

return External
