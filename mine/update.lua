local files = {
    "main.lua",
    "history.lua",
    "fuel.lua",
    "vein.lua",
    "monitor.lua",
    "status.lua",
    "state.lua",
    "update.lua",
    "startup.lua",
    "config.lua",
    "quarry.lua",
}

local baseUrl = "https://raw.githubusercontent.com/muhlenlogan8/minecraft-turtle-miner/main/mine/"

for _, file in ipairs(files) do
    local path = "mine/" .. file

    if file == "config.lua" and fs.exists(path) then
        print("Keeping existing:", file)
    else
        if fs.exists(path) then
            fs.delete(path)
        end

        print("Updating:", file)
        shell.run("wget", baseUrl .. file, path)
    end
end

print("Done")
