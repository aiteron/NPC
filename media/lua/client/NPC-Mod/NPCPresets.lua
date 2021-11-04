NPCPresets = {}

--[[
FEMALE HAIR = Bald, Bob, BobCurly, Braids, Buffont, Bun, BunCurly, Fresh, CentreParting, Cornrows, Demi, FlatTop, GreasedBack, Grungey, GrungeyBehindEars, Grungey02, 
GrungeyParted, Hat, HatCurly, HatLong, HatLongBraided, HatLongCurly, LeftParting, Long, Longcurly, Long2, Long2curly, LongBraids, CentrePartingLong, LongBraids02, 
MohawkFan, MohawkFlat, MohawkShort, MohawkSpike, Kate, KateCurly, OverEye, OverEyeCurly, OverLeftEye, PonyTail, PonyTailBraids, Back, Rachel, RachelCurly, RightParting, 
ShortCurly, Spike, LibertySpikes, TopCurls

MALE HAIR = Bald, Baldspot, Braids, Buffont, Fresh, CentreParting, Cornrows, CrewCut, Donny, Fabian, FabianCurly, FlatTop, GreasedBack, Grungey, GrungeyBehindEars, 
Hat, HatLong, HatLongBraided, HatLongCurly, LeftParting, LongBraids, CentrePartingLong, LongBraids02, Messy, MessyCurly, MohawkFan, MohawkFlat, MohawkShort, MohawkSpike, 
Mullet, MulletCurly, Picard, PonyTail, PonyTailBraids, Recede, RightParting, Short, ShortHatCurly, ShortAfroCurly, Spike, LibertySpikes, Metal

MALE BEARD = "", Chin, BeardOnly, Chops, Full, Goatee, Long, Moustache, PointyChin, LongScruffy

PROFESSIONS = unemployed, fireofficer, policeofficer, parkranger, constructionworker, securityguard, carpenter, 
burglar, chef, repairman, farmer, fisherman, doctor, veteran, nurse, lumberjack, fitnessInstructor, burgerflipper, electrician, engineer, metalworker, mechanics

]]--

local female_hair_LIST = {"Bald", "Bob", "BobCurly", "Braids", "Buffont", "Bun", "BunCurly", "Fresh", "CentreParting", "Cornrows", "Demi", "FlatTop", "GreasedBack", "Grungey", "GrungeyBehindEars", "Grungey02", 
"GrungeyParted", "Hat", "HatCurly", "HatLong", "HatLongBraided", "HatLongCurly", "LeftParting", "Long", "Longcurly", "Long2", "Long2curly", "LongBraids", "CentrePartingLong", "LongBraids02", 
"MohawkFan", "MohawkFlat", "MohawkShort", "MohawkSpike", "Kate", "KateCurly", "OverEye", "OverEyeCurly", "OverLeftEye", "PonyTail", "PonyTailBraids", "Back", "Rachel", "RachelCurly", "RightParting", 
"ShortCurly", "Spike", "LibertySpikes", "TopCurls"}

local male_hair_LIST = {"Bald", "Baldspot", "Braids", "Buffont", "Fresh", "CentreParting", "Cornrows", "CrewCut", "Donny", "Fabian", "FabianCurly", "FlatTop", "GreasedBack", "Grungey", "GrungeyBehindEars", 
"Hat", "HatLong", "HatLongBraided", "HatLongCurly", "LeftParting", "LongBraids", "CentrePartingLong", "LongBraids02", "Messy", "MessyCurly", "MohawkFan", "MohawkFlat", "MohawkShort", "MohawkSpike", 
"Mullet", "MulletCurly", "Picard", "PonyTail", "PonyTailBraids", "Recede", "RightParting", "Short", "ShortHatCurly", "ShortAfroCurly", "Spike", "LibertySpikes", "Metal"}

local male_beard_LIST = {"", "Chin", "BeardOnly", "Chops", "Full", "Goatee", "Long", "Moustache", "PointyChin", "LongScruffy"}

local professions_LIST = {"unemployed", "fireofficer", "policeofficer", "parkranger", "constructionworker", "securityguard", "carpenter", 
"burglar", "chef", "repairman", "farmer", "fisherman", "doctor", "veteran", "nurse", "lumberjack", "fitnessInstructor", "burgerflipper", "electrician", "engineer", "metalworker", "mechanics"}

local random_weapon_LIST = { "Base.Pan", "Base.SpearCrafted", "Base.HuntingKnife", "Base.KitchenKnife", "Base.Axe"}

NPCPresets.Aiteron = {
    chance = 5,
    isFemale = false,                           -- bool
    skinColor = 0,                              -- int 0-4 (From light to dark)
    hair = "Short",                             -- string
    hairColor = {r = 0.5, g = 0.5, b = 0.5},    -- RGBA
    beard = "Full",                             -- string
    beardColor = {r = 0.5, g = 0.5, b = 0.5},   -- RGBA
    forename = "Alexander",
    surname = "Blinov",
    profession = "veteran",
    defaultReputation = -100,
    perks = {
        Fitness = 5,
        Strength = 5,

        Sprinting = 5,
        Lightfoot = 5,
        Nimble = 5,
        Sneak = 5,

        Axe = 5,
        Blunt = 5,
        SmallBlunt = 5,
        LongBlade = 5,
        SmallBlade = 5,
        Spear = 5,
        Maintenance = 5,

        Woodwork = 5,
        Cooking = 5,
        Farming = 5, 
        Doctor = 5,
        Electricity = 5,
        MetalWelding = 5,
        Mechanics = 5,
        Tailoring = 5,

        Aiming = 5,
        Reloading = 5,

        Fishing = 5,
        Trapping = 5,
        PlantScavenging = 5
    },
    outfit = {                          -- Item in arms: "Both hands", "Primary", "Secondary"
        "Base.Hat_BeretArmy",
        "Base.Tshirt_ArmyGreen",
        "Base.Bag_ALICEpack",
        "Base.Trousers_CamoGreen",
        "Base.Shoes_BlackBoots",
        "Base.Belt2",
        {"Base.HuntingKnife", "Secondary"}
    },
    items = {
        "Base.Axe",
        { "Base.Bag_ALICEpack", "Base.DeadRat" },
        "Base.Apple",
        "Base.Hammer",
        "Base.AssaultRifle"
    },
    attachments = {
         {"Base.Axe", 1, "Big Weapon On Back with Bag", "Back"},
         {"Base.Hammer", 2, "Belt Left", "Belt Left"}
    },
    itemsInArms = {
        {"Base.AssaultRifle", "BOTH"}
    }
}


NPCPresets.Alice = {
    chance = 5,
    isFemale = true,                           -- bool
    skinColor = 4,                              -- int 0-4 (From light to dark)
    hair = "PonyTail",                             -- string
    hairColor = {r = 0.9, g = 0.1, b = 0.1},    -- RGBA
    beard = "",                             -- string
    beardColor = {r = 0.5, g = 0.5, b = 0.5},   -- RGBA
    forename = "Alice",
    surname = "Brodsky",
    profession = "nurse",
    defaultReputation = 0,
    perks = {
        Fitness = 3,
        Strength = 3,

        Sprinting = 5,
        Lightfoot = 5,
        Nimble = 5,
        Sneak = 5,

        Axe = 5,
        Blunt = 5,
        SmallBlunt = 5,
        LongBlade = 5,
        SmallBlade = 5,
        Spear = 10,
        Maintenance = 5,

        Woodwork = 0,
        Cooking = 5,
        Farming = 5, 
        Doctor = 5,
        Electricity = 5,
        MetalWelding = 5,
        Mechanics = 5,
        Tailoring = 5,

        Aiming = 5,
        Reloading = 5,

        Fishing = 5,
        Trapping = 5,
        PlantScavenging = 5
    },
    outfit = {
        "Base.Dress_Normal",
        "Base.Shoes_BlueTrainers",
        "Base.Bag_DuffelBag",
        "Base.Belt2"
    },
    items = {
        "Base.Axe",
        { "Base.Bag_DuffelBag", "Base.DeadRat" },
        "Base.Apple",
        "Base.Hammer"
    },
    attachments = {
         {"Base.Axe", 1, "Big Weapon On Back with Bag", "Back"},
         {"Base.Hammer", 2, "Belt Left", "Belt Left"}
    }
}

NPCPresets.Random = {
    chance = 90,
    isFemale = "RAND",                           -- bool
    skinColor = "RAND",                              -- int 0-4 (From light to dark)
    hair = "RAND",                             -- string
    hairColor = "RAND",    -- RGBA
    beard = "RAND",                             -- string
    beardColor = "RAND",   -- RGBA
    forename = "RAND",
    surname = "RAND",
    profession = "RAND",
    defaultReputation = "RAND",
    perks = {
        Fitness = "RAND",
        Strength = "RAND",

        Sprinting = "RAND",
        Lightfoot = "RAND",
        Nimble = "RAND",
        Sneak = "RAND",

        Axe = "RAND",
        Blunt = "RAND",
        SmallBlunt = "RAND",
        LongBlade = "RAND",
        SmallBlade = "RAND",
        Spear = "RAND",
        Maintenance = "RAND",

        Woodwork = "RAND",
        Cooking = "RAND",
        Farming = "RAND", 
        Doctor = "RAND",
        Electricity = "RAND",
        MetalWelding = "RAND",
        Mechanics = "RAND",
        Tailoring = "RAND",

        Aiming = "RAND",
        Reloading = "RAND",

        Fishing = "RAND",
        Trapping = "RAND",
        PlantScavenging = "RAND"
    },
    outfit = "RAND",
    items = {
        "RAND_WEAPON"
    },
    attachments = {
    },
    itemsInArms = {
    }
}

function NPCPresets_GetPreset()
    local chance = 0
    local randChance = ZombRand(0, 101)

    local resultPreset = NPCPresets.Aiteron

    for name, pr in pairs(NPCPresets) do
        chance = chance + pr.chance
        if randChance < chance then
            resultPreset = {}
            if pr.isFemale == "RAND" then
                if ZombRand(0, 2) == 0 then
                   resultPreset.isFemale = true
                else
                    resultPreset.isFemale = false
                end
            else
                resultPreset.isFemale = pr.isFemale
            end
            --
            if pr.skinColor == "RAND" then
                resultPreset.skinColor = ZombRand(0, 5)
            else
                resultPreset.skinColor = pr.skinColor
            end
            --
            if pr.hair == "RAND" then
                if resultPreset.isFemale then
                    resultPreset.hair = female_hair_LIST[ZombRand(1, (#female_hair_LIST + 1))]
                else
                    resultPreset.hair = male_hair_LIST[ZombRand(1, (#male_hair_LIST + 1))]
                end
            else
                resultPreset.hair = pr.hair
            end
            --
            if pr.hairColor == "RAND" then
                resultPreset.hairColor = { r = ZombRand(0, 101)/100.0, g = ZombRand(0, 101)/100.0, b = ZombRand(0, 101)/100.0 }
            else
                resultPreset.hairColor = pr.hairColor
            end
            --
            if pr.beard == "RAND" then
                resultPreset.beard = male_beard_LIST[ZombRand(1, (#male_beard_LIST + 1))]
            else
                resultPreset.beard = pr.beard
            end
            --
            if pr.beardColor == "RAND" then
                resultPreset.beardColor = { r = ZombRand(0, 101)/100.0, g = ZombRand(0, 101)/100.0, b = ZombRand(0, 101)/100.0 }
            else
                resultPreset.beardColor = pr.beardColor
            end
            --
            if pr.forename == "RAND" then
                if resultPreset.isFemale then
                    resultPreset.forename = SurvivorFactory.FemaleForenames:get(ZombRand(0, SurvivorFactory.FemaleForenames:size()))
                else
                    resultPreset.forename = SurvivorFactory.MaleForenames:get(ZombRand(0, SurvivorFactory.MaleForenames:size()))
                end
            else
                resultPreset.forename = pr.forename
            end
            --
            if pr.surname == "RAND" then
                resultPreset.surname = SurvivorFactory.Surnames:get(ZombRand(0, SurvivorFactory.Surnames:size()))
            else
                resultPreset.surname = pr.surname
            end
            --
            if pr.profession == "RAND" then
                resultPreset.profession = professions_LIST[ZombRand(1, (#professions_LIST + 1))]
            else
                resultPreset.profession = pr.profession
            end
            --
            if pr.defaultReputation == "RAND" then
                resultPreset.defaultReputation = ZombRand(-250, 250)
            else
                resultPreset.defaultReputation = pr.defaultReputation
            end
            ------
            resultPreset.perks = {}

            if pr.perks.Fitness == "RAND" then
                resultPreset.perks.Fitness = ZombRand(2, 8)
            else
                resultPreset.perks.Fitness = pr.perks.Fitness
            end
            --
            if pr.perks.Strength == "RAND" then
                resultPreset.perks.Strength = ZombRand(2, 8)
            else
                resultPreset.perks.Strength = pr.perks.Strength
            end
            --
            if pr.perks.Sprinting == "RAND" then
                resultPreset.perks.Sprinting = ZombRand(0, 6)
            else
                resultPreset.perks.Sprinting = pr.perks.Sprinting
            end
            --
            if pr.perks.Lightfoot == "RAND" then
                resultPreset.perks.Lightfoot = ZombRand(0, 6)
            else
                resultPreset.perks.Lightfoot = pr.perks.Lightfoot
            end
            --
            if pr.perks.Nimble == "RAND" then
                resultPreset.perks.Nimble = ZombRand(0, 6)
            else
                resultPreset.perks.Nimble = pr.perks.Nimble
            end
            --
            if pr.perks.Sneak == "RAND" then
                resultPreset.perks.Sneak = ZombRand(0, 6)
            else
                resultPreset.perks.Sneak = pr.perks.Sneak
            end
            --
            if pr.perks.Axe == "RAND" then
                resultPreset.perks.Axe = ZombRand(0, 6)
            else
                resultPreset.perks.Axe = pr.perks.Axe
            end
            --
            if pr.perks.Blunt == "RAND" then
                resultPreset.perks.Blunt = ZombRand(0, 6)
            else
                resultPreset.perks.Blunt = pr.perks.Blunt
            end
            --
            if pr.perks.SmallBlunt == "RAND" then
                resultPreset.perks.SmallBlunt = ZombRand(0, 6)
            else
                resultPreset.perks.SmallBlunt = pr.perks.SmallBlunt
            end
            --
            if pr.perks.LongBlade == "RAND" then
                resultPreset.perks.LongBlade = ZombRand(0, 6)
            else
                resultPreset.perks.LongBlade = pr.perks.LongBlade
            end
            --
            if pr.perks.SmallBlade == "RAND" then
                resultPreset.perks.SmallBlade = ZombRand(0, 6)
            else
                resultPreset.perks.SmallBlade = pr.perks.SmallBlade
            end
            --
            if pr.perks.Spear == "RAND" then
                resultPreset.perks.Spear = ZombRand(0, 6)
            else
                resultPreset.perks.Spear = pr.perks.Spear
            end
            --
            if pr.perks.Maintenance == "RAND" then
                resultPreset.perks.Maintenance = ZombRand(0, 6)
            else
                resultPreset.perks.Maintenance = pr.perks.Maintenance
            end
            --
            if pr.perks.Woodwork == "RAND" then
                resultPreset.perks.Woodwork = ZombRand(0, 6)
            else
                resultPreset.perks.Woodwork = pr.perks.Woodwork
            end
            --
            if pr.perks.Cooking == "RAND" then
                resultPreset.perks.Cooking = ZombRand(0, 6)
            else
                resultPreset.perks.Cooking = pr.perks.Cooking
            end
            --
            if pr.perks.Farming == "RAND" then
                resultPreset.perks.Farming = ZombRand(0, 6)
            else
                resultPreset.perks.Farming = pr.perks.Farming
            end
            --
            if pr.perks.Doctor == "RAND" then
                resultPreset.perks.Doctor = ZombRand(0, 6)
            else
                resultPreset.perks.Doctor = pr.perks.Doctor
            end
            --
            if pr.perks.Electricity == "RAND" then
                resultPreset.perks.Electricity = ZombRand(0, 6)
            else
                resultPreset.perks.Electricity = pr.perks.Electricity
            end
            --
            if pr.perks.MetalWelding == "RAND" then
                resultPreset.perks.MetalWelding = ZombRand(0, 6)
            else
                resultPreset.perks.MetalWelding = pr.perks.MetalWelding
            end
            --
            if pr.perks.Mechanics == "RAND" then
                resultPreset.perks.Mechanics = ZombRand(0, 6)
            else
                resultPreset.perks.Mechanics = pr.perks.Mechanics
            end
            --
            if pr.perks.Tailoring == "RAND" then
                resultPreset.perks.Tailoring = ZombRand(0, 6)
            else
                resultPreset.perks.Tailoring = pr.perks.Tailoring
            end
            --
            if pr.perks.Aiming == "RAND" then
                resultPreset.perks.Aiming = ZombRand(0, 6)
            else
                resultPreset.perks.Aiming = pr.perks.Aiming
            end
            --
            if pr.perks.Reloading == "RAND" then
                resultPreset.perks.Reloading = ZombRand(0, 6)
            else
                resultPreset.perks.Reloading = pr.perks.Reloading
            end
            --
            if pr.perks.Fishing == "RAND" then
                resultPreset.perks.Fishing = ZombRand(0, 6)
            else
                resultPreset.perks.Fishing = pr.perks.Fishing
            end
            --
            if pr.perks.Trapping == "RAND" then
                resultPreset.perks.Trapping = ZombRand(0, 6)
            else
                resultPreset.perks.Trapping = pr.perks.Trapping
            end
            --
            if pr.perks.PlantScavenging == "RAND" then
                resultPreset.perks.PlantScavenging = ZombRand(0, 6)
            else
                resultPreset.perks.PlantScavenging = pr.perks.PlantScavenging
            end
            -------------
            if pr.outfit == "RAND" then
                resultPreset.outfit = "RAND"
            else
                resultPreset.outfit = pr.outfit
            end
            --
            resultPreset.items = {}
            for i, item in ipairs(pr.items) do
                if item == "RAND_WEAPON" then
                    table.insert(resultPreset.items, random_weapon_LIST[ZombRand(1, (#random_weapon_LIST + 1))])
                else
                    table.insert(resultPreset.items, item)
                end
            end

            resultPreset.attachments = {}
            resultPreset.itemsInArms = {}

            return resultPreset
        end 
    end

    return resultPreset
end