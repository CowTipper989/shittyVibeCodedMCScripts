-- Set peripheral sides
local inputChest = peripheral.wrap("right")
local outputChest = peripheral.wrap("left")
local rejectChest = peripheral.wrap("top")  -- third chest for unmatched items

-- Load recipes from file
local function loadRecipes(filename)
    if not fs.exists(filename) then
        error("Recipe file does not exist: " .. filename)
    end

    local file = fs.open(filename, "r")
    if not file then
        error("Could not open file: " .. filename .. " (check file permissions or mode)")
    end

    local recipes = {}
    while true do
        local line = file.readLine()
        if not line then break end

        local recipe = {}
        for item in line:gmatch("%S+") do
            table.insert(recipe, item)
        end

        if #recipe == 9 then
            table.insert(recipes, recipe)
        else
            print("Warning: Skipped malformed recipe line.")
        end
    end

    file.close()
    return recipes
end


-- Get inventory map { [item_name] = count }
local function getInventoryMap(inv)
    local map = {}
    for slot, item in pairs(inv.list()) do
        if item then
            map[item.name] = (map[item.name] or 0) + item.count
        end
    end
    return map
end

-- Check if inventory contains enough items for the recipe
local function canCraft(invMap, recipe)
    local needed = {}
    for _, item in ipairs(recipe) do
        needed[item] = (needed[item] or 0) + 1
    end

    for name, count in pairs(needed) do
        if not invMap[name] or invMap[name] < count then
            return false
        end
    end

    return true
end

-- Pull items from input to output in recipe order
local function moveItemsInOrder(input, output, recipe)
    local inputList = input.list()
    for _, itemName in ipairs(recipe) do
        local found = false
        for slot, item in pairs(inputList) do
            if item.name == itemName then
                sleep (.5)
                input.pushItems(peripheral.getName(output), slot, 1)
                -- sleep (1)
                inputList = input.list() -- refresh after moving
                found = true
                break
            end
        end
        if not found then
            print("Missing item during transfer: " .. itemName)
            return false
        end
    end
    return true
end

-- Move all items from input to reject chest
local function moveAllToReject(input, reject)
    local invList = input.list()
    for slot, item in pairs(invList) do
        input.pushItems(peripheral.getName(reject), slot, item.count)
        sleep(0.5)  -- optional small delay
    end
    print("Moved unmatched items to reject chest.")
end

-- Main loop
local recipes = loadRecipes("recipes.txt")

-- Main loop with reject handling
while true do
    local invMap = getInventoryMap(inputChest)
    local hasItems = false
    for _, count in pairs(invMap) do
        if count > 0 then
            hasItems = true
            break
        end
    end

    if hasItems then
        local matched = false
        for _, recipe in ipairs(recipes) do
            if canCraft(invMap, recipe) then
                print("Found matching recipe, moving items...")
                moveItemsInOrder(inputChest, outputChest, recipe)
                matched = true
                break
            end
        end
        if not matched then
            moveAllToReject(inputChest, rejectChest)
        end
    end

    sleep(1)
end
