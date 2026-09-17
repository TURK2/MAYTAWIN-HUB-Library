-- Maytawin UI Library v1.0
-- Rayfield-inspired, built for performance.

local Maytawin = {}

-- Services.
local playersService = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

local localPlayer = playersService.LocalPlayer

-- Constants.
local UI_FOLDER_NAME = "MaytawinUI"
local TWEEN_SPEED = 0.25
local TWEEN_STYLE = Enum.EasingStyle.Quart
local TWEEN_DIRECTION = Enum.EasingDirection.Out
local DRAG_THRESHOLD = 4
local SIDEBAR_WIDTH = 180
local TOPBAR_HEIGHT = 48

-- State.
local connections = {}
local gui = nil
local mainFrame = nil
local contentHolder = nil
local sidebarFrame = nil
local tabButtons = {}
local activeTab = nil
local tabs = {}
local dragging = false
local dragStart = nil
local startPos = nil
local isCollapsed = false
local collapsedPill = nil

-- Utility.
local function create(class, props)
    local instance = Instance.new(class)
    for key, value in pairs(props) do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    if props.Parent then
        instance.Parent = props.Parent
    end
    return instance
end

local function tween(instance, props, speed)
    local info = TweenInfo.new(speed or TWEEN_SPEED, TWEEN_STYLE, TWEEN_DIRECTION)
    local t = tweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function addCorner(parent, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

local function addStroke(parent, color, thickness)
    create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 70),
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function createDraggable(frame, handle)
    handle = handle or frame
    local dragConnection
    local dragInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            local moved = false

            dragConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragConnection:Disconnect()
                end
            end)

            dragInput = input:GetPropertyChangedSignal("Position"):Connect(function()
                if not dragging then return end
                local delta = input.Position - dragStart
                if not moved and (math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD) then
                    moved = true
                end
                if moved then
                    frame.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if dragConnection then dragConnection:Disconnect() end
            if dragInput then dragInput:Disconnect() end
        end
    end)
end

-- ============================================================
-- WINDOW
-- ============================================================

function Maytawin:CreateWindow(props)
    props = props or {}
    local windowName = props.name or props.Name or "Maytawin UI"
    local subtitle = props.subtitle or props.Subtitle or "by Maytawin"
    local sidebarLayout = props.sidebarLayout or props.SidebarLayout or false
    local toggleKeybind = props.toggleKeybind or props.ToggleKeybind or Enum.KeyCode.RightShift

    -- Clean up previous instance.
    local old = game:GetService("CoreGui"):FindFirstChild(UI_FOLDER_NAME)
    if old then old:Destroy() end

    gui = create("ScreenGui", {
        Name = UI_FOLDER_NAME,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui"),
    })

    -- Main window frame.
    mainFrame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 620, 0, 420),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(25, 25, 32),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui,
    })
    addCorner(mainFrame, 12)
    addStroke(mainFrame, Color3.fromRGB(50, 50, 62), 1)

    -- Top bar.
    local topBar = create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    addCorner(topBar, 12)

    local titleLabel = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = windowName,
        TextColor3 = Color3.fromRGB(240, 240, 245),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    local subtitleLabel = create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(0, 200, 0, 14),
        Position = UDim2.new(0, 16, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = Color3.fromRGB(130, 130, 150),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    -- Close button.
    local closeBtn = create("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -38, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(60, 45, 50),
        BorderSizePixel = 0,
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(200, 120, 130),
        TextSize = 12,
        Parent = topBar,
    })
    addCorner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    -- Minimize button.
    local minBtn = create("TextButton", {
        Name = "Minimize",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -72, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(50, 55, 60),
        BorderSizePixel = 0,
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(170, 180, 190),
        TextSize = 12,
        Parent = topBar,
    })
    addCorner(minBtn, 6)

    createDraggable(mainFrame, topBar)

    -- Content area.
    contentHolder = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -TOPBAR_HEIGHT),
        Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT),
        BackgroundTransparency = 1,
        Parent = mainFrame,
    })

    -- Sidebar.
    if sidebarLayout then
        sidebarFrame = create("Frame", {
            Name = "Sidebar",
            Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(22, 22, 30),
            BorderSizePixel = 0,
            Parent = contentHolder,
        })
        create("Frame", {
            Name = "Separator",
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(45, 45, 58),
            BorderSizePixel = 0,
            Parent = sidebarFrame,
        })
    end

    -- Tab content area.
    local tabContent = create("Frame", {
        Name = "TabContent",
        Size = sidebarLayout and UDim2.new(1, -SIDEBAR_WIDTH, 1, 0) or UDim2.new(1, 0, 1, 0),
        Position = sidebarLayout and UDim2.new(0, SIDEBAR_WIDTH, 0, 0) or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = contentHolder,
    })

    -- Toggle visibility.
    local toggleConn = userInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == toggleKeybind then
            gui.Enabled = not gui.Enabled
        end
    end)
    table.insert(connections, toggleConn)

    -- Collapsed pill.
    collapsedPill = create("Frame", {
        Name = "CollapsedPill",
        Size = UDim2.new(0, 140, 0, 36),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        BorderSizePixel = 0,
        Visible = false,
        Parent = gui,
    })
    addCorner(collapsedPill, 18)
    addStroke(collapsedPill, Color3.fromRGB(60, 60, 75), 1)

    local pillLabel = create("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = windowName,
        TextColor3 = Color3.fromRGB(220, 220, 235),
        TextSize = 13,
        Parent = collapsedPill,
    })
    createDraggable(collapsedPill)

    collapsedPill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            isCollapsed = false
            collapsedPill.Visible = false
            gui.Enabled = true
        end
    end)

    minBtn.MouseButton1Click:Connect(function()
        isCollapsed = true
        gui.Enabled = false
        collapsedPill.Visible = true
    end)

    -- Window object.
    local window = {}

    function window:CreateTab(tabProps)
        tabProps = tabProps or {}
        local tabName = tabProps.name or tabProps.Name or "Tab"
        local tabIcon = tabProps.icon or tabProps.Icon

        -- Create the tab button.
        local tabBtn
        if sidebarLayout then
            tabBtn = create("TextButton", {
                Name = "Tab_" .. tabName,
                Size = UDim2.new(1, -16, 0, 36),
                Position = UDim2.new(0, 8, 0, 8 + #tabButtons * 40),
                BackgroundColor3 = Color3.fromRGB(30, 30, 40),
                BorderSizePixel = 0,
                Text = "",
                Parent = sidebarFrame,
            })
            addCorner(tabBtn, 6)

            if tabIcon then
                create("ImageLabel", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0, 10, 0.5, -9),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://" .. tostring(tabIcon),
                    ImageColor3 = Color3.fromRGB(160, 160, 180),
                    Parent = tabBtn,
                })
            end

            create("TextLabel", {
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, tabIcon and 34 or 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = tabName,
                TextColor3 = Color3.fromRGB(180, 180, 200),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = tabBtn,
            })
        else
            tabBtn = create("TextButton", {
                Name = "Tab_" .. tabName,
                Size = UDim2.new(0, 100, 1, 0),
                Position = UDim2.new(0, #tabButtons * 104, 0, 0),
                BackgroundTransparency = 1,
                Text = tabName,
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(150, 150, 170),
                TextSize = 12,
                Parent = topBar,
            })
        end

        table.insert(tabButtons, { button = tabBtn, name = tabName })

        -- Create the tab content frame.
        local tabFrame = create("ScrollingFrame", {
            Name = "Frame_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = tabContent,
        })
        create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = tabFrame,
        })
        create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tabFrame,
        })

        -- Tab object.
        local tab = {}
        local elementCount = 0

        local function getParentFrame()
            return tabFrame
        end

        local function makeElement(class, height, props)
            elementCount = elementCount + 1
            local el = create(class, {
                Size = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Color3.fromRGB(35, 35, 46),
                BorderSizePixel = 0,
                LayoutOrder = elementCount,
                Parent = getParentFrame(),
            })
            addCorner(el, 6)
            if props then
                for k, v in pairs(props) do
                    if k ~= "Parent" and k ~= "Size" then
                        el[k] = v
                    end
                end
            end
            return el
        end

        -- ====== CreateToggle ======
        function tab:CreateToggle(toggleProps)
            toggleProps = toggleProps or {}
            local name = toggleProps.name or toggleProps.Name or "Toggle"
            local default = toggleProps.default or toggleProps.Default or false
            local callback = toggleProps.callback or toggleProps.Callback
            local flag = toggleProps.flag or toggleProps.Flag

            local holder = makeElement("Frame", 38)

            local label = create("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = Color3.fromRGB(200, 200, 215),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local track = create("Frame", {
                Size = UDim2.new(0, 36, 0, 20),
                Position = UDim2.new(1, -48, 0.5, -10),
                BackgroundColor3 = default and Color3.fromRGB(80, 130, 220) or Color3.fromRGB(60, 60, 75),
                BorderSizePixel = 0,
                Parent = holder,
            })
            addCorner(track, 10)

            local knob = create("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(240, 240, 250),
                BorderSizePixel = 0,
                Parent = track,
            })
            addCorner(knob, 8)

            local state = default

            local function setState(value, fireCallback)
                state = value
                if fireCallback and callback then
                    task.spawn(callback, state)
                end
                tween(track, {
                    BackgroundColor3 = state and Color3.fromRGB(80, 130, 220) or Color3.fromRGB(60, 60, 75),
                })
                tween(knob, {
                    Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                })
            end

            local clickConn = holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    setState(not state, true)
                end
            end)
            table.insert(connections, clickConn)

            -- Toggle object.
            local toggleObj = {}
            function toggleObj:Set(value)
                setState(value, false)
            end
            function toggleObj:Get()
                return state
            end

            return toggleObj
        end

        -- ====== CreateSlider ======
        function tab:CreateSlider(sliderProps)
            sliderProps = sliderProps or {}
            local name = sliderProps.name or sliderProps.Name or "Slider"
            local min = sliderProps.min or sliderProps.Min or 0
            local max = sliderProps.max or sliderProps.Max or 100
            local default = sliderProps.default or sliderProps.Default or min
            local callback = sliderProps.callback or sliderProps.Callback
            local flag = sliderProps.flag or sliderProps.Flag

            local holder = makeElement("Frame", 52)

            local label = create("TextLabel", {
                Size = UDim2.new(1, -60, 0, 20),
                Position = UDim2.new(0, 12, 0, 4),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = Color3.fromRGB(200, 200, 215),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local valueLabel = create("TextLabel", {
                Size = UDim2.new(0, 50, 0, 20),
                Position = UDim2.new(1, -58, 0, 4),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = tostring(default),
                TextColor3 = Color3.fromRGB(120, 170, 255),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = holder,
            })

            local barBg = create("Frame", {
                Size = UDim2.new(1, -24, 0, 6),
                Position = UDim2.new(0, 12, 0, 32),
                BackgroundColor3 = Color3.fromRGB(50, 50, 65),
                BorderSizePixel = 0,
                Parent = holder,
            })
            addCorner(barBg, 3)

            local barFill = create("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(80, 130, 220),
                BorderSizePixel = 0,
                Parent = barBg,
            })
            addCorner(barFill, 3)

            local knob = create("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, -7, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(230, 230, 245),
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = barBg,
            })
            addCorner(knob, 7)

            local value = default
            local draggingSlider = false

            local function updateFromX(x)
                local relX = math.clamp((x - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                local newVal = math.floor(min + relX * (max - min) + 0.5)
                if newVal ~= value then
                    value = newVal
                    valueLabel.Text = tostring(value)
                    barFill.Size = UDim2.new(relX, 0, 1, 0)
                    knob.Position = UDim2.new(relX, -7, 0.5, -7)
                    if callback then
                        task.spawn(callback, value)
                    end
                end
            end

            local sliderConn = barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    updateFromX(input.Position.X)
                end
            end)
            table.insert(connections, sliderConn)

            local moveConn = userInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromX(input.Position.X)
                end
            end)
            table.insert(connections, moveConn)

            local endConn = userInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)
            table.insert(connections, endConn)

            -- Initial fill.
            local initRel = (default - min) / (max - min)
            barFill.Size = UDim2.new(initRel, 0, 1, 0)
            knob.Position = UDim2.new(initRel, -7, 0.5, -7)

            local sliderObj = {}
            function sliderObj:Set(val)
                val = math.clamp(val, min, max)
                local relX = (val - min) / (max - min)
                value = val
                valueLabel.Text = tostring(value)
                barFill.Size = UDim2.new(relX, 0, 1, 0)
                knob.Position = UDim2.new(relX, -7, 0.5, -7)
            end
            function sliderObj:Get()
                return value
            end

            return sliderObj
        end

        -- ====== CreateButton ======
        function tab:CreateButton(btnProps)
            btnProps = btnProps or {}
            local name = btnProps.name or btnProps.Name or "Button"
            local callback = btnProps.callback or btnProps.Callback

            local holder = makeElement("TextButton", 38, {
                Text = "",
                BackgroundColor3 = Color3.fromRGB(50, 70, 110),
                AutoButtonColor = false,
            })
            addCorner(holder, 6)

            local label = create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = name,
                TextColor3 = Color3.fromRGB(220, 225, 240),
                TextSize = 12,
                Parent = holder,
            })

            holder.MouseEnter:Connect(function()
                tween(holder, { BackgroundColor3 = Color3.fromRGB(65, 90, 140) }, 0.15)
            end)
            holder.MouseLeave:Connect(function()
                tween(holder, { BackgroundColor3 = Color3.fromRGB(50, 70, 110) }, 0.15)
            end)

            local btnConn = holder.MouseButton1Click:Connect(function()
                if callback then
                    task.spawn(callback)
                end
            end)
            table.insert(connections, btnConn)

            return {}
        end

        -- ====== CreateLabel ======
        function tab:CreateLabel(labelProps)
            labelProps = labelProps or {}
            local text = labelProps.text or labelProps.Text or "Label"

            local holder = makeElement("Frame", 28, {
                BackgroundTransparency = 1,
            })

            create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 4, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Color3.fromRGB(170, 170, 190),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            return {}
        end

        -- ====== CreateDivider ======
        function tab:CreateDivider()
            makeElement("Frame", 2, {
                BackgroundColor3 = Color3.fromRGB(50, 50, 65),
                BackgroundTransparency = 0.3,
            })
            return {}
        end

        -- ====== CreateSection ======
        function tab:CreateSection(sectionProps)
            sectionProps = sectionProps or {}
            local text = sectionProps.name or sectionProps.Name or "Section"

            local holder = makeElement("Frame", 30, {
                BackgroundTransparency = 1,
            })

            create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = text,
                TextColor3 = Color3.fromRGB(120, 170, 255),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            return {}
        end

        -- ====== CreateDropdown ======
        function tab:CreateDropdown(dropProps)
            dropProps = dropProps or {}
            local name = dropProps.name or dropProps.Name or "Dropdown"
            local options = dropProps.options or dropProps.Options or {}
            local callback = dropProps.callback or dropProps.Callback
            local default = dropProps.default or dropProps.Default or options[1]

            local holder = makeElement("Frame", 38)

            local label = create("TextLabel", {
                Size = UDim2.new(0, 120, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = Color3.fromRGB(200, 200, 215),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local currentLabel = create("TextLabel", {
                Size = UDim2.new(0, 120, 1, 0),
                Position = UDim2.new(1, -132, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = tostring(default),
                TextColor3 = Color3.fromRGB(120, 170, 255),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = holder,
            })

            local dropdownOpen = false
            local optionFrame

            local function closeDropdown()
                if optionFrame then
                    optionFrame:Destroy()
                    optionFrame = nil
                end
                dropdownOpen = false
            end

            local function openDropdown()
                if dropdownOpen then closeDropdown() return end
                dropdownOpen = true

                optionFrame = create("Frame", {
                    Size = UDim2.new(1, -24, 0, math.min(#options * 30, 150)),
                    Position = UDim2.new(0, 12, 1, 4),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 52),
                    BorderSizePixel = 0,
                    ZIndex = 5,
                    Parent = holder,
                })
                addCorner(optionFrame, 6)
                addStroke(optionFrame, Color3.fromRGB(60, 60, 80))

                local list = create("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 3,
                    CanvasSize = UDim2.new(0, 0, 0, #options * 30),
                    Parent = optionFrame,
                })
                create("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = list,
                })

                for i, opt in ipairs(options) do
                    local optBtn = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundTransparency = 1,
                        Text = tostring(opt),
                        Font = Enum.Font.Gotham,
                        TextColor3 = Color3.fromRGB(190, 190, 210),
                        TextSize = 11,
                        LayoutOrder = i,
                        Parent = list,
                    })

                    optBtn.MouseButton1Click:Connect(function()
                        currentLabel.Text = tostring(opt)
                        closeDropdown()
                        if callback then
                            task.spawn(callback, opt)
                        end
                    end)

                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundTransparency = 0.8
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundTransparency = 1
                    end)
                end
            end

            local dropConn = holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    openDropdown()
                end
            end)
            table.insert(connections, dropConn)

            local dropObj = {}
            function dropObj:Set(value)
                currentLabel.Text = tostring(value)
            end
            function dropObj:Get()
                return currentLabel.Text
            end

            return dropObj
        end

        -- Tab selection logic.
        local function selectTab()
            for _, entry in ipairs(tabButtons) do
                if entry.name == tabName then
                    tween(entry.button, {
                        BackgroundColor3 = sidebarLayout and Color3.fromRGB(45, 50, 65) or Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = sidebarLayout and 0 or 1,
                        TextColor3 = Color3.fromRGB(240, 240, 250),
                    })
                else
                    tween(entry.button, {
                        BackgroundColor3 = sidebarLayout and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = sidebarLayout and 0 or 1,
                        TextColor3 = Color3.fromRGB(150, 150, 170),
                    })
                end
            end

            for _, frame in ipairs(tabContent:GetChildren()) do
                if frame:IsA("ScrollingFrame") then
                    frame.Visible = frame.Name == "Frame_" .. tabName
                end
            end
            activeTab = tabName
        end

        tabBtn.MouseButton1Click:Connect(selectTab)

        -- Auto-select first tab.
        if #tabButtons == 1 then
            selectTab()
        end

        tabs[tabName] = tab
        return tab
    end

    function window:Notify(notifyProps)
        notifyProps = notifyProps or {}
        local title = notifyProps.title or notifyProps.Title or "Notification"
        local content = notifyProps.content or notifyProps.Content or ""
        local duration = notifyProps.duration or notifyProps.Duration or 4

        local notif = create("Frame", {
            Size = UDim2.new(0, 280, 0, 0),
            Position = UDim2.new(1, -20, 0, 20),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Color3.fromRGB(35, 35, 48),
            BorderSizePixel = 0,
            Parent = gui,
            ZIndex = 10,
        })
        addCorner(notif, 8)
        addStroke(notif, Color3.fromRGB(60, 60, 85))

        local notifTitle = create("TextLabel", {
            Size = UDim2.new(1, -20, 0, 22),
            Position = UDim2.new(0, 12, 0, 8),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = Color3.fromRGB(230, 230, 245),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notif,
        })

        local notifContent = create("TextLabel", {
            Size = UDim2.new(1, -20, 0, 18),
            Position = UDim2.new(0, 12, 0, 32),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = content,
            TextColor3 = Color3.fromRGB(160, 160, 185),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = notif,
        })

        notif.Size = UDim2.new(0, 280, 0, 64)

        task.delay(duration, function()
            if notif and notif.Parent then
                local fade = tween(notif, { BackgroundTransparency = 1 }, 0.3)
                fade.Completed:Connect(function()
                    notif:Destroy()
                end)
            end
        end)

        return {}
    end

    function window:Destroy()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        connections = {}
        if gui then gui:Destroy() end
    end

    return window
end

return Maytawin