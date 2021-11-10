local isPrintOn = true
local allCategoryOn = false
local categoryMode = {
    ["NPC"] = true,
    ["NPCManager"] = true,
    ["NPCWalkToAction"] = true,
    ["AI"] = true,
    ["ScanSquaresSystem"] = true
}


function NPCPrint(category, a, b, c, d, e, f, g, h, j, k)
    if (categoryMode[category] or allCategoryOn) and isPrintOn then
        if b == nil then
            print("NPCPrint: [", category, "] ", a)
        elseif c == nil then
            print("NPCPrint: [", category, "] ", a, ", ", b)
        elseif d == nil then
            print("NPCPrint: [", category, "] ", a, ", ", b, ", ", c)
        elseif e == nil then
            print("NPCPrint: [", category, "] ", a, ", ", b, ", ", c, ", ", d)
        elseif f == nil then
            print("NPCPrint: [", category, "] ", a, ", ", b, ", ", c, ", ", d, ", ", e)
        elseif g == nil then
            print("NPCPrint: [", category, "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f)
        elseif h == nil then
            print("NPCPrint: [", category, "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f, ", ", g)
        elseif j == nil then
            print("NPCPrint: [", category, "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f, ", ", g, ", ", h)
        elseif k == nil then
            print("NPCPrint: [", category, "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f, ", ", g, ", ", h, ", ", j)
        else
            print("NPCPrint: [", category, "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f, ", ", g, ", ", h, ", ", j, ", ", k)
        end
    end
end