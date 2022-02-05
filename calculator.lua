local json = require('json')
local fs = require('fs')

local HP = 3052

local damages = json.decode(fs.readFileSync("damages.json"))
local found = {}

local separator = " | "
local show_damage = true

local function find(tbl,val)
    for i,v in pairs(tbl) do
        if v == val then return i end
    end
end

local function sum(tbl)
    local count = 0
    for i,v in pairs(tbl) do
        count = count + damages[v]
    end

    return count
end

local function is_already_calculated(result)
    if #found == 0 then
        return false
    end

    for i,v in pairs(found) do
        for i2,v2 in pairs(result) do
            if find(v,v2) then
                -- we go deeper
                local exact_match_found = true

                for i3,v3 in pairs(result) do
                    if not find(v,v3) then
                        exact_match_found = false
                    end
                end

                if exact_match_found then
                    return true
                end
            end
        end
    end

    return false
end

local function construct_success_string(result)

    local success_string = ""

    for i,v in pairs(result) do
        success_string = success_string .. v
        
        if show_damage then
            success_string = success_string .. " (" .. tostring(damages[v]) .. " damage)"
        end

        if i ~= #result then
            success_string = success_string .. separator
        end
    end

    return success_string
end

local function copy(t)
    local new_table = {}

    for i,v in pairs(t) do
        new_table[i] = v
    end

    return new_table
end

local function make_nice(number)
    local digit = number % 10
    if digit == 1 then
        return "st"
    elseif digit == 2 then
        return "nd"
    elseif digit == 3 then
        return "rd"
    else
        return "th"
    end
end

local function count(target, total_iterations, current_iteration, indices)
    target = target or 69
    total_iterations = total_iterations or 2
    current_iteration = current_iteration or 1

    for i,v in pairs(damages) do
        if current_iteration >= total_iterations then
            local copy = copy(indices)
            table.insert(copy, i)
            local remainder = HP - sum(copy)

            if remainder == target then
                if not is_already_calculated(copy) then
                    table.insert(found, copy)
                    print("MATCH FOUND!")
                    print(construct_success_string(copy))
                    print("This reaches the HP of " .. target .. " from a tower of HP " .. HP .. ". This is the " .. #found .. make_nice(#found) .. " combination calculated so far.")
                    print("================================================================")
                end
            end
        else
            if not indices then
                count(target, total_iterations, current_iteration + 1, {i})
            else
                local copy = copy(indices)
                table.insert(copy, i)
                count(target, total_iterations, current_iteration + 1, copy)
            end
        end
    end
end

local suc, err = pcall(function()
    io.write("Enter the target HP: ")
    local target = tonumber(io.read())
    io.write("Enter the amount of cards to use: ")
    local cards = tonumber(io.read())

    if not (cards and target) then
        error("Invalid input: must be a number")
    end

    count(target, cards)

    local results = ""

    for i,v in pairs(found) do
        results = results .. table.concat(v, ", ") .. "\n"
    end

    print("\n\n| " .. #found .. " results found\n| Written to results.txt\n| Thank you for using the Wang Calculator, have a nice day")

    fs.writeFileSync("./results/" .. tostring(target) .. "hp_" .. tostring(cards) .. "cards" .. ".txt", results:sub(1,-2))
end)

if not suc then
    print("ERROR: " .. err)
end
