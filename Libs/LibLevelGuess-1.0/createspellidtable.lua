-- this file is for a standalone lua interpreter with the luasocket, luasec libraries
local OUTPUTFILE = "SpellIdData.lua"
local tinsert = table.insert
local tremove = table.remove
local tonumber = tonumber
local strfind = string.find

local https = require("ssl.https")

local classToWebsite = {
    ["WARRIOR"] = "https://www.wowhead.com/warrior",
    ["PALADIN"] = "https://www.wowhead.com/paladin",
    ["HUNTER"] = "https://www.wowhead.com/hunter",
    ["ROGUE"] = "https://www.wowhead.com/rogue",
    ["PRIEST"] = "https://www.wowhead.com/priest",
    ["DEATHKNIGHT"] = "https://www.wowhead.com/death-knight",
    ["SHAMAN"] = "https://www.wowhead.com/shaman",
    ["MAGE"] = "https://www.wowhead.com/mage",
    ["WARLOCK"] = "https://www.wowhead.com/warlock",
    ["MONK"] = "https://www.wowhead.com/monk",
    ["DRUID"] = "https://www.wowhead.com/druid",
    ["DEMONHUNTER"] = "https://www.wowhead.com/demon-hunter"
}

local function ProcessContent(websiteString, CLASS)
    print("Parsing...")
    -- parsing function from lifetapt
    local sfStart, sfEnd, sfHtml
    local parseCount = 0
    local result = {}
    local minLevel = 1
    if CLASS == "DEATHKNIGHT" then
        minLevel = 8
    elseif CLASS == "DEMONHUNTER" then
        minLevel = 8
    end
    sfStart = 0
    sfEnd = 0
    while sfStart and sfEnd do
        sfStart, sfEnd, sfHtml = strfind(websiteString, "new Listview.-{template: 'spell',(.-)\n", sfEnd)
        if sfStart and sfEnd then
            local spStart, spEnd, spID, spLevel
            spStart = 0
            spEnd = 0

            while spStart and spEnd do
                spStart, spEnd, spID, spLevel = strfind(sfHtml,
                    "{.-\"id\":([0-9]+),\"level\":([0-9]+),.-},", spEnd)
                if spStart and spEnd then
                    if ((spLevel and tonumber(spLevel)) or 0) < minLevel then
                        spLevel = minLevel
                    end
                    -- print("SpellID: "..(tonumber(spID) or "nil") .." | Level: "..(tonumber(spLevel) or "nil"))
                    tinsert(result, {spellID = spID, Class = CLASS, Level = tonumber(spLevel)})
                    parseCount = parseCount + 1
                end
            end
        end
    end
    print("Parsed "..parseCount.." spells!")
    return result
end

local function writeTableToFile(tablecontent, filename)
    local f = assert(io.open(filename, "w"))

    f:write("local lib = LibStub(\"LibLevelGuess-1.0\")\n\n")
    f:write("if not lib then error(\"SpellIdData for LibLevelGuess needs library to be loaded before\") return end\n\n")

    f:write("local myDataVersion = ", os.time(), "\n")
    f:write("if lib.spellIdData and myDataVersion <= lib.spellIdDataVersion then return end\n\n")
    f:write("lib.spellIdDataVersion = myDataVersion\n")
    f:write("lib.spellIdData = {\n")

    for k, v in pairs(tablecontent) do
        if v then
            f:write("\t[", v.spellID, "] = {Level=", v.Level, ",Class=\"", v.Class, "\"},\n")
        else
            print(k .. " is nil")
        end
    end

    f:write("}\n")
    f:close()
end

local result = {}

for class, url in pairs(classToWebsite) do
    local content, httpCode, header = https.request(url)
    if content and httpCode == 200 then
        print("Got " .. url .. " for class " .. class)
        local classResult = ProcessContent(content, class)
        for _, v in pairs(classResult) do
            tinsert(result, v)
        end
    else
        print("Failed fetching " .. url .. ": " .. header)
    end
end

-- Remove duplicates
local count = 0
table.sort(result, function(v1, v2)
    return v1.spellID < v2.spellID
end)
local lastk = nil
local lastid = nil
local lastClass = nil
local lastLevel = nil
for k, v in pairs(result) do
    if v.spellID == lastid then
        count = count + 1
        if v.Class ~= lastClass then
            result[lastk].Class = "MULTI"
        end
        if v.Level < lastLevel then
            result[lastk].Level = v.Level
        end
        tremove(result, k)
    else
        lastk = k
        lastid = v.spellID
        lastClass = v.Class
        lastLevel = v.Level
    end
end
print("Removed " .. count .. " duplicates")

-- Remove useless items that give no extra info
count = 0
for k, v in pairs(result) do
    if v.Class == "MULTI" and v.Level == 1 then
        count = count + 1
        tremove(result, k)
    end
end
print("Removed " .. count .. " multiclass level 1 spells")

table.sort(result, function(v1, v2)
    if v1.Class < v2.Class then
        return true
    elseif (v1.Class > v2.Class) then
        return nil
    end

    if v1.Level < v2.Level then
        return true
    elseif v1.Level > v2.Level then
        return nil
    end

    return v1.spellID < v2.spellID
end)

writeTableToFile(result, OUTPUTFILE)
