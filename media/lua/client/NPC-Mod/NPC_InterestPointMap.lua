NPC_InterestPointMap = {}
NPC_InterestPointMap.Rooms = {}
-- [ID] = {x= y=}

function NPC_InterestPointMap:getNearestNewRoom(x, y, visitedRooms)
    local dist = 99999
    local nearestRoomID = nil    
    for ID, room in pairs(NPC_InterestPointMap.Rooms) do
        if visitedRooms[ID] == nil then
            local d = NPCUtils.getDistanceBetweenXYZ(room.x, room.y, x, y)
            if d < dist then
                dist = d
                nearestRoomID = ID
            end
        end
    end
    return nearestRoomID
end
