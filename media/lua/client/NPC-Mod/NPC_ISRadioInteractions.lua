local DEBUG = false;


local function doSkill(_player, _amount, _name, _perk)
    if _amount == nil or _amount <= 0 then return; end

    --local curXp = _player:getXp():getXP(_perk);
    local amount = 50*_amount;
    --if curXp>0 then
        --amount = (2 / curXp)*50;
    --end

    local oldXp = _player:getXp():getXP(_perk);
    _player:getXp():AddXP(_perk , amount);
    amount = _player:getXp():getXP(_perk) - oldXp;
    _player:getModData().NPC:SayNote(_name.." +"..round(amount,2), NPCColor.Green)
end

local function applyBoredom(_player, _amount, _isSet)
    local bodyDamage = _player:getBodyDamage();
    if bodyDamage~=nil then
        local val = bodyDamage:getBoredomLevel();

        if _isSet then
            val = _amount;
        else
            local am = _amount*5;
            val = val+am;
        end

        if val<0 then val = 0; end
        if val>100 then val = 100; end

        bodyDamage:setBoredomLevel(val);

        if DEBUG then
            _player:setHaloNote("Boredom "..tostring(val));
        end
    end
end

local function applyUnhappiness(_player, _amount, _isSet)
    local bodyDamage = _player:getBodyDamage();
    if bodyDamage~=nil then
        local val = bodyDamage:getUnhappynessLevel();

        if _isSet then
            val = _amount;
        else
            local am = _amount*5;
            val = val+am;
        end

        if val<0 then val = 0; end
        if val>100 then val = 100; end

        bodyDamage:setUnhappynessLevel(val);

        if DEBUG then
            _player:setHaloNote("Unhappiness "..tostring(val));
        end
    end
end

local function doStat(_statStr, _player, _amount, _isSet)
    if _statStr=="Boredom" then
        applyBoredom(_player,_amount,_isSet);
        return;
    elseif _statStr=="Unhappiness" then
        applyUnhappiness(_player,_amount,_isSet);
        return;
    end

    local stats = _player:getStats();
    if stats["get".._statStr]~=nil and stats["get".._statStr]~=nil then
        local val = stats["get".._statStr](stats);

        local range100 = false;
        if _statStr=="Panic" then
            range100 = true;
        end

        if _isSet then
            val = _amount;
        else
            local mod = range100 and 5 or 0.05;
            local am = _amount*mod;
            val = val+am;
        end

        if val<0 then val = 0; end
        if (not range100) and val>1 then val = 1; end
        if range100 and val>100 then val = 100; end

        stats["set".._statStr](stats,val);
        if DEBUG then
            local val = stats["get".._statStr](stats);
            _player:setHaloNote(_statStr.." "..tostring(val));
        end
    end
end

local Interactions = {};
--Stats
Interactions.ANG = function(_player, _amount, _opIsSet) doStat("Anger",_player,_amount, _opIsSet); end       -- Anger
Interactions.BOR = function(_player, _amount, _opIsSet) doStat("Boredom",_player,_amount, _opIsSet); end     -- boredom
Interactions.END = function(_player, _amount, _opIsSet) doStat("Endurance",_player,_amount, _opIsSet); end   -- endurance
Interactions.FAT = function(_player, _amount, _opIsSet) doStat("Fatigue",_player,_amount, _opIsSet); end     -- fatigue
Interactions.FIT = function(_player, _amount, _opIsSet) doStat("Fitness",_player,_amount, _opIsSet); end     -- fitness
Interactions.HUN = function(_player, _amount, _opIsSet) doStat("Hunger",_player,_amount, _opIsSet); end      -- hunger
Interactions.MOR = function(_player, _amount, _opIsSet) doStat("Morale",_player,_amount, _opIsSet); end      -- morale
Interactions.STS = function(_player, _amount, _opIsSet) doStat("Stress",_player,_amount, _opIsSet); end      -- stress
Interactions.FEA = function(_player, _amount, _opIsSet) doStat("Fear",_player,_amount, _opIsSet); end        -- Fear
Interactions.PAN = function(_player, _amount, _opIsSet) doStat("Panic",_player,_amount, _opIsSet); end       -- Panic
Interactions.SAN = function(_player, _amount, _opIsSet) doStat("Sanity",_player,_amount, _opIsSet); end      -- Sanity
Interactions.SIC = function(_player, _amount, _opIsSet) doStat("Sickness",_player,_amount, _opIsSet); end    -- Sickness
Interactions.PAI = function(_player, _amount, _opIsSet) doStat("Pain",_player,_amount, _opIsSet); end        -- Pain
Interactions.DRU = function(_player, _amount, _opIsSet) doStat("Drunkenness",_player,_amount, _opIsSet); end -- Drunkenness
Interactions.THI = function(_player, _amount, _opIsSet) doStat("Thirst",_player,_amount, _opIsSet); end      -- thirst
Interactions.UHP = function(_player, _amount, _opIsSet) doStat("Unhappiness",_player,_amount, _opIsSet); end      -- thirst
--Skills
--agility
Interactions.SPR = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Sprinting"), Perks.Sprinting); end         --sprinting
Interactions.LFT = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Lightfooted"), Perks.Lightfoot); end         --lightfooded
Interactions.NIM = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Nimble"), Perks.Nimble); end            --nimble
Interactions.SNE = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Sneaking"), Perks.Sneak); end             --sneaking
--blade
Interactions.BAA = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Axe"), Perks.Axe); end       -- Axe
Interactions.BUA = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Blunt"), Perks.Blunt); end       -- Blunt
--crafting
Interactions.CRP = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Carpentry"), Perks.Woodwork); end           --carpentry
Interactions.COO = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Cooking"), Perks.Cooking); end           --cooking
Interactions.FRM = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Farming"), Perks.Farming); end           --farming
Interactions.DOC = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Doctor"), Perks.Doctor); end            --firstaid
Interactions.ELC = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Electricity"), Perks.Electricity); end           --electricty
Interactions.MTL = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Metalworking"), Perks.MetalWelding); end            --metalwelding
--firearm
Interactions.AIM = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Aiming"), Perks.Aiming); end            --aiming
Interactions.REL = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Reloading"), Perks.Reloading); end         --reloading
--survivalist
Interactions.FIS = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Fishing"), Perks.Fishing); end           --fishing
Interactions.TRA = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Trapping"), Perks.Trapping); end          --trapping
Interactions.FOR = function(_player, _amount) doSkill(_player, _amount, getText("IGUI_perks_Foraging"), Perks.PlantScavenging); end   --foraging 

local instance = nil;

NPC_ISRadioInteractions = {}

function NPC_ISRadioInteractions:getInstance()
    if instance ~= nil then
        return instance;
    end

    local channelLog = {};
    local interactLog = {};
    local interactions = {};
    local cooldowns = {};
    local self = {};

    function self.split(str,sep)
        local sep, fields = sep or ":", {};
        local pattern = string.format("([^%s]+)", sep);
        str:gsub(pattern, function(c) fields[#fields+1] = c end);
        return fields;
    end

    function self.playerInRange(_player, _x, _y, _z)
        if math.floor(_player:getZ()) == math.floor(_z) then
            if _player:getX() >= _x-5 and _player:getX() <= _x+5 and _player:getY() >= _y-5 and _player:getY() <= _y+5 then
                return true;
            end
        end
        return false;
    end

    function self.checkPlayer(player, _interactCodes, _x, _y, _z, _line, _source)
        local source = (not (_x==-1 and _y==-1 and _z==-1)) and getCell():getGridSquare(_x,_y,_z) or nil;
        local plrsquare = player:getSquare();
        if source and source:isOutside() ~= plrsquare:isOutside() then
            return;
        end

        if player:isAsleep() then
            return;
        end

        --player:Say(_line);
        local playerUUID = player:getModData().NPC.UUID
        local stats = player:getStats();
        local xp = player:getXp();

        if stats ~= nil and xp ~= nil then
            local codes = self.split(_interactCodes, ",");
            for _,_v in ipairs(codes) do
                if _v:len() > 4 then
                    local code = string.sub(_v, 1, 3);
                    local op = string.sub(_v, 4, 4);
                    local amount = tonumber(string.sub(_v, 5, _v:len()));
                    if amount ~= nil then
                        amount = op=="-" and amount*-1 or amount;

                        if Interactions[code] ~= nil then
                            if not cooldowns[playerUUID] or not cooldowns[playerUUID][code] or cooldowns[playerUUID][code]<=0 then
                                Interactions[code](player, amount, op=="=");
                                cooldowns[playerUUID] = cooldowns[playerUUID] or {}
                                cooldowns[playerUUID][code] = 30; -- FIXME: ignores FPS
                            end
                        end
                    end
                end
            end

            local moodles = player:getMoodles();
            if moodles ~= nil then
                moodles:Update();
            end
        end
    end

    function self.OnDeviceText( _interactCodes, _x, _y, _z, _line )
        if _interactCodes ~= nil and _interactCodes:len() > 0 and _line ~=nil then
            for i, npc in ipairs(NPCManager.characters) do
                local player = npc.character
                if player and player:isDead() then player = nil end
                if player ~=nil and ((_x==-1 and _y==-1 and _z==-1) or self.playerInRange(player, _x, _y, _z)) then
                    self.checkPlayer(player, _interactCodes, _x, _y, _z, _line)
                end
            end
        end
    end

    function self.OnTick()
        for i, npc in ipairs(NPCManager.characters) do
            local uuid = npc.UUID
            local tbl = cooldowns[uuid]
            if tbl then
                for code,value in pairs(tbl) do
                    if value > 0 then
                        tbl[code] = value - (1*getGameTime():getMultiplier());
                    end
                end
            end
        end
    end

    local function Init()
        Events.OnDeviceText.Add( self.OnDeviceText );
        Events.OnTick.Add( self.OnTick );

        instance = self;
        return self;
    end

    return Init();
end

Events.OnGameBoot.Add(function() NPC_ISRadioInteractions:getInstance(); end);

