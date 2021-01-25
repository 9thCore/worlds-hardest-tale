-- A basic encounter script skeleton you can copy and modify for your own creations.

music = "Snayk - Growing On Me" --Either OGG or WAV. Extension is added automatically. Uncomment for custom music.
encountertext = "Poseur strikes a pose!" --Modify as necessary. It will only be read out in the action select screen.
nextwaves = {}
wavetimer = 4.0
arenasize = {155, 130}
unescape = true
require "Libraries/tableprint"
require "Libraries/Preload"

local mainMenuThing = require("Libraries/mainmenu")

enemies = {
"poseur"
}

enemypositions = {
{0, 0}
}

-- A custom list with attacks to choose from. Actual selection happens in EnemyDialogueEnding(). Put here in case you want to use it.
possible_attacks = {}

function EncounterStarting()

    -- If you want to change the game state immediately, this is the place.

    Discord.SetName("Playing The World's Hardest Tale")

    Player.SetControlOverride(true)

    if CYFversion < "0.6.5" or CYFversion == "1.0" then
        error("This mod was meant to be played with CYF 0.6.5 (or higher, but I can't guarantee it'll work 100%)!")

    elseif CYFversion > "0.6.5" then
        DEBUG("This mod was developed in CYF 0.6.5. There may be a chance that this mod won't work correctly with this version.")

    end

    State("NONE")
end

function EnemyDialogueStarting()
    -- Good location for setting monster dialogue depending on how the battle is going.
end

function EnemyDialogueEnding()
    -- Good location to fill the 'nextwaves' table with the attacks you want to have simultaneously.
    nextwaves = { possible_attacks[math.random(#possible_attacks)] }
end

function DefenseEnding() --This built-in function fires after the defense round ends.
    encountertext = RandomEncounterText() --This built-in function gets a random encounter text from a random enemy.
end

function HandleSpare()
    State("ENEMYDIALOGUE")
end

function HandleItem(ItemID)
    BattleDialog({"Selected item " .. ItemID .. "."})
end