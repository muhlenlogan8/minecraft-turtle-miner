local files = {
    "main.lua",
    "history.lua",
    "fuel.lua",
    "vein.lua",
    "monitor.lua",
    "status.lua",
    "state.lua",
    "update.lua",
    "startup.lua"
}

local baseUrl = "https://raw.githubusercontent.com/muhlenlogan8/minecraft-turtle-miner/main/mine/"

for _, file in ipairs(files) do
    print(fs.exists("mine/" .. file))
    if fs.exists("mine/" .. file) then
        fs.delete("mine/" .. file)
    end
    
    print("Updating:", file)
    shell.run("wget", baseUrl .. file, "mine/" .. file)
end

print("Done")
