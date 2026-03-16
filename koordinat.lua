--[[
  COORDINATE SAVER PRO
  BY ALFIAN
  F8 toggle
]]

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player     = Players.LocalPlayer

pcall(function()
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name == "CoordSaverPro" then g:Destroy() end
    end
end)

-- ══════════════════════════════
-- STATE
-- ══════════════════════════════
local savedCoords = {}
local autoSave    = true
local idleThresh  = 2.5
local lastMovTime = tick()
local lastAutoPos = nil
local idleSaved   = false
local MIN_DIST    = 2.0

local function fmtPos(v3)
    if not v3 then return "nil" end
    return string.format("%.2f, %.2f, %.2f", v3.X, v3.Y, v3.Z)
end
local function getHRP()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function addCoord(pos, source)
    local e = {
        index  = #savedCoords + 1,
        pos    = pos,
        posStr = fmtPos(pos),
        source = source or "MANUAL",
        time   = os.date("%H:%M:%S"),
    }
    table.insert(savedCoords, e)
    return e
end

-- ══════════════════════════════
-- WARNA
-- ══════════════════════════════
local BK = Color3.fromRGB(7,   7,  10)
local DK = Color3.fromRGB(14, 14,  20)
local CD = Color3.fromRGB(22, 22,  32)
local BD = Color3.fromRGB(45, 45,  65)
local W1 = Color3.fromRGB(220,220,230)
local G1 = Color3.fromRGB(90, 90, 110)
local GR = Color3.fromRGB(60, 220,120)
local RD = Color3.fromRGB(210, 70,  70)
local YL = Color3.fromRGB(220,190,  60)
local CY = Color3.fromRGB(80, 210,255)
local AC = Color3.fromRGB(120,100,255)
local PK = Color3.fromRGB(255,100,180)

local function uic(p, r)
    local u = Instance.new("UICorner", p)
    u.CornerRadius = UDim.new(0, r or 7)
end
local function usk(p, c, t)
    local s = Instance.new("UIStroke", p)
    s.Color = c or BD; s.Thickness = t or 1
end
local function mkL(par, txt, sz, col, font, xa)
    local l = Instance.new("TextLabel", par)
    l.BackgroundTransparency = 1
    l.Text           = txt or ""
    l.TextColor3     = col  or W1
    l.Font           = font or Enum.Font.Gotham
    l.TextSize       = sz   or 11
    l.TextXAlignment = xa   or Enum.TextXAlignment.Left
    l.ZIndex         = 14
    return l
end

-- ══════════════════════════════
-- SCREEN GUI
-- ══════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name           = "CoordSaverPro"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 9999
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = player.PlayerGui  -- langsung parent ke PlayerGui

-- MAIN FRAME
local F = Instance.new("Frame", sg)
F.Size             = UDim2.new(0, 260, 0, 480)
F.Position         = UDim2.new(0, 20, 0, 80)
F.BackgroundColor3 = BK
F.BorderSizePixel  = 0
F.Active           = true
F.Draggable        = true
F.ZIndex           = 10
uic(F, 10); usk(F, BD, 1)

-- top accent line
local TAcc = Instance.new("Frame", F)
TAcc.Size             = UDim2.new(1,-4,0,1)
TAcc.Position         = UDim2.new(0,2,0,0)
TAcc.BackgroundColor3 = Color3.fromRGB(90,90,140)
TAcc.BorderSizePixel  = 0; TAcc.ZIndex = 15
uic(TAcc, 1)

-- ── TOPBAR ──
local TB = Instance.new("Frame", F)
TB.Size             = UDim2.new(1,0,0,36)
TB.Position         = UDim2.new(0,0,0,0)
TB.BackgroundColor3 = DK
TB.BorderSizePixel  = 0; TB.ZIndex = 11
uic(TB, 10)
local TBfix = Instance.new("Frame", TB)
TBfix.Size             = UDim2.new(1,0,0,10)
TBfix.Position         = UDim2.new(0,0,1,-10)
TBfix.BackgroundColor3 = DK
TBfix.BorderSizePixel  = 0; TBfix.ZIndex = 11
local TBbot = Instance.new("Frame", TB)
TBbot.Size             = UDim2.new(1,0,0,1)
TBbot.Position         = UDim2.new(0,0,1,-1)
TBbot.BackgroundColor3 = BD
TBbot.BorderSizePixel  = 0; TBbot.ZIndex = 12

-- live dot
local Dot = Instance.new("Frame", TB)
Dot.Size             = UDim2.new(0,6,0,6)
Dot.Position         = UDim2.new(0,11,0.5,-3)
Dot.BackgroundColor3 = GR
Dot.BorderSizePixel  = 0; Dot.ZIndex = 13
uic(Dot, 6)
-- blink
local dotVisible = true
task.spawn(function()
    while sg and sg.Parent do
        dotVisible = not dotVisible
        Dot.BackgroundTransparency = dotVisible and 0 or 0.6
        task.wait(0.9)
    end
end)

local TLbl = mkL(TB, "COORD SAVER PRO", 11, W1, Enum.Font.GothamBold)
TLbl.Size     = UDim2.new(1,-50,1,0)
TLbl.Position = UDim2.new(0,23,0,0)
TLbl.ZIndex   = 13

local XB = Instance.new("TextButton", TB)
XB.Size             = UDim2.new(0,22,0,22)
XB.Position         = UDim2.new(1,-27,0.5,-11)
XB.BackgroundColor3 = CD
XB.Text             = "✕"
XB.TextColor3       = G1
XB.Font             = Enum.Font.GothamBold
XB.TextSize         = 10
XB.BorderSizePixel  = 0; XB.ZIndex = 14
uic(XB, 5); usk(XB, BD, 1)
XB.MouseEnter:Connect(function() XB.TextColor3 = W1 end)
XB.MouseLeave:Connect(function() XB.TextColor3 = G1 end)
XB.MouseButton1Click:Connect(function() sg:Destroy() end)

-- ── BODY (UIListLayout) ──
local Body = Instance.new("Frame", F)
Body.Size             = UDim2.new(1,-20,1,-46)
Body.Position         = UDim2.new(0,10,0,42)
Body.BackgroundTransparency = 1
Body.ZIndex           = 11

local BL = Instance.new("UIListLayout", Body)
BL.SortOrder = Enum.SortOrder.LayoutOrder
BL.Padding   = UDim.new(0,6)

-- ── KOORDINAT BOX ──
local CoordBox = Instance.new("Frame", Body)
CoordBox.LayoutOrder      = 1
CoordBox.Size             = UDim2.new(1,0,0,68)
CoordBox.BackgroundColor3 = CD
CoordBox.BorderSizePixel  = 0; CoordBox.ZIndex = 12
uic(CoordBox, 8); usk(CoordBox, BD, 1)

local CoordHdr = mkL(CoordBox, "📍  KOORDINAT SEKARANG", 8, G1, Enum.Font.GothamBold)
CoordHdr.Size     = UDim2.new(1,-10,0,12)
CoordHdr.Position = UDim2.new(0,8,0,5)
CoordHdr.ZIndex   = 13

local CoordX = mkL(CoordBox, "X: –", 10, CY, Enum.Font.Code)
CoordX.Size     = UDim2.new(1,-10,0,13)
CoordX.Position = UDim2.new(0,8,0,19)
CoordX.ZIndex   = 13

local CoordY = mkL(CoordBox, "Y: –", 10, PK, Enum.Font.Code)
CoordY.Size     = UDim2.new(1,-10,0,13)
CoordY.Position = UDim2.new(0,8,0,33)
CoordY.ZIndex   = 13

local CoordZ = mkL(CoordBox, "Z: –", 10, YL, Enum.Font.Code)
CoordZ.Size     = UDim2.new(1,-10,0,13)
CoordZ.Position = UDim2.new(0,8,0,47)
CoordZ.ZIndex   = 13

-- ── SAVE BUTTON ──
local SaveBtn = Instance.new("TextButton", Body)
SaveBtn.LayoutOrder      = 2
SaveBtn.Size             = UDim2.new(1,0,0,36)
SaveBtn.BackgroundColor3 = Color3.fromRGB(20,70,35)
SaveBtn.Text             = "💾   SAVE KOORDINAT"
SaveBtn.TextColor3       = GR
SaveBtn.Font             = Enum.Font.GothamBold
SaveBtn.TextSize         = 12
SaveBtn.BorderSizePixel  = 0; SaveBtn.ZIndex = 12
uic(SaveBtn, 8); usk(SaveBtn, Color3.fromRGB(50,160,80), 1)
SaveBtn.MouseEnter:Connect(function()
    SaveBtn.BackgroundColor3 = Color3.fromRGB(25,90,45)
end)
SaveBtn.MouseLeave:Connect(function()
    SaveBtn.BackgroundColor3 = Color3.fromRGB(20,70,35)
end)

-- ── AUTO-SAVE ROW ──
local AutoRow = Instance.new("Frame", Body)
AutoRow.LayoutOrder      = 3
AutoRow.Size             = UDim2.new(1,0,0,26)
AutoRow.BackgroundColor3 = CD
AutoRow.BorderSizePixel  = 0; AutoRow.ZIndex = 12
uic(AutoRow, 6); usk(AutoRow, BD, 1)

local AutoLbl = mkL(AutoRow, "Auto-save saat diam", 10, G1, Enum.Font.Gotham)
AutoLbl.Size     = UDim2.new(1,-52,1,0)
AutoLbl.Position = UDim2.new(0,8,0,0)
AutoLbl.ZIndex   = 13

local AutoToggle = Instance.new("TextButton", AutoRow)
AutoToggle.Size             = UDim2.new(0,38,0,18)
AutoToggle.Position         = UDim2.new(1,-42,0.5,-9)
AutoToggle.BackgroundColor3 = AC
AutoToggle.Text             = "ON"
AutoToggle.TextColor3       = W1
AutoToggle.Font             = Enum.Font.GothamBold
AutoToggle.TextSize         = 9
AutoToggle.BorderSizePixel  = 0; AutoToggle.ZIndex = 13
uic(AutoToggle, 5)

-- ── IDLE LABEL ──
local IdleLbl = mkL(Body, "⏱  Diam selama: 2.5 dtk", 9, G1, Enum.Font.Gotham)
IdleLbl.LayoutOrder = 4
IdleLbl.Size        = UDim2.new(1,0,0,14)
IdleLbl.ZIndex      = 12

-- ── STATUS BOX ──
local StatBox = Instance.new("Frame", Body)
StatBox.LayoutOrder      = 5
StatBox.Size             = UDim2.new(1,0,0,26)
StatBox.BackgroundColor3 = CD
StatBox.BorderSizePixel  = 0; StatBox.ZIndex = 12
uic(StatBox, 6); usk(StatBox, BD, 1)

local StatLbl = mkL(StatBox, "● Siap — 0 koordinat tersimpan", 9, GR, Enum.Font.Code)
StatLbl.Size     = UDim2.new(1,-10,1,0)
StatLbl.Position = UDim2.new(0,8,0,0)
StatLbl.ZIndex   = 13

-- ── LOG HEADER ──
local LogHdrLbl = mkL(Body, "LOG KOORDINAT", 8, G1, Enum.Font.GothamBold)
LogHdrLbl.LayoutOrder = 6
LogHdrLbl.Size        = UDim2.new(1,0,0,14)
LogHdrLbl.ZIndex      = 12

-- ── LOG SCROLL ──
local LogScroll = Instance.new("ScrollingFrame", Body)
LogScroll.LayoutOrder               = 7
LogScroll.Size                      = UDim2.new(1,0,0,152)
LogScroll.BackgroundColor3          = DK
LogScroll.BorderSizePixel           = 0
LogScroll.ScrollBarThickness        = 2
LogScroll.ScrollBarImageColor3      = BD
LogScroll.CanvasSize                = UDim2.new(0,0,0,0)
LogScroll.AutomaticCanvasSize       = Enum.AutomaticSize.Y
LogScroll.ZIndex                    = 12
uic(LogScroll, 6); usk(LogScroll, BD, 1)

local LogLayout = Instance.new("UIListLayout", LogScroll)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding   = UDim.new(0,2)
local LogPad = Instance.new("UIPadding", LogScroll)
LogPad.PaddingTop    = UDim.new(0,4)
LogPad.PaddingLeft   = UDim.new(0,4)
LogPad.PaddingRight  = UDim.new(0,4)
LogPad.PaddingBottom = UDim.new(0,4)

-- ── CLEAR + COPY ──
local BtnRow = Instance.new("Frame", Body)
BtnRow.LayoutOrder      = 8
BtnRow.Size             = UDim2.new(1,0,0,28)
BtnRow.BackgroundTransparency = 1
BtnRow.ZIndex           = 12
local BRL = Instance.new("UIListLayout", BtnRow)
BRL.FillDirection = Enum.FillDirection.Horizontal
BRL.Padding       = UDim.new(0,6)
BRL.SortOrder     = Enum.SortOrder.LayoutOrder

local ClearBtn = Instance.new("TextButton", BtnRow)
ClearBtn.LayoutOrder      = 1
ClearBtn.Size             = UDim2.new(0.36,-3,1,0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(50,12,12)
ClearBtn.Text             = "🗑  CLEAR"
ClearBtn.TextColor3       = RD
ClearBtn.Font             = Enum.Font.GothamBold
ClearBtn.TextSize         = 10
ClearBtn.BorderSizePixel  = 0; ClearBtn.ZIndex = 12
uic(ClearBtn, 6); usk(ClearBtn, BD, 1)

local CopyBtn = Instance.new("TextButton", BtnRow)
CopyBtn.LayoutOrder      = 2
CopyBtn.Size             = UDim2.new(0.64,-3,1,0)
CopyBtn.BackgroundColor3 = Color3.fromRGB(12,40,20)
CopyBtn.Text             = "📋  COPY LOG"
CopyBtn.TextColor3       = GR
CopyBtn.Font             = Enum.Font.GothamBold
CopyBtn.TextSize         = 10
CopyBtn.BorderSizePixel  = 0; CopyBtn.ZIndex = 12
uic(CopyBtn, 6); usk(CopyBtn, BD, 1)

-- ══════════════════════════════
-- LOGIC
-- ══════════════════════════════
local function updateStat()
    StatLbl.Text       = string.format("● %d koordinat tersimpan", #savedCoords)
    StatLbl.TextColor3 = #savedCoords > 0 and GR or G1
end

local function pushLogRow(entry)
    local srcClr = entry.source == "IDLE" and YL or GR
    local srcTag = entry.source == "IDLE" and "⏱" or "💾"

    local row = Instance.new("Frame", LogScroll)
    row.LayoutOrder         = entry.index
    row.Size                = UDim2.new(1,0,0,38)
    row.BackgroundColor3    = CD
    row.BorderSizePixel     = 0; row.ZIndex = 13
    uic(row, 4)

    local badge = mkL(row, "#"..entry.index, 8, srcClr, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    badge.Size     = UDim2.new(0,20,0,20)
    badge.Position = UDim2.new(0,4,0,9)
    badge.ZIndex   = 14

    local stag = mkL(row, srcTag, 11, srcClr, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    stag.Size     = UDim2.new(0,16,0,16)
    stag.Position = UDim2.new(0,26,0,11)
    stag.ZIndex   = 14

    local coordTxt = string.format("X:%.1f  Y:%.1f  Z:%.1f",
        entry.pos.X, entry.pos.Y, entry.pos.Z)
    local ctxt = mkL(row, coordTxt, 9, W1, Enum.Font.Code)
    ctxt.Size     = UDim2.new(1,-52,0,14)
    ctxt.Position = UDim2.new(0,46,0,5)
    ctxt.ZIndex   = 14

    local tLbl = mkL(row, entry.time, 8, G1, Enum.Font.Gotham)
    tLbl.Size     = UDim2.new(1,-52,0,12)
    tLbl.Position = UDim2.new(0,46,0,21)
    tLbl.ZIndex   = 14

    task.defer(function()
        LogScroll.CanvasPosition = Vector2.new(0, 99999)
    end)
end

local function saveCoord(source)
    local hrp = getHRP()
    if not hrp then
        StatLbl.Text       = "⚠  Karakter belum spawn!"
        StatLbl.TextColor3 = RD
        return
    end
    local pos = hrp.Position
    if #savedCoords > 0 then
        if (pos - savedCoords[#savedCoords].pos).Magnitude < 0.5 then return end
    end
    local entry = addCoord(pos, source)
    pushLogRow(entry)
    updateStat()

    local origTxt = SaveBtn.Text
    local origClr = SaveBtn.BackgroundColor3
    SaveBtn.Text             = "✓  TERSIMPAN!"
    SaveBtn.BackgroundColor3 = Color3.fromRGB(15,60,30)
    task.delay(1.2, function()
        SaveBtn.Text             = origTxt
        SaveBtn.BackgroundColor3 = origClr
    end)
    StatLbl.Text       = string.format("💾 Saved #%d  [%s]", entry.index, entry.source)
    StatLbl.TextColor3 = GR
    task.delay(2, updateStat)
end

-- ── HEARTBEAT: live coord + auto-idle ──
local lastPos = nil
RunService.Heartbeat:Connect(function()
    local hrp = getHRP()
    if not hrp then
        CoordX.Text = "X: –"; CoordY.Text = "Y: –"; CoordZ.Text = "Z: –"
        return
    end
    local pos = hrp.Position
    CoordX.Text = string.format("X:  %.3f", pos.X)
    CoordY.Text = string.format("Y:  %.3f", pos.Y)
    CoordZ.Text = string.format("Z:  %.3f", pos.Z)

    if lastPos and (pos - lastPos).Magnitude > 0.1 then
        lastMovTime = tick(); idleSaved = false
    end
    lastPos = pos

    if autoSave and not idleSaved then
        local idle = tick() - lastMovTime
        if idle >= idleThresh then
            local farEnough = true
            if lastAutoPos then
                farEnough = (pos - lastAutoPos).Magnitude >= MIN_DIST
            end
            if farEnough then
                lastAutoPos = pos; idleSaved = true
                saveCoord("IDLE")
            end
        end
    end
end)

-- ── HANDLERS ──
SaveBtn.MouseButton1Click:Connect(function() saveCoord("MANUAL") end)

AutoToggle.MouseButton1Click:Connect(function()
    autoSave = not autoSave
    AutoToggle.Text             = autoSave and "ON"  or "OFF"
    AutoToggle.BackgroundColor3 = autoSave and AC    or Color3.fromRGB(60,20,20)
    IdleLbl.Text       = autoSave
        and ("⏱  Diam selama: "..idleThresh.." dtk")
        or  "⏱  Auto-save: NONAKTIF"
    IdleLbl.TextColor3 = autoSave and G1 or RD
end)

ClearBtn.MouseButton1Click:Connect(function()
    savedCoords = {}
    for _, c in ipairs(LogScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    lastAutoPos = nil; idleSaved = false
    updateStat()
    StatLbl.Text       = "🗑  Log dibersihkan"
    StatLbl.TextColor3 = YL
    task.delay(2, updateStat)
end)

CopyBtn.MouseButton1Click:Connect(function()
    if #savedCoords == 0 then
        StatLbl.Text       = "⚠  Tidak ada koordinat!"
        StatLbl.TextColor3 = RD
        task.delay(2, updateStat); return
    end
    local lines = {
        "-- ════════════════════════════════════",
        "-- COORD SAVER LOG  |  "..#savedCoords.." koordinat",
        "-- "..os.date("%Y-%m-%d %H:%M:%S"),
        "-- ════════════════════════════════════",
        "",
        "local savedCoordinates = {",
    }
    for _, e in ipairs(savedCoords) do
        table.insert(lines, string.format(
            '  {index=%d, x=%.3f, y=%.3f, z=%.3f, source="%s", time="%s"},',
            e.index, e.pos.X, e.pos.Y, e.pos.Z, e.source, e.time
        ))
    end
    table.insert(lines, "}")
    local export = table.concat(lines, "\n")
    pcall(function() setclipboard(export) end)
    pcall(function() toclipboard(export) end)

    CopyBtn.Text             = "✓  TERSALIN!"
    CopyBtn.BackgroundColor3 = Color3.fromRGB(15,70,20)
    StatLbl.Text             = string.format("📋  %d koordinat disalin!", #savedCoords)
    StatLbl.TextColor3       = GR
    task.delay(2, function()
        CopyBtn.Text             = "📋  COPY LOG"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(12,40,20)
        updateStat()
    end)
end)

UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F8 then
        F.Visible = not F.Visible
    end
end)

print("Coord Saver Pro | By Alfian | F8 toggle")
