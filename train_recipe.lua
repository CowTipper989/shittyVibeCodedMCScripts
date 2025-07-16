local inputChest = peripheral.wrap("left")
local outputChest = peripheral.wrap("right")

local function waitForNewItem(prevCounts)
    while true do
        local currentItems = inputChest.list()
        -- Find slot with new item count increased by 1 or new slot with count 1
        for slot, item in pairs(currentItems) do
            local prevCount = prevCounts[slot] or 0
            if item.count > prevCount then
                return slot, item.name
            end
        end
        -- Wait a bit before checking again
        sleep(0.2)
    end
end

local function saveRecipe(recipe)
    local file = fs.open("recipes.txt", "a")
    if not file then
        error("Failed to open recipes.txt for writing")
    end
    file.writeLine(table.concat(recipe, " "))
    file.close()
    print("Saved recipe: " .. table.concat(recipe, " "))
end

local function trainRecipe()
    print("Waiting for recipe input (9 items)...")
    local recordedItems = {}
    local prevCounts = {}

    -- Initialize prevCounts
    for slot, item in pairs(inputChest.list()) do
        prevCounts[slot] = item.count
    end

    while #recordedItems < 9 do
        local slot, itemName = waitForNewItem(prevCounts)
        -- Take 1 item out from input chest to output chest
        local moved = inputChest.pushItems(peripheral.getName(outputChest), slot, 1)
        if moved == 1 then
            table.insert(recordedItems, itemName)
            print("Recorded item " .. #recordedItems .. ": " .. itemName)
        else
            print("Failed to move item from slot " .. slot)
        end

        -- Update prevCounts for that slot
        local newCount = 0
        local currentItems = inputChest.list()
        if currentItems[slot] then
            newCount = currentItems[slot].count
        end
        prevCounts[slot] = newCount
    end

    saveRecipe(recordedItems)
    print("Recipe training complete. Ready for next recipe.")
end

while true do
    trainRecipe()
end
