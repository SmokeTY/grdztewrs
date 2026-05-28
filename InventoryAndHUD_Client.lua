--[[
================================================================================
    INVENTORY & HUD CLIENT SCRIPT
    ==============================
    Handles:
    - Gold & XP display (always visible HUD)
    - Level & equipped weapon display
    - Inventory GUI (toggle with "I" key or button)
    - Loot pickup notifications
    - Equip weapons from inventory
    
    Place this LocalScript in StarterPlayerScripts.
    Works with the CombatSystem server script.
    
    Author: Script Puller Project
================================================================================
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local LootRemote = Remotes:WaitForChild("LootEvent")
local InventoryUpdateRemote = Remotes:WaitForChild("InventoryUpdateEvent")
local EquipRequestRemote = Remotes:WaitForChild("EquipRequestEvent")
local OpenInventoryRemote = Remotes:WaitForChild("OpenInventoryEvent")
local LootDropRemote = Remotes:WaitForChild("LootDropEvent")

-- ============================================================================
-- RARITY COLORS
-- ============================================================================

local RarityColors = {
    Common = Color3.fromRGB(200, 200, 200),
    Uncommon = Color3.fromRGB(30, 255, 30),
    Rare = Color3.fromRGB(50, 120, 255),
    Epic = Color3.fromRGB(163, 53, 238),
    Legendary = Color3.fromRGB(255, 165, 0),
}

-- ============================================================================
-- CREATE MAIN SCREEN GUI
-- ============================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CombatHUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- ============================================================================
-- HUD - TOP BAR (Gold, XP, Level, Weapon)
-- ============================================================================

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(0, 400, 0, 90)
TopBar.Position = UDim2.new(0.5, -200, 0, 10)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TopBar.BackgroundTransparency = 0.3
TopBar.BorderSizePixel = 0
TopBar.Parent = ScreenGui

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = TopBar

local topStroke = Instance.new("UIStroke")
topStroke.Color = Color3.fromRGB(80, 80, 120)
topStroke.Thickness = 2
topStroke.Parent = TopBar

-- Level Display
local LevelLabel = Instance.new("TextLabel")
LevelLabel.Name = "LevelLabel"
LevelLabel.Size = UDim2.new(0.5, 0, 0, 25)
LevelLabel.Position = UDim2.new(0, 10, 0, 5)
LevelLabel.BackgroundTransparency = 1
LevelLabel.Text = "Level: 1"
LevelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
LevelLabel.TextSize = 18
LevelLabel.Font = Enum.Font.GothamBold
LevelLabel.TextXAlignment = Enum.TextXAlignment.Left
LevelLabel.Parent = TopBar

-- Gold Display
local GoldLabel = Instance.new("TextLabel")
GoldLabel.Name = "GoldLabel"
GoldLabel.Size = UDim2.new(0.5, -10, 0, 25)
GoldLabel.Position = UDim2.new(0.5, 0, 0, 5)
GoldLabel.BackgroundTransparency = 1
GoldLabel.Text = "Gold: 0"
GoldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
GoldLabel.TextSize = 18
GoldLabel.Font = Enum.Font.GothamBold
GoldLabel.TextXAlignment = Enum.TextXAlignment.Right
GoldLabel.Parent = TopBar

-- XP Bar Background
local XPBarBG = Instance.new("Frame")
XPBarBG.Name = "XPBarBG"
XPBarBG.Size = UDim2.new(1, -20, 0, 16)
XPBarBG.Position = UDim2.new(0, 10, 0, 33)
XPBarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
XPBarBG.BorderSizePixel = 0
XPBarBG.Parent = TopBar

local xpBarCorner = Instance.new("UICorner")
xpBarCorner.CornerRadius = UDim.new(0, 6)
xpBarCorner.Parent = XPBarBG

-- XP Bar Fill
local XPBarFill = Instance.new("Frame")
XPBarFill.Name = "XPBarFill"
XPBarFill.Size = UDim2.new(0, 0, 1, 0)
XPBarFill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
XPBarFill.BorderSizePixel = 0
XPBarFill.Parent = XPBarBG

local xpFillCorner = Instance.new("UICorner")
xpFillCorner.CornerRadius = UDim.new(0, 6)
xpFillCorner.Parent = XPBarFill

-- XP Text overlay
local XPText = Instance.new("TextLabel")
XPText.Name = "XPText"
XPText.Size = UDim2.new(1, 0, 1, 0)
XPText.BackgroundTransparency = 1
XPText.Text = "XP: 0 / 100"
XPText.TextColor3 = Color3.fromRGB(255, 255, 255)
XPText.TextSize = 12
XPText.Font = Enum.Font.GothamBold
XPText.Parent = XPBarBG

-- Weapon Display
local WeaponLabel = Instance.new("TextLabel")
WeaponLabel.Name = "WeaponLabel"
WeaponLabel.Size = UDim2.new(1, -20, 0, 20)
WeaponLabel.Position = UDim2.new(0, 10, 0, 53)
WeaponLabel.BackgroundTransparency = 1
WeaponLabel.Text = "Weapon: Iron Sword"
WeaponLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
WeaponLabel.TextSize = 14
WeaponLabel.Font = Enum.Font.Gotham
WeaponLabel.TextXAlignment = Enum.TextXAlignment.Left
WeaponLabel.Parent = TopBar

-- Attack/Defense Display
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "StatsLabel"
StatsLabel.Size = UDim2.new(1, -20, 0, 20)
StatsLabel.Position = UDim2.new(0, 10, 0, 68)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "ATK: 10 | DEF: 5"
StatsLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
StatsLabel.TextSize = 12
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Parent = TopBar

-- ============================================================================
-- INVENTORY BUTTON (bottom right)
-- ============================================================================

local InventoryButton = Instance.new("TextButton")
InventoryButton.Name = "InventoryButton"
InventoryButton.Size = UDim2.new(0, 120, 0, 40)
InventoryButton.Position = UDim2.new(1, -130, 1, -50)
InventoryButton.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
InventoryButton.Text = "Inventory [I]"
InventoryButton.TextColor3 = Color3.fromRGB(220, 220, 255)
InventoryButton.TextSize = 14
InventoryButton.Font = Enum.Font.GothamBold
InventoryButton.BorderSizePixel = 0
InventoryButton.Parent = ScreenGui

local invBtnCorner = Instance.new("UICorner")
invBtnCorner.CornerRadius = UDim.new(0, 8)
invBtnCorner.Parent = InventoryButton

local invBtnStroke = Instance.new("UIStroke")
invBtnStroke.Color = Color3.fromRGB(100, 100, 180)
invBtnStroke.Thickness = 2
invBtnStroke.Parent = InventoryButton

-- ============================================================================
-- INVENTORY PANEL
-- ============================================================================

local InventoryFrame = Instance.new("Frame")
InventoryFrame.Name = "InventoryFrame"
InventoryFrame.Size = UDim2.new(0, 500, 0, 450)
InventoryFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
InventoryFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
InventoryFrame.BackgroundTransparency = 0.05
InventoryFrame.BorderSizePixel = 0
InventoryFrame.Visible = false
InventoryFrame.Parent = ScreenGui

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 12)
invCorner.Parent = InventoryFrame

local invStroke = Instance.new("UIStroke")
invStroke.Color = Color3.fromRGB(100, 80, 200)
invStroke.Thickness = 2
invStroke.Parent = InventoryFrame

-- Title
local InvTitle = Instance.new("TextLabel")
InvTitle.Size = UDim2.new(1, 0, 0, 40)
InvTitle.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
InvTitle.BackgroundTransparency = 0.3
InvTitle.Text = "  INVENTORY"
InvTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
InvTitle.TextSize = 20
InvTitle.Font = Enum.Font.GothamBold
InvTitle.TextXAlignment = Enum.TextXAlignment.Left
InvTitle.BorderSizePixel = 0
InvTitle.Parent = InventoryFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = InvTitle

-- Slots counter
local SlotsLabel = Instance.new("TextLabel")
SlotsLabel.Size = UDim2.new(0.4, 0, 0, 40)
SlotsLabel.Position = UDim2.new(0.6, 0, 0, 0)
SlotsLabel.BackgroundTransparency = 1
SlotsLabel.Text = "0 / 30 slots"
SlotsLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
SlotsLabel.TextSize = 14
SlotsLabel.Font = Enum.Font.Gotham
SlotsLabel.TextXAlignment = Enum.TextXAlignment.Right
SlotsLabel.Parent = InventoryFrame

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = InventoryFrame

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = CloseBtn

-- Scrolling item list
local ItemScroll = Instance.new("ScrollingFrame")
ItemScroll.Name = "ItemScroll"
ItemScroll.Size = UDim2.new(1, -20, 1, -50)
ItemScroll.Position = UDim2.new(0, 10, 0, 45)
ItemScroll.BackgroundTransparency = 1
ItemScroll.BorderSizePixel = 0
ItemScroll.ScrollBarThickness = 6
ItemScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 200)
ItemScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemScroll.Parent = InventoryFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = ItemScroll

-- ============================================================================
-- LOOT NOTIFICATION AREA (right side)
-- ============================================================================

local NotificationFrame = Instance.new("Frame")
NotificationFrame.Name = "Notifications"
NotificationFrame.Size = UDim2.new(0, 300, 0, 400)
NotificationFrame.Position = UDim2.new(1, -310, 0.3, 0)
NotificationFrame.BackgroundTransparency = 1
NotificationFrame.Parent = ScreenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 3)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Parent = NotificationFrame

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local inventoryOpen = false
local currentInventoryData = {}

--- Toggle inventory open/close
local function ToggleInventory()
    inventoryOpen = not inventoryOpen
    InventoryFrame.Visible = inventoryOpen
    
    if inventoryOpen then
        -- Request inventory data from server
        OpenInventoryRemote:FireServer()
    end
end

--- Create an inventory item row
local function CreateItemRow(itemData, index)
    local color = RarityColors[itemData.Rarity] or RarityColors.Common
    
    local row = Instance.new("Frame")
    row.Name = "Item_" .. index
    row.Size = UDim2.new(1, 0, 0, 60)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    row.LayoutOrder = index
    
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row
    
    -- Rarity indicator bar (left side)
    local rarityBar = Instance.new("Frame")
    rarityBar.Size = UDim2.new(0, 4, 1, -8)
    rarityBar.Position = UDim2.new(0, 4, 0, 4)
    rarityBar.BackgroundColor3 = color
    rarityBar.BorderSizePixel = 0
    rarityBar.Parent = row
    
    local rarityBarCorner = Instance.new("UICorner")
    rarityBarCorner.CornerRadius = UDim.new(0, 2)
    rarityBarCorner.Parent = rarityBar
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.55, 0, 0, 22)
    nameLabel.Position = UDim2.new(0, 15, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = itemData.Name
    nameLabel.TextColor3 = color
    nameLabel.TextSize = 15
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row
    
    -- Item stats
    local statsText = "DMG: " .. itemData.Damage .. " | SPD: " .. itemData.Speed .. " | " .. itemData.Rarity
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0.7, 0, 0, 16)
    statsLabel.Position = UDim2.new(0, 15, 0, 27)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = statsText
    statsLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    statsLabel.TextSize = 11
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = row
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.7, 0, 0, 14)
    descLabel.Position = UDim2.new(0, 15, 0, 43)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = itemData.Description or ""
    descLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
    descLabel.TextSize = 10
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = row
    
    -- Equip button
    local equipBtn = Instance.new("TextButton")
    equipBtn.Size = UDim2.new(0, 80, 0, 30)
    equipBtn.Position = UDim2.new(1, -90, 0.5, -15)
    equipBtn.BorderSizePixel = 0
    
    if itemData.IsEquipped then
        equipBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        equipBtn.Text = "EQUIPPED"
        equipBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
    else
        equipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
        equipBtn.Text = "EQUIP"
        equipBtn.TextColor3 = Color3.fromRGB(220, 220, 255)
    end
    
    equipBtn.TextSize = 12
    equipBtn.Font = Enum.Font.GothamBold
    equipBtn.Parent = row
    
    local eqCorner = Instance.new("UICorner")
    eqCorner.CornerRadius = UDim.new(0, 6)
    eqCorner.Parent = equipBtn
    
    -- Equip click handler
    if not itemData.IsEquipped then
        equipBtn.MouseButton1Click:Connect(function()
            EquipRequestRemote:FireServer(itemData.Id)
        end)
    end
    
    return row
end

--- Refresh the inventory display
local function RefreshInventory(data)
    -- Clear existing items
    for _, child in ipairs(ItemScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if not data or not data.Items then return end
    
    -- Update slots label
    SlotsLabel.Text = (data.UsedSlots or 0) .. " / " .. (data.MaxSlots or 30) .. " slots"
    
    -- Create rows for each item
    for i, item in ipairs(data.Items) do
        local row = CreateItemRow(item, i)
        row.Parent = ItemScroll
    end
    
    -- Update canvas size
    ItemScroll.CanvasSize = UDim2.new(0, 0, 0, (#data.Items * 65))
end

--- Show a loot notification popup
local function ShowLootNotification(itemName, rarity)
    local color = RarityColors[rarity] or RarityColors.Common
    
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 30)
    notif.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    notif.BackgroundTransparency = 0.3
    notif.BorderSizePixel = 0
    notif.Parent = NotificationFrame
    
    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = UDim.new(0, 6)
    nCorner.Parent = notif
    
    local nStroke = Instance.new("UIStroke")
    nStroke.Color = color
    nStroke.Transparency = 0.5
    nStroke.Thickness = 1
    nStroke.Parent = notif
    
    local nLabel = Instance.new("TextLabel")
    nLabel.Size = UDim2.new(1, -10, 1, 0)
    nLabel.Position = UDim2.new(0, 5, 0, 0)
    nLabel.BackgroundTransparency = 1
    nLabel.Text = itemName
    nLabel.TextColor3 = color
    nLabel.TextSize = 13
    nLabel.Font = Enum.Font.GothamBold
    nLabel.TextXAlignment = Enum.TextXAlignment.Left
    nLabel.Parent = notif
    
    -- Fade out and destroy after 4 seconds
    task.delay(3, function()
        local tween = TweenService:Create(notif, TweenInfo.new(1, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1
        })
        local textTween = TweenService:Create(nLabel, TweenInfo.new(1, Enum.EasingStyle.Quad), {
            TextTransparency = 1
        })
        tween:Play()
        textTween:Play()
        task.delay(1, function()
            notif:Destroy()
        end)
    end)
end

--- Update HUD with stats data
local function UpdateHUD(data)
    if not data then return end
    
    if data.StatsUpdate then
        -- Update gold
        GoldLabel.Text = "Gold: " .. tostring(data.Gold or 0)
        
        -- Update level
        LevelLabel.Text = "Level: " .. tostring(data.Level or 1)
        
        -- Update XP bar
        local xp = data.XP or 0
        local xpToNext = data.XPToNext or 100
        local xpPercent = math.clamp(xp / xpToNext, 0, 1)
        XPBarFill.Size = UDim2.new(xpPercent, 0, 1, 0)
        XPText.Text = "XP: " .. tostring(xp) .. " / " .. tostring(xpToNext)
        
        -- Update weapon
        WeaponLabel.Text = "Weapon: " .. (data.EquippedWeaponName or "None")
        
        -- Update stats
        StatsLabel.Text = "ATK: " .. tostring(data.Attack or 0) .. " | DEF: " .. tostring(data.Defense or 0)
    else
        -- Full inventory update
        RefreshInventory(data)
    end
end

-- ============================================================================
-- EVENT CONNECTIONS
-- ============================================================================

-- Receive inventory/stats updates from server
InventoryUpdateRemote.OnClientEvent:Connect(function(data)
    UpdateHUD(data)
end)

-- Receive loot notifications
LootRemote.OnClientEvent:Connect(function(itemName, rarity)
    ShowLootNotification(itemName, rarity)
end)

-- Loot drop notification (item fell on ground)
LootDropRemote.OnClientEvent:Connect(function(data)
    ShowLootNotification("DROPPED: " .. data.ItemName .. " [" .. data.Rarity .. "]", data.Rarity)
end)

-- Inventory button click
InventoryButton.MouseButton1Click:Connect(function()
    ToggleInventory()
end)

-- Close button
CloseBtn.MouseButton1Click:Connect(function()
    inventoryOpen = false
    InventoryFrame.Visible = false
end)

-- Keyboard shortcut: "I" to toggle inventory
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.I then
        ToggleInventory()
    end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

print("[CombatHUD] Inventory & HUD client loaded!")
print("[CombatHUD] Press 'I' or click the Inventory button to open your items.")
