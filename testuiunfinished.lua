--!strict
--[[
	NewUI.lua v2.0 — standalone Roblox UI library
	=============================================
	Usage:
		local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/your/repo/NewUI.lua"))()
		local Window = Library:CreateWindow({
			Title = "EXTERNAL // v2.0",
			SubTitle = "Private Build",
			Accent = Color3.fromRGB(130, 80, 255),
			Keybind = Enum.KeyCode.RightControl,
			AnimatedTitle = true,
			TitleAnimationType = "Typewriter", -- "Typewriter" | "GradientShift" | "Glow"
		})
		local Tab = Window:AddTab("Main")
		local Section = Tab:AddSection("Settings", "A tooltip for this section")
		Section:AddToggle({ Text = "Enabled", Flag = "enabled", Default = true, Callback = function(v) end })
		Section:AddSlider({ Text = "Speed", Min = 0, Max = 100, Default = 50, Unit = "%", Flag = "speed" })
		Section:AddDropdown({ Text = "Mode", Items = { "A", "B" }, Default = "A", Flag = "mode" })
		Section:AddKeybind({ Text = "Toggle", Mode = "Toggle", Default = Enum.KeyCode.RightShift, Flag = "key" })
		Section:AddColorPicker({ Text = "Color", Default = Color3.new(1, 0, 0), Flag = "color" })
		Section:AddTextbox({ Text = "Name", Placeholder = "input...", Flag = "name" })
		Section:AddButton({ Text = "Do Thing", Callback = function() end })
		Window:AddConfigSection(Tab, "Configs")
		Library:Notify({ Title = "Loaded", Content = "NewUI ready", Duration = 3, Type = "Success" })

		Library:SaveConfig("my-config"); Library:LoadConfig("my-config")
		Library:SetAccent(Color3.fromRGB(255, 80, 130))
		Library:Destroy()
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local TweenCreate = TweenService.Create
local MathClamp = math.clamp
local MathFloor = math.floor
local MathMax = math.max
local MathMin = math.min
local MathRound = math.round
local TableInsert = table.insert
local TableRemove = table.remove
local TableClear = table.clear
local StringFormat = string.format
local StringLower = string.lower
local StringSub = string.sub
local StringSplit = string.split
local StringFind = string.find
local StringGsub = string.gsub
local TypeOf = typeof

local FONT = Enum.Font.Gotham
local FONT_SEMI = Enum.Font.GothamSemibold
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MONO = Enum.Font.Code

local _GEnv = getgenv()
local _Gethui: any = _GEnv.gethui
	or _GEnv.get_hidden_ui
	or _GEnv.gethiddenui
	or _GEnv.get_hidden_gui
	or _GEnv.gethiddengui

local function GetGuiParent(): Instance
	if _Gethui ~= nil then
		local ok, result = pcall(function()
			return _Gethui()
		end)
		if ok and TypeOf(result) == "Instance" then
			return result
		end
	end
	return CoreGui
end

-- ==================== THEME ====================

local Theme: any = {
	Background = Color3.fromRGB(13, 13, 17),
	Background2 = Color3.fromRGB(20, 20, 27),
	Background3 = Color3.fromRGB(28, 28, 36),
	Border = Color3.fromRGB(42, 42, 56),
	Hover = Color3.fromRGB(42, 42, 56),
	Text = Color3.fromRGB(228, 228, 240),
	TextDim = Color3.fromRGB(138, 138, 156),
	Accent = Color3.fromRGB(130, 80, 255),
	Success = Color3.fromRGB(84, 200, 130),
	Warning = Color3.fromRGB(242, 176, 62),
	Danger = Color3.fromRGB(238, 82, 82),
	_Listeners = {},
}

local function ThemeBind(cb: () -> ())
	TableInsert(Theme._Listeners, cb)
end

local function ThemeFire()
	for _, cb in Theme._Listeners do
		pcall(cb)
	end
end

-- ==================== LIBRARY CORE ====================

local Lib: any = {
	Version = "2.0.0",
	Flags = {},
	Configs = {},
	Windows = {},
	Elements = {},
	Connections = {},
	_FlagMap = {},
	_Notifications = {},
	_MaxZ = 50,
	_Destroyed = false,
}

local function Connect(sig: any, fn: any): RBXScriptConnection
	local conn = sig:Connect(fn)
	TableInsert(Lib.Connections, conn)
	return conn
end

local function New(className: string, parent: Instance?, props: { [string]: any }?): any
	local obj: any = Instance.new(className)
	if props ~= nil then
		for key, value in props do
			obj[key] = value
		end
	end
	if parent ~= nil then
		obj.Parent = parent
	end
	return obj
end

local function Tween(obj: any, info: TweenInfo, goal: { [string]: any }): Tween
	return TweenCreate(TweenService, obj, info, goal)
end

local function TweenPlay(t: Tween): Tween
	t:Play()
	return t
end

local function AddCorner(obj: any, radius: number): any
	local corner: any = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = obj
	return corner
end

local function AddStroke(obj: any, color: Color3?, thickness: number?, transparency: number?): any
	local stroke: any = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = obj
	return stroke
end

local function AddGradient(obj: any, keypoints: { ColorSequenceKeypoint }, rotation: number?): any
	local gradient: any = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(keypoints)
	gradient.Rotation = rotation or 0
	gradient.Parent = obj
	return gradient
end

local function TextLabel(parent: any, textStr: string, size: number?, font: Enum.Font?, color: Color3?, xalign: Enum.TextXAlignment?): any
	local label = New("TextLabel", parent, {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = textStr,
		Font = font or FONT,
		TextSize = size or 13,
		TextColor3 = color or Theme.Text,
		TextXAlignment = xalign or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	return label
end

local function PointInRect(point: Vector2, frame: any): boolean
	local pos = frame.AbsolutePosition
	local size = frame.AbsoluteSize
	return point.X >= pos.X
		and point.X <= pos.X + size.X
		and point.Y >= pos.Y
		and point.Y <= pos.Y + size.Y
end

local function Color3ToHex(color: Color3): string
	return StringFormat("#%02X%02X%02X", MathFloor(color.R * 255 + 0.5), MathFloor(color.G * 255 + 0.5), MathFloor(color.B * 255 + 0.5))
end

local function HexToColor3(hex: string): (Color3?, string?)
	local clean = StringGsub(hex, "#", "")
	if #clean ~= 6 then
		return nil, "invalid hex length"
	end
	local ok, result = pcall(Color3.fromHex, clean)
	if ok and TypeOf(result) == "Color3" then
		return result, nil
	end
	return nil, "invalid hex"
end

local KEY_NAMES: { [string]: string } = {
	RightControl = "RCtrl",
	LeftControl = "LCtrl",
	RightShift = "RShift",
	LeftShift = "LShift",
	RightAlt = "RAlt",
	LeftAlt = "LAlt",
	MouseButton1 = "M1",
	MouseButton2 = "M2",
	MouseButton3 = "M3",
	Backspace = "BkSp",
	Return = "Enter",
	CapsLock = "Caps",
	MouseWheel = "MWheel",
	Unknown = "None",
	None = "None",
}

local function KeyName(key: any): string
	if TypeOf(key) == "EnumItem" then
		if key.EnumType == Enum.KeyCode then
			return KEY_NAMES[key.Name] or key.Name
		elseif key.EnumType == Enum.UserInputType then
			return KEY_NAMES[key.Name] or key.Name
		end
	end
	return "None"
end

local function KeyFromName(name: any): any
	if name == nil or name == "" or name == "None" or name == "Unknown" then
		return Enum.KeyCode.Unknown
	end
	local ok1, kc = pcall(function()
		return Enum.KeyCode[name]
	end)
	if ok1 and kc ~= nil then
		return kc
	end
	local ok2, uit = pcall(function()
		return Enum.UserInputType[name]
	end)
	if ok2 and uit ~= nil then
		return uit
	end
	return Enum.KeyCode.Unknown
end

local function InputMatches(input: InputObject, key: any): boolean
	if TypeOf(key) ~= "EnumItem" then
		return false
	end
	if key.EnumType == Enum.KeyCode then
		return input.KeyCode == key
	elseif key.EnumType == Enum.UserInputType then
		return input.UserInputType == key
	end
	return false
end

local function IsTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

-- ==================== FILE / CONFIG ====================

local function EnsureConfigFolder(): boolean
	local okFolder, isFolder = pcall(isfolder, "ExternalConfigs")
	if not okFolder or not isFolder then
		return pcall(makefolder, "ExternalConfigs")
	end
	return true
end

function Lib:SaveConfig(name: string): boolean
	local trimmed = StringGsub(tostring(name or ""), "%.json$", "")
	trimmed = StringGsub(trimmed, "[^%w%-_ ]", "")
	if trimmed == "" then
		trimmed = "config"
	end
	if not EnsureConfigFolder() then
		return false
	end
	local payload = {
		Version = Lib.Version,
		Name = trimmed,
		SavedAt = os.time(),
		Flags = Lib.Flags,
	}
	local ok, json = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok then
		return false
	end
	return pcall(writefile, "ExternalConfigs/" .. trimmed .. ".json", json)
end

function Lib:LoadConfig(name: string): boolean
	local path = "ExternalConfigs/" .. tostring(name or "") .. ".json"
	local ok, raw = pcall(readfile, path)
	if not ok or TypeOf(raw) ~= "string" then
		return false
	end
	local ok2, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok2 or TypeOf(data) ~= "table" then
		return false
	end
	local flags = data.Flags
	if TypeOf(flags) ~= "table" then
		return false
	end
	for flag, value in flags do
		local element = Lib._FlagMap[flag]
		if element ~= nil and element.SetValue ~= nil then
			pcall(function()
				element:SetValue(value)
			end)
		else
			Lib.Flags[flag] = value
		end
	end
	return true
end

function Lib:RefreshConfigs(): { string }
	local out: { string } = {}
	local okFolder, isFolder = pcall(isfolder, "ExternalConfigs")
	if okFolder and isFolder then
		local ok, files = pcall(listfiles, "ExternalConfigs")
		if ok and TypeOf(files) == "table" then
			for _, file in files do
				if TypeOf(file) == "string" then
					local parts = StringSplit(file, "\\")
					local name = parts[#parts]
					parts = StringSplit(name, "/")
					name = parts[#parts]
					if StringLower(StringSub(name, -5)) == ".json" then
						TableInsert(out, StringSub(name, 1, -6))
					end
				end
			end
		end
	end
	Lib.Configs = out
	return out
end

function Lib:DeleteConfig(name: string): boolean
	return pcall(delfile, "ExternalConfigs/" .. tostring(name or "") .. ".json")
end

function Lib:GetFlag(flag: string, default: any): any
	local value = Lib.Flags[flag]
	if value == nil then
		return default
	end
	return value
end

-- ==================== THEME API ====================

function Lib:SetTheme(overrides: { [string]: any })
	for key, value in overrides do
		Theme[key] = value
	end
	ThemeFire()
end

function Lib:SetAccent(color: Color3)
	Theme.Accent = color
	ThemeFire()
end

function Lib:GetTheme(): any
	return Theme
end

-- ==================== ELEMENTS ====================

local function LibUpdateFlag(element: any)
	if element.Flag ~= nil and element.Flag ~= "" then
		Lib._FlagMap[element.Flag] = element
		Lib.Flags[element.Flag] = element:Serialize()
	end
end

local function StubElement(): any
	return {
		Type = "Stub",
		Height = 30,
		Object = nil,
		Connections = {},
		SetValue = function() end,
		GetValue = function()
			return nil
		end,
		Serialize = function()
			return nil
		end,
		OnChanged = function() end,
		AddKeybind = function() end,
		Destroy = function() end,
	}
end

local function GuardBuild(name: string, fn: () -> any): any
	local ok, result = pcall(fn)
	if ok then
		return result
	end
	warn(("[NewUI] %s failed to build: %s"):format(name, tostring(result)))
	return StubElement()
end

local function BuildElement(section: any, height: number, class: string, opts: any?): any
	local element: any = {
		Type = class,
		Section = section,
		Height = height,
		Connections = {},
		Callbacks = {},
		Destroyed = false,
	}
	if opts ~= nil and opts.Callback ~= nil then
		TableInsert(element.Callbacks, opts.Callback)
	end
	element.Object = New("Frame", section.Body, {
		Size = UDim2.new(1, -20, 0, height),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})
	TableInsert(section.Elements, element)
	TableInsert(Lib.Elements, element)
	element.Connect = function(_, signal: any, fn: any): RBXScriptConnection
		local conn = signal:Connect(fn)
		TableInsert(element.Connections, conn)
		TableInsert(Lib.Connections, conn)
		return conn
	end
	element.FireCallbacks = function(_, ...: any)
		for _, cb in element.Callbacks do
			pcall(cb, ...)
		end
	end
	element.OnChanged = function(_, cb: any)
		TableInsert(element.Callbacks, cb)
		return element
	end
	element.Destroy = function()
		if element.Destroyed then
			return
		end
		element.Destroyed = true
		for _, conn in element.Connections do
			pcall(conn.Disconnect, conn)
		end
		TableClear(element.Connections)
		if element.Object ~= nil then
			pcall(element.Object.Destroy, element.Object)
		end
	end
	return element
end

local function ElementLabel(element: any, textStr: string, width: number?, size: number?)
	local label = TextLabel(element.Object, textStr, size or 13, FONT_SEMI, Theme.Text, Enum.TextXAlignment.Left)
	label.Size = UDim2.fromOffset(width or 130, size or 14)
	label.Position = UDim2.fromOffset(0, (element.Height - (size or 14)) / 2)
	return label
end

local function ScheduleLayout(section: any)
	task.defer(function()
		if section.Destroyed then
			return
		end
		local y = 22
		for _, element in section.Elements do
			if element.Object ~= nil then
				element.Object.Position = UDim2.fromOffset(10, y)
				y += element.Height
			end
		end
		section.Body.Size = UDim2.new(1, 0, 0, y + 6)
		section.Root.Size = UDim2.new(1, 0, 0, y + 28)
		for _, element in section.Elements do
			if element.Repaint ~= nil then
				pcall(element.Repaint)
			end
		end
		LayoutTab(section.Tab)
	end)
end

local function LayoutTab(tab: any)
	task.defer(function()
		if tab.Destroyed then
			return
		end
		local leftH = 6
		local rightH = 6
		for _, section in tab.LeftSections do
			if section.Root ~= nil then
				leftH += section.Root.AbsoluteSize.Y + 8
			end
		end
		for _, section in tab.RightSections do
			if section.Root ~= nil then
				rightH += section.Root.AbsoluteSize.Y + 8
			end
		end
		local width = MathMax(tab.Content.AbsoluteSize.X, 100)
		local height = MathMax(leftH, rightH)
		tab.Content.CanvasSize = UDim2.fromOffset(MathFloor(width), MathFloor(height))
		tab.Left.Size = UDim2.new(0.5, -6, 0, height)
		tab.Right.Size = UDim2.new(0.5, -6, 0, height)
	end)
end

-- ==================== TOOLTIP ====================

local TooltipFrame: any = nil
local TooltipAlive = false

local function HideTooltip()
	TooltipAlive = false
	if TooltipFrame ~= nil then
		local frame = TooltipFrame
		TooltipFrame = nil
		TweenPlay(Tween(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 1,
		})):Completed:Connect(function()
			pcall(frame.Destroy, frame)
		end)
	end
end

local function ShowTooltip(textStr: string, target: any)
	HideTooltip()
	TooltipAlive = true
	local layer = Lib.GUI
	if layer == nil then
		return
	end
	local camera = game.Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local measure = TextService:GetTextSize(textStr, 12, FONT, Vector2.new(600, 60))
	local width = measure.X + 24
	local frame = New("CanvasGroup", layer, {
		Size = UDim2.fromOffset(width, 30),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Background2,
		BackgroundTransparency = 0.05,
		GroupTransparency = 1,
		ZIndex = 300,
	})
	AddCorner(frame, 6)
	AddStroke(frame, Theme.Border, 1, 0.2)
	local label = TextLabel(frame, textStr, 12, FONT, Theme.Text, Enum.TextXAlignment.Left)
	label.Size = UDim2.new(1, -16, 0, 12)
	label.Position = UDim2.fromOffset(8, 8)
	TooltipFrame = frame
	task.defer(function()
		if not TooltipAlive or TooltipFrame ~= frame then
			return
		end
		local viewport = camera.ViewportSize
		local pos = target.AbsolutePosition
		local x = MathClamp(pos.X + target.AbsoluteSize.X / 2 - width / 2, 4, viewport.X - width - 4)
		local y = pos.Y - 36
		if y < 4 then
			y = pos.Y + target.AbsoluteSize.Y + 6
		end
		frame.Position = UDim2.fromOffset(MathFloor(x), MathFloor(y))
		TweenPlay(Tween(frame, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
		}))
	end)
end

-- ==================== SECTIONS ====================

local SectionMethods: any = {}

local function BuildSection(tab: any, column: string, name: string, tooltip: string?)
	local section: any = {
		Type = "Section",
		Name = name,
		Tab = tab,
		Elements = {},
		Connections = {},
		Destroyed = false,
	}
	section.Root = New("Frame", tab[column], {
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
	})
	local header = New("Frame", section.Root, {
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
	})
	local nameLabel = TextLabel(header, name, 13, FONT_BOLD, Theme.Text, Enum.TextXAlignment.Left)
	nameLabel.Size = UDim2.new(1, -20, 0, 14)
	nameLabel.Position = UDim2.fromOffset(0, 2)
	nameLabel.TextTransparency = 0.15
	if tooltip ~= nil and tooltip ~= "" then
		local tip = New("TextButton", header, {
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(1, -14, 0, 2),
			BackgroundTransparency = 1,
			Text = "?",
			Font = FONT_BOLD,
			TextSize = 12,
			TextColor3 = Theme.TextDim,
			AutoButtonColor = false,
			ZIndex = 4,
		})
		TableInsert(section.Connections, Connect(tip.MouseEnter, function()
			ShowTooltip(tooltip, tip)
		end))
		TableInsert(section.Connections, Connect(tip.MouseLeave, HideTooltip))
	end
	section.Body = New("Frame", section.Root, {
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundTransparency = 1,
	})

	if column == "Left" then
		TableInsert(tab.LeftSections, section)
	else
		TableInsert(tab.RightSections, section)
	end

	for methodName, methodFn in SectionMethods do
		section[methodName] = methodFn
	end

	return section
end

-- ==================== TOGGLE ====================

local function BuildToggle(section: any, opts: any): any
	local element = BuildElement(section, 30, "Toggle", opts)
	element.Flag = opts.Flag
	element.Default = opts.Default == true
	ElementLabel(element, opts.Text or opts.Flag or "Toggle")

	local pill = New("Frame", element.Object, {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -38, 0, 5),
		BackgroundColor3 = Theme.Background3,
		BackgroundTransparency = 0,
		ZIndex = 2,
	})
	AddCorner(pill, 10)
	local stroke = AddStroke(pill, Theme.Border, 1)

	local knob = New("Frame", pill, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Theme.Text,
		ZIndex = 3,
	})
	AddCorner(knob, 7)

	local button = New("TextButton", pill, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
	})

	local value = element.Default

	local function Paint()
		TweenPlay(Tween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(value and 21 or 3, 3),
			BackgroundColor3 = value and Theme.Text or Theme.TextDim,
		}))
		TweenPlay(Tween(pill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = value and Theme.Accent or Theme.Background3,
		}))
		TweenPlay(Tween(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = value and Theme.Accent or Theme.Border,
		}))
	end

	element.SetValue = function(_, newValue: boolean)
		value = newValue and true or false
		Paint()
		LibUpdateFlag(element)
		return element
	end
	element.GetValue = function()
		return value
	end
	element.Serialize = function()
		return value
	end
	element.RefreshTheme = function()
		Paint()
	end
	element.AddKeybind = function(_, keyopts: any)
		local keyDefaults = keyopts or {}
		local chip = New("TextButton", element.Object, {
			Size = UDim2.fromOffset(40, 18),
			Position = UDim2.new(1, -84, 0, 6),
			BackgroundColor3 = Theme.Background3,
			Text = KeyName(keyDefaults.Default),
			Font = FONT,
			TextSize = 10,
			TextColor3 = Theme.Text,
			AutoButtonColor = false,
			ZIndex = 4,
		})
		AddCorner(chip, 6)
		AddStroke(chip, Theme.Border, 1)
		local capturing = false
		local boundKey: any = keyDefaults.Default
		local chipConn = Connect(chip.MouseButton1Click, function()
			if capturing then
				return
			end
			capturing = true
			chip.Text = "..."
		end)
		local captureConn = Connect(UserInputService.InputBegan, function(input: InputObject, gameProcessed: boolean)
			if not capturing or gameProcessed then
				return
			end
			local inputType = input.UserInputType
			if inputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					capturing = false
					chip.Text = KeyName(boundKey)
					return
				end
				if input.KeyCode ~= Enum.KeyCode.Unknown then
					boundKey = input.KeyCode
					capturing = false
					chip.Text = KeyName(boundKey)
				end
			elseif inputType == Enum.UserInputType.MouseButton1
				or inputType == Enum.UserInputType.MouseButton2
				or inputType == Enum.UserInputType.MouseButton3
			then
				boundKey = inputType
				capturing = false
				chip.Text = KeyName(boundKey)
			end
		end)
		local keyConn = Connect(UserInputService.InputBegan, function(input: InputObject, gameProcessed: boolean)
			if capturing or IsTyping() or gameProcessed then
				return
			end
			if InputMatches(input, boundKey) then
				element:SetValue(not value)
				element:FireCallbacks(value)
			end
		end)
		element.SetKey = function(_, key: any)
			if TypeOf(key) == "string" then
				key = KeyFromName(key)
			end
			boundKey = key
			chip.Text = KeyName(boundKey)
			LibUpdateFlag(element)
			return element
		end
		element.GetKey = function()
			return boundKey
		end
		element.Serialize = function()
			if boundKey ~= nil and TypeOf(boundKey) == "EnumItem" then
				return boundKey.Name
			end
			return value
		end
		element.SetValue = function(_, newValue: boolean)
			value = newValue and true or false
			Paint()
			LibUpdateFlag(element)
			return element
		end
		TableInsert(element.Connections, chipConn)
		TableInsert(element.Connections, captureConn)
		TableInsert(element.Connections, keyConn)
		return element
	end

	element:Connect(button.MouseButton1Click, function()
		element:SetValue(not value)
		element:FireCallbacks(value)
	end)

	if opts.Keybind ~= nil then
		element:AddKeybind(opts.Keybind)
	end

	element:SetValue(element.Default)

	return element
end

-- ==================== SLIDER ====================

local function BuildSlider(section: any, opts: any): any
	local element = BuildElement(section, 46, "Slider", opts)
	element.Flag = opts.Flag
	element.Min = opts.Min or 0
	element.Max = opts.Max or 100
	element.Decimals = opts.Decimals or 2
	element.Step = opts.Step
	element.Unit = opts.Unit or ""
	element.Default = opts.Default

	local minVal = element.Min
	local maxVal = element.Max
	local stepVal = element.Step or (10 ^ (-element.Decimals))
	local unit = element.Unit
	local decimals = element.Decimals

	ElementLabel(element, opts.Text or opts.Flag or "Slider")

	local valueBox = New("TextBox", element.Object, {
		Size = UDim2.fromOffset(64, 18),
		Position = UDim2.new(1, -64, 0, 1),
		BackgroundColor3 = Theme.Background3,
		Font = FONT,
		TextSize = 11,
		TextColor3 = Theme.Text,
		Text = "",
		PlaceholderText = "0",
		PlaceholderColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false,
		ZIndex = 3,
	})
	AddCorner(valueBox, 5)
	AddStroke(valueBox, Theme.Border, 1)

	local track = New("Frame", element.Object, {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromOffset(0, 32),
		BackgroundColor3 = Theme.Background3,
		ZIndex = 2,
	})
	AddCorner(track, 3)
	AddStroke(track, Theme.Border, 1)

	local fill = New("Frame", track, {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Accent,
		ZIndex = 2,
	})
	AddCorner(fill, 3)

	local knob = New("Frame", track, {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(-6, -3),
		BackgroundColor3 = Theme.Text,
		ZIndex = 3,
	})
	AddCorner(knob, 6)
	local knobStroke = AddStroke(knob, Theme.Accent, 1.5)

	local value = element.Default
	local dragging = false

	local function FormatValue(v: number): string
		return StringFormat("%." .. tostring(decimals) .. "f", v) .. unit
	end

	local function Snap(raw: number): number
		local snapped = MathRound((raw - minVal) / stepVal) * stepVal + minVal
		return MathClamp(snapped, minVal, maxVal)
	end

	local function Paint()
		local trackWidth = MathMax(track.AbsoluteSize.X, 1)
		local frac = MathClamp((value - minVal) / MathMax(maxVal - minVal, 0.0001), 0, 1)
		fill.Size = UDim2.fromScale(frac, 1)
		knob.Position = UDim2.fromOffset(frac * (trackWidth - 6) - 6, -3)
		valueBox.Text = FormatValue(value)
	end

	local function Apply(v: number, fire: boolean)
		value = Snap(v)
		Paint()
		LibUpdateFlag(element)
		if fire then
			element:FireCallbacks(value)
		end
	end

	element.SetValue = function(_, newValue: number)
		Apply(newValue, false)
		return element
	end
	element.GetValue = function()
		return value
	end
	element.Serialize = function()
		return value
	end
	element:Repaint = Paint
	element.RefreshTheme = function()
		fill.BackgroundColor3 = Theme.Accent
		knobStroke.Color = Theme.Accent
	end

	element:Connect(track.InputBegan, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			local mouse = UserInputService:GetMouseLocation()
			local frac = (mouse.X - track.AbsolutePosition.X) / MathMax(track.AbsoluteSize.X, 1)
			Apply(minVal + frac * (maxVal - minVal), true)
		end
	end)

	element:Connect(UserInputService.InputEnded, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	element:Connect(UserInputService.InputChanged, function(input: InputObject)
		if dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch)
		then
			local mouse = UserInputService:GetMouseLocation()
			local frac = (mouse.X - track.AbsolutePosition.X) / MathMax(track.AbsoluteSize.X, 1)
			Apply(minVal + frac * (maxVal - minVal), true)
		end
	end)

	element:Connect(valueBox.FocusLost, function(enterPressed: boolean)
		local parsed = tonumber(StringGsub(valueBox.Text, "[^%d%.%-]", ""))
		if parsed ~= nil then
			Apply(parsed, true)
		else
			Apply(value, true)
		end
	end)

	element:Connect(valueBox:GetPropertyChangedSignal("Text"), function()
		local current = valueBox.Text
		local cleaned = StringGsub(current, "[^%d%.%-]", "")
		if cleaned ~= current then
			valueBox.Text = cleaned
		end
	end)

	element:SetValue(element.Default or minVal)

	return element
end

-- ==================== DROPDOWN ====================

local function BuildDropdown(section: any, opts: any): any
	local element = BuildElement(section, 30, "Dropdown", opts)
	element.Flag = opts.Flag
	element.Multi = opts.MultiSelect == true
	element.Search = opts.Search == true
	element.Items = {}
	for _, item in opts.Items or {} do
		TableInsert(element.Items, tostring(item))
	end

	local window = section.Tab.Window

	local row = New("TextButton", element.Object, {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 3),
		BackgroundColor3 = Theme.Background3,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})
	AddCorner(row, 6)
	local rowStroke = AddStroke(row, Theme.Border, 1)

	local titleLabel = TextLabel(row, opts.Text or opts.Flag or "Dropdown", 12, FONT_SEMI, Theme.Text, Enum.TextXAlignment.Left)
	titleLabel.Size = UDim2.fromOffset(120, 14)
	titleLabel.Position = UDim2.fromOffset(8, 5)

	local valueLabel = TextLabel(row, "None", 12, FONT, Theme.TextDim, Enum.TextXAlignment.Left)
	valueLabel.Size = UDim2.new(1, -160, 0, 14)
	valueLabel.Position = UDim2.fromOffset(128, 5)
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right

	local chevron = TextLabel(row, "▾", 12, FONT_SEMI, Theme.TextDim, Enum.TextXAlignment.Right)
	chevron.Size = UDim2.fromOffset(16, 14)
	chevron.Position = UDim2.new(1, -20, 0, 5)

	local list: any = nil
	local listScroll: any = nil
	local listSearch: any = nil
	local open = false

	local selected: { [string]: boolean } = {}

	local function SelectedArray(): { string }
		local out: { string } = {}
		for item, isSelected in selected do
			if isSelected then
				TableInsert(out, item)
			end
		end
		return out
	end

	local function IsSelected(item: string): boolean
		return selected[item] == true
	end

	local function UpdateValueLabel()
		if element.Multi then
			local arr = SelectedArray()
			valueLabel.Text = #arr == 0 and "None" or (#arr .. " selected")
		else
			local found = ""
			for item, isSelected in selected do
				if isSelected then
					found = item
					break
				end
			end
			valueLabel.Text = found == "" and "None" or found
		end
	end

	local function Emit()
		LibUpdateFlag(element)
		if element.Multi then
			element:FireCallbacks(SelectedArray())
		else
			local found = ""
			for item, isSelected in selected do
				if isSelected then
					found = item
					break
				end
			end
			element:FireCallbacks(found)
		end
	end

	local Close: any = nil

	local function BuildRows(filter: string)
		if listScroll == nil then
			return
		end
		for _, child in listScroll:GetChildren() do
			if child:IsA("TextButton") then
				pcall(child.Destroy, child)
			end
		end
		local y = 0
		local lowerFilter = StringLower(filter or "")
		for _, item in element.Items do
			if lowerFilter == "" or StringFind(StringLower(item), lowerFilter, 1, true) ~= nil then
				local isSelected = IsSelected(item)
				local rowBtn = New("TextButton", listScroll, {
					Size = UDim2.new(1, -6, 0, 24),
					Position = UDim2.fromOffset(3, y),
					BackgroundColor3 = isSelected and Theme.Background2 or Theme.Background3,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 4,
				})
				AddCorner(rowBtn, 4)
				local itemLabel = TextLabel(rowBtn, item, 12, FONT, isSelected and Theme.Accent or Theme.Text, Enum.TextXAlignment.Left)
				itemLabel.Size = UDim2.new(1, -26, 0, 14)
				itemLabel.Position = UDim2.fromOffset(8, 5)
				if element.Multi or isSelected then
					local check = TextLabel(rowBtn, isSelected and "✓" or "", 12, FONT_BOLD, Theme.Accent, Enum.TextXAlignment.Right)
					check.Size = UDim2.fromOffset(16, 14)
					check.Position = UDim2.new(1, -20, 0, 5)
				end
				Connect(rowBtn.MouseButton1Click, function()
					selected[item] = not IsSelected(item)
					if not element.Multi then
						for other, _ in selected do
							if other ~= item then
								selected[other] = false
							end
						end
					end
					UpdateValueLabel()
					Emit()
					BuildRows(filter)
					if not element.Multi then
						Close()
					end
				end)
				y += 24
			end
		end
		listScroll.CanvasSize = UDim2.fromOffset(0, y)
	end

	Close = function()
		if not open then
			return
		end
		open = false
		if list ~= nil then
			TweenPlay(Tween(list, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				GroupTransparency = 1,
			})):Completed:Connect(function()
				if not open and list ~= nil then
					list.Visible = false
				end
			end)
			chevron.Rotation = 0
		end
		rowStroke.Color = Theme.Border
	end

	local function Open()
		if open then
			Close()
			return
		end
		open = true
		if list == nil then
			list = New("CanvasGroup", window.Root, {
				Size = UDim2.fromOffset(200, 100),
				Position = UDim2.fromOffset(0, 0),
				BackgroundColor3 = Theme.Background2,
				BackgroundTransparency = 0,
				GroupTransparency = 1,
				Visible = false,
				ZIndex = 60,
			})
			AddCorner(list, 8)
			AddStroke(list, Theme.Border, 1)
			local top = 4
			if element.Search then
				listSearch = New("TextBox", list, {
					Size = UDim2.new(1, -12, 0, 22),
					Position = UDim2.fromOffset(6, 4),
					BackgroundColor3 = Theme.Background3,
					Font = FONT,
					TextSize = 11,
					TextColor3 = Theme.Text,
					Text = "",
					PlaceholderText = "Search...",
					PlaceholderColor3 = Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Center,
					ClearTextOnFocus = false,
					ZIndex = 5,
				})
				AddCorner(listSearch, 5)
				AddStroke(listSearch, Theme.Border, 1)
				Connect(listSearch:GetPropertyChangedSignal("Text"), function()
					BuildRows(listSearch.Text)
				end)
				top = 30
			end
			listScroll = New("ScrollingFrame", list, {
				Size = UDim2.new(1, -8, 0, 1),
				Position = UDim2.fromOffset(4, top),
				BackgroundTransparency = 1,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Theme.Border,
				CanvasSize = UDim2.fromOffset(0, 0),
				ZIndex = 5,
			})
		end
		local yOffset = row.AbsolutePosition.Y + row.AbsoluteSize.Y - window.Root.AbsolutePosition.Y
		local xOffset = row.AbsolutePosition.X - window.Root.AbsolutePosition.X
		local width = MathMax(row.AbsoluteSize.X, 120)
		local count = 0
		for _ in element.Items do
			count += 1
		end
		local maxHeight = element.Search and 178 or 150
		local contentH = count * 24 + (element.Search and 30 or 6)
		local height = MathMin(contentH, maxHeight)
		list.Position = UDim2.fromOffset(MathFloor(xOffset), MathFloor(yOffset))
		list.Size = UDim2.fromOffset(MathFloor(width), MathFloor(height))
		listScroll.Size = UDim2.new(1, -8, 0, height - (element.Search and 32 or 4))
		list.Visible = true
		BuildRows(listSearch ~= nil and listSearch.Text or "")
		TweenPlay(Tween(list, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
		}))
		chevron.Rotation = 180
		rowStroke.Color = Theme.Accent
	end

	element.Close = Close

	local outsideConn = Connect(UserInputService.InputBegan, function(input: InputObject)
		if not open then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local mouse = UserInputService:GetMouseLocation()
		if list ~= nil and PointInRect(mouse, list) then
			return
		end
		if PointInRect(mouse, row) then
			return
		end
		Close()
	end)

	element:Connect(row.MouseButton1Click, Open)
	TableInsert(element.Connections, outsideConn)

	element.SetValue = function(_, newValue: any)
		for item in selected do
			selected[item] = false
		end
		if element.Multi then
			if TypeOf(newValue) == "table" then
				for _, item in newValue do
					selected[tostring(item)] = true
				end
			end
		else
			if TypeOf(newValue) == "string" then
				for _, item in element.Items do
					if item == newValue then
						selected[item] = true
					end
				end
			end
		end
		UpdateValueLabel()
		LibUpdateFlag(element)
		if list ~= nil then
			BuildRows(listSearch ~= nil and listSearch.Text or "")
		end
		return element
	end
	element.GetValue = function()
		if element.Multi then
			return SelectedArray()
		end
		for item, isSelected in selected do
			if isSelected then
				return item
			end
		end
		return nil
	end
	element.Serialize = function()
		if element.Multi then
			return SelectedArray()
		end
		for item, isSelected in selected do
			if isSelected then
				return item
			end
		end
		return ""
	end
	element.RefreshItems = function(_, items: { string })
		TableClear(element.Items)
		for _, item in items do
			TableInsert(element.Items, tostring(item))
		end
		for item in selected do
			selected[item] = false
		end
		UpdateValueLabel()
		if list ~= nil then
			BuildRows(listSearch ~= nil and listSearch.Text or "")
		end
		return element
	end
	element.RefreshTheme = function()
		rowStroke.Color = open and Theme.Accent or Theme.Border
	end
	element.Destroy = function()
		if element.Destroyed then
			return
		end
		element.Destroyed = true
		for _, conn in element.Connections do
			pcall(conn.Disconnect, conn)
		end
		TableClear(element.Connections)
		if element.Object ~= nil then
			pcall(element.Object.Destroy, element.Object)
		end
		if list ~= nil then
			pcall(list.Destroy, list)
		end
	end

	element:SetValue(opts.Default)

	return element
end

-- ==================== KEYBIND ====================

local function BuildKeybind(section: any, opts: any): any
	local element = BuildElement(section, 30, "Keybind")
	element.Flag = opts.Flag
	element.Mode = opts.Mode or "Toggle"
	ElementLabel(element, opts.Text or opts.Flag or "Keybind")

	local chip = New("TextButton", element.Object, {
		Size = UDim2.fromOffset(80, 20),
		Position = UDim2.new(1, -80, 0, 5),
		BackgroundColor3 = Theme.Background3,
		Text = "None",
		Font = FONT,
		TextSize = 11,
		TextColor3 = Theme.Text,
		AutoButtonColor = false,
		ZIndex = 3,
	})
	AddCorner(chip, 6)
	AddStroke(chip, Theme.Border, 1)

	local boundKey: any = opts.Default
	local capturing = false
	local state = false

	element.SetKey = function(_, key: any)
		if TypeOf(key) == "string" then
			key = KeyFromName(key)
		end
		boundKey = key
		chip.Text = KeyName(boundKey)
		LibUpdateFlag(element)
		return element
	end
	element.GetKey = function()
		return boundKey
	end
	element.SetValue = function(_, key: any)
		element:SetKey(key)
		return element
	end
	element.GetValue = function()
		return boundKey
	end
	element.Serialize = function()
		if boundKey ~= nil and TypeOf(boundKey) == "EnumItem" then
			return boundKey.Name
		end
		return "Unknown"
	end
	element.RefreshTheme = function() end

	element:Connect(chip.MouseButton1Click, function()
		if capturing then
			return
		end
		capturing = true
		chip.Text = "..."
	end)

	element:Connect(UserInputService.InputBegan, function(input: InputObject, gameProcessed: boolean)
		if capturing then
			if gameProcessed then
				return
			end
			local inputType = input.UserInputType
			if inputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					capturing = false
					chip.Text = KeyName(boundKey)
					return
				end
				if input.KeyCode ~= Enum.KeyCode.Unknown then
					boundKey = input.KeyCode
					capturing = false
					chip.Text = KeyName(boundKey)
					LibUpdateFlag(element)
				end
			elseif inputType == Enum.UserInputType.MouseButton1
				or inputType == Enum.UserInputType.MouseButton2
				or inputType == Enum.UserInputType.MouseButton3
			then
				boundKey = inputType
				capturing = false
				chip.Text = KeyName(boundKey)
				LibUpdateFlag(element)
			end
			return
		end
		if IsTyping() or gameProcessed then
			return
		end
		if not InputMatches(input, boundKey) then
			return
		end
		if element.Mode == "Toggle" then
			state = not state
			element:FireCallbacks(boundKey, state)
		elseif element.Mode == "Hold" then
			state = true
			element:FireCallbacks(boundKey, true)
		else
			element:FireCallbacks(boundKey, true)
		end
	end)

	element:Connect(UserInputService.InputEnded, function(input: InputObject)
		if element.Mode == "Hold" and InputMatches(input, boundKey) and not capturing then
			state = false
			element:FireCallbacks(boundKey, false)
		end
	end)

	element:SetKey(boundKey)

	return element
end

-- ==================== COLOR PICKER ====================

local function BuildColorPicker(section: any, opts: any): any
	local element = BuildElement(section, 30, "ColorPicker")
	element.Flag = opts.Flag
	element.TransparencyEnabled = opts.TransparencyEnabled ~= false
	ElementLabel(element, opts.Text or opts.Flag or "Color")

	local swatch = New("TextButton", element.Object, {
		Size = UDim2.fromOffset(90, 20),
		Position = UDim2.new(1, -90, 0, 5),
		BackgroundColor3 = Theme.Background3,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})
	AddCorner(swatch, 5)
	AddStroke(swatch, Theme.Border, 1)

	local swatchColor = New("Frame", swatch, {
		Size = UDim2.fromOffset(20, 14),
		Position = UDim2.fromOffset(5, 3),
		BackgroundColor3 = Theme.Accent,
		ZIndex = 4,
	})
	AddCorner(swatchColor, 3)

	local hexLabel = TextLabel(swatch, "#000000", 11, FONT_MONO, Theme.TextDim, Enum.TextXAlignment.Left)
	hexLabel.Size = UDim2.new(1, -30, 0, 14)
	hexLabel.Position = UDim2.fromOffset(28, 3)

	local window = section.Tab.Window
	local popup: any = nil
	local open = false

	local hue = 0
	local sat = 1
	local val = 1
	local alpha = 1

	local function CurrentColor(): Color3
		return Color3.fromHSV(hue, sat, val)
	end

	local svBox: any = nil
	local svCursor: any = nil
	local hueBar: any = nil
	local hueCursor: any = nil
	local alphaBar: any = nil
	local alphaCursor: any = nil
	local hexBox: any = nil

	local function PaintSwatch()
		local color = CurrentColor()
		swatchColor.BackgroundColor3 = color
		swatchColor.BackgroundTransparency = 1 - alpha
		hexLabel.Text = Color3ToHex(color)
		if hexBox ~= nil and not hexBox:IsFocused() then
			hexBox.Text = Color3ToHex(color)
		end
	end

	local Paint: any = nil
	local Close: any = nil

	local function BuildPopup()
		popup = New("CanvasGroup", window.Root, {
			Size = UDim2.fromOffset(150, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Theme.Background2,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 61,
		})
		AddCorner(popup, 8)
		AddStroke(popup, Theme.Border, 1)

		svBox = New("Frame", popup, {
			Size = UDim2.fromOffset(130, 130),
			Position = UDim2.fromOffset(10, 10),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 4,
		})
		AddCorner(svBox, 6)

		local hueKeypoints: { ColorSequenceKeypoint } = {}
		for i = 0, 6 do
			local t = i / 6
			TableInsert(hueKeypoints, ColorSequenceKeypoint.new(t, Color3.fromHSV(t, 1, 1)))
		end

		AddGradient(svBox, {
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, CurrentColor()),
		}, 0)
		AddGradient(svBox, {
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1), 0),
			ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0), 1),
		}, 90)

		svCursor = New("Frame", svBox, {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 5,
		})
		AddCorner(svCursor, 6)
		AddStroke(svCursor, Color3.new(0, 0, 0), 1.5)

		hueBar = New("Frame", popup, {
			Size = UDim2.new(1, -20, 0, 10),
			Position = UDim2.fromOffset(10, 148),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 4,
		})
		AddCorner(hueBar, 5)
		AddGradient(hueBar, hueKeypoints, 0)

		hueCursor = New("Frame", hueBar, {
			Size = UDim2.fromOffset(12, 14),
			Position = UDim2.fromOffset(-6, -2),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 5,
		})
		AddCorner(hueCursor, 6)
		AddStroke(hueCursor, Color3.new(0, 0, 0), 1.5)

		local nextY = 168
		if element.TransparencyEnabled then
			alphaBar = New("Frame", popup, {
				Size = UDim2.new(1, -20, 0, 10),
				Position = UDim2.fromOffset(10, nextY),
				BackgroundColor3 = Color3.new(1, 1, 1),
				ZIndex = 4,
			})
			AddCorner(alphaBar, 5)
			AddGradient(alphaBar, {
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1), 1),
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1), 0),
			}, 0)
			alphaCursor = New("Frame", alphaBar, {
				Size = UDim2.fromOffset(12, 14),
				Position = UDim2.fromOffset(-6, -2),
				BackgroundColor3 = Color3.new(1, 1, 1),
				ZIndex = 5,
			})
			AddCorner(alphaCursor, 6)
			AddStroke(alphaCursor, Color3.new(0, 0, 0), 1.5)
			nextY += 18
		end

		hexBox = New("TextBox", popup, {
			Size = UDim2.new(1, -20, 0, 22),
			Position = UDim2.fromOffset(10, nextY),
			BackgroundColor3 = Theme.Background3,
			Font = FONT_MONO,
			TextSize = 11,
			TextColor3 = Theme.Text,
			Text = "#000000",
			PlaceholderText = "#FFFFFF",
			PlaceholderColor3 = Theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			ClearTextOnFocus = false,
			ZIndex = 5,
		})
		AddCorner(hexBox, 5)
		AddStroke(hexBox, Theme.Border, 1)
		nextY += 30

		popup.Size = UDim2.fromOffset(150, nextY + 4)

		element:Connect(hexBox.FocusLost, function()
			local parsed, _ = HexToColor3(hexBox.Text)
			if parsed ~= nil then
				hue, sat, val = parsed:ToHSV()
				alpha = MathClamp(alpha, 0, 1)
				PaintSwatch()
				Paint()
			else
				hexBox.Text = Color3ToHex(CurrentColor())
			end
		end)
		element:Connect(hexBox:GetPropertyChangedSignal("Text"), function()
			local current = StringGsub(hexBox.Text, "#", "")
			local cleaned = StringGsub(current, "[^%x]", "")
			cleaned = StringSub(cleaned, 1, 6)
			if cleaned ~= current then
				hexBox.Text = "#" .. cleaned
			end
		end)

		local function SVFromMouse(mouse: Vector2)
			local pos = svBox.AbsolutePosition
			local size = svBox.AbsoluteSize
			sat = MathClamp((mouse.X - pos.X) / MathMax(size.X, 1), 0, 1)
			val = 1 - MathClamp((mouse.Y - pos.Y) / MathMax(size.Y, 1), 0, 1)
			Paint()
		end

		local function HueFromMouse(mouse: Vector2)
			local pos = hueBar.AbsolutePosition
			local size = hueBar.AbsoluteSize
			hue = MathClamp((mouse.X - pos.X) / MathMax(size.X, 1), 0, 1)
			Paint()
		end

		local function AlphaFromMouse(mouse: Vector2)
			local pos = alphaBar.AbsolutePosition
			local size = alphaBar.AbsoluteSize
			alpha = 1 - MathClamp((mouse.X - pos.X) / MathMax(size.X, 1), 0, 1)
			Paint()
		end

		local dragTarget: any = nil

		element:Connect(UserInputService.InputBegan, function(input: InputObject)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local mouse = UserInputService:GetMouseLocation()
			if PointInRect(mouse, svBox) then
				dragTarget = svBox
				SVFromMouse(mouse)
			elseif PointInRect(mouse, hueBar) then
				dragTarget = hueBar
				HueFromMouse(mouse)
			elseif alphaBar ~= nil and PointInRect(mouse, alphaBar) then
				dragTarget = alphaBar
				AlphaFromMouse(mouse)
			end
		end)

		element:Connect(UserInputService.InputChanged, function(input: InputObject)
			if dragTarget == nil then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			local mouse = UserInputService:GetMouseLocation()
			if dragTarget == svBox then
				SVFromMouse(mouse)
			elseif dragTarget == hueBar then
				HueFromMouse(mouse)
			elseif dragTarget == alphaBar then
				AlphaFromMouse(mouse)
			end
		end)

		element:Connect(UserInputService.InputEnded, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragTarget = nil
			end
		end)

		element:Connect(UserInputService.InputBegan, function(input: InputObject)
			if not open then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local mouse = UserInputService:GetMouseLocation()
			if PointInRect(mouse, popup) then
				return
			end
			if PointInRect(mouse, swatch) then
				return
			end
			Close()
		end)
	end

	Paint = function()
		if svBox == nil then
			return
		end
		svCursor.Position = UDim2.fromOffset(MathFloor(sat * (svBox.AbsoluteSize.X - 12)), MathFloor((1 - val) * (svBox.AbsoluteSize.Y - 12)))
		local grad = svBox:FindFirstChildOfClass("UIGradient")
		if grad ~= nil then
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, CurrentColor()),
			})
		end
		hueCursor.Position = UDim2.fromOffset(MathFloor(hue * (hueBar.AbsoluteSize.X - 12)), -2)
		if alphaCursor ~= nil then
			alphaCursor.Position = UDim2.fromOffset(MathFloor((1 - alpha) * (alphaBar.AbsoluteSize.X - 12)), -2)
		end
		PaintSwatch()
		LibUpdateFlag(element)
		element:FireCallbacks(CurrentColor(), 1 - alpha)
	end

	Close = function()
		if not open then
			return
		end
		open = false
		if popup ~= nil then
			TweenPlay(Tween(popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				GroupTransparency = 1,
			})):Completed:Connect(function()
				if not open and popup ~= nil then
					popup.Visible = false
				end
			end)
		end
	end

	local function Open()
		if open then
			Close()
			return
		end
		open = true
		if popup == nil then
			BuildPopup()
		end
		local yOffset = swatch.AbsolutePosition.Y + swatch.AbsoluteSize.Y - window.Root.AbsolutePosition.Y + 4
		local xOffset = swatch.AbsolutePosition.X + swatch.AbsoluteSize.X - popup.AbsoluteSize.X - window.Root.AbsolutePosition.X
		if xOffset < 4 then
			xOffset = swatch.AbsolutePosition.X - window.Root.AbsolutePosition.X
		end
		popup.Position = UDim2.fromOffset(MathFloor(xOffset), MathFloor(yOffset))
		popup.Visible = true
		Paint()
		TweenPlay(Tween(popup, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
		}))
	end

	element.Close = Close

	element:Connect(swatch.MouseButton1Click, Open)

	element.SetValue = function(_, newValue: any)
		local color: Color3
		local transparency = 0
		if TypeOf(newValue) == "Color3" then
			color = newValue
		elseif TypeOf(newValue) == "table" then
			if newValue.Color3 ~= nil then
				color = newValue.Color3
				transparency = newValue.Transparency or 0
			else
				color = Color3.fromRGB(newValue.R or 255, newValue.G or 255, newValue.B or 255)
				transparency = newValue.T or 0
			end
		else
			color = Color3.new(1, 1, 1)
		end
		hue, sat, val = color:ToHSV()
		alpha = 1 - MathClamp(transparency, 0, 1)
		PaintSwatch()
		LibUpdateFlag(element)
		return element
	end
	element.GetValue = function()
		return CurrentColor(), 1 - alpha
	end
	element.Serialize = function()
		local color = CurrentColor()
		return {
			R = MathRound(color.R * 255),
			G = MathRound(color.G * 255),
			B = MathRound(color.B * 255),
			T = MathRound((1 - alpha) * 255) / 255,
		}
	end
	element.RefreshTheme = function() end
	element.Destroy = function()
		if element.Destroyed then
			return
		end
		element.Destroyed = true
		for _, conn in element.Connections do
			pcall(conn.Disconnect, conn)
		end
		TableClear(element.Connections)
		if element.Object ~= nil then
			pcall(element.Object.Destroy, element.Object)
		end
		if popup ~= nil then
			pcall(popup.Destroy, popup)
		end
	end

	element:SetValue(opts.Default or Color3.new(1, 0, 0))

	return element
end

-- ==================== TEXTBOX ====================

local function BuildTextbox(section: any, opts: any): any
	local element = BuildElement(section, 30, "Textbox")
	element.Flag = opts.Flag
	element.Numeric = opts.Numeric == true
	ElementLabel(element, opts.Text or opts.Flag or "Textbox")

	local box = New("TextBox", element.Object, {
		Size = UDim2.fromOffset(120, 22),
		Position = UDim2.new(1, -120, 0, 4),
		BackgroundColor3 = Theme.Background3,
		Font = FONT,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Text = "",
		PlaceholderText = opts.Placeholder or "Input...",
		PlaceholderColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 3,
	})
	AddCorner(box, 6)
	AddStroke(box, Theme.Border, 1)
	New("UIPadding", box, {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	element.SetValue = function(_, newValue: string)
		box.Text = tostring(newValue or "")
		LibUpdateFlag(element)
		return element
	end
	element.GetValue = function()
		return box.Text
	end
	element.Serialize = function()
		return box.Text
	end
	element.RefreshTheme = function() end

	if element.Numeric then
		element:Connect(box:GetPropertyChangedSignal("Text"), function()
			local current = box.Text
			local cleaned = StringGsub(current, "[^%d%.%-]", "")
			if cleaned ~= current then
				box.Text = cleaned
			end
		end)
	end

	element:Connect(box.FocusLost, function()
		element:FireCallbacks(box.Text)
		LibUpdateFlag(element)
	end)

	element:SetValue(opts.Default or "")

	return element
end

-- ==================== BUTTON ====================

local function BuildButton(section: any, opts: any): any
	local element = BuildElement(section, 30, "Button")

	local button = New("TextButton", element.Object, {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.fromOffset(0, 2),
		BackgroundColor3 = Theme.Background3,
		Text = opts.Text or "Button",
		Font = FONT_SEMI,
		TextSize = 13,
		TextColor3 = Theme.Text,
		AutoButtonColor = false,
		ClipsDescendants = true,
		ZIndex = 3,
	})
	AddCorner(button, 6)
	local stroke = AddStroke(button, Theme.Border, 1)

	element:Connect(button.MouseEnter, function()
		TweenPlay(Tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Theme.Hover,
		}))
		TweenPlay(Tween(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = Theme.Accent,
		}))
	end)

	element:Connect(button.MouseLeave, function()
		TweenPlay(Tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Theme.Background3,
		}))
		TweenPlay(Tween(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = Theme.Border,
		}))
	end)

	element:Connect(button.MouseButton1Click, function(x: number, y: number)
		local ripple = New("Frame", button, {
			Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(x, y),
			BackgroundColor3 = Theme.Accent,
			ZIndex = 5,
		})
		AddCorner(ripple, 60)
		local t = TweenPlay(Tween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(52, 52),
			Position = UDim2.fromOffset(x - 26, y - 26),
			BackgroundTransparency = 0.85,
		}))
		t:Completed:Connect(function()
			pcall(ripple.Destroy, ripple)
		end)
		TweenPlay(Tween(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Theme.Accent,
		}))
		task.delay(0.1, function()
			if not button.Parent then
				return
			end
			TweenPlay(Tween(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {
				BackgroundColor3 = Theme.Hover,
			}))
		end)
		pcall(opts.Callback)
	end)

	element.RefreshTheme = function() end

	return element
end

-- ==================== LABEL / SEPARATOR ====================

local function BuildLabel(section: any, opts: any): any
	local element = BuildElement(section, 22, "Label")
	local label = TextLabel(element.Object, opts.Text or "", 12, FONT, Theme.TextDim, opts.Alignment or Enum.TextXAlignment.Left)
	label.Size = UDim2.new(1, 0, 0, 16)
	label.Position = UDim2.fromOffset(0, 3)
	element.RefreshTheme = function() end
	return element
end

local function BuildSeparator(section: any): any
	local element = BuildElement(section, 12, "Separator")
	New("Frame", element.Object, {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, 5),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.5,
	})
	element.RefreshTheme = function() end
	return element
end

-- ==================== SECTION METHODS ====================

SectionMethods.AddToggle = function(self: any, opts: any): any
	return GuardBuild("Toggle", function()
		local el = BuildToggle(self, opts or {})
		ScheduleLayout(self)
		return el
	end)
end

SectionMethods.AddSlider = function(self: any, opts: any): any
	return GuardBuild("Slider", function()
		local el = BuildSlider(self, opts or {})
		ScheduleLayout(self)
		return el
	end)
end

SectionMethods.AddDropdown = function(self: any, opts: any): any
	return GuardBuild("Dropdown", function()
		local el = BuildDropdown(self, opts or {})
		ScheduleLayout(self)
		return el
	end)
end

SectionMethods.AddKeybind = function(self: any, opts: any): any
	return GuardBuild("Keybind", function()
		local el = BuildKeybind(self, opts or {})
		ScheduleLayout(self)
		return el
	end)
end

SectionMethods.AddColorPicker = function(self: any, opts: any): any
	return GuardBuild("ColorPicker", function()
		local el = BuildColorPicker(self, opts or {})
		ScheduleLayout(self)
		return el
	end)
end

SectionMethods.AddTextbox = function(self: any, opts: any): any
	return GuardBuild("Textbox", function()
		local el = BuildTextbox(self, opts or {})
		ScheduleLayout(self)
		return el
	end)
end

SectionMethods.AddButton = function(self: any, opts: any): any
	return GuardBuild("Button", function()
		local el = BuildButton(self, opts or {})
		ScheduleLayout(self)
		return el
	end)
end

SectionMethods.AddLabel = function(self: any, opts: any): any
	return GuardBuild("Label", function()
		local el = BuildLabel(self, opts or {})
		ScheduleLayout(self)
		return el
	end)
end

SectionMethods.AddSeparator = function(self: any): any
	return GuardBuild("Separator", function()
		local el = BuildSeparator(self)
		ScheduleLayout(self)
		return el
	end)
end

-- ==================== TABS ====================

local TabMethods: any = {}

local function BuildTab(window: any, name: string): any
	local tab: any = {
		Type = "Tab",
		Name = name,
		Window = window,
		LeftSections = {},
		RightSections = {},
		Destroyed = false,
	}

	tab.Content = New("ScrollingFrame", window.ContentArea, {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Border,
		CanvasSize = UDim2.fromOffset(0, 0),
		Visible = false,
		ZIndex = 2,
	})
	tab.Left = New("Frame", tab.Content, {
		Size = UDim2.new(0.5, -6, 0, 100),
		Position = UDim2.fromOffset(6, 6),
		BackgroundTransparency = 1,
	})
	tab.Right = New("Frame", tab.Content, {
		Size = UDim2.new(0.5, -6, 0, 100),
		Position = UDim2.new(1, -6, 0, 6),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
	})

	for methodName, methodFn in TabMethods do
		tab[methodName] = methodFn
	end

	return tab
end

TabMethods.AddSection = function(self: any, name: string, tooltip: string?): any
	local leftH = 0
	local rightH = 0
	for _, section in self.LeftSections do
		leftH += section.Root.AbsoluteSize.Y
	end
	for _, section in self.RightSections do
		rightH += section.Root.AbsoluteSize.Y
	end
	local column = rightH < leftH and "Right" or "Left"
	return BuildSection(self, column, name, tooltip)
end

TabMethods.AddLeftSection = function(self: any, name: string, tooltip: string?): any
	return BuildSection(self, "Left", name, tooltip)
end

TabMethods.AddRightSection = function(self: any, name: string, tooltip: string?): any
	return BuildSection(self, "Right", name, tooltip)
end

TabMethods.AddConfigSection = function(self: any, name: string): any
	local section = BuildSection(self, "Left", name or "Configs")
	local configList = GuardBuild("ConfigDropdown", function()
		return BuildDropdown(section, {
			Text = "Config",
			Items = Lib:RefreshConfigs(),
			MultiSelect = false,
			Search = true,
		})
	end)
	local saveBox = GuardBuild("ConfigNameBox", function()
		return BuildTextbox(section, {
			Text = "Name",
			Placeholder = "config-name",
		})
	end)
	GuardBuild("SaveButton", function()
		BuildButton(section, {
			Text = "Save Config",
			Callback = function()
				local saved = Lib:SaveConfig(saveBox:GetValue() or "config")
				configList:RefreshItems(Lib:RefreshConfigs())
				Lib:Notify({
					Title = "Config",
					Content = saved and "Saved successfully" or "Failed to save",
					Duration = 2.5,
					Type = saved and "Success" or "Warning",
				})
			end,
		})
		return true
	end)
	GuardBuild("LoadButton", function()
		BuildButton(section, {
			Text = "Load Config",
			Callback = function()
				local selected = configList:GetValue()
				if selected == nil or selected == "" then
					Lib:Notify({ Title = "Config", Content = "No config selected", Duration = 2, Type = "Warning" })
					return
				end
				local loaded = Lib:LoadConfig(selected)
				Lib:Notify({
					Title = "Config",
					Content = loaded and ("Loaded \"" .. selected .. "\"") or "Failed to load",
					Duration = 2.5,
					Type = loaded and "Success" or "Warning",
				})
			end,
		})
		return true
	end)
	GuardBuild("DeleteButton", function()
		BuildButton(section, {
			Text = "Delete Config",
			Callback = function()
				local selected = configList:GetValue()
				if selected == nil or selected == "" then
					Lib:Notify({ Title = "Config", Content = "No config selected", Duration = 2, Type = "Warning" })
					return
				end
				Lib:DeleteConfig(selected)
				configList:RefreshItems(Lib:RefreshConfigs())
				Lib:Notify({ Title = "Config", Content = "Deleted \"" .. selected .. "\"", Duration = 2, Type = "Info" })
			end,
		})
		return true
	end)
	GuardBuild("RefreshButton", function()
		BuildButton(section, {
			Text = "Refresh List",
			Callback = function()
				configList:RefreshItems(Lib:RefreshConfigs())
			end,
		})
		return true
	end)
	ScheduleLayout(section)
	return section
end

-- ==================== NOTIFICATIONS ====================

local NOTIFY_COLORS: { [string]: Color3 } = {
	Info = Theme.Accent,
	Success = Theme.Success,
	Warning = Theme.Warning,
	Danger = Theme.Danger,
}

function Lib:Notify(opts: any)
	if Lib._Destroyed then
		return nil
	end
	local title = opts.Title or "Notification"
	local content = opts.Content or ""
	local duration = opts.Duration or 3
	local notifyType = opts.Type or "Info"
	local color = NOTIFY_COLORS[notifyType] or Theme.Accent

	if Lib.NotifyLayer == nil then
		Lib.NotifyLayer = New("Frame", Lib.GUI, {
			Size = UDim2.fromScale(0, 0),
			Position = UDim2.new(1, -8, 0, 8),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			ZIndex = 100,
		})
	end

	local frame = New("CanvasGroup", Lib.NotifyLayer, {
		Size = UDim2.fromOffset(300, 66),
		Position = UDim2.new(1, 340, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Theme.Background2,
		GroupTransparency = 0,
		ZIndex = 100,
	})
	AddCorner(frame, 8)
	AddStroke(frame, Theme.Border, 1, 0.3)

	New("Frame", frame, {
		Size = UDim2.fromOffset(4, 66),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = color,
		ZIndex = 2,
	})

	local titleLabel = TextLabel(frame, title, 13, FONT_BOLD, Theme.Text, Enum.TextXAlignment.Left)
	titleLabel.Size = UDim2.new(1, -64, 0, 14)
	titleLabel.Position = UDim2.fromOffset(14, 7)

	local contentLabel = TextLabel(frame, content, 11, FONT, Theme.TextDim, Enum.TextXAlignment.Left)
	contentLabel.Size = UDim2.new(1, -84, 0, 14)
	contentLabel.Position = UDim2.fromOffset(14, 26)
	contentLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local closeButton = New("TextButton", frame, {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -26, 0, 6),
		BackgroundTransparency = 1,
		Text = "✕",
		Font = FONT,
		TextSize = 12,
		TextColor3 = Theme.TextDim,
		AutoButtonColor = false,
		ZIndex = 3,
	})

	New("Frame", frame, {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = Theme.Border,
		ZIndex = 2,
	})
	local progress = New("Frame", frame, {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = color,
		ZIndex = 3,
	})

	local entry: any = { Frame = frame, Closing = false }
	TableInsert(Lib._Notifications, 1, entry)

	local function Restack()
		for index, notif in Lib._Notifications do
			if notif.Frame ~= nil and notif.Frame.Parent ~= nil then
				notif.Frame.Position = UDim2.new(1, 0, 0, 8 + (index - 1) * 74)
				notif.Frame.ZIndex = 100 + index
			end
		end
	end

	local function Dismiss()
		if entry.Closing then
			return
		end
		entry.Closing = true
		TweenPlay(Tween(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			GroupTransparency = 1,
			Position = UDim2.new(1, 340, 0, frame.Position.Y.Offset),
		})):Completed:Connect(function()
			pcall(frame.Destroy, frame)
			for i = #Lib._Notifications, 1, -1 do
				if Lib._Notifications[i] == entry then
					TableRemove(Lib._Notifications, i)
				end
			end
			Restack()
		end)
	end

	Connect(closeButton.MouseButton1Click, Dismiss)

	TweenPlay(Tween(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, 0, 0, 8 + (#Lib._Notifications - 1) * 74),
	}))
	Restack()

	if duration > 0 then
		TweenPlay(Tween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.fromScale(0, 1),
		})):Completed:Connect(function()
			Dismiss()
		end)
	end

	return entry
end

-- ==================== WINDOW ====================

local function BuildWindow(opts: any): any
	local title = opts.Title or "NewUI"
	local subtitle = opts.SubTitle or ""
	local size = opts.Size or UDim2.fromOffset(600, 430)
	local accent = opts.Accent
	local keybind: any = opts.Keybind
	local animatedTitle = opts.AnimatedTitle ~= false
	local titleAnimation = opts.TitleAnimationType or "Typewriter"

	if accent ~= nil then
		Theme.Accent = accent
	end

	local window: any = {
		Type = "Window",
		Title = title,
		SubTitle = subtitle,
		AnimatedTitle = animatedTitle,
		TitleAnimationType = titleAnimation,
		Tabs = {},
		_TitleAlive = true,
		_TitleGen = 0,
	}

	local gui = New("ScreenGui", GetGuiParent(), {
		DisplayOrder = 10 + #Lib.Windows,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	window.GUI = gui

	local shadow = New("Frame", gui, {
		Size = UDim2.new(1, 8, 1, 8),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		ZIndex = 1,
	})
	AddCorner(shadow, 12)

	local root = New("CanvasGroup", gui, {
		Size = size,
		Position = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Theme.Background2,
		GroupTransparency = 0,
		ZIndex = 2,
	})
	AddCorner(root, 10)
	AddStroke(root, Theme.Border, 1)
	window.Root = root

	local accentBar = New("Frame", root, {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Accent,
		ZIndex = 3,
	})

	local titlebar = New("Frame", root, {
		Size = UDim2.new(1, 0, 0, 42),
		Position = UDim2.fromOffset(0, 2),
		BackgroundColor3 = Theme.Background3,
		BackgroundTransparency = 0.4,
		ZIndex = 3,
	})
	AddCorner(titlebar, 10)

	local titleLabel = TextLabel(titlebar, title, 16, FONT_BOLD, Theme.Text, Enum.TextXAlignment.Left)
	titleLabel.Size = UDim2.new(1, -130, 0, 18)
	titleLabel.Position = UDim2.fromOffset(12, 4)
	titleLabel.ZIndex = 4
	window.TitleLabel = titleLabel

	local subtitleLabel = TextLabel(titlebar, subtitle, 10, FONT, Theme.TextDim, Enum.TextXAlignment.Left)
	subtitleLabel.Size = UDim2.new(1, -130, 0, 12)
	subtitleLabel.Position = UDim2.fromOffset(12, 24)
	subtitleLabel.ZIndex = 4
	window.SubtitleLabel = subtitleLabel

	local windowVisible = true

	local function ToggleWindow()
		windowVisible = not windowVisible
		TweenPlay(Tween(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = windowVisible and 0 or 1,
		}))
		TweenPlay(Tween(shadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = windowVisible and 0.55 or 1,
		}))
	end

	if keybind ~= nil then
		local keychip = New("TextButton", titlebar, {
			Size = UDim2.fromOffset(84, 22),
			Position = UDim2.new(1, -96, 0, 10),
			BackgroundColor3 = Theme.Background3,
			Text = KeyName(keybind),
			Font = FONT,
			TextSize = 10,
			TextColor3 = Theme.TextDim,
			AutoButtonColor = false,
			ZIndex = 4,
		})
		AddCorner(keychip, 6)
		AddStroke(keychip, Theme.Border, 1)
		local capturing = false
		Connect(keychip.MouseButton1Click, function()
			if capturing then
				return
			end
			capturing = true
			keychip.Text = "..."
		end)
		Connect(UserInputService.InputBegan, function(input: InputObject)
			if capturing then
				local inputType = input.UserInputType
				if inputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape then
						capturing = false
						keychip.Text = KeyName(keybind)
						return
					end
					if input.KeyCode ~= Enum.KeyCode.Unknown then
						keybind = input.KeyCode
						capturing = false
						keychip.Text = KeyName(keybind)
					end
				elseif inputType == Enum.UserInputType.MouseButton1
					or inputType == Enum.UserInputType.MouseButton2
					or inputType == Enum.UserInputType.MouseButton3
				then
					keybind = inputType
					capturing = false
					keychip.Text = KeyName(keybind)
				end
				return
			end
			if IsTyping() then
				return
			end
			if InputMatches(input, keybind) then
				ToggleWindow()
			end
		end)
	end

	local tabbar = New("Frame", root, {
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.fromOffset(0, 44),
		BackgroundTransparency = 1,
		ZIndex = 3,
	})
	New("UIListLayout", tabbar, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	New("UIPadding", tabbar, {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local indicator = New("Frame", tabbar, {
		Size = UDim2.fromOffset(60, 2),
		Position = UDim2.fromOffset(0, 30),
		BackgroundColor3 = Theme.Accent,
		ZIndex = 4,
	})

	local contentArea = New("Frame", root, {
		Size = UDim2.new(1, 0, 1, -82),
		Position = UDim2.fromOffset(0, 78),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})
	window.ContentArea = contentArea

	-- ============ DRAGGING ============

	local dragging = false
	local dragOffset = Vector2.zero
	local dragTarget = UDim2.fromOffset(40, 40)

	local function Raise()
		Lib._MaxZ += 1
		root.ZIndex = Lib._MaxZ
		shadow.ZIndex = MathMax(root.ZIndex - 1, 1)
	end

	Connect(titlebar.InputBegan, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragOffset = input.Position - root.AbsolutePosition
			dragTarget = root.Position
			Raise()
			window:ClosePopups()
		end
	end)

	Connect(UserInputService.InputEnded, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	Connect(UserInputService.InputChanged, function(input: InputObject)
		if dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch)
		then
			dragTarget = UDim2.fromOffset(input.Position.X - dragOffset.X, input.Position.Y - dragOffset.Y)
		end
	end)

	Connect(RunService.Heartbeat, function()
		if not dragging then
			return
		end
		local camera = game.Workspace.CurrentCamera
		if camera == nil then
			return
		end
		local viewport = camera.ViewportSize
		local x = MathClamp(dragTarget.X.Offset, -(root.AbsoluteSize.X - 40), viewport.X - 40)
		local y = MathClamp(dragTarget.Y.Offset, 0, viewport.Y - 30)
		local current = root.Position
		local nextX = current.X.Offset + (x - current.X.Offset) * 0.25
		local nextY = current.Y.Offset + (y - current.Y.Offset) * 0.25
		root.Position = UDim2.fromOffset(nextX, nextY)
		shadow.Position = UDim2.fromOffset(nextX + 2, nextY + 2)
	end)

	-- ============ TABS ============

	local activeTab: any = nil

	local function PaintTabButtons()
		for _, tab in window.Tabs do
			if tab.Button ~= nil then
				tab.Button.TextColor3 = (tab == activeTab) and Theme.Accent or Theme.TextDim
				tab.Button.Font = (tab == activeTab) and FONT_SEMI or FONT
			end
		end
		if activeTab ~= nil and activeTab.Button ~= nil then
			local width = MathMax(activeTab.Button.AbsoluteSize.X - 8, 0)
			local x = MathMax(activeTab.Button.AbsolutePosition.X - tabbar.AbsolutePosition.X + 4, 0)
			TweenPlay(Tween(indicator, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(width, 2),
				Position = UDim2.fromOffset(x, 30),
			}))
		end
	end

	local function SwitchTab(tab: any)
		if activeTab == tab then
			return
		end
		if activeTab ~= nil then
			activeTab.Content.Visible = false
		end
		activeTab = tab
		tab.Content.Visible = true
		PaintTabButtons()
		window:ClosePopups()
		LayoutTab(tab)
	end

	window.ClosePopups = function()
		for _, tab in window.Tabs do
			for _, column in { tab.LeftSections, tab.RightSections } do
				for _, section in column do
					for _, element in section.Elements do
						if element.Close ~= nil then
							pcall(element.Close)
						end
					end
				end
			end
		end
	end

	window.AddTab = function(_, name: string): any
		local tab = BuildTab(window, tostring(name or "Tab"))
		tab.Button = New("TextButton", tabbar, {
			Size = UDim2.fromOffset(0, 24),
			LayoutOrder = #window.Tabs,
			BackgroundTransparency = 1,
			Text = tostring(name or "Tab"),
			Font = FONT,
			TextSize = 13,
			TextColor3 = Theme.TextDim,
			AutoButtonColor = false,
			ZIndex = 4,
		})
		New("UIPadding", tab.Button, {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		})
		tab.Button.AutomaticSize = Enum.AutomaticSize.X
		Connect(tab.Button.MouseButton1Click, function()
			SwitchTab(tab)
		end)
		TableInsert(window.Tabs, tab)
		task.defer(function()
			if activeTab == nil then
				SwitchTab(tab)
			end
		end)
		return tab
	end

	window.AddConfigSection = function(_, tab: any, name: string?)
		if tab ~= nil and tab.AddConfigSection ~= nil then
			return tab:AddConfigSection(name or "Configs")
		end
		return nil
	end

	local StartTitleAnimation: (win: any) -> () = nil

	window.SetTitle = function(_, newTitle: string)
		window.Title = tostring(newTitle or window.Title)
		window._TitleGen += 1
		titleLabel.Text = window.Title
		StartTitleAnimation(window)
		return window
	end

	window.SetVisible = function(_, visible: boolean)
		windowVisible = visible
		TweenPlay(Tween(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = visible and 0 or 1,
		}))
		return window
	end

	window:Toggle = ToggleWindow

	window.Destroy = function()
		window._TitleAlive = false
		window._TitleGen += 1
		for _, tab in window.Tabs do
			tab.Destroyed = true
			if tab.Content ~= nil then
				pcall(tab.Content.Destroy, tab.Content)
			end
		end
		TableClear(window.Tabs)
		pcall(gui.Destroy, gui)
	end

	ThemeBind(function()
		accentBar.BackgroundColor3 = Theme.Accent
		indicator.BackgroundColor3 = Theme.Accent
		PaintTabButtons()
	end)

	-- ============ ANIMATED TITLE ============

	StartTitleAnimation = function(win: any)
		local myGen = win._TitleGen
		local fullText = win.Title

		local function IsCurrent()
			return win._TitleAlive and win._TitleGen == myGen
		end

		local existingGrad = titleLabel:FindFirstChildOfClass("UIGradient")
		if existingGrad then
			pcall(existingGrad.Destroy, existingGrad)
		end
		titleLabel.TextStrokeTransparency = 1

		if not win.AnimatedTitle then
			titleLabel.Text = fullText
			return
		end
		local animKind = win.TitleAnimationType or "Typewriter"
		if animKind == "Typewriter" then
			task.spawn(function()
				while IsCurrent() do
					for i = 1, #fullText do
						if not IsCurrent() then
							return
						end
						titleLabel.Text = StringSub(fullText, 1, i) .. "|"
						task.wait(0.075)
					end
					for i = 1, 6 do
						if not IsCurrent() then
							return
						end
						titleLabel.Text = fullText .. (i % 2 == 1 and "|" or " ")
						task.wait(0.18)
					end
					for i = #fullText, 0, -1 do
						if not IsCurrent() then
							return
						end
						titleLabel.Text = StringSub(fullText, 1, i) .. "|"
						task.wait(0.02)
					end
					task.wait(0.5)
				end
			end)
		elseif animKind == "GradientShift" then
			local gradient = titleLabel:FindFirstChildOfClass("UIGradient")
			if gradient == nil then
				gradient = New("UIGradient", titleLabel, {
					Rotation = 0,
				})
			end
			local function RefreshGradient()
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.Text),
					ColorSequenceKeypoint.new(0.42, Theme.Accent),
					ColorSequenceKeypoint.new(0.58, Theme.Accent),
					ColorSequenceKeypoint.new(1, Theme.Text),
				})
			end
			RefreshGradient()
			ThemeBind(RefreshGradient)
			task.spawn(function()
				while IsCurrent() do
					gradient.Offset = Vector2.new(-1.4, 0)
					local t = TweenPlay(Tween(gradient, TweenInfo.new(2.4, Enum.EasingStyle.Linear), {
						Offset = Vector2.new(1.4, 0),
					}))
					local done = false
					local conn = t.Completed:Connect(function()
						done = true
					end)
					while not done and IsCurrent() do
						task.wait()
					end
					conn:Disconnect()
					if not IsCurrent() then
						return
					end
					task.wait(0.35)
				end
			end)
		else
			titleLabel.TextStrokeTransparency = 0.85
			titleLabel.TextStrokeColor3 = Theme.Accent
			task.spawn(function()
				while IsCurrent() do
					local t1 = TweenPlay(Tween(titleLabel, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						TextStrokeTransparency = 0.2,
					}))
					local done1 = false
					local c1 = t1.Completed:Connect(function()
						done1 = true
					end)
					while not done1 and IsCurrent() do
						task.wait()
					end
					c1:Disconnect()
					if not IsCurrent() then
						return
					end
					local t2 = TweenPlay(Tween(titleLabel, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						TextStrokeTransparency = 0.85,
					}))
					local done2 = false
					local c2 = t2.Completed:Connect(function()
						done2 = true
					end)
					while not done2 and IsCurrent() do
						task.wait()
					end
					c2:Disconnect()
					if not IsCurrent() then
						return
					end
				end
			end)
		end
	end

	StartTitleAnimation(window)

	TableInsert(Lib.Windows, window)

	return window
end

-- ==================== PUBLIC API ====================

function Lib:CreateWindow(opts: any): any
	local ok, result = pcall(function()
		return BuildWindow(opts or {})
	end)
	if not ok then
		warn("[NewUI] CreateWindow failed: " .. tostring(result))
		return nil
	end
	return result
end

function Lib:Destroy()
	Lib._Destroyed = true
	HideTooltip()
	for _, conn in Lib.Connections do
		pcall(conn.Disconnect, conn)
	end
	TableClear(Lib.Connections)
	for _, window in Lib.Windows do
		pcall(window.Destroy, window)
	end
	TableClear(Lib.Windows)
	TableClear(Lib.Elements)
	TableClear(Lib._FlagMap)
	if Lib.GUI ~= nil then
		pcall(Lib.GUI.Destroy, Lib.GUI)
		Lib.GUI = nil
	end
	Lib.NotifyLayer = nil
	TableClear(Lib._Notifications)
end

Lib.Unload = Lib.Destroy

-- ==================== GUI ROOT ====================

do
	local ok, result = pcall(function()
		return New("ScreenGui", GetGuiParent(), {
			DisplayOrder = 9,
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		})
	end)
	if ok then
		Lib.GUI = result
	end
end

-- ==================== RETURN ====================

return Lib
