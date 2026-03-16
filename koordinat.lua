--[[
  COORDINATE SAVER PRO
  BY ALFIAN
  Real-time coords + Save + Auto-idle + Log + Copy
]]

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player     = Players.LocalPlayer

pcall(function()
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name == "CoordSaverAlfian" then g:Destroy() end
    end
end)

-- ══════════════════════════════
-- STATE
-- ══════════════════════════════
local savedCoords = {}
local autoSaveOn  = true
local IDLE_SEC    = 2.5
local MIN_DIST    = 2.0
local lastMovTime = tick()
local lastPos     = nil
local lastAutoPos = nil
local idleSaved   = false

local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function fmtPos(p)
    return string.format("%.2f, %.2f, %.2f", p.X, p.Y, p.Z)
end

-- ══════════════════════════════
-- WARNA
-- ══════════════════════════════
local BK  = Color3.fromRGB(8,   8,   12)
local DK  = Color3.fromRGB(14,  14,  20)
local CD  = Color3.fromRGB(22,  22,  32)
local BD  = Color3.fromRGB(45,  45,  65)
local W1  = Color3.fromRGB(220, 220, 230)
local G1  = Color3.fromRGB(90,  90,  110)
local GR  = Color3.fromRGB(60,  220, 120)
local RD  = Color3.fromRGB(210, 70,  70)
local YL  = Color3.fromRGB(220, 190, 60)
local CY  = Color3.fromRGB(80,  210, 255)
local AC  = Color3.fromRGB(120, 100, 255)
local PK  = Color3.fromRGB(255, 100, 180)

local function uic(p, r)
    local u = Instance.new("UICorner", p)
    u.CornerRadius = UDim.new(0, r or 7)
end
local function usk(p, c, t)
    local s = Instance.new("UIStroke", p)
    s.Color = c or BD; s.Thickness = t or 1
    return s
end
local function mkLbl(par, txt, sz, col, font, xa)
    local l = Instance.new("TextLabel", par)
    l.BackgroundTransparency = 1
    l.Text = txt; l.TextColor3 = col or W1
    l.Font = font or Enum.Font.Gotham
    l.TextSize = sz or 10; l.ZIndex = 14
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    return l
end

-- ══════════════════════════════
-- SCREEN GUI
-- ══════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name = "CoordSaverAlfian"; sg.ResetOnSpawn = false
sg.DisplayOrder = 9999; sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = player.PlayerGui

-- MAIN FRAME
local F = Instance.new("Frame", sg)
F.Size = UDim2.new(0, 258, 0, 488)
F.Position = UDim2.new(0, 20, 0, 80)
F.BackgroundColor3 = BK; F.BorderSizePixel = 0
F.Active = true; F.Draggable = true; F.ZIndex = 10
uic(F, 10); usk(F, BD, 1)

-- top accent
local TAc = Instance.new("Frame", F)
TAc.Size = UDim2.new(1,-4,0,1); TAc.Position = UDim2.new(0,2,0,0)
TAc.BackgroundColor3 = Color3.fromRGB(120,100,255); TAc.BorderSizePixel=0; TAc.ZIndex=15
uic(TAc,1)

-- ── TOPBAR ──
local TB = Instance.new("Frame", F)
TB.Size = UDim2.new(1,0,0,38); TB.BackgroundColor3 = DK
TB.BorderSizePixel=0; TB.ZIndex=11
uic(TB,10)
local TBFix = Instance.new("Frame",TB)
TBFix.Size=UDim2.new(1,0,0,10); TBFix.Position=UDim2.new(0,0,1,-10)
TBFix.BackgroundColor3=DK; TBFix.BorderSizePixel=0; TBFix.ZIndex=11
local TBBot = Instance.new("Frame",TB)
TBBot.Size=UDim2.new(1,0,0,1); TBBot.Position=UDim2.new(0,0,1,-1)
TBBot.BackgroundColor3=BD; TBBot.BorderSizePixel=0; TBBot.ZIndex=12

-- live dot (blink)
local Dot = Instance.new("Frame", TB)
Dot.Size=UDim2.new(0,6,0,6); Dot.Position=UDim2.new(0,11,0.5,-3)
Dot.BackgroundColor3=GR; Dot.BorderSizePixel=0; Dot.ZIndex=13
uic(Dot,6)
local dotTween = game:GetService("TweenService")
task.spawn(function()
    while sg and sg.Parent do
        dotTween:Create(Dot,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
            {BackgroundTransparency=0.7}):Play()
        task.wait(1)
        dotTween:Create(Dot,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
            {BackgroundTransparency=0}):Play()
        task.wait(1)
    end
end)

local TTitle = mkLbl(TB,"COORD SAVER PRO",11,W1,Enum.Font.GothamBold)
TTitle.Size=UDim2.new(1,-80,0,16); TTitle.Position=UDim2.new(0,22,0,6); TTitle.ZIndex=13

local TBy = mkLbl(TB,"BY ALFIAN",8,G1,Enum.Font.GothamBold)
TBy.Size=UDim2.new(1,-80,0,12); TBy.Position=UDim2.new(0,22,0,22); TBy.ZIndex=13

local XB = Instance.new("TextButton",TB)
XB.Size=UDim2.new(0,22,0,22); XB.Position=UDim2.new(1,-28,0.5,-11)
XB.BackgroundColor3=CD; XB.Text="✕"; XB.TextColor3=G1
XB.Font=Enum.Font.GothamBold; XB.TextSize=9; XB.BorderSizePixel=0; XB.ZIndex=14
uic(XB,5); usk(XB,BD,1)
XB.MouseEnter:Connect(function() XB.TextColor3=W1 end)
XB.MouseLeave:Connect(function() XB.TextColor3=G1 end)
XB.MouseButton1Click:Connect(function()
    dotTween:Create(F,TweenInfo.new(0.18,Enum.EasingStyle.Quart),
        {Size=UDim2.new(0,258,0,0),BackgroundTransparency=1}):Play()
    task.delay(0.2,function() sg:Destroy() end)
end)

-- ── BODY (UIListLayout) ──
local Body = Instance.new("Frame",F)
Body.Size=UDim2.new(1,-20,1,-50); Body.Position=UDim2.new(0,10,0,44)
Body.BackgroundTransparency=1; Body.ZIndex=11
local BL = Instance.new("UIListLayout",Body)
BL.SortOrder=Enum.SortOrder.LayoutOrder; BL.Padding=UDim.new(0,7)

-- ── KOORDINAT LIVE CARD ──
local CoordCard = Instance.new("Frame",Body)
CoordCard.LayoutOrder=1; CoordCard.Size=UDim2.new(1,0,0,72)
CoordCard.BackgroundColor3=CD; CoordCard.BorderSizePixel=0; CoordCard.ZIndex=12
uic(CoordCard,8); usk(CoordCard,BD,1)

local CHdr = mkLbl(CoordCard,"📍  KOORDINAT SEKARANG",8,G1,Enum.Font.GothamBold)
CHdr.Size=UDim2.new(1,-10,0,12); CHdr.Position=UDim2.new(0,8,0,5); CHdr.ZIndex=13

local CX = mkLbl(CoordCard,"X :  –",10,CY,Enum.Font.Code)
CX.Size=UDim2.new(1,-10,0,14); CX.Position=UDim2.new(0,8,0,19); CX.ZIndex=13

local CY2 = mkLbl(CoordCard,"Y :  –",10,PK,Enum.Font.Code)
CY2.Size=UDim2.new(1,-10,0,14); CY2.Position=UDim2.new(0,8,0,34); CY2.ZIndex=13

local CZ = mkLbl(CoordCard,"Z :  –",10,YL,Enum.Font.Code)
CZ.Size=UDim2.new(1,-10,0,14); CZ.Position=UDim2.new(0,8,0,49); CZ.ZIndex=13

-- ── SAVE BUTTON ──
local SaveBtn = Instance.new("TextButton",Body)
SaveBtn.LayoutOrder=2; SaveBtn.Size=UDim2.new(1,0,0,38)
SaveBtn.BackgroundColor3=Color3.fromRGB(20,70,35)
SaveBtn.Text="💾  SAVE KOORDINAT"; SaveBtn.TextColor3=GR
SaveBtn.Font=Enum.Font.GothamBold; SaveBtn.TextSize=12
SaveBtn.BorderSizePixel=0; SaveBtn.ZIndex=12
uic(SaveBtn,8); usk(SaveBtn,Color3.fromRGB(40,150,70),1)

-- ── AUTO-SAVE ROW ──
local ALRow = Instance.new("Frame",Body)
ALRow.LayoutOrder=3; ALRow.Size=UDim2.new(1,0,0,26)
ALRow.BackgroundColor3=CD; ALRow.BorderSizePixel=0; ALRow.ZIndex=12
uic(ALRow,6); usk(ALRow,BD,1)

local ALKey = mkLbl(ALRow,"Auto-save saat diam",10,G1,Enum.Font.Gotham)
ALKey.Size=UDim2.new(0.65,0,1,0); ALKey.Position=UDim2.new(0,8,0,0); ALKey.ZIndex=13

local ALBtn = Instance.new("TextButton",ALRow)
ALBtn.Size=UDim2.new(0,38,0,18); ALBtn.Position=UDim2.new(1,-44,0.5,-9)
ALBtn.BackgroundColor3=AC; ALBtn.Text="ON"; ALBtn.TextColor3=W1
ALBtn.Font=Enum.Font.GothamBold; ALBtn.TextSize=9; ALBtn.BorderSizePixel=0; ALBtn.ZIndex=13
uic(ALBtn,5); usk(ALBtn,BD,1)

local IdleInfo = mkLbl(Body,"⏱  Diam "..IDLE_SEC.." detik sebelum auto-save",8,G1,Enum.Font.Gotham)
IdleInfo.LayoutOrder=4; IdleInfo.Size=UDim2.new(1,0,0,12); IdleInfo.ZIndex=12

-- ── STATUS BAR ──
local StatBar = Instance.new("Frame",Body)
StatBar.LayoutOrder=5; StatBar.Size=UDim2.new(1,0,0,26)
StatBar.BackgroundColor3=CD; StatBar.BorderSizePixel=0; StatBar.ZIndex=12
uic(StatBar,6); usk(StatBar,BD,1)

local StatLbl = mkLbl(StatBar,"● Siap — 0 koordinat",9,GR,Enum.Font.Code)
StatLbl.Size=UDim2.new(1,-10,1,0); StatLbl.Position=UDim2.new(0,8,0,0); StatLbl.ZIndex=13

-- ── LOG SECTION LABEL ──
local LogSecLbl = mkLbl(Body,"LOG KOORDINAT",7,BD,Enum.Font.GothamBold)
LogSecLbl.LayoutOrder=6; LogSecLbl.Size=UDim2.new(1,0,0,12); LogSecLbl.ZIndex=12

-- ── LOG SCROLL ──
local LogScroll = Instance.new("ScrollingFrame",Body)
LogScroll.LayoutOrder=7; LogScroll.Size=UDim2.new(1,0,0,160)
LogScroll.BackgroundColor3=DK; LogScroll.BorderSizePixel=0; LogScroll.ZIndex=12
LogScroll.ScrollBarThickness=2; LogScroll.ScrollBarImageColor3=BD
LogScroll.CanvasSize=UDim2.new(0,0,0,0)
LogScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
uic(LogScroll,6); usk(LogScroll,BD,1)

local LogLayout = Instance.new("UIListLayout",LogScroll)
LogLayout.SortOrder=Enum.SortOrder.LayoutOrder; LogLayout.Padding=UDim.new(0,2)
local LogPad = Instance.new("UIPadding",LogScroll)
LogPad.PaddingTop=UDim.new(0,4); LogPad.PaddingLeft=UDim.new(0,4)
LogPad.PaddingRight=UDim.new(0,4); LogPad.PaddingBottom=UDim.new(0,4)

-- ── CLEAR + COPY ──
local BtnRow = Instance.new("Frame",Body)
BtnRow.LayoutOrder=8; BtnRow.Size=UDim2.new(1,0,0,28)
BtnRow.BackgroundTransparency=1; BtnRow.ZIndex=12
local BRL = Instance.new("UIListLayout",BtnRow)
BRL.FillDirection=Enum.FillDirection.Horizontal
BRL.Padding=UDim.new(0,6); BRL.SortOrder=Enum.SortOrder.LayoutOrder

local ClearBtn = Instance.new("TextButton",BtnRow)
ClearBtn.LayoutOrder=1; ClearBtn.Size=UDim2.new(0.38,0,1,0)
ClearBtn.BackgroundColor3=Color3.fromRGB(50,12,12)
ClearBtn.Text="🗑  CLEAR"; ClearBtn.TextColor3=RD
ClearBtn.Font=Enum.Font.GothamBold; ClearBtn.TextSize=10
ClearBtn.BorderSizePixel=0; ClearBtn.ZIndex=12
uic(ClearBtn,6); usk(ClearBtn,BD,1)

local CopyBtn = Instance.new("TextButton",BtnRow)
CopyBtn.LayoutOrder=2; CopyBtn.Size=UDim2.new(0.62,-6,1,0)
CopyBtn.BackgroundColor3=Color3.fromRGB(12,38,18)
CopyBtn.Text="📋  COPY LOG"; CopyBtn.TextColor3=GR
CopyBtn.Font=Enum.Font.GothamBold; CopyBtn.TextSize=10
CopyBtn.BorderSizePixel=0; CopyBtn.ZIndex=12
uic(CopyBtn,6); usk(CopyBtn,BD,1)

-- ══════════════════════════════
-- LOGIC
-- ══════════════════════════════
local function updateStat()
    StatLbl.Text = string.format("● %d koordinat tersimpan", #savedCoords)
    StatLbl.TextColor3 = #savedCoords > 0 and GR or G1
end

local function pushRow(entry)
    local srcClr = entry.source == "MANUAL" and GR or YL
    local srcIco = entry.source == "MANUAL" and "💾" or "⏱"

    local row = Instance.new("Frame",LogScroll)
    row.LayoutOrder=entry.index; row.Size=UDim2.new(1,0,0,38)
    row.BackgroundColor3=CD; row.BorderSizePixel=0; row.ZIndex=13
    uic(row,5); usk(row,BD,1)

    -- left accent bar
    local accent = Instance.new("Frame",row)
    accent.Size=UDim2.new(0,2,1,-4); accent.Position=UDim2.new(0,0,0,2)
    accent.BackgroundColor3=srcClr; accent.BorderSizePixel=0; accent.ZIndex=14
    uic(accent,2)

    -- badge
    local badge = mkLbl(row,"#"..entry.index,8,srcClr,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
    badge.Size=UDim2.new(0,18,0,14); badge.Position=UDim2.new(0,6,0,4); badge.ZIndex=14

    -- icon
    local ico = mkLbl(row,srcIco,11,srcClr,Enum.Font.Gotham,Enum.TextXAlignment.Center)
    ico.Size=UDim2.new(0,14,0,14); ico.Position=UDim2.new(0,6,0,20); ico.ZIndex=14

    -- coord
    local p = entry.pos
    local ctxt = mkLbl(row,
        string.format("X:%.1f  Y:%.1f  Z:%.1f", p.X, p.Y, p.Z),
        9, W1, Enum.Font.Code)
    ctxt.Size=UDim2.new(1,-52,0,14); ctxt.Position=UDim2.new(0,28,0,4); ctxt.ZIndex=14

    -- time
    local tl = mkLbl(row, entry.time, 8, G1, Enum.Font.Gotham)
    tl.Size=UDim2.new(1,-52,0,12); tl.Position=UDim2.new(0,28,0,21); tl.ZIndex=14

    -- source tag
    local sl = mkLbl(row, entry.source, 7, srcClr, Enum.Font.GothamBold)
    sl.Size=UDim2.new(0,40,0,10); sl.Position=UDim2.new(1,-44,0,4); sl.ZIndex=14

    -- scroll to bottom
    task.defer(function()
        LogScroll.CanvasPosition = Vector2.new(0, 99999)
    end)
end

local function saveCoord(source)
    local hrp = getHRP()
    if not hrp then
        StatLbl.Text="⚠ Karakter belum spawn!"; StatLbl.TextColor3=RD; return
    end
    local pos = hrp.Position

    -- cegah duplikat
    if #savedCoords > 0 then
        if (pos - savedCoords[#savedCoords].pos).Magnitude < 0.5 then return end
    end

    local entry = {
        index  = #savedCoords + 1,
        pos    = pos,
        source = source or "MANUAL",
        time   = os.date("%H:%M:%S"),
    }
    table.insert(savedCoords, entry)
    pushRow(entry)
    updateStat()

    -- flash save button
    if source == "MANUAL" then
        local orig = SaveBtn.Text
        SaveBtn.Text="✓  TERSIMPAN!"; SaveBtn.BackgroundColor3=Color3.fromRGB(15,55,25)
        task.delay(1.2, function()
            SaveBtn.Text="💾  SAVE KOORDINAT"; SaveBtn.BackgroundColor3=Color3.fromRGB(20,70,35)
        end)
    end

    -- status flash
    StatLbl.Text=string.format("💾 Saved #%d [%s]", entry.index, source)
    StatLbl.TextColor3=GR
    task.delay(2, updateStat)
end

-- ══════════════════════════════
-- REAL-TIME UPDATE
-- ══════════════════════════════
RunService.Heartbeat:Connect(function()
    local hrp = getHRP()
    if not hrp then
        CX.Text="X :  –"; CY2.Text="Y :  –"; CZ.Text="Z :  –"; return
    end
    local pos = hrp.Position
    CX.Text  = string.format("X :  %.3f", pos.X)
    CY2.Text = string.format("Y :  %.3f", pos.Y)
    CZ.Text  = string.format("Z :  %.3f", pos.Z)

    -- deteksi gerak
    if lastPos then
        if (pos - lastPos).Magnitude > 0.1 then
            lastMovTime = tick(); idleSaved = false
        end
    end
    lastPos = pos

    -- auto-save saat diam
    if autoSaveOn and not idleSaved then
        if tick() - lastMovTime >= IDLE_SEC then
            local far = true
            if lastAutoPos then
                far = (pos - lastAutoPos).Magnitude >= MIN_DIST
            end
            if far then
                lastAutoPos = pos; idleSaved = true
                saveCoord("IDLE")
            end
        end
    end
end)

-- ══════════════════════════════
-- BUTTON HANDLERS
-- ══════════════════════════════
SaveBtn.MouseButton1Click:Connect(function()
    saveCoord("MANUAL")
end)

ALBtn.MouseButton1Click:Connect(function()
    autoSaveOn = not autoSaveOn
    ALBtn.Text = autoSaveOn and "ON" or "OFF"
    ALBtn.BackgroundColor3 = autoSaveOn and AC or Color3.fromRGB(55,15,15)
    ALBtn.TextColor3 = autoSaveOn and W1 or RD
    IdleInfo.Text = autoSaveOn
        and ("⏱  Diam "..IDLE_SEC.." detik sebelum auto-save")
        or  "⏱  Auto-save: NONAKTIF"
    IdleInfo.TextColor3 = autoSaveOn and G1 or RD
end)

ClearBtn.MouseButton1Click:Connect(function()
    savedCoords = {}
    for _, c in ipairs(LogScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    lastAutoPos = nil; idleSaved = false
    updateStat()
    StatLbl.Text="🗑 Log dibersihkan"; StatLbl.TextColor3=YL
    task.delay(2, updateStat)
end)

CopyBtn.MouseButton1Click:Connect(function()
    if #savedCoords == 0 then
        StatLbl.Text="⚠ Tidak ada koordinat!"; StatLbl.TextColor3=RD
        task.delay(2, updateStat); return
    end

    local lines = {
        "-- ════════════════════════════════",
        "-- COORD SAVER PRO  |  "..#savedCoords.." titik",
        "-- "..os.date("%Y-%m-%d %H:%M:%S"),
        "-- ════════════════════════════════",
        "",
        "local koordinat = {",
    }
    for _, e in ipairs(savedCoords) do
        table.insert(lines, string.format(
            '  {index=%d, x=%.3f, y=%.3f, z=%.3f, source="%s", time="%s"},',
            e.index, e.pos.X, e.pos.Y, e.pos.Z, e.source, e.time
        ))
    end
    table.insert(lines, "}")
    table.insert(lines, "")
    table.insert(lines, "-- Cara pakai:")
    table.insert(lines, "-- for _, k in ipairs(koordinat) do")
    table.insert(lines, "--   hrp.CFrame = CFrame.new(k.x, k.y+5, k.z)")
    table.insert(lines, "--   task.wait(0.3)")
    table.insert(lines, "-- end")

    local out = table.concat(lines, "\n")
    local ok = pcall(function() setclipboard(out) end)
    if not ok then pcall(function() toclipboard(out) end) end

    CopyBtn.Text="✓  TERSALIN!"; CopyBtn.BackgroundColor3=Color3.fromRGB(10,55,20)
    StatLbl.Text=string.format("📋 %d koordinat disalin ke clipboard!", #savedCoords)
    StatLbl.TextColor3=GR
    task.delay(2, function()
        CopyBtn.Text="📋  COPY LOG"; CopyBtn.BackgroundColor3=Color3.fromRGB(12,38,18)
        updateStat()
    end)
end)

UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F8 then F.Visible = not F.Visible end
end)

print("Coord Saver Pro | By Alfian | F8 toggle")
