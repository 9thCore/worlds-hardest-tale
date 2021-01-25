lunajson = require("Libraries/lunajson")
key = require("Libraries/keyboard")

local sprites = {} --stores all sprites to make it easy to hide/show them

bannedNames = {
	"CON",
	"PRN",
	"AUX",
	"NUL",
	"LST"
}

for i=1,10 do
	table.insert(bannedNames, "COM" .. (i-1))
	table.insert(bannedNames, "LPT" .. (i-1))

end

musicList = {
	"Positive Force",
	"Potential For Anything",
	"Predestined Fate",
	"Pressure Cooker",
	"Pushing Onwards",
	"Snayk - Growing On Me"
}

allFolders = Misc.ListDir("Levels", true) --Gets all of the directories in the Levels folder (just in case somebody puts their levels in there).
allFiles = Misc.ListDir("Levels", false) --This gets all of the files in the Levels folder.
linkFiles = {}
levelFiles = {}
allJsonFiles = {}

local music = 6 --stores the current music id

for _,fileName in ipairs(allFiles) do

	local file = Misc.OpenFile("Levels/" .. fileName, "r")

	if fileName:sub(-5) == ".json" then

		local lines = file.ReadLines()

		fullString = ""

		for _,l in ipairs(lines) do
			fullString = fullString .. l

		end

		local json = lunajson.decode(fullString)

		if json["tiles"] then
			table.insert(levelFiles, {file, fileName})

		else
			table.insert(linkFiles, {file, fileName})
			table.insert(allJsonFiles, {file, fileName})

		end

	end

end

for _,dir in ipairs(allFolders) do

	local showLvls = true

	local allFilesInDir = Misc.ListDir("Levels/" .. dir, false)

	for _,fileName in ipairs(allFilesInDir) do

		if fileName == "aaa_hidelevels" then showLvls = false end

		local file = Misc.OpenFile("Levels/" .. dir .. "/" .. fileName, "r")

		if fileName:sub(-5) == ".json" then

			local lines = file.ReadLines()

			fullString = ""

			for _,l in ipairs(lines) do
				fullString = fullString .. l

			end

			local json = lunajson.decode(fullString)

			if json["tiles"] then
				if showLvls then
					table.insert(levelFiles, {file, fileName, dir .. "/"})

				end

			else
				table.insert(linkFiles, {file, fileName, dir .. "/"})
				table.insert(allJsonFiles, {file, fileName, dir .. "/"})

			end

		end

	end

end

for _,f in ipairs(levelFiles) do table.insert(allJsonFiles, f) end --this is so that the levelpacks always appear first

function reloadAllLevels()

	allFolders = Misc.ListDir("Levels", true) --Gets all of the directories in the Levels folder (just in case somebody puts their levels in there).
	allFiles = Misc.ListDir("Levels", false) --This gets all of the files in the Levels folder.
	linkFiles = {}
	levelFiles = {}
	allJsonFiles = {}
	
	for _,fileName in ipairs(allFiles) do

		local file = Misc.OpenFile("Levels/" .. fileName, "r")

		if fileName:sub(-5) == ".json" then

			local lines = file.ReadLines()

			fullString = ""

			for _,l in ipairs(lines) do
				fullString = fullString .. l

			end

			local json = lunajson.decode(fullString)

			if json["tiles"] then
				table.insert(levelFiles, {file, fileName})

			else
				table.insert(linkFiles, {file, fileName})
				table.insert(allJsonFiles, {file, fileName})

			end

		end

	end

	for _,dir in ipairs(allFolders) do

		local allFilesInDir = Misc.ListDir("Levels/" .. dir, false)

		for _,fileName in ipairs(allFilesInDir) do

			if fileName == "aaa_hidelevels" then showLvls = false end

			local file = Misc.OpenFile("Levels/" .. dir .. "/" .. fileName, "r")

			if fileName:sub(-5) == ".json" then

				local lines = file.ReadLines()

				fullString = ""

				for _,l in ipairs(lines) do
					fullString = fullString .. l

				end

				local json = lunajson.decode(fullString)

				if json["tiles"] then
					table.insert(levelFiles, {file, fileName, dir .. "/"})

				else
					table.insert(linkFiles, {file, fileName, dir .. "/"})
					table.insert(allJsonFiles, {file, fileName, dir .. "/"})

				end

			end

		end

	end

	for _,f in ipairs(levelFiles) do table.insert(allJsonFiles, f) end --this is so that the levelpacks always appear first

end

local exitTimer = 0

--The first arg is the text that should be displayed, the second is the path to the lua script
local function CreateButton(text, path)

	local button = {}

	button.path = path

	if path ~= "QUIT" and not Misc.FileExists("Lua/" .. path) then
		button.path = "MISSING"
	end

	local text = text or "INVALID_TEXT"

	button.text = CreateText("[instant][effect:none]" .. text, {320, 400}, 300, "ui")

	button.text.HideBubble()
	button.text.color = {1,1,1}
	button.text.progressmode = "none"
	button.text.Scale(2,2)

	table.insert(sprites, button.text)

	return button
end

local actionCooldown = 0 --Used for not checking for inputs right as a player hit "Go Back" or something

--hide stuff
CreateLayer("cover", "Top", false)

--ui stuff
CreateLayer("ui", "cover", false)

--checkpoint layer
CreateLayer("checkL", "ui", true)

local cover = CreateSprite("black", "cover")
cover.MoveToAbs(320, 240)

local title = CreateText("[instant][effect:none]The World's Hardest Tale", {320, 400}, 300, "ui")
title.HideBubble()
title.color = {1,1,1}
title.progressmode = "none"
title.Scale(2,2)
title.absx = 320 - title.GetTextWidth()

table.insert(sprites, title)

local heart = CreateSprite("ut-heart", "cover")
heart.color = {1,0,0}
heart.Scale(1.5, 1.5)
heart.absx = 250

table.insert(sprites, heart)

local heartBtn = 1

buttons = {
	CreateButton("Play Levels", "Libraries/playlevels.lua"),
	CreateButton("Level Editor", "Libraries/leveleditor.lua"),
	CreateButton("Level Pack Editor", "Libraries/packeditor.lua"),
	CreateButton("Quit", "QUIT") --Special case for the quit button because I just like torturing myself
}

buttonScripts = {} --used for storing and accessing the lua script files (the files that buttons point to)

for i=1,#buttons do
	local btn = buttons[i]

	btn.text.absx = 280
	btn.text.absy = 280 - (i-1)*50

	if btn.path ~= "QUIT" and btn.path ~= "MISSING" then

		local file = require(btn.path:match("(.+)%..+"))

		table.insert(buttonScripts, file)

	elseif btn.path == "QUIT" then

		table.insert(buttonScripts, "QUIT")

	elseif btn.path == "MISSING" then

		table.insert(buttonScripts, "MISSING")

	end

end

local cover2 = CreateSprite("black", "ui")
cover2.MoveToAbs(320, 240)
cover2.alpha = 0

local function Exit()
	if exitTimer > 0 then

		if actionCooldown == 0 and Input.GetKey("Escape") == 1 then exitTimer = 60*3.75 end

		if exitTimer == 1 then
			Audio.PlaySound("seeya")

		end

		if exitTimer == (60*3.75) then
			State("DONE")

		end

		cover2.alpha = cover2.alpha + 1/(60*3.5)

		Audio.Volume(0.75 - (exitTimer/(60*3.5))*0.75)

		exitTimer = exitTimer + 1

	end
end

local musicChangeTimer = 0

function changeMusic(id)
	if id ~= music then
		musicChangeTimer = 1
		music = id

	end
end

function Update()

	if Input.GetKey("R") == 1 then

		reloadAllLevels()

		DEBUG("Reloaded all levels.")

	end

	Exit()

	if musicChangeTimer > 0 then

		musicChangeTimer = musicChangeTimer + 1

		if musicChangeTimer < 30 then

			Audio.Volume(0.75 - (musicChangeTimer/30)*0.75)

		elseif musicChangeTimer == 30 then

			Audio.LoadFile(musicList[music])

		else

			Audio.Volume(((musicChangeTimer-30)/30)*0.75)

		end

	end

	Player.SetMaxHPShift(1, 10000, false, false, false)

	local areOtherScriptsActive = false

	for _,scr in ipairs(buttonScripts) do
		if scr ~= "QUIT" and scr ~= "MISSING" then

			if scr.getActive() then

				scr.Update()

				for _,spr in ipairs(sprites) do
					spr.alpha = 0
				end

				areOtherScriptsActive = true
				actionCooldown = 10 --10 frames
				break
			end

		end

	end

	if actionCooldown > 0 then actionCooldown = actionCooldown - 1 end

	if exitTimer == 0 and not areOtherScriptsActive then

		Discord.SetDetails("Chilling in the main menu")

		if Input.GetKey("Escape") == 1 and actionCooldown == 0 then exitTimer = 1 actionCooldown = 10 end

		for _,spr in ipairs(sprites) do
			spr.alpha = 1
		end

		--input check
		if actionCooldown == 0 and Input.Down == 1 then
			heartBtn = heartBtn + 1

			if heartBtn > #buttons then heartBtn = 1 end

			Audio.PlaySound("menuconfirm")

		elseif actionCooldown == 0 and Input.Up == 1 then
			heartBtn = heartBtn - 1

			if heartBtn < 1 then heartBtn = #buttons end

			Audio.PlaySound("menuconfirm")

		elseif actionCooldown == 0 and Input.Confirm == 1 then
			Audio.PlaySound("menuconfirm")

			local btn = buttons[heartBtn]
			local scr = buttonScripts[heartBtn]

			if btn.path == "QUIT" then
				exitTimer = 1
				actionCooldown = 10
			elseif btn.path == "MISSING" then
				DEBUG("The file path is incorrect! Make sure that it points to an existing file.")
			else
				buttonScripts[heartBtn].setActive(true)
			end
		end
	end

	--updato hearto positiono
	heart.absy = 292 - (heartBtn-1)*50

end