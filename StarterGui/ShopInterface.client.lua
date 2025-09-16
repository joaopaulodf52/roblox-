local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHOP_BUTTON_COLOR = Color3.fromRGB(45, 45, 45)
local SHOP_BUTTON_SELECTED_COLOR = Color3.fromRGB(70, 120, 70)
local ITEM_FRAME_COLOR = Color3.fromRGB(32, 32, 32)
local SUCCESS_COLOR = Color3.fromRGB(150, 220, 150)
local ERROR_COLOR = Color3.fromRGB(220, 140, 140)
local INFO_COLOR = Color3.fromRGB(200, 200, 200)

local function getItemName(itemId)
    local itemConfig = ItemsConfig[itemId]
    if itemConfig and itemConfig.name then
        return itemConfig.name
    end

    return itemId or "?"
end

local function formatCurrency(amount, currency)
    currency = string.lower(currency or "gold")
    if currency == "gold" then
        return string.format("%d ouro", amount or 0)
    end

    return string.format("%d %s", amount or 0, currency)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopInterface"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "ShopContainer"
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.Position = UDim2.new(1, -20, 0, 20)
mainFrame.Size = UDim2.new(0, 420, 0, 420)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -20, 0, 24)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "Lojas"
titleLabel.Parent = mainFrame

local shopsFrame = Instance.new("Frame")
shopsFrame.Name = "ShopsList"
shopsFrame.BackgroundTransparency = 1
shopsFrame.Position = UDim2.new(0, 10, 0, 44)
shopsFrame.Size = UDim2.new(0, 140, 1, -130)
shopsFrame.Parent = mainFrame

local shopsLayout = Instance.new("UIListLayout")
shopsLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopsLayout.Padding = UDim.new(0, 6)
shopsLayout.Parent = shopsFrame

local shopHeader = Instance.new("Frame")
shopHeader.Name = "ShopHeader"
shopHeader.BackgroundTransparency = 1
shopHeader.Position = UDim2.new(0, 160, 0, 44)
shopHeader.Size = UDim2.new(1, -170, 0, 60)
shopHeader.Parent = mainFrame

local shopNameLabel = Instance.new("TextLabel")
shopNameLabel.Name = "ShopName"
shopNameLabel.BackgroundTransparency = 1
shopNameLabel.Size = UDim2.new(1, 0, 0, 26)
shopNameLabel.Position = UDim2.new(0, 0, 0, 0)
shopNameLabel.Font = Enum.Font.GothamBold
shopNameLabel.TextSize = 18
shopNameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
shopNameLabel.TextXAlignment = Enum.TextXAlignment.Left
shopNameLabel.Text = "Selecione uma loja"
shopNameLabel.Parent = shopHeader

local shopDescriptionLabel = Instance.new("TextLabel")
shopDescriptionLabel.Name = "ShopDescription"
shopDescriptionLabel.BackgroundTransparency = 1
shopDescriptionLabel.Size = UDim2.new(1, 0, 0, 32)
shopDescriptionLabel.Position = UDim2.new(0, 0, 0, 26)
shopDescriptionLabel.Font = Enum.Font.Gotham
shopDescriptionLabel.TextSize = 14
shopDescriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
shopDescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
shopDescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
shopDescriptionLabel.TextWrapped = true
shopDescriptionLabel.Text = ""
shopDescriptionLabel.Parent = shopHeader

local itemsFrame = Instance.new("ScrollingFrame")
itemsFrame.Name = "ItemsList"
itemsFrame.Position = UDim2.new(0, 160, 0, 110)
itemsFrame.Size = UDim2.new(1, -170, 1, -210)
itemsFrame.CanvasSize = UDim2.new()
itemsFrame.ScrollBarThickness = 6
itemsFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
itemsFrame.BackgroundTransparency = 0.2
itemsFrame.BorderSizePixel = 0
itemsFrame.Parent = mainFrame

local itemsPadding = Instance.new("UIPadding")
itemsPadding.PaddingTop = UDim.new(0, 6)
itemsPadding.PaddingLeft = UDim.new(0, 6)
itemsPadding.PaddingRight = UDim.new(0, 6)
itemsPadding.Parent = itemsFrame

local itemsLayout = Instance.new("UIListLayout")
itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemsLayout.Padding = UDim.new(0, 6)
itemsLayout.Parent = itemsFrame

itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local contentSize = itemsLayout.AbsoluteContentSize.Y + 12
    itemsFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize)
end)

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.BackgroundTransparency = 0.4
messageLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
messageLabel.Size = UDim2.new(1, -20, 0, 64)
messageLabel.Position = UDim2.new(0, 10, 1, -74)
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextSize = 16
messageLabel.TextColor3 = INFO_COLOR
messageLabel.TextWrapped = true
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.Text = "Selecione uma loja para visualizar os itens disponíveis."
messageLabel.Parent = mainFrame

local shopButtons = {}
local selectedShopButton
local currentShopId

local function highlightShop(shopId)
    if selectedShopButton and selectedShopButton.Parent then
        selectedShopButton.BackgroundColor3 = SHOP_BUTTON_COLOR
    end

    local button = shopButtons[shopId]
    selectedShopButton = button
    if button then
        button.BackgroundColor3 = SHOP_BUTTON_SELECTED_COLOR
    end
end

local function clearItemEntries()
    for _, child in ipairs(itemsFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    itemsFrame.CanvasSize = UDim2.new()
end

local function createItemEntry(itemData)
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = itemData.itemId or "Item"
    entryFrame.BackgroundColor3 = ITEM_FRAME_COLOR
    entryFrame.BackgroundTransparency = 0.1
    entryFrame.BorderSizePixel = 0
    entryFrame.Size = UDim2.new(1, -12, 0, 110)
    entryFrame.Parent = itemsFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 10, 0, 8)
    nameLabel.Size = UDim2.new(1, -140, 0, 24)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    local bundleSize = tonumber(itemData.bundleSize) or 1
    if bundleSize > 1 then
        nameLabel.Text = string.format("%s (Pacote x%d)", itemData.name, bundleSize)
    else
        nameLabel.Text = itemData.name
    end
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entryFrame

    local detailsLabel = Instance.new("TextLabel")
    detailsLabel.Name = "DetailsLabel"
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.Position = UDim2.new(0, 10, 0, 34)
    detailsLabel.Size = UDim2.new(1, -160, 0, 24)
    detailsLabel.Font = Enum.Font.Gotham
    detailsLabel.TextSize = 14
    detailsLabel.TextColor3 = Color3.fromRGB(215, 215, 215)
    detailsLabel.TextXAlignment = Enum.TextXAlignment.Left

    local details = { formatCurrency(itemData.price, itemData.currency) }
    if bundleSize > 1 then
        table.insert(details, string.format("Pacote: %d itens", bundleSize))
    end
    if itemData.maxQuantity then
        table.insert(details, string.format("Máx compra: %d", itemData.maxQuantity))
    end
    detailsLabel.Text = table.concat(details, "  •  ")
    detailsLabel.Parent = entryFrame

    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "DescriptionLabel"
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.Position = UDim2.new(0, 10, 0, 58)
    descriptionLabel.Size = UDim2.new(1, -160, 0, 32)
    descriptionLabel.Font = Enum.Font.Gotham
    descriptionLabel.TextSize = 13
    descriptionLabel.TextWrapped = true
    descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
    descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
    descriptionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descriptionLabel.Text = itemData.description ~= "" and itemData.description or ""
    descriptionLabel.Parent = entryFrame

    local reasonLabel = Instance.new("TextLabel")
    reasonLabel.Name = "ReasonLabel"
    reasonLabel.BackgroundTransparency = 1
    reasonLabel.Position = UDim2.new(0, 10, 0, 86)
    reasonLabel.Size = UDim2.new(1, -160, 0, 18)
    reasonLabel.Font = Enum.Font.Gotham
    reasonLabel.TextSize = 12
    reasonLabel.TextWrapped = true
    reasonLabel.TextXAlignment = Enum.TextXAlignment.Left
    reasonLabel.TextColor3 = Color3.fromRGB(220, 120, 120)
    reasonLabel.Text = itemData.reason or ""
    reasonLabel.Visible = itemData.reason ~= nil
    reasonLabel.Parent = entryFrame

    local quantityBox = Instance.new("TextBox")
    quantityBox.Name = "QuantityBox"
    quantityBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    quantityBox.BorderSizePixel = 0
    quantityBox.Position = UDim2.new(1, -120, 0, 34)
    quantityBox.Size = UDim2.new(0, 48, 0, 28)
    quantityBox.ClearTextOnFocus = false
    quantityBox.Font = Enum.Font.Gotham
    quantityBox.TextSize = 14
    quantityBox.TextColor3 = Color3.fromRGB(235, 235, 235)
    quantityBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
    quantityBox.PlaceholderText = "Qtd"
    quantityBox.Text = "1"
    quantityBox.Parent = entryFrame

    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.BackgroundColor3 = Color3.fromRGB(65, 130, 80)
    buyButton.BorderSizePixel = 0
    buyButton.Position = UDim2.new(1, -60, 0, 34)
    buyButton.Size = UDim2.new(0, 50, 0, 28)
    buyButton.Font = Enum.Font.GothamBold
    buyButton.TextSize = 14
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.Text = "Comprar"
    buyButton.Parent = entryFrame

    if not itemData.available then
        buyButton.BackgroundColor3 = Color3.fromRGB(90, 50, 50)
        buyButton.Text = "Bloqueado"
        buyButton.AutoButtonColor = false
        buyButton.Active = false
        quantityBox.Visible = false
    else
        buyButton.MouseButton1Click:Connect(function()
            if not currentShopId then
                messageLabel.TextColor3 = INFO_COLOR
                messageLabel.Text = "Selecione uma loja antes de comprar."
                return
            end

            local desired = tonumber(quantityBox.Text)
            if not desired then
                messageLabel.TextColor3 = ERROR_COLOR
                messageLabel.Text = "Informe uma quantidade válida."
                return
            end

            desired = math.floor(desired)
            if desired < 1 then
                messageLabel.TextColor3 = ERROR_COLOR
                messageLabel.Text = "A quantidade deve ser pelo menos 1."
                return
            end

            Remotes.ShopPurchase:FireServer({
                shopId = currentShopId,
                itemId = itemData.itemId,
                quantity = desired,
            })
        end)
    end
end

local function renderShop(shopData)
    if type(shopData) ~= "table" then
        return
    end

    currentShopId = shopData.id
    highlightShop(shopData.id)

    shopNameLabel.Text = shopData.name or shopData.id or "Loja"
    shopDescriptionLabel.Text = shopData.description or ""

    clearItemEntries()

    local items = shopData.items or {}
    if #items == 0 then
        messageLabel.TextColor3 = INFO_COLOR
        messageLabel.Text = "Nenhum item disponível nesta loja no momento."
        return
    end

    for _, item in ipairs(items) do
        createItemEntry(item)
    end

    messageLabel.TextColor3 = INFO_COLOR
    messageLabel.Text = string.format("Mostrando %d itens em %s.", #items, shopData.name or shopData.id or "loja")
end

local function requestShop(shopId)
    if not shopId or shopId == "" then
        return
    end

    Remotes.ShopOpen:FireServer({ shopId = shopId })
end

local function buildShopButtons()
    for _, child in ipairs(shopsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    shopButtons = {}

    local entries = {}
    for id, definition in pairs(ShopConfig) do
        table.insert(entries, {
            id = definition.id or id,
            name = definition.name or id,
        })
    end

    table.sort(entries, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    for index, entry in ipairs(entries) do
        local button = Instance.new("TextButton")
        button.Name = entry.id
        button.BackgroundColor3 = SHOP_BUTTON_COLOR
        button.BorderSizePixel = 0
        button.Size = UDim2.new(1, 0, 0, 34)
        button.LayoutOrder = index
        button.AutoButtonColor = true
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.TextColor3 = Color3.fromRGB(235, 235, 235)
        button.Text = entry.name
        button.Parent = shopsFrame

        shopButtons[entry.id] = button

        button.MouseButton1Click:Connect(function()
            highlightShop(entry.id)
            messageLabel.TextColor3 = INFO_COLOR
            messageLabel.Text = string.format("Solicitando itens de %s...", entry.name)
            requestShop(entry.id)
        end)
    end

    if entries[1] then
        highlightShop(entries[1].id)
        requestShop(entries[1].id)
    end
end

Remotes.ShopOpen.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    local action = payload.action
    if action == "open" and type(payload.shop) == "table" then
        renderShop(payload.shop)
    elseif action == "error" then
        messageLabel.TextColor3 = ERROR_COLOR
        messageLabel.Text = payload.message or "Não foi possível abrir a loja."
    end
end)

Remotes.ShopPurchase.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    if payload.action ~= "result" then
        return
    end

    if payload.success then
        local detail = payload.detail or {}
        local itemId = payload.itemId or detail.itemId
        local itemName = getItemName(itemId)
        local quantity = detail.quantity or payload.quantity or 0
        local message = payload.message or string.format("Compra concluída: %s x%d", itemName, quantity)

        messageLabel.TextColor3 = SUCCESS_COLOR
        messageLabel.Text = message
    else
        messageLabel.TextColor3 = ERROR_COLOR
        messageLabel.Text = payload.message or "Compra não realizada."
    end
end)

buildShopButtons()
