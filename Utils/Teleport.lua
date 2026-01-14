local Logger = require("Core/Logger")

local Teleport = {}

function Teleport.TeleportEntity(entity, pos, facing)
    if not entity or not pos then return false end

    local targetPos = Vector4.new(pos.x, pos.y, pos.z, pos.w or 1.0)
    local rot = facing or entity:GetWorldOrientation():ToEulerAngles()

    Game.GetTeleportationFacility():Teleport(entity, targetPos, rot)
    --Logger.Log(string.format("Teleport: moved entity to (%.2f, %.2f, %.2f)", targetPos.x, targetPos.y, targetPos.z))
    return true
end

function Teleport.DistanceBetween(posA, posB)
    if not posA or not posB then return math.huge end
    local dx, dy, dz = posA.x - posB.x, posA.y - posB.y, (posA.z or 0) - (posB.z or 0)
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function Teleport.DistanceFromPlayer(pos)
    local player = Game.GetPlayer()
    if not player or not pos then return math.huge end
    return Teleport.DistanceBetween(player:GetWorldPosition(), pos)
end

function Teleport.GetPlayerPosition()
    local player = Game.GetPlayer()
    return player and player:GetWorldPosition() or nil
end

function Teleport.GetForwardOffset(distance, yawOverride)
    local player = Game.GetPlayer()
    if not player then return nil end

    local pos = player:GetWorldPosition()
    local rot = player:GetWorldOrientation():ToEulerAngles()
    local yaw = yawOverride or rot.yaw

    local yawRad = math.rad(yaw)
    local xOffset = distance * -math.sin(yawRad)
    local yOffset = distance *  math.cos(yawRad)

    return Vector4.new(pos.x + xOffset, pos.y + yOffset, pos.z, 1.0)
end

function Teleport.GetRightOffset(distance, yawOverride)
    local player = Game.GetPlayer()
    if not player then return nil end

    local pos = player:GetWorldPosition()
    local rot = player:GetWorldOrientation():ToEulerAngles()
    local yaw = yawOverride or rot.yaw

    local yawRad = math.rad(yaw + 90)
    local xOffset = distance * -math.sin(yawRad)
    local yOffset = distance *  math.cos(yawRad)

    return Vector4.new(pos.x + xOffset, pos.y + yOffset, pos.z, 1.0)
end


return Teleport
