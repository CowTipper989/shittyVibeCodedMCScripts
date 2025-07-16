local file = fs.open("recipes.txt", "r")
if not file then
    print("Failed to open file")
    return
end

local line = file.readLine()
file.close()

if line then
    print("First recipe line:", line)
else
    print("File is empty")
end
