local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Library = {
    Flags = {},
    Theme = {
        Background = Color3.fromRGB(15, 12, 20),
        Sidebar = Color3.fromRGB(20, 16, 26),
        Section = Color3.fromRGB(25, 20, 32),
        Border = Color3.fromRGB(45, 35, 60),
        Accent = Color3.fromRGB(138, 43, 226),
        AccentHover = Color3.fromRGB(158, 63, 246),
        Text = Color3.fromRGB(240, 240, 245),
        TextDim = Color3.fromRGB(160, 150, 180)
    },
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
}

local writefile = writefile or function() end
local readfile = readfile or function() return "{}" end
local isfolder = isfolder or function() return false end
local makefolder = makefolder or function() end

local function create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        if typeof(v) == "Instance" and k == "Parent" then continue end
        instance[k] = v
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

-- Watermark & Notifications
local watermarkContainer
function Library:SetWatermark(text)
    local guiParent = if RunService:IsStudio() then Players.LocalPlayer:WaitForChild("PlayerGui") else CoreGui
    local screenGui = guiParent:FindFirstChild("PurpleUILibrary")
    if not screenGui then return end
    
    if not watermarkContainer then
        watermarkContainer = create("Frame", {
            Size = UDim2.fromOffset(0, 30),
            AutomaticSize = Enum.AutomaticSize.X,
            Position = UDim2.fromOffset(20, 20),
            BackgroundColor3 = Library.Theme.Section,
            Parent = screenGui
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = watermarkContainer })
        create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = watermarkContainer })
        create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = watermarkContainer })
        
        create("TextLabel", {
            Name = "Title",
            Size = UDim2.fromScale(0, 1),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Library.Theme.Accent,
            Font = Library.Theme.FontBold,
            TextSize = 14,
            Parent = watermarkContainer
        })
    else
        watermarkContainer.Title.Text = text
    end
end

local notifContainer
function Library:Notify(title, text, duration)
    local guiParent = if RunService:IsStudio() then Players.LocalPlayer:WaitForChild("PlayerGui") else CoreGui
    local screenGui = guiParent:FindFirstChild("PurpleUILibrary")
    if not screenGui then return end

    if not notifContainer then
        notifContainer = create("Frame", {
            Size = UDim2.fromOffset(250, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(1, -270, 1, -20),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Parent = screenGui
        })
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = notifContainer })
    end

    duration = duration or 3

    local notif = create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Library.Theme.Section,
        Position = UDim2.fromOffset(300, 0),
        ClipsDescendants = true,
        Parent = notifContainer
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
    create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = notif })

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(10, 5),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Library.Theme.Accent,
        Font = Library.Theme.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })
    
    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(10, 25),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Library.Theme.TextDim,
        Font = Library.Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })

    local progressBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = Library.Theme.Accent,
        Parent = notif
    })

    TweenService:Create(notif, Library.TweenInfo, { Position = UDim2.fromOffset(0, 0) }):Play()
    TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 3) }):Play()
    
    task.delay(duration, function()
        local outTween = TweenService:Create(notif, Library.TweenInfo, { Position = UDim2.fromOffset(300, 0) })
        outTween:Play()
        outTween.Completed:Wait()
        notif:Destroy()
    end)
end

function Library:CreateWindow(title)
    local guiParent = if RunService:IsStudio() then Players.LocalPlayer:WaitForChild("PlayerGui") else CoreGui
    local existing = guiParent:FindFirstChild("PurpleUILibrary")
    if existing then existing:Destroy() end

    local screenGui = create("ScreenGui", {
        Name = "PurpleUILibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = guiParent
    })

    local mainFrame = create("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(550, 380),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Library.Theme.Background,
        ClipsDescendants = true,
        Parent = screenGui
    })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = mainFrame })
    create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = mainFrame })

    local dragging, dragInput, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and input.Position.Y < mainFrame.AbsolutePosition.Y + 40 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local sidebar = create("Frame", {
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundColor3 = Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = sidebar })

    local titleLabel = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = title or "Purple UI",
        TextColor3 = Library.Theme.Accent,
        Font = Library.Theme.FontBold,
        TextSize = 16,
        Parent = sidebar
    })

    local tabContainer = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -50),
        Position = UDim2.fromOffset(0, 50),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        Parent = sidebar
    })
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = tabContainer })
    create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = tabContainer })

    local contentContainer = create("Frame", {
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.fromOffset(140, 0),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })

    local Window = { Tabs = {}, CurrentTab = nil }

    function Window:CreateTab(name)
        local tabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Library.Theme.Background,
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Library.Theme.TextDim,
            Font = Library.Theme.Font,
            TextSize = 14,
            AutoButtonColor = false,
            Parent = tabContainer
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabBtn })

        local tabContent = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Library.Theme.Border,
            Visible = false,
            Parent = contentContainer
        })
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = tabContent })
        create("UIPadding", { PaddingTop = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), Parent = tabContent })

        tabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Content.Visible = false
                TweenService:Create(t.Button, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                    TextColor3 = Library.Theme.TextDim
                }):Play()
            end
            tabContent.Visible = true
            TweenService:Create(tabBtn, Library.TweenInfo, {
                BackgroundTransparency = 0,
                BackgroundColor3 = Library.Theme.Section,
                TextColor3 = Library.Theme.Accent
            }):Play()
            Window.CurrentTab = name
        end)

        if not Window.CurrentTab then
            tabContent.Visible = true
            tabBtn.BackgroundTransparency = 0
            tabBtn.BackgroundColor3 = Library.Theme.Section
            tabBtn.TextColor3 = Library.Theme.Accent
            Window.CurrentTab = name
        end

        local Tab = { Content = tabContent, Button = tabBtn }
        table.insert(Window.Tabs, Tab)

        function Tab:CreateButton(btnName, callback)
            local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Section,
                Text = "",
                AutoButtonColor = false,
                Parent = tabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
            create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = btn })
            
            local btnText = create("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = btnName,
                TextColor3 = Library.Theme.Text,
                Font = Library.Theme.FontBold,
                TextSize = 14,
                Parent = btn
            })

            btn.MouseEnter:Connect(function() TweenService:Create(btn, Library.TweenInfo, { BackgroundColor3 = Library.Theme.Border }):Play() end)
            btn.MouseLeave:Connect(function() TweenService:Create(btn, Library.TweenInfo, { BackgroundColor3 = Library.Theme.Section }):Play() end)
            btn.MouseButton1Down:Connect(function() TweenService:Create(btn, Library.TweenInfo, { BackgroundColor3 = Library.Theme.Accent }):Play() end)
            btn.MouseButton1Up:Connect(function()
                TweenService:Create(btn, Library.TweenInfo, { BackgroundColor3 = Library.Theme.Border }):Play()
                if callback then callback() end
            end)
        end

        function Tab:CreateToggle(toggleName, flag, default, callback)
            Library.Flags[flag] = default or false
            
            local toggleFrame = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Section,
                Text = "",
                AutoButtonColor = false,
                Parent = tabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = toggleFrame })
            create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = toggleFrame })
            
            create("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = toggleName,
                TextColor3 = Library.Theme.Text,
                Font = Library.Theme.Font,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = toggleFrame
            })

            local toggleBg = create("Frame", {
                Size = UDim2.fromOffset(40, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                BackgroundColor3 = Library.Theme.Background,
                Parent = toggleFrame
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleBg })
            local bgStroke = create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = toggleBg })

            local toggleKnob = create("Frame", {
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.fromOffset(3, 3),
                BackgroundColor3 = Library.Theme.TextDim,
                Parent = toggleBg
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleKnob })

            local function UpdateVisuals()
                local state = Library.Flags[flag]
                local goalPos = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
                local goalBg = state and Library.Theme.Accent or Library.Theme.Background
                local goalKnob = state and Library.Theme.Text or Library.Theme.TextDim
                
                TweenService:Create(toggleKnob, Library.TweenInfo, { Position = goalPos, BackgroundColor3 = goalKnob }):Play()
                TweenService:Create(toggleBg, Library.TweenInfo, { BackgroundColor3 = goalBg }):Play()
            end

            toggleFrame.MouseButton1Click:Connect(function()
                Library.Flags[flag] = not Library.Flags[flag]
                UpdateVisuals()
                if callback then callback(Library.Flags[flag]) end
            end)

            UpdateVisuals()
            if default and callback then callback(default) end
            
            return {
                Set = function(v)
                    Library.Flags[flag] = v
                    UpdateVisuals()
                    if callback then callback(v) end
                end
            }
        end

        function Tab:CreateSlider(sliderName, flag, min, max, default, callback)
            Library.Flags[flag] = default or min
            
            local sliderFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Library.Theme.Section,
                Parent = tabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = sliderFrame })
            create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = sliderFrame })
            
            create("TextLabel", {
                Size = UDim2.new(1, -50, 0, 25),
                Position = UDim2.fromOffset(10, 2),
                BackgroundTransparency = 1,
                Text = sliderName,
                TextColor3 = Library.Theme.Text,
                Font = Library.Theme.Font,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sliderFrame
            })

            local valText = create("TextLabel", {
                Size = UDim2.fromOffset(40, 25),
                Position = UDim2.new(1, -50, 0, 2),
                BackgroundTransparency = 1,
                Text = tostring(Library.Flags[flag]),
                TextColor3 = Library.Theme.Accent,
                Font = Library.Theme.FontBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = sliderFrame
            })

            local trackBtn = create("TextButton", {
                Size = UDim2.new(1, -20, 0, 6),
                Position = UDim2.fromOffset(10, 32),
                BackgroundColor3 = Library.Theme.Background,
                Text = "",
                AutoButtonColor = false,
                Parent = sliderFrame
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackBtn })

            local fill = create("Frame", {
                Size = UDim2.fromScale( (Library.Flags[flag] - min) / (max - min), 1 ),
                BackgroundColor3 = Library.Theme.Accent,
                Parent = trackBtn
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

            local draggingSlider = false
            local function updateSlider(input)
                local relative = math.clamp(input.Position.X - trackBtn.AbsolutePosition.X, 0, trackBtn.AbsoluteSize.X)
                local alpha = relative / trackBtn.AbsoluteSize.X
                local val = math.floor(min + ((max - min) * alpha))
                Library.Flags[flag] = val
                valText.Text = tostring(val)
                TweenService:Create(fill, TweenInfo.new(0.05), { Size = UDim2.fromScale(alpha, 1) }):Play()
                if callback then callback(val) end
            end

            trackBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
            end)

            if default and callback then callback(default) end

            return {
                Set = function(v)
                    v = math.clamp(v, min, max)
                    Library.Flags[flag] = v
                    valText.Text = tostring(v)
                    local alpha = (v - min) / (max - min)
                    TweenService:Create(fill, TweenInfo.new(0.05), { Size = UDim2.fromScale(alpha, 1) }):Play()
                    if callback then callback(v) end
                end
            }
        end

        function Tab:CreateDropdown(dropdownName, flag, options, default, callback)
            Library.Flags[flag] = default or options[1]
            
            local dropFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Library.Theme.Section,
                ClipsDescendants = true,
                Parent = tabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = dropFrame })
            create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = dropFrame })
            
            local dropBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundTransparency = 1,
                Text = "",
                Parent = dropFrame
            })
            
            create("TextLabel", {
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = dropdownName .. " : " .. tostring(Library.Flags[flag]),
                TextColor3 = Library.Theme.Text,
                Font = Library.Theme.Font,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = dropBtn
            })

            local icon = create("TextLabel", {
                Size = UDim2.fromOffset(20, 40),
                Position = UDim2.new(1, -30, 0, 0),
                BackgroundTransparency = 1,
                Text = "+",
                TextColor3 = Library.Theme.TextDim,
                Font = Library.Theme.FontBold,
                TextSize = 18,
                Parent = dropBtn
            })

            local container = create("Frame", {
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.fromOffset(10, 45),
                BackgroundTransparency = 1,
                Parent = dropFrame
            })
            local layout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = container })

            local expanded = false
            local elements = {}

            local function toggleDrop()
                expanded = not expanded
                local targetHeight = expanded and (45 + (#options * 30)) or 40
                TweenService:Create(dropFrame, Library.TweenInfo, { Size = UDim2.new(1, 0, 0, targetHeight) }):Play()
                icon.Text = expanded and "-" or "+"
            end

            dropBtn.MouseButton1Click:Connect(toggleDrop)

            for i, option in ipairs(options) do
                local optBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundColor3 = Library.Theme.Background,
                    Text = option,
                    TextColor3 = Library.Theme.TextDim,
                    Font = Library.Theme.Font,
                    TextSize = 14,
                    AutoButtonColor = false,
                    Parent = container
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = optBtn })

                optBtn.MouseButton1Click:Connect(function()
                    Library.Flags[flag] = option
                    dropBtn:FindFirstChildOfClass("TextLabel").Text = dropdownName .. " : " .. option
                    toggleDrop()
                    if callback then callback(option) end
                end)
            end

            if default and callback then callback(default) end

            return {
                Set = function(v)
                    Library.Flags[flag] = v
                    dropBtn:FindFirstChildOfClass("TextLabel").Text = dropdownName .. " : " .. tostring(v)
                    if callback then callback(v) end
                end
            }
        end

        function Tab:CreateKeybind(bindName, flag, default, callback)
            Library.Flags[flag] = default or Enum.KeyCode.Unknown
            local binding = false

            local bindFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Section,
                Parent = tabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = bindFrame })
            create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = bindFrame })
            
            create("TextLabel", {
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = bindName,
                TextColor3 = Library.Theme.Text,
                Font = Library.Theme.Font,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = bindFrame
            })

            local bindBtn = create("TextButton", {
                Size = UDim2.fromOffset(80, 24),
                Position = UDim2.new(1, -90, 0.5, -12),
                BackgroundColor3 = Library.Theme.Background,
                Text = Library.Flags[flag].Name,
                TextColor3 = Library.Theme.Accent,
                Font = Library.Theme.FontBold,
                TextSize = 12,
                AutoButtonColor = false,
                Parent = bindFrame
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = bindBtn })
            create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = bindBtn })

            bindBtn.MouseButton1Click:Connect(function()
                binding = true
                bindBtn.Text = "..."
                bindBtn.TextColor3 = Library.Theme.TextDim
            end)

            UserInputService.InputBegan:Connect(function(input, processed)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false
                    Library.Flags[flag] = input.KeyCode
                    bindBtn.Text = input.KeyCode.Name
                    bindBtn.TextColor3 = Library.Theme.Accent
                elseif not processed and input.KeyCode == Library.Flags[flag] and input.KeyCode ~= Enum.KeyCode.Unknown then
                    if callback then callback() end
                end
            end)
        end

        function Tab:CreateColorPicker(pickerName, flag, default, callback)
            Library.Flags[flag] = default or Color3.new(1, 1, 1)

            local pickFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Section,
                ClipsDescendants = true,
                Parent = tabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = pickFrame })
            create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = pickFrame })
            
            create("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = pickerName,
                TextColor3 = Library.Theme.Text,
                Font = Library.Theme.Font,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = pickFrame
            })

            local colorDisplay = create("TextButton", {
                Size = UDim2.fromOffset(40, 20),
                Position = UDim2.new(1, -50, 0, 8),
                BackgroundColor3 = Library.Flags[flag],
                Text = "",
                AutoButtonColor = false,
                Parent = pickFrame
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorDisplay })
            create("UIStroke", { Color = Library.Theme.Border, Thickness = 1, Parent = colorDisplay })
            
            local expanded = false
            local container = create("Frame", {
                Size = UDim2.new(1, 0, 0, 90),
                Position = UDim2.fromOffset(0, 40),
                BackgroundTransparency = 1,
                Visible = false,
                Parent = pickFrame
            })
            
            colorDisplay.MouseButton1Click:Connect(function()
                expanded = not expanded
                TweenService:Create(pickFrame, Library.TweenInfo, { Size = UDim2.new(1, 0, 0, expanded and 130 or 36) }):Play()
                container.Visible = expanded
            end)

            local function createColorSlider(cName, yPos, colorRGB)
                local slider = create("TextButton", {
                    Size = UDim2.new(1, -20, 0, 20),
                    Position = UDim2.fromOffset(10, yPos),
                    BackgroundColor3 = Library.Theme.Background,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = container
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = slider })
                
                local fill = create("Frame", {
                    Size = UDim2.fromScale(colorRGB, 1),
                    BackgroundColor3 = Color3.new(cName == "R" and 1 or 0, cName == "G" and 1 or 0, cName == "B" and 1 or 0),
                    Parent = slider
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = fill })
                
                local dragging = false
                slider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                local function updateVal(input)
                    local relative = math.clamp(input.Position.X - slider.AbsolutePosition.X, 0, slider.AbsoluteSize.X)
                    local alpha = relative / slider.AbsoluteSize.X
                    fill.Size = UDim2.fromScale(alpha, 1)
                    return alpha
                end
                
                return {slider = slider, fill = fill, updateVal = updateVal, dragging = function() return dragging end}
            end

            local rSlider = createColorSlider("R", 0, Library.Flags[flag].R)
            local gSlider = createColorSlider("G", 30, Library.Flags[flag].G)
            local bSlider = createColorSlider("B", 60, Library.Flags[flag].B)

            local function updateColor(input)
                local r = rSlider.dragging() and rSlider.updateVal(input) or rSlider.fill.Size.X.Scale
                local g = gSlider.dragging() and gSlider.updateVal(input) or gSlider.fill.Size.X.Scale
                local b = bSlider.dragging() and bSlider.updateVal(input) or bSlider.fill.Size.X.Scale
                local newCol = Color3.new(r, g, b)
                Library.Flags[flag] = newCol
                TweenService:Create(colorDisplay, TweenInfo.new(0.1), { BackgroundColor3 = newCol }):Play()
                if callback then callback(newCol) end
            end

            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if rSlider.dragging() or gSlider.dragging() or bSlider.dragging() then
                        updateColor(input)
                    end
                end
            end)
        end

        return Tab
    end

    return Window
end

function Library:SaveConfig(name)
    if not isfolder("PurpleUI_Configs") then
        makefolder("PurpleUI_Configs")
    end
    
    local serializedFlags = {}
    for k, v in pairs(Library.Flags) do
        if typeof(v) == "Color3" then
            serializedFlags[k] = {Type = "Color3", R = v.R, G = v.G, B = v.B}
        elseif typeof(v) == "EnumItem" then
            serializedFlags[k] = {Type = "KeyCode", Value = v.Name}
        else
            serializedFlags[k] = v
        end
    end
    
    local data = HttpService:JSONEncode(serializedFlags)
    writefile("PurpleUI_Configs/" .. name .. ".json", data)
end

function Library:LoadConfig(name)
    local path = "PurpleUI_Configs/" .. name .. ".json"
    local success, content = pcall(function() return readfile(path) end)
    if success and content then
        local data = HttpService:JSONDecode(content)
        for flag, val in pairs(data) do
            if type(val) == "table" then
                if val.Type == "Color3" then
                    Library.Flags[flag] = Color3.new(val.R, val.G, val.B)
                elseif val.Type == "KeyCode" then
                    Library.Flags[flag] = Enum.KeyCode[val.Value]
                end
            else
                Library.Flags[flag] = val
            end
        end
    end
end

return Library
