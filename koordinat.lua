--[[
  ╔══════════════════════════════════╗
  ║     COORDINATE SAVER PRO         ║
  ║  Save, log, dan copy koordinat   ║
  ╚══════════════════════════════════╝
  
  FITUR:
  - Koordinat selalu tampil real-time
  - Tombol SAVE KOORDINAT manual
  - Auto-save saat karakter diam (opsional)
  - Log semua koordinat tersimpan
  - Clear log & Copy log ke clipboard
]]

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player     = Players.LocalPlayer

-- Hapus GUI lama jika ada
pcall(function()
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name == "CoordSaverPro" then g:Destroy() end
    end
end)

-- ══════════════════════════════════════
-- STATE
-- ══════════════════════════════════════
local savedCoords  = {}           -- tabel log koordinat
local autoSave     = true         -- toggle auto-save saat diam
local idleThresh   = 2.5          -- detik diam sebelum auto-save
local lastMovTime  = tick()       -- waktu terakhir karakter bergerak
local lastAutoPos  = nil          -- posisi saat auto-save terakhir (hindari duplikat)
local MIN_DIST     = 2.0          -- jarak minimum antar auto-save agar tidak duplikat
local idleSaved    = false        -- sudah disave saat idle ini?

-- ══════════════════════════════════════
-- HELPER
-- ══════════════════════════════════════
local function fmtPos(v3)
    if not v3 then return "nil" end
    return string.format("%.2f, %.2f, %.2f", v3.X, v3.Y, v3.Z)
end

local function getHRP()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function addCoord(pos, source)
    -- source: "MANUAL" | "IDLE" | "AUTO"
    local entry = {
        index  = #savedCoords + 1,
        pos    = pos,
        posStr = fmtPos(pos),
        source = source or "MANUAL",
        time   = os.date("%H:%M:%S"),
    }
    table.insert(savedCoords, entry)
    return entry
end

-- ══════════════════════════════════════
-- WARNA
-- ══════════════════════════════════════
local BK  = Color3.fromRGB(7,  7,  10)
local DK  = Color3.fromRGB(14, 14, 20)
local CD  = Color3.fromRGB(22, 22, 32)
local BD  = Color3.fromRGB(45, 45, 65)
local W1  = Color3.fromRGB(220,220,230)
local G1  = Color3.fromRGB(90, 90,110)
local GR  = Color3.fromRGB(60, 220,120)
local RD  = Color3.fromRGB(210,70, 70)
local YL  = Color3.fromRGB(220,190,60)
local CY  = Color3.fromRGB(80, 210,255)
local AC  = Color3.fromRGB(120,100,255)
local PK  = Color3.fromRGB(255,100,180)

-- ══════════════════════════════════════
-- GUI SETUP
-- ══════════════════════════════════════
local function cr(p, r)
    local u = Instance.new("UICorner", p)
    u.CornerRadius = UDim.new(0, r or 7)
end
local function sk(p, c, t)
    local s = Instance.new("UIStroke", p)
    s.Color     = c or BD
    s.Thickness = t or 1
end
local function lbl(parent, txt, size, color, font, xa)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text           = txt
    l.TextColor3     = color  or W1
    l.Font           = font   or Enum.Font.Gotham
    l.TextSize       = size   or 11
    l.TextXAlignment = xa     or Enum.TextXAlignment.Left
    l.ZIndex         = 12
    return l
end

local sg = Instance.new("ScreenGui")
sg.Name           = "CoordSaverPro"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 9999
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = player.PlayerGui

-- MAIN FRAME
local F = Instance.new("Frame", sg)
F.Size             = UDim2.new(0, 260, 0, 480)
F.Position         = UDim2.new(0, 20, 0, 80)
F.BackgroundColor3 = BK
F.BorderSizePixel  = 0
F.Active           = true
F.Draggable        = true
F.ZIndex           = 10
cr(F, 10) sk(F, BD, 1)

-- ── TOP BAR ──
local TB = Instance.new("Frame", F)
TB.Size             = UDim2.new(1,0,0,36)
TB.BackgroundColor3 = DK
TB.BorderSizePixel  = 0
TB.ZIndex           = 11
cr(TB, 10)
-- rounded bottom fix
local TBF = Instance.new("Frame", TB)
TBF.Size             = UDim2.new(1,0,0,10)
TBF.Position         = UDim2.new(0,0,1,-10)
TBF.BackgroundColor3 = DK
TBF.BorderSizePixel  = 0
TBF.ZIndex           = 11

-- Dot indicator (selalu hijau = selalu nyala)
local Dot = Instance.new("Frame", TB)
Dot.Size             = UDim2.new(0,7,0,7)
Dot.Position         = UDim2.new(0,11,0.5,-3)
Dot.BackgroundColor3 = GR
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 13
cr(Dot, 7)

local TLbl = lbl(TB, "COORD SAVER", 12, W1, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
TLbl.Size     = UDim2.new(1,-50,1,0)
TLbl.Position = UDim2.new(0,24,0,0)
TLbl.ZIndex   = 12

local XB = Instance.new("TextButton", TB)
XB.Size             = UDim2.new(0,22,0,22)
XB.Position         = UDim2.new(1,-27,0.5,-11)
XB.Text             = "✕"
XB.TextColor3       = G1
XB.BackgroundColor3 = CD
XB.Font             = Enum.Font.GothamBold
XB.TextSize         = 10
XB.BorderSizePixel  = 0
XB.ZIndex           = 13
cr(XB, 5)
XB.MouseButton1Click:Connect(function() sg:Destroy() end)

-- ── KOORDINAT LIVE DISPLAY ──
local CoordBox = Instance.new("Frame", F)
CoordBox.Size             = UDim2.new(1,-20,0,62)
CoordBox.Position         = UDim2.new(0,10,0,44)
CoordBox.BackgroundColor3 = CD
CoordBox.BorderSizePixel  = 0
CoordBox.ZIndex           = 11
cr(CoordBox, 8) sk(CoordBox, BD, 1)

local CoordHdr = lbl(CoordBox, "📍 KOORDINAT SEKARANG", 8, G1, Enum.Font.GothamBold)
CoordHdr.Size     = UDim2.new(1,-10,0,12)
CoordHdr.Position = UDim2.new(0,8,0,6)
CoordHdr.ZIndex   = 12

local CoordX = lbl(CoordBox, "X: –", 10, CY, Enum.Font.Code)
CoordX.Size     = UDim2.new(1,-10,0,13)
CoordX.Position = UDim2.new(0,8,0,20)
CoordX.ZIndex   = 12

local CoordY = lbl(CoordBox, "Y: –", 10, PK, Enum.Font.Code)
CoordY.Size     = UDim2.new(1,-10,0,13)
CoordY.Position = UDim2.new(0,8,0,33)
CoordY.ZIndex   = 12

local CoordZ = lbl(CoordBox, "Z: –", 10, YL, Enum.Font.Code)
CoordZ.Size     = UDim2.new(1,-10,0,13)
CoordZ.Position = UDim2.new(0,8,0,46)
CoordZ.ZIndex   = 12

-- ── SAVE BUTTON ──
local SaveBtn = Instance.new("TextButton", F)
SaveBtn.Size             = UDim2.new(1,-20,0,36)
SaveBtn.Position         = UDim2.new(0,10,0,114)
SaveBtn.BackgroundColor3 = Color3.fromRGB(30,100,50)
SaveBtn.Text             = "💾  SAVE KOORDINAT"
SaveBtn.TextColor3       = GR
SaveBtn.Font             = Enum.Font.GothamBold
SaveBtn.TextSize         = 13
SaveBtn.BorderSizePixel  = 0
SaveBtn.ZIndex           = 11
cr(SaveBtn, 8) sk(SaveBtn, Color3.fromRGB(50,180,90), 1)

-- ── AUTO-SAVE TOGGLE ──
local AutoRow = Instance.new("Frame", F)
AutoRow.Size             = UDim2.new(1,-20,0,26)
AutoRow.Position         = UDim2.new(0,10,0,158)
AutoRow.BackgroundColor3 = CD
AutoRow.BorderSizePixel  = 0
AutoRow.ZIndex           = 11
cr(AutoRow, 6) sk(AutoRow, BD, 1)

local AutoLbl = lbl(AutoRow, "Auto-save saat diam", 10, G1, Enum.Font.Gotham)
AutoLbl.Size     = UDim2.new(1,-50,1,0)
AutoLbl.Position = UDim2.new(0,8,0,0)
AutoLbl.ZIndex   = 12

local AutoToggle = Instance.new("TextButton", AutoRow)
AutoToggle.Size             = UDim2.new(0,38,0,18)
AutoToggle.Position         = UDim2.new(1,-44,0.5,-9)
AutoToggle.BackgroundColor3 = AC
AutoToggle.Text             = "ON"
AutoToggle.TextColor3       = W1
AutoToggle.Font             = Enum.Font.GothamBold
AutoToggle.TextSize         = 9
AutoToggle.BorderSizePixel  = 0
AutoToggle.ZIndex           = 12
cr(AutoToggle, 5)

-- Idle threshold label
local IdleLbl = lbl(F, "⏱ Diam selama: 2.5 dtk", 9, G1, Enum.Font.Gotham)
IdleLbl.Size     = UDim2.new(1,-20,0,14)
IdleLbl.Position = UDim2.new(0,10,0,190)
IdleLbl.ZIndex   = 11

-- ── STATUS BAR ──
local StatBox = Instance.new("Frame", F)
StatBox.Size             = UDim2.new(1,-20,0,28)
StatBox.Position         = UDim2.new(0,10,0,208)
StatBox.BackgroundColor3 = CD
StatBox.BorderSizePixel  = 0
StatBox.ZIndex           = 11
cr(StatBox, 6) sk(StatBox, BD, 1)

local StatLbl = lbl(StatBox, "● Siap — 0 koordinat tersimpan", 9, GR, Enum.Font.Code)
StatLbl.Size     = UDim2.new(1,-10,1,0)
StatLbl.Position = UDim2.new(0,8,0,0)
StatLbl.ZIndex   = 12

-- ── LOG HEADER ──
local LogHdr = lbl(F, "LOG KOORDINAT", 8, Color3.fromRGB(50,50,70), Enum.Font.GothamBold)
LogHdr.Size     = UDim2.new(1,-20,0,14)
LogHdr.Position = UDim2.new(0,10,0,242)
LogHdr.ZIndex   = 11

-- ── LOG SCROLL ──
local LogScroll = Instance.new("ScrollingFrame", F)
LogScroll.Size                  = UDim2.new(1,-20,0,152)
LogScroll.Position              = UDim2.new(0,10,0,258)
LogScroll.BackgroundColor3      = DK
LogScroll.BorderSizePixel       = 0
LogScroll.ScrollBarThickness    = 2
LogScroll.ScrollBarImageColor3  = BD
LogScroll.CanvasSize            = UDim2.new(0,0,0,0)
LogScroll.ZIndex                = 11
cr(LogScroll, 6) sk(LogScroll, BD, 1)

local LogLayout = Instance.new("UIListLayout", LogScroll)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding   = UDim.new(0,1)
local LogPad = Instance.new("UIPadding", LogScroll)
LogPad.PaddingTop    = UDim.new(0,4)
LogPad.PaddingLeft   = UDim.new(0,4)
LogPad.PaddingRight  = UDim.new(0,4)
LogPad.PaddingBottom = UDim.new(0,4)

LogLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    LogScroll.CanvasSize = UDim2.new(0,0,0,LogLayout.AbsoluteContentSize.Y+8)
end)

-- ── CLEAR + COPY BUTTONS ──
local function mkBtn(xPct, w, txt, col, textCol)
    local b = Instance.new("TextButton", F)
    b.Size              = UDim2.new(w, -6, 0, 26)
    b.Position          = UDim2.new(xPct, 3, 0, 416)
    b.BackgroundColor3  = col or CD
    b.Text              = txt
    b.TextColor3        = textCol or W1
    b.Font              = Enum.Font.GothamBold
    b.TextSize          = 10
    b.BorderSizePixel   = 0
    b.ZIndex            = 11
    cr(b, 6) sk(b, BD, 1)
    return b
end

local ClearBtn = mkBtn(0,    0.34, "🗑  CLEAR",    Color3.fromRGB(55,15,15), RD)
local CopyBtn  = mkBtn(0.34, 0.66, "📋  COPY LOG", Color3.fromRGB(15,40,20), GR)

-- ══════════════════════════════════════
-- LOGIC: PUSH LOG ROW
-- ══════════════════════════════════════
local SOURCE_COLOR = {
    MANUAL = GR,
    IDLE   = YL,
}

local function pushLogRow(entry)
    local srcClr = SOURCE_COLOR[entry.source] or CY
    local srcTag = entry.source == "IDLE" and "⏱" or "💾"

    local row = Instance.new("Frame", LogScroll)
    row.LayoutOrder         = entry.index
    row.Size                = UDim2.new(1,0,0,36)
    row.BackgroundColor3    = CD
    row.BorderSizePixel     = 0
    row.ZIndex              = 12
    cr(row, 4)

    -- index badge
    local badge = lbl(row, "#"..entry.index, 8, srcClr, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    badge.Size     = UDim2.new(0,20,0,20)
    badge.Position = UDim2.new(0,4,0,8)
    badge.ZIndex   = 13

    -- source tag
    local stag = lbl(row, srcTag, 11, srcClr, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    stag.Size     = UDim2.new(0,16,0,16)
    stag.Position = UDim2.new(0,26,0,10)
    stag.ZIndex   = 13

    -- coordinates text
    local pos = entry.pos
    local coordTxt = string.format("X:%.1f  Y:%.1f  Z:%.1f", pos.X, pos.Y, pos.Z)
    local ctxt = lbl(row, coordTxt, 9, W1, Enum.Font.Code)
    ctxt.Size     = UDim2.new(1,-50,0,14)
    ctxt.Position = UDim2.new(0,46,0,4)
    ctxt.ZIndex   = 13

    -- time label
    local tlbl2 = lbl(row, entry.time, 8, G1, Enum.Font.Gotham)
    tlbl2.Size     = UDim2.new(1,-50,0,12)
    tlbl2.Position = UDim2.new(0,46,0,20)
    tlbl2.ZIndex   = 13

    task.defer(function()
        LogScroll.CanvasPosition = Vector2.new(0, LogLayout.AbsoluteContentSize.Y)
    end)
end

-- ══════════════════════════════════════
-- LOGIC: UPDATE STATUS
-- ══════════════════════════════════════
local function updateStat()
    StatLbl.Text = string.format("● %d koordinat tersimpan", #savedCoords)
    StatLbl.TextColor3 = #savedCoords > 0 and GR or G1
end

-- ══════════════════════════════════════
-- LOGIC: SAVE COORDINATE
-- ══════════════════════════════════════
local function saveCoord(source)
    local hrp = getHRP()
    if not hrp then
        StatLbl.Text      = "⚠ Karakter belum spawn!"
        StatLbl.TextColor3 = RD
        return
    end
    local pos = hrp.Position

    -- cegah duplikat: jika posisi sangat dekat dengan save terakhir
    if #savedCoords > 0 then
        local last = savedCoords[#savedCoords]
        if (pos - last.pos).Magnitude < 0.5 then return end
    end

    local entry = addCoord(pos, source)
    pushLogRow(entry)
    updateStat()

    -- Flash save button
    local origTxt = SaveBtn.Text
    local origClr = SaveBtn.BackgroundColor3
    SaveBtn.Text             = "✓  TERSIMPAN!"
    SaveBtn.BackgroundColor3 = Color3.fromRGB(20,80,40)
    task.delay(1.2, function()
        SaveBtn.Text             = origTxt
        SaveBtn.BackgroundColor3 = origClr
    end)

    -- status flash
    StatLbl.Text       = string.format("💾 Saved #%d dari %s", entry.index, entry.source)
    StatLbl.TextColor3 = GR
    task.delay(2, updateStat)
end

-- ══════════════════════════════════════
-- LOGIC: REAL-TIME COORD UPDATE
-- ══════════════════════════════════════
local lastPos    = nil
local idleTimer  = 0

RunService.Heartbeat:Connect(function(dt)
    local hrp = getHRP()
    if not hrp then
        CoordX.Text = "X: –"
        CoordY.Text = "Y: –"
        CoordZ.Text = "Z: –"
        return
    end

    local pos = hrp.Position
    CoordX.Text = string.format("X: %.3f", pos.X)
    CoordY.Text = string.format("Y: %.3f", pos.Y)
    CoordZ.Text = string.format("Z: %.3f", pos.Z)

    -- deteksi gerak untuk auto-idle
    if lastPos then
        local moved = (pos - lastPos).Magnitude
        if moved > 0.1 then
            lastMovTime = tick()
            idleSaved   = false
        end
    end
    lastPos = pos

    -- auto-save saat idle
    if autoSave and not idleSaved then
        local idleTime = tick() - lastMovTime
        if idleTime >= idleThresh then
            -- cek jarak dari auto-save terakhir
            local farEnough = true
            if lastAutoPos then
                farEnough = (pos - lastAutoPos).Magnitude >= MIN_DIST
            end
            if farEnough then
                lastAutoPos = pos
                idleSaved   = true
                saveCoord("IDLE")
            end
        end
    end
end)

-- ══════════════════════════════════════
-- BUTTON HANDLERS
-- ══════════════════════════════════════

-- SAVE MANUAL
SaveBtn.MouseButton1Click:Connect(function()
    saveCoord("MANUAL")
end)

-- AUTO TOGGLE
AutoToggle.MouseButton1Click:Connect(function()
    autoSave = not autoSave
    AutoToggle.Text             = autoSave and "ON"  or "OFF"
    AutoToggle.BackgroundColor3 = autoSave and AC    or Color3.fromRGB(60,20,20)
    IdleLbl.Text                = autoSave
        and ("⏱ Diam selama: "..idleThresh.." dtk")
        or  "⏱ Auto-save: NONAKTIF"
    IdleLbl.TextColor3          = autoSave and G1 or RD
end)

-- CLEAR
ClearBtn.MouseButton1Click:Connect(function()
    savedCoords = {}
    for _, c in ipairs(LogScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    lastAutoPos = nil
    idleSaved   = false
    updateStat()
    StatLbl.Text       = "🗑 Log dibersihkan"
    StatLbl.TextColor3 = YL
    task.delay(2, updateStat)
end)

-- COPY LOG
CopyBtn.MouseButton1Click:Connect(function()
    if #savedCoords == 0 then
        StatLbl.Text       = "⚠ Tidak ada koordinat!"
        StatLbl.TextColor3 = RD
        task.delay(2, updateStat)
        return
    end

    local lines = {}
    table.insert(lines, "-- ═══════════════════════════════════")
    table.insert(lines, "-- COORD SAVER LOG  |  "..#savedCoords.." koordinat")
    table.insert(lines, "-- "..os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "-- ═══════════════════════════════════")
    table.insert(lines, "")
    table.insert(lines, "local savedCoordinates = {")
    for _, e in ipairs(savedCoords) do
        table.insert(lines, string.format(
            '  {index=%d, x=%.3f, y=%.3f, z=%.3f, source="%s", time="%s"},',
            e.index, e.pos.X, e.pos.Y, e.pos.Z, e.source, e.time
        ))
    end
    table.insert(lines, "}")
    table.insert(lines, "")
    table.insert(lines, "-- Cara pakai di script lain:")
    table.insert(lines, "-- for _, coord in ipairs(savedCoordinates) do")
    table.insert(lines, '--   print(coord.index, coord.x, coord.y, coord.z)')
    table.insert(lines, "-- end")

    local export = table.concat(lines, "\n")

    local ok = pcall(function() setclipboard(export) end)
    if not ok then pcall(function() toclipboard(export) end) end

    CopyBtn.Text             = "✓  TERSALIN!"
    CopyBtn.BackgroundColor3 = Color3.fromRGB(15,70,20)
    StatLbl.Text             = string.format("📋 %d koordinat disalin!", #savedCoords)
    StatLbl.TextColor3       = GR
    task.delay(2, function()
        CopyBtn.Text             = "📋  COPY LOG"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(15,40,20)
        updateStat()
    end)
end)

-- F8 toggle GUI
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F8 then
        F.Visible = not F.Visible
    end
end)

print("✅ Coord Saver Pro aktif | F8 toggle | 💾 Manual | ⏱ Auto-idle")
