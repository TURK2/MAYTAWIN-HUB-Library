-- Maytawin UI Library v2.3
-- Fixed centering (no UIScale), rounded topBar, cleaner float button.

local Maytawin = {}

-- Services.
local playersService = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")

-- Constants.
local UI_FOLDER_NAME = "MaytawinUI"
local BASE_W, BASE_H = 620, 430
local SIDEBAR_WIDTH = 190
local TOPBAR_HEIGHT = 56
local DRAG_THRESHOLD = 4

-- Palette: soft white / light blue.
local COLOR = {
    bg        = Color3.fromRGB(246, 249, 253),
    bg2       = Color3.fromRGB(238, 244, 251),
    bg3       = Color3.fromRGB(228, 237, 248),
    stroke    = Color3.fromRGB(206, 219, 235),
    strokeHi  = Color3.fromRGB(176, 199, 224),
    text      = Color3.fromRGB(44, 60, 84),
    textDim   = Color3.fromRGB(112, 132, 158),
    textMuted = Color3.fromRGB(158, 175, 196),
    accent    = Color3.fromRGB(122, 172, 236),
    accentSoft= Color3.fromRGB(184, 212, 245),
    accentDark= Color3.fromRGB(98, 146, 210),
    danger    = Color3.fromRGB(220, 122, 132),
    watermark = Color3.fromRGB(210, 222, 236),
    white     = Color3.fromRGB(255, 255, 255),
}

-- State.
local connections = {}
local gui, mainFrame, contentHolder, sidebarFrame
local tabButtons = {}
local tabs = {}
local activeTab
local floatBtn
local isOpen = true

-- Utility.
local function create(class, props)
    local instance = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then instance[k] = v end
    end
    if props and props.Parent then instance.Parent = props.Parent end
    return instance
end

local function tween(instance, props, speed, style, dir)
    local info = TweenInfo.new(
        speed or 0.22,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    )
    local t = tweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function addCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
        Parent = parent,
    })
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or COLOR.stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function addPadding(parent, t, b, l, r)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        Parent = parent,
    })
end

local function dragify(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    local moveConn, endConn

    local function stop()
        dragging = false
        if moveConn then moveConn:Disconnect() moveConn = nil end
        if endConn then endConn:Disconnect() endConn = nil end
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        local moved = false

        moveConn = input.Changed:Connect(function()
            if not dragging then return end
            if input.UserInputState == Enum.UserInputState.End then stop() return end
            local delta = input.Position - dragStart
            if not moved and (math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD) then
                moved = true
            end
            if moved then
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)

        endConn = userInputService.InputEnded:Connect(function(i)
            if i == input then stop() end
        end)
    end)
end

-- ============================================================
-- WINDOW
-- ============================================================

function Maytawin:CreateWindow(props)
    props = props or {}
    local windowName = props.name or "Maytawin UI"
    local subtitle = props.subtitle or "by Maytawin"
    local sidebarLayout = props.sidebarLayout ~= false
    local toggleKey = props.toggleKeybind or Enum.KeyCode.RightShift

    local old = coreGui:FindFirstChild(UI_FOLDER_NAME)
    if old then old:Destroy() end

    gui = create("ScreenGui", {
        Name = UI_FOLDER_NAME,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = coreGui,
    })

    -- Full-screen parent.
    local root = create("Frame", {
        Name = "Root",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        Parent = gui,
    })

    -- Main frame, anchored at screen center. Size computed dynamically.
    mainFrame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.fromOffset(BASE_W, BASE_H),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = COLOR.bg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    })
    addCorner(mainFrame, 18)
    addStroke(mainFrame, COLOR.stroke, 1)

    -- Compute size based on viewport. Always fit + preserve aspect.
    local function computeFrameSize()
        local cam = workspace.CurrentCamera
        local vp = (gui and gui.AbsoluteSize.X > 0) and gui.AbsoluteSize
            or (cam and cam.ViewportSize)
            or Vector2.new(1920, 1080)
        local maxW = math.max(280, vp.X - 40)
        local maxH = math.max(220, vp.Y - 40)
        local w, h = BASE_W, BASE_H
        if w > maxW then
            h = h * (maxW / w)
            w = maxW
        end
        if h > maxH then
            w = w * (maxH / h)
            h = maxH
        end
        return math.floor(w), math.floor(h)
    end

    local function applySize()
        local w, h = computeFrameSize()
        tween(mainFrame, { Size = UDim2.fromOffset(w, h) }, 0.2)
        -- Reassert centering on every resize to be safe.
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    end

    task.defer(applySize)

    -- Top accent line.
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = COLOR.accentSoft,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = mainFrame,
    })

    -- Top bar with its own UICorner so the top corners match mainFrame.
    local topBar = create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
        Position = UDim2.new(0, 0, 0, 3),
        BackgroundColor3 = COLOR.bg2,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    addCorner(topBar, 18)

    -- Watermark behind title.
    create("TextLabel", {
        Name = "Watermark",
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.new(0, 60, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = "ByMaytawin",
        TextColor3 = COLOR.watermark,
        TextTransparency = 0.2,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 0,
        Parent = topBar,
    })

    -- Brand dot.
    local brandDot = create("Frame", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(0, 18, 0.5, -14),
        BackgroundColor3 = COLOR.accent,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = topBar,
    })
    addCorner(brandDot, 5)

    create("TextLabel", {
        Size = UDim2.new(0, 220, 0, 16),
        Position = UDim2.new(0, 36, 0, 13),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = windowName,
        TextColor3 = COLOR.text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = topBar,
    })

    create("TextLabel", {
        Size = UDim2.new(0, 220, 0, 12),
        Position = UDim2.new(0, 36, 0, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = COLOR.textMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = topBar,
    })

    -- Only close button.
    local closeBtn = create("TextButton", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -42, 0.5, -15),
        BackgroundColor3 = COLOR.bg3,
        BorderSizePixel = 0,
        Text = "×",
        Font = Enum.Font.GothamBold,
        TextColor3 = COLOR.textDim,
        TextSize = 16,
        AutoButtonColor = false,
        ZIndex = 3,
        Parent = topBar,
    })
    addCorner(closeBtn, 10)
    addStroke(closeBtn, COLOR.stroke, 1)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(248, 220, 224), TextColor3 = COLOR.danger }, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundColor3 = COLOR.bg3, TextColor3 = COLOR.textDim }, 0.15)
    end)

    dragify(mainFrame, topBar)

    -- Body.
    local body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -(TOPBAR_HEIGHT + 3)),
        Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT + 3),
        BackgroundTransparency = 1,
        Parent = mainFrame,
    })
    contentHolder = body

    if sidebarLayout then
        sidebarFrame = create("Frame", {
            Name = "Sidebar",
            Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
            BackgroundColor3 = COLOR.bg2,
            BorderSizePixel = 0,
            Parent = body,
        })
        create("Frame", {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = COLOR.stroke,
            BorderSizePixel = 0,
            Parent = sidebarFrame,
        })
        addPadding(sidebarFrame, 12, 12, 10, 10)
    end

    local tabContent = create("Frame", {
        Name = "TabContent",
        Size = sidebarLayout and UDim2.new(1, -SIDEBAR_WIDTH, 1, 0) or UDim2.new(1, 0, 1, 0),
        Position = sidebarLayout and UDim2.new(0, SIDEBAR_WIDTH, 0, 0) or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = body,
    })

    -- ============================================================
    -- Floating toggle button (clean circle w/ drawn icon).
    -- ============================================================
    floatBtn = create("TextButton", {
        Name = "FloatBtn",
        Size = UDim2.fromOffset(54, 54),
        Position = UDim2.new(0, 22, 0.5, -27),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = COLOR.white,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = root,
        ZIndex = 20,
    })
    addCorner(floatBtn, 27)
    addStroke(floatBtn, COLOR.accentSoft, 2)

    -- Icon holder (contains ☰ or ✕, drawn with frames).
    local iconHolder = create("Frame", {
        Name = "IconHolder",
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = floatBtn,
        ZIndex = 3,
    })

    -- Three bars (hamburger).
    local bar1 = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2.5),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = COLOR.accentDark,
        BorderSizePixel = 0,
        Parent = iconHolder,
    })
    addCorner(bar1, 1)

    local bar2 = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2.5),
        Position = UDim2.new(0, 0, 0, 9.5),
        BackgroundColor3 = COLOR.accentDark,
        BorderSizePixel = 0,
        Parent = iconHolder,
    })
    addCorner(bar2, 1)

    local bar3 = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2.5),
        Position = UDim2.new(0, 0, 0, 15),
        BackgroundColor3 = COLOR.accentDark,
        BorderSizePixel = 0,
        Parent = iconHolder,
    })
    addCorner(bar3, 1)

    -- Toggle icon between hamburger and X.
    local function setIcon(open)
        if open then
            -- Rotate bars into an X.
            bar1.Size = UDim2.new(1.15, 0, 0, 2.5)
            bar1.Position = UDim2.new(-0.075, 0, 0.5, -1.25)
            bar1.Rotation = 45
            bar2.Visible = false
            bar3.Size = UDim2.new(1.15, 0, 0, 2.5)
            bar3.Position = UDim2.new(-0.075, 0, 0.5, -1.25)
            bar3.Rotation = -45
        else
            bar1.Size = UDim2.new(1, 0, 0, 2.5)
            bar1.Position = UDim2.new(0, 0, 0, 4)
            bar1.Rotation = 0
            bar2.Visible = true
            bar3.Size = UDim2.new(1, 0, 0, 2.5)
            bar3.Position = UDim2.new(0, 0, 0, 15)
            bar3.Rotation = 0
        end
    end

    floatBtn.MouseEnter:Connect(function()
        tween(floatBtn, { Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0, 22, 0.5, -30) }, 0.15)
    end)
    floatBtn.MouseLeave:Connect(function()
        tween(floatBtn, { Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0, 22, 0.5, -27) }, 0.15)
    end)

    dragify(floatBtn)

    -- Center helper (also reasserts AnchorPoint).
    local function centerWindow()
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    end

    -- Open / close logic.
    local function setOpen(state)
        if isOpen == state then return end
        isOpen = state
        if state then
            -- Recenter BEFORE showing so animation starts from center.
            centerWindow()
            mainFrame.Visible = true
            local w, h = computeFrameSize()
            mainFrame.Size = UDim2.fromOffset(w * 0.92, h * 0.92)
            tween(mainFrame, { Size = UDim2.fromOffset(w, h) }, 0.25, Enum.EasingStyle.Quart)
            setIcon(true)
        else
            setIcon(false)
            mainFrame.Visible = false
        end
    end

    -- Tap detection (avoids toggling on drag).
    local tapBegan
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            tapBegan = input.Position
        end
    end)
    floatBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if tapBegan then
                if (input.Position - tapBegan).Magnitude < DRAG_THRESHOLD then
                    setOpen(not isOpen)
                end
                tapBegan = nil
            end
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        setOpen(false)
    end)

    table.insert(connections, userInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == toggleKey then
            setOpen(not isOpen)
        end
    end))

    -- Resize on viewport change, always recenter.
    table.insert(connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        applySize()
        centerWindow()
    end))

    -- ========================================================
    -- WINDOW API
    -- ========================================================

    local window = {}

    function window:CreateTab(tabProps)
        tabProps = tabProps or {}
        local tabName = tabProps.name or "Tab"
        local tabIcon = tabProps.icon or tabProps.Icon

        local tabBtn = create("TextButton", {
            Name = "Tab_" .. tabName,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = COLOR.bg3,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #tabButtons + 1,
            Parent = sidebarFrame or tabContent,
        })
        addCorner(tabBtn, 10)

        local indicator = create("Frame", {
            Size = UDim2.new(0, 3, 0.55, 0),
            Position = UDim2.new(0, -4, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = COLOR.accent,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Parent = tabBtn,
        })
        addCorner(indicator, 2)

        if tabIcon then
            create("ImageLabel", {
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.new(0, 10, 0.5, -9),
                BackgroundTransparency = 1,
                Image = "rbxassetid://" .. tostring(tabIcon),
                ImageColor3 = COLOR.textDim,
                Parent = tabBtn,
            })
        end

        create("TextLabel", {
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.new(0, tabIcon and 34 or 12, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = tabName,
            TextColor3 = COLOR.textDim,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabBtn,
        })

        table.insert(tabButtons, { button = tabBtn, name = tabName, indicator = indicator })

        if sidebarFrame then
            local layout = sidebarFrame:FindFirstChildOfClass("UIListLayout")
            if not layout then
                create("UIListLayout", {
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = sidebarFrame,
                })
            end
        end

        local tabFrame = create("ScrollingFrame", {
            Name = "Frame_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLOR.strokeHi,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = tabContent,
        })
        addPadding(tabFrame, 14, 14, 14, 14)
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tabFrame,
        })

        local tab = {}
        local elementCount = 0

        local function makeElement(class, height, props)
            elementCount = elementCount + 1
            local el = create(class, {
                Size = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = COLOR.bg2,
                BorderSizePixel = 0,
                LayoutOrder = elementCount,
                Parent = tabFrame,
            })
            addCorner(el, 10)
            addStroke(el, COLOR.stroke, 1)
            if props then
                for k, v in pairs(props) do
                    if k ~= "Parent" and k ~= "Size" then el[k] = v end
                end
            end
            return el
        end

        function tab:CreateToggle(p)
            p = p or {}
            local name = p.name or "Toggle"
            local default = p.default or false
            local cb = p.callback

            local holder = makeElement("Frame", 40)

            create("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = COLOR.text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local track = create("Frame", {
                Size = UDim2.fromOffset(38, 22),
                Position = UDim2.new(1, -50, 0.5, -11),
                BackgroundColor3 = default and COLOR.accent or COLOR.stroke,
                BorderSizePixel = 0,
                Parent = holder,
            })
            addCorner(track, 11)

            local knob = create("Frame", {
                Size = UDim2.fromOffset(18, 18),
                Position = default and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = COLOR.white,
                BorderSizePixel = 0,
                Parent = track,
            })
            addCorner(knob, 9)
            addStroke(knob, COLOR.stroke, 1)

            local state = default

            local function setState(v, fire)
                state = v
                if fire and cb then task.spawn(cb, state) end
                tween(track, { BackgroundColor3 = state and COLOR.accent or COLOR.stroke }, 0.2)
                tween(knob, {
                    Position = state and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                }, 0.2)
            end

            holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    setState(not state, true)
                end
            end)

            return {
                Set = function(_, v) setState(v, false) end,
                Get = function() return state end,
            }
        end

        function tab:CreateSlider(p)
            p = p or {}
            local name = p.name or "Slider"
            local min = p.min or 0
            local max = p.max or 100
            local default = math.clamp(p.default or min, min, max)
            local cb = p.callback

            local holder = makeElement("Frame", 56)

            create("TextLabel", {
                Size = UDim2.new(1, -70, 0, 20),
                Position = UDim2.new(0, 14, 0, 6),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = COLOR.text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local valueLabel = create("TextLabel", {
                Size = UDim2.new(0, 50, 0, 20),
                Position = UDim2.new(1, -64, 0, 6),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = tostring(default),
                TextColor3 = COLOR.accentDark,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = holder,
            })

            local barBg = create("Frame", {
                Size = UDim2.new(1, -28, 0, 6),
                Position = UDim2.new(0, 14, 0, 36),
                BackgroundColor3 = COLOR.stroke,
                BorderSizePixel = 0,
                Parent = holder,
            })
            addCorner(barBg, 3)

            local barFill = create("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = COLOR.accent,
                BorderSizePixel = 0,
                Parent = barBg,
            })
            addCorner(barFill, 3)

            local knob = create("Frame", {
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(0, -8, 0.5, -8),
                BackgroundColor3 = COLOR.white,
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = barBg,
            })
            addCorner(knob, 8)
            addStroke(knob, COLOR.strokeHi, 1)

            local value = default
            local draggingSlider = false

            local function updateFromX(x)
                local relX = math.clamp((x - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                local newVal = math.floor(min + relX * (max - min) + 0.5)
                if newVal ~= value then
                    value = newVal
                    valueLabel.Text = tostring(value)
                    barFill.Size = UDim2.new(relX, 0, 1, 0)
                    knob.Position = UDim2.new(relX, -8, 0.5, -8)
                    if cb then task.spawn(cb, value) end
                end
            end

            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    updateFromX(input.Position.X)
                end
            end)

            table.insert(connections, userInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromX(input.Position.X)
                end
            end))

            table.insert(connections, userInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end))

            local initRel = (default - min) / (max - min)
            barFill.Size = UDim2.new(initRel, 0, 1, 0)
            knob.Position = UDim2.new(initRel, -8, 0.5, -8)

            return {
                Set = function(_, v)
                    v = math.clamp(v, min, max)
                    local rel = (v - min) / (max - min)
                    value = v
                    valueLabel.Text = tostring(value)
                    barFill.Size = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, -8, 0.5, -8)
                end,
                Get = function() return value end,
            }
        end

        function tab:CreateButton(p)
            p = p or {}
            local name = p.name or "Button"
            local cb = p.callback

            local holder = makeElement("TextButton", 40, {
                Text = "",
                BackgroundColor3 = COLOR.accent,
                AutoButtonColor = false,
            })

            create("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = name,
                TextColor3 = COLOR.white,
                TextSize = 12,
                Parent = holder,
            })

            holder.MouseEnter:Connect(function()
                tween(holder, { BackgroundColor3 = COLOR.accentDark }, 0.15)
            end)
            holder.MouseLeave:Connect(function()
                tween(holder, { BackgroundColor3 = COLOR.accent }, 0.15)
            end)
            holder.MouseButton1Click:Connect(function()
                if cb then task.spawn(cb) end
            end)

            return {}
        end

        function tab:CreateLabel(p)
            p = p or {}
            local holder = makeElement("Frame", 28, { BackgroundTransparency = 1 })
            local s = holder:FindFirstChildOfClass("UIStroke")
            if s then s.Transparency = 1 end
            create("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                Position = UDim2.new(0, 4, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = p.text or "Label",
                TextColor3 = COLOR.textDim,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })
            return {}
        end

        function tab:CreateSection(p)
            p = p or {}
            local holder = makeElement("Frame", 30, { BackgroundTransparency = 1 })
            local s = holder:FindFirstChildOfClass("UIStroke")
            if s then s.Transparency = 1 end
            create("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = p.name or "Section",
                TextColor3 = COLOR.accentDark,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })
            return {}
        end

        function tab:CreateDivider()
            local holder = makeElement("Frame", 1, { BackgroundColor3 = COLOR.stroke, BackgroundTransparency = 0.4 })
            local s = holder:FindFirstChildOfClass("UIStroke")
            if s then s.Transparency = 1 end
            return {}
        end

        local function selectTab()
            for _, entry in ipairs(tabButtons) do
                local isActive = entry.name == tabName
                tween(entry.button, {
                    BackgroundTransparency = isActive and 0 or 1,
                    BackgroundColor3 = COLOR.bg3,
                }, 0.18)
                tween(entry.indicator, {
                    BackgroundTransparency = isActive and 0 or 1,
                }, 0.18)
            end
            for _, frame in ipairs(tabContent:GetChildren()) do
                if frame:IsA("ScrollingFrame") then
                    frame.Visible = frame.Name == "Frame_" .. tabName
                end
            end
            activeTab = tabName
        end

        tabBtn.MouseEnter:Connect(function()
            if activeTab ~= tabName then
                tween(tabBtn, { BackgroundTransparency = 0.5 }, 0.15)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if activeTab ~= tabName then
                tween(tabBtn, { BackgroundTransparency = 1 }, 0.15)
            end
        end)
        tabBtn.MouseButton1Click:Connect(selectTab)

        if #tabButtons == 1 then selectTab() end

        tabs[tabName] = tab
        return tab
    end

    function window:Notify(p)
        p = p or {}
        local title = p.title or "Notification"
        local content = p.content or ""
        local duration = p.duration or 4

        local wrap = create("Frame", {
            Size = UDim2.fromOffset(300, 68),
            Position = UDim2.new(1, 22, 0, 22),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = COLOR.bg,
            BorderSizePixel = 0,
            Parent = root,
            ZIndex = 50,
        })
        addCorner(wrap, 12)
        addStroke(wrap, COLOR.strokeHi, 1)

        local accentBar = create("Frame", {
            Size = UDim2.new(0, 3, 1, -16),
            Position = UDim2.new(0, 6, 0, 8),
            BackgroundColor3 = COLOR.accent,
            BorderSizePixel = 0,
            Parent = wrap,
        })
        addCorner(accentBar, 2)

        create("TextLabel", {
            Size = UDim2.new(1, -30, 0, 20),
            Position = UDim2.new(0, 18, 0, 10),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = COLOR.text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = wrap,
        })
        create("TextLabel", {
            Size = UDim2.new(1, -30, 0, 16),
            Position = UDim2.new(0, 18, 0, 34),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = content,
            TextColor3 = COLOR.textDim,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = wrap,
        })

        tween(wrap, { Position = UDim2.new(1, -22, 0, 22) }, 0.32, Enum.EasingStyle.Quart)

        task.delay(duration, function()
            if wrap and wrap.Parent then
                tween(wrap, { Position = UDim2.new(1, 22, 0, 22) }, 0.28)
                task.wait(0.3)
                wrap:Destroy()
            end
        end)
        return {}
    end

    function window:Destroy()
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        connections = {}
        if gui then gui:Destroy() end
    end

    return window
end

return Maytawin