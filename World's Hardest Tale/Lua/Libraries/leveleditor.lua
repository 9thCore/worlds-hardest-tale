self = {}

local sprites = {} --stores all sprites to make it easy to hide/show them
local editorUI = {} --editor ui
local enemySprites = {} --stores all ENEMY sprites... dont ask
local names = {} --is used for making the list of levels

local initialMenuSprites = {} --stores the sprites that show up when you initially enter the editor (new & load)
local initialMenuSprites2 = {} --stores the sprites that show up when you make a new level

local placedSprites = {} --stores all placed sprites (to get their ids when saving)
local walls = {} --used for updating all wall sprites

local allEnemyPoints = {} --stores all enemy movement points
local enemyPoints = {} --stores all enemy movement points of the selected enemy only

local isActivated = false

local enemyID = 1

local editingStage = 1 --the stage (1st is the initial menu, 2nd is inputting level name (when selecting New Level), 3rd is selecting level (when selecting Load Level), 4th is editing)

local editingMode = 1 --1 is normal placing, 2 is click on enemy and edit its path
local editingEnemy = {} --stores the x and y positions of an enemy if it's being edited

local selectedTile = 1 --defaults to wall

local tiles = {}

--All things for determining which level to load
local totalPageCount = 1
local page = 1
local pos2 = 1

local levelCountOnPage = 0 --How many levels are on this page.
local pageLimit = 6 --The limit on the amount of levels per page.

totalPageCount = math.floor(#levelFiles/pageLimit+1)

local function setLevelCount()
	if page > #levelFiles / pageLimit then
		levelCountOnPage = #levelFiles % pageLimit
	else
		levelCountOnPage = pageLimit
	end
end

local levelName = "Unnamed Level " .. #levelFiles+1

local playerStartPoint --stores the player start point

local pos = 1

local cooldown = 0
local keyHold = 10

for i=1,1200 do table.insert(tiles, 0) end

for i=1,6 do
	local txtobj = CreateText("[instant][effect:none]bad thing occured", {280, 330 - i*40}, 300, "ui")
	txtobj.alpha = 0
	txtobj.HideBubble()
	txtobj.progressmode = "none"
	txtobj.Scale(2,2)

	table.insert(names, txtobj)
end

local hologram = CreateSprite("Walls/single", "heartL")
hologram.alpha = 0

table.insert(editorUI, hologram)

local back = CreateText("[instant][effect:none]Go Back", {280, 280}, 300, "ui")
back.alpha = 0
back.HideBubble()
back.progressmode = "none"
back.Scale(2,2)

table.insert(initialMenuSprites, back)

CreateLayer("top_ui", "heartL", false)

local posText = CreateText("[instant][effect:none]X: Y: ", {540, 456}, 300, "top_ui")
posText.alpha = 0
posText.HideBubble()
posText.progressmode = "none"
posText.Scale(2,2)

table.insert(editorUI, posText)

local speedT = CreateText("[instant][effect:none]Speed: ", {1, 8}, 300, "top_ui")
speedT.alpha = 0
speedT.HideBubble()
speedT.progressmode = "none"
speedT.Scale(2,2)

table.insert(editorUI, speedT)

local modeT = CreateText("[instant][effect:none]Mode: ", {1, 8}, 300, "top_ui")
modeT.alpha = 0
modeT.HideBubble()
modeT.progressmode = "none"

table.insert(editorUI, modeT)

local helpReminder = CreateText("[instant][effect:none]Press H and J for help!", {320, 8}, 300, "top_ui")
helpReminder.alpha = 0
helpReminder.HideBubble()
helpReminder.progressmode = "none"
helpReminder.absx = 320 - helpReminder.GetTextWidth()/2

table.insert(editorUI, helpReminder)

local btn1 = CreateText("[instant][effect:none]New Level", {280, 240}, 300, "ui")
btn1.alpha = 0
btn1.HideBubble()
btn1.progressmode = "none"
btn1.Scale(2,2)

table.insert(initialMenuSprites, btn1)

local btn2 = CreateText("[instant][effect:none]Load Level", {280, 200}, 300, "ui")
btn2.alpha = 0
btn2.HideBubble()
btn2.progressmode = "none"
btn2.Scale(2,2)

table.insert(initialMenuSprites, btn2)

local heart = CreateSprite("ut-heart", "cover")
heart.alpha = 0
heart.color = {1,0,0}
heart.Scale(1.5, 1.5)
heart.absx = 250

table.insert(initialMenuSprites, heart)

local title = CreateText("[instant][effect:none]Level Editor", {320, 400}, 300, "ui")
title.alpha = 0
title.HideBubble()
title.progressmode = "none"
title.Scale(2,2)
title.absx = 320 - title.GetTextWidth()

table.insert(initialMenuSprites, title)


local title3 = CreateText("[instant][effect:none]Input a name\nfor the level", {320, 400}, 300, "ui")
title3.alpha = 0
title3.HideBubble()
title3.progressmode = "none"
title3.Scale(2,2)
title3.absx = 320 - title3.GetTextWidth()

table.insert(initialMenuSprites2, title3)

local input = CreateText("[instant][effect:none]", {320, 240}, 300, "ui")
input.alpha = 0
input.HideBubble()
input.progressmode = "none"
input.Scale(2,2)
input.absx = 320 - title.GetTextWidth()

table.insert(initialMenuSprites2, input)

local title2 = CreateText("[instant][effect:none]Select a level", {320, 440}, 300, "ui")
title2.alpha = 0
title2.HideBubble()
title2.progressmode = "none"
title2.Scale(2,2)
title2.absx = 320 - title2.GetTextWidth()


local back2 = CreateText("[instant][effect:none]Go Back", {280, 330}, 300, "ui")
back2.alpha = 0
back2.HideBubble()
back2.progressmode = "none"
back2.Scale(2,2)

local pageText = CreateText("[instant][effect:none]Page ", {280, 370}, 300, "ui")
pageText.alpha = 0
pageText.HideBubble()
pageText.progressmode = "none"
pageText.Scale(2,2)

local pageText2 = CreateText("[instant][effect:none]Press arrow keys to change page", {90, 410}, 500, "ui")
pageText2.alpha = 0
pageText2.HideBubble()
pageText2.progressmode = "none"
pageText2.Scale(1.5,1.5)

local heart2 = CreateSprite("ut-heart", "cover")
heart2.alpha = 0
heart2.color = {1,0,0}
heart2.Scale(1.5, 1.5)
heart2.absx = 250

local helpText = [[
[color:000000]The editor has some neat keybinds:

[color:00c000][Esc][color:000000] Exit out of the editor (this doesn't save your level!)
[color:00c000][H][color:000000] Show this panel (and close it)
[color:00c000][J][color:000000] Show the enemy help panel (and close it)
[color:00c000][S][color:000000] Save your level
[color:00c000][1-7][color:000000] Allows you to select a tile
Tiles are as follows:
1-Air      |  5-Coin      |  9-Key Wall
2-Wall     |  6-Checkpoint
3-Player  |  7-Endpoint
4-Enemy  |  8-Key
[color:00c000][M][color:000000] Switch music
[color:00c000][E][color:000000] Switch editing mode
The editing mode defaults to normal: being able to place tiles.
However, by pressing E, you can switch to enemy-editing! (and vice-versa)
The enemy-editing mode is quite complex so it's covered in another panel.
[color:00c000][Left-Click][color:000000] Place your selected tile.
(You can hold it down!)
]]

local enemyHelpText = [[
[color:000000]While in enemy-editing mode, you can select an enemy ([color:00c000]Left-Click[color:000000] on it) and:
[color:00c000][Left-Click][color:000000] Add enemy point (if you want to add an enemy point on top of another enemy hold [color:00c000][Left or Right Control][color:000000]!)
[color:00c000][Right-Click][color:000000] Remove enemy point
[color:00c000][C][color:000000] Change the enemy's color (blue, orange or white. they impact gameplay!)
[color:00c000][B][color:000000] Change the enemy's movement mode (continuous or back-and-forth)
[color:00c000][Up or Down Arrow][color:000000] Add/Remove to the enemy's speed respectively.
If you hold down [color:00c000][Left or Right Control][color:000000] while changing the speed, you'll change it by 0.05.
If you hold down [color:00c000][Left or Right Alt][color:000000] while changing the speed, you'll change it by 0.1.
]]

CreateLayer("helpLayer", "VeryHighest", true)

local saveT = CreateText("[instant][effect:none]This should absolutely NOT appear.", {540, 456}, 300, "top_ui")
saveT.color = {1,1,0}
saveT.alpha = 0
saveT.HideBubble()
saveT.progressmode = "none"
saveT.Scale(2,2)
saveT.MoveToAbs(320 - saveT.GetTextWidth(), 340)

local help = 0 --0 is not active, 1 is the helpText, 2 is enemyHelpText

local musicID = 1 --used for saving the music

local helpT = CreateText("", {90, 430}, 500, "helpLayer")
helpT.SetTail("none", "50%")
helpT.HideBubble()
helpT.alpha = 0
helpT.progressmode = "none"

for _,spr in ipairs(sprites) do
	spr.alpha = 0

end

local function updatePoints(tile, added, removedID)
	
	local tabl = {}

	for _,e in ipairs(enemyPoints) do
		if e.isactive then
			table.insert(tabl, {e.absx, e.absy})

		end

	end

	allEnemyPoints[tile["index"]][2] = tile["speed"]
	allEnemyPoints[tile["index"]][3] = tabl
	allEnemyPoints[tile["index"]][4] = tile.sprite.color

end

local function checkSide(tls, side, check, i)

	local diff

	if side == 1 then diff = 41
	elseif side == 2 then diff = 40
	elseif side == 3 then diff = 39
	elseif side == 4 then diff = 1
	elseif side == 5 then diff = -1
	elseif side == 6 then diff = -39
	elseif side == 7 then diff = -40
	elseif side == 8 then diff = -41
	end

	if tls[i-diff] == nil then return true
	elseif i%40==1 and side == 4 then return true
	elseif i%40==0 and side == 5 then return true
	else return tls[i-diff] == check end

end

local function getTileAt(x, y)
	--search through all placed sprites, if the tile is found then return it
	for _,spr in ipairs(placedSprites) do

		if spr.absx == x and spr.absy == y then
			return spr

		end

	end

	--if it didnt find anything, just return nil
	return nil

end

local function updateWallSprites()

	local tls = tiles

	for ind,wall in ipairs(walls) do

		local i

		if wall.isactive then

			i = (30 - (wall.absy-8)/16) * 40 + (wall.absx-8)/16 - 39

			local rotation = 0
			local filename = "single"

			if not checkSide(tls, 2, 1, i) and not checkSide(tls, 4, 1, i) and not checkSide(tls, 5, 1, i) and checkSide(tls, 7, 1, i) then
				filename = "pillar_top"

			elseif checkSide(tls, 2, 1, i) and not checkSide(tls, 4, 1, i) and not checkSide(tls, 5, 1, i) and not checkSide(tls, 7, 1, i) then
				filename = "pillar_top"
				rotation = 180

			elseif not checkSide(tls, 2, 1, i) and not checkSide(tls, 4, 1, i) and checkSide(tls, 5, 1, i) and not checkSide(tls, 7, 1, i) then
				filename = "pillar_top"
				rotation = 90

			elseif not checkSide(tls, 2, 1, i) and checkSide(tls, 4, 1, i) and not checkSide(tls, 5, 1, i) and not checkSide(tls, 7, 1, i) then
				filename = "pillar_top"
				rotation = 270

			elseif not checkSide(tls, 2, 1, i) and not checkSide(tls, 4, 1, i) and not checkSide(tls, 5, 1, i) and not checkSide(tls, 7, 1, i) then
				filename = "single"

			elseif not checkSide(tls, 2, 1, i) and checkSide(tls, 4, 1, i) and checkSide(tls, 5, 1, i) and checkSide(tls, 7, 1, i) then
				filename = "side"

			elseif checkSide(tls, 2, 1, i) and not checkSide(tls, 4, 1, i) and checkSide(tls, 5, 1, i) and checkSide(tls, 7, 1, i) then
				filename = "side"
				rotation = 90

			elseif checkSide(tls, 2, 1, i) and checkSide(tls, 4, 1, i) and checkSide(tls, 5, 1, i) and not checkSide(tls, 7, 1, i) then
				filename = "side"
				rotation = 180

			elseif checkSide(tls, 2, 1, i) and checkSide(tls, 4, 1, i) and not checkSide(tls, 5, 1, i) and checkSide(tls, 7, 1, i) then
				filename = "side"
				rotation = 270

			elseif not checkSide(tls, 2, 1, i) and not checkSide(tls, 4, 1, i) and checkSide(tls, 5, 1, i) and checkSide(tls, 7, 1, i) then
				filename = "edge"

			elseif not checkSide(tls, 2, 1, i) and checkSide(tls, 4, 1, i) and not checkSide(tls, 5, 1, i) and checkSide(tls, 7, 1, i) then
				filename = "edge"
				rotation = -90

			elseif checkSide(tls, 2, 1, i) and checkSide(tls, 4, 1, i) and not checkSide(tls, 5, 1, i) and not checkSide(tls, 7, 1, i) then
				filename = "edge"
				rotation = -180

			elseif checkSide(tls, 2, 1, i) and not checkSide(tls, 4, 1, i) and checkSide(tls, 5, 1, i) and not checkSide(tls, 7, 1, i) then
				filename = "edge"
				rotation = -270

			elseif checkSide(tls, 2, 1, i) and not checkSide(tls, 4, 1, i) and not checkSide(tls, 5, 1, i) and checkSide(tls, 7, 1, i) then
				filename = "pillar_middle"

			elseif not checkSide(tls, 2, 1, i) and checkSide(tls, 4, 1, i) and checkSide(tls, 5, 1, i) and not checkSide(tls, 7, 1, i) then
				filename = "pillar_middle"
				rotation = 90

			elseif checkSide(tls, 2, 1, i) and checkSide(tls, 4, 1, i) and checkSide(tls, 5, 1, i) and checkSide(tls, 7, 1, i) then
				filename = "inside"

			end

			wall.Set("Walls/" .. filename)
			wall.rotation = rotation
		end

	end

end

local function getFullStringFromFile(file)
	local lines = file.readLines()

	--transform the file into one single string
	local fullString = ""

	for i=1,#lines do
		fullString = fullString .. lines[i]
	end

	--return it
	return fullString
end

local function createCheckpoint(x, y)
	
	local check = CreateSprite("checkpoint", "checkL")

	check.MoveToAbs(x, y)
	
	check["id"] = 5

	table.insert(sprites, check)
	table.insert(placedSprites, check)

end

local function createEndpoint(x, y)
	
	local endp = CreateSprite("endpoint", "checkL")

	endp.MoveToAbs(x, y)
	
	endp["id"] = 6

	table.insert(sprites, endp)
	table.insert(placedSprites, endp)

end

local function createEnemy(x, y, points)
	
	local enemy = CreateProjectileAbs("enemy", x, y, "ui")

	enemy["index"] = #allEnemyPoints + 1 --the index of the enemy in the allEnemyPoints table

	if points and points[enemy["index"]] and points[enemy["index"]][2] then
		enemy["speed"] = points[enemy["index"]][2]

	else
		enemy["speed"] = 2

	end

	enemy["id"] = 3

	if points and points[enemy["index"]] then
		table.insert(allEnemyPoints, points[enemy["index"]])

	else
		table.insert(allEnemyPoints, {0, 2, {}, {1, 1, 1}})

	end

	enemy.sprite.color = allEnemyPoints[enemy["index"]][4] or {1, 1, 1}

	table.insert(enemySprites, enemy)
	table.insert(placedSprites, enemy)

end

local function createCoin(x, y)
	
	local coin = CreateSprite("coin", "ui")

	coin.MoveToAbs(x, y)
	coin["id"] = 4

	table.insert(sprites, coin)
	table.insert(placedSprites, coin)

end

local function createKey(x, y)
	
	local key = CreateSprite("key", "ui")

	key.MoveToAbs(x, y)
	key["id"] = 7

	table.insert(sprites, key)
	table.insert(placedSprites, key)

end

local function createKeyWall(x, y)
	
	local keyWall = CreateSprite("keywall", "ui")

	keyWall.MoveToAbs(x, y)
	keyWall["id"] = 8

	table.insert(sprites, keyWall)
	table.insert(placedSprites, keyWall)

end

local function createStartPoint(x, y)

	if playerStartPoint then
		playerStartPoint.Remove()
	end

	local start = CreateSprite("ut-heart", "ui")
	start.color = {1,0,0}
	start["id"] = 2
	start.MoveToAbs(x, y)

	playerStartPoint = start

end

local function createWall(x, y)

	local wall = CreateSprite("Walls/single", "ui")
	wall["id"] = 1
	wall.MoveToAbs(x, y)

	table.insert(sprites, wall)
	table.insert(placedSprites, wall)
	table.insert(walls, wall)

end

local saveText = ""

local function Save(startTime)

	local dir = ""

	for _,lvl in ipairs(levelFiles) do

		if lvl[2] == levelName .. ".json" then

			if lvl[3] then dir = lvl[3] break end

		end

	end

	local file = Misc.OpenFile("Levels/" .. dir .. levelName .. ".json", "w")

	file.Delete()

	file.Write("{\n\"music\": " .. musicID .. ",\n\"tiles\": [\n")

	local tilesT = ""

	local ePointsT = ""

	for i=1,1200 do

		if i ~= 1200 then
			tilesT = tilesT .. tiles[i] .. ","
		else
			tilesT = tilesT .. tiles[i]
		end

		if tiles[i] == 3 then

			local enemy = getTileAt((i-1)%40*16+8, 480 - math.floor((i-1)/40)*16 - 8)

			if enemy["index"] and allEnemyPoints[enemy["index"]] then

				local ePoints = allEnemyPoints[enemy["index"]]

				local str = lunajson.encode(ePoints)
			
				ePointsT =  ePointsT .. str .. ",\n"

			end

		end

		if i%40 == 0 then tilesT = tilesT .. "\n" end

	end

	file.Write(tilesT)

	file.Write("],\n\"enemyPoints\": [\n")

	file.Write(ePointsT:sub(1, -3))

	file.Write("\n]\n")

	file.Write("}\n")

	Audio.PlaySound("save")

	saveT.alpha = 1
	saveText = "[instant][effect:none]Saved to \"" .. levelName .. ".json\". Took " .. tostring(os.clock() - startTime):sub(1,5) .. " seconds."
	saveT.absx = 320 - saveT.GetTextWidth()

end

for _,spr in ipairs(initialMenuSprites) do
	spr.alpha = 0
end

for _,spr in ipairs(initialMenuSprites2) do
	spr.alpha = 0
end

local function Clamp(val, min, max)
	return math.min(math.max(val, min), max)
end

local lastEditingEnemy = {}

local speedTimer = 0

function self.Update()

	saveT.alpha = saveT.alpha - 1/90
	saveT.SetText(saveText)
	saveT.absx = 320 - saveT.GetTextWidth()

	if speedTimer > 0 then speedTimer = speedTimer - 1 end
	if cooldown > 0 then cooldown = cooldown - 1 end

	local mouseX = Clamp(math.floor(Input.MousePosX/16)*16+8, 8, 632)
	local mouseY = Clamp(math.floor(Input.MousePosY/16)*16+8, 8, 472)

	names[1].SetText("")
	names[2].SetText("")
	names[3].SetText("")
	names[4].SetText("")
	names[5].SetText("")
	names[6].SetText("")

	setLevelCount()

	heart.absy = 332 - pos*40

	if Input.GetKey("Escape") == 1 then

		saveT.SetText("")
		saveT.alpha = 0

		Audio.PlaySound("menuconfirm")

		if editingStage == 1 then
			isActivated = false

		else

			if editingStage == 4 then
				changeMusic(6)
				levelName = "Unnamed Level " .. #levelFiles+1
				editingMode = 1
				selectedTile = 1

				for i=1,1200 do table.insert(tiles, 0) end

				for _,spr in ipairs(sprites) do
					spr.Remove()

				end

				for _,spr in ipairs(enemySprites) do
					spr.Remove()

				end

				if playerStartPoint then playerStartPoint.Remove() playerStartPoint = nil end

				musicID = 1

				allEnemyPoints = {}
				editingEnemy = {}
				enemySprites = {}
				sprites = {}
				placedSprites = {}
				walls = {}

			end

			editingStage = 1
		end

	end

	pageText.SetText("")

	if editingStage == 1 then

		if Input.Up == 1 then
			Audio.PlaySound("menuconfirm")
			pos = pos - 1

			if pos < 1 then pos = 3 end

		elseif Input.Down == 1 then
			Audio.PlaySound("menuconfirm")
			pos = pos + 1

			if pos > 3 then pos = 1 end
		elseif Input.Confirm == 1 then
			cooldown = 10
			Audio.PlaySound("menuconfirm")
			if pos == 1 then isActivated = false editingStage = 1
			else
				
				tiles = {}
				for i=1,1200 do table.insert(tiles, 0) end

				editingStage = pos

			end
		end

	elseif editingStage == 2 and cooldown <= 0 then

		input.SetText("[instant][effect:none]" .. levelName)
		input.absx = 320 - input.GetTextWidth()

		levelName = key.DetectInput(levelName)

		if Input.GetKey("Return") == 1 then

			changeMusic(1)

			--if the level name is banned/disallowed in Windows, it'll revert it back to a normal name.
			for _,n in ipairs(bannedNames) do
				if levelName == n then
					DEBUG("That name is banned! The level name has been reverted to \"Unnamed Level " .. #levelFiles+1 .. "\"")
					levelName = "Unnamed Level " .. #levelFiles+1
					break

				end

			end

			if levelName:sub(-1) == " " then levelName = levelName:sub(1, -2) end

			if levelName == "" then levelName = "Unnamed Level " .. #levelFiles+1 end

			editingStage = 4

			input.SetText("")
			input.alpha = 0

		end

	elseif editingStage == 3 then

		if Input.GetKey("R") == 1 then

			page = Clamp(page, 1, math.ceil(#levelFiles / pageLimit))

			setLevelCount()
			if pos2 > math.min(levelCountOnPage+1, 7) then pos2 = math.min(levelCountOnPage+1, 7) end

		end

		setLevelCount()

		if Input.Up == 1 then
			Audio.PlaySound("menuconfirm")
			pos2 = pos2 - 1

			if pos2 < 1 then pos2 = math.min(levelCountOnPage+1, 7) end

		elseif Input.Down == 1 then
			Audio.PlaySound("menuconfirm")
			pos2 = pos2 + 1

			if pos2 > math.min(levelCountOnPage+1, 7) then pos2 = 1 end

		elseif Input.Left == 1 then
			Audio.PlaySound("menuconfirm")
			page = page - 1

			if page < 1 then page = math.ceil(#levelFiles / pageLimit) end
			setLevelCount()

			if pos2 > math.min(levelCountOnPage+1, 7) then pos2 = math.min(levelCountOnPage+1, 7) end

		elseif Input.Right == 1 then
			Audio.PlaySound("menuconfirm")
			page = page + 1

			if page > math.ceil(#levelFiles / pageLimit) then page = 1 end
			setLevelCount()

			if pos2 > math.min(levelCountOnPage+1, 7) then pos2 = math.min(levelCountOnPage+1, 7) end

		elseif Input.Confirm == 1 then --OPEN / LOAD A LEVEL IN THE EDITOR--
			cooldown = 10
			Audio.PlaySound("menuconfirm")

			if pos2 == 1 then editingStage = 1
			else

				local file = levelFiles[pos2-1 + (page-1)*pageLimit][1]

				levelName = levelFiles[pos2-1 + (page-1)*pageLimit][2]:sub(1, -6)

				local pos = lunajson.decode(getFullStringFromFile(file))

				musicID = pos["music"] or 1
				musicID = Clamp(musicID, 1, #musicList)

				changeMusic(musicID)

				tiles = pos["tiles"]

				for i,tile in ipairs(pos["tiles"]) do

					realX = (i-1)%40
					realY = math.floor((i-1)/40)

					if tile == 1 then
						createWall(realX*16 + 8, 480 - realY*16 - 8)

					elseif tile == 2 then
						createStartPoint(realX*16 + 8, 480 - realY*16 - 8)

					elseif tile == 3 then
						createEnemy(realX*16 + 8, 480 - realY*16 - 8, pos["enemyPoints"])

					elseif tile == 4 then
						createCoin(realX*16 + 8, 480 - realY*16 - 8)

					elseif tile == 5 then
						createCheckpoint(realX*16 + 8, 480 - realY*16 - 8)

					elseif tile == 6 then
						createEndpoint(realX*16 + 8, 480 - realY*16 - 8)

					elseif tile == 7 then
						createKey(realX*16 + 8, 480 - realY*16 - 8)

					elseif tile == 8 then
						createKeyWall(realX*16 + 8, 480 - realY*16 - 8)

					end

				end

				allEnemyPoints = pos["enemyPoints"]

				editingStage = 4

				updateWallSprites()

			end
		end

		heart2.absy = 342 - (pos2-1)*40

		for i=(page-1)*pageLimit+1, math.min(#levelFiles, (page-1)*pageLimit+6) do
			local lvl = levelFiles[i]
			
			names[i - (page-1)*pageLimit].SetText("[instant][effect:none]" .. lvl[2]:match("(.+)%..+"))

		end

		pageText.SetText("[instant][effect:none]Page " .. page)

	elseif editingStage == 4 then --ACTUAL EDITOR LOGIC HERE--

		posText.SetText("[instant][effect:none]X: " .. mouseX .. " Y: " .. mouseY)
		posText.absx = 640 - posText.GetTextWidth()*2

		if playerStartPoint then playerStartPoint.alpha = 1 end

		hologram.alpha = 0.5

		if Input.GetKey("S") == 1 then Save(os.clock()) end

		if Input.GetKey("Alpha1") == 1 then selectedTile = 0 --air
		elseif Input.GetKey("Alpha2") == 1 then selectedTile = 1 --wall
		elseif Input.GetKey("Alpha3") == 1 then selectedTile = 2 --player
		elseif Input.GetKey("Alpha4") == 1 then selectedTile = 3 --enemy
		elseif Input.GetKey("Alpha5") == 1 then selectedTile = 4 --coin
		elseif Input.GetKey("Alpha6") == 1 then selectedTile = 5 --checkpoint
		elseif Input.GetKey("Alpha7") == 1 then selectedTile = 6  --endpoint
		elseif Input.GetKey("Alpha8") == 1 then selectedTile = 7 --key
		elseif Input.GetKey("Alpha9") == 1 then selectedTile = 8 end --key wall

		if Input.GetKey("E") == 1 then Audio.PlaySound("menuconfirm") if editingMode == 1 then editingMode = 2 else editingMode = 1 end editingEnemy = {} end --switch editing mode

		if Input.GetKey("M") == 1 then Audio.PlaySound("menuconfirm") musicID = musicID + 1 if musicID > #musicList then musicID = 1 end changeMusic(musicID) end --switch music

		local hologramSprite = {"empty", "Walls/single", "ut-heart", "enemy", "coin", "checkpoint", "endpoint", "key", "keywall"}

		hologram.Set(hologramSprite[selectedTile+1])

		if selectedTile == 2 then hologram.color = {1, 0, 0} else hologram.color = {1, 1, 1} end

		if editingMode == 1 then
			for _,spr in ipairs(sprites) do
				if spr.isactive then
					spr.alpha = 1
				end
			end

			if playerStartPoint then playerStartPoint.color = {1,0,0} end

			hologram.alpha = 0.5

		else
			for _,spr in ipairs(sprites) do
				if spr.isactive then
					spr.alpha = 0.5
				end
			end

			if playerStartPoint then playerStartPoint.alpha = 0.5 end

			hologram.Set("enemy_overlay")
			hologram.color = {1,1,1}

			posText.color = {1,1,1}

		end

		if Input.GetKey("H") == 1 then
			if help ~= 1 then
				help = 1
				helpT.bubbleHeight = 409
				helpT.ShowBubble()
				helpT.SetText("[instant][effect:none]" .. helpText)

			else
				help = 0
				helpT.SetText("")
				helpT.HideBubble()

			end

		elseif Input.GetKey("J") == 1 then
			if help ~= 2 then
				help = 2
				helpT.bubbleHeight = 284
				helpT.ShowBubble()
				helpT.SetText("[instant][effect:none]" .. enemyHelpText)

			else
				help = 0
				helpT.SetText("")
				helpT.HideBubble()

			end

		end

		if editingMode == 1 and Input.GetKey("Mouse0") > 0 then

			if selectedTile == 0 then

				--special case for the enemies: also remove their movement table from the enemyPoints table
				local tile = getTileAt(mouseX, mouseY)

				if tile and tile["id"] == 3 and tile["index"] <= #allEnemyPoints then
					table.remove(allEnemyPoints, tile["index"])

					for _,enemy in ipairs(enemySprites) do
						if enemy["index"] > tile["index"] then enemy["index"] = enemy["index"] - 1 end

					end

				end

				--replace any tile in this place (where the user clicked with the air tile) with air
				for i,tile in ipairs(placedSprites) do
					if tile.absx == mouseX and tile.absy == mouseY then
						table.remove(placedSprites, i)
						tile.Remove()
						i = i - 1
					end
				end

			else

				if playerStartPoint and playerStartPoint.absx == mouseX and playerStartPoint.absy == mouseY then
					playerStartPoint.Remove()
					playerStartPoint = nil
				end

				local alreadyExisting = false

				--check if there's a tile already here. if there is (and it's the same tile as the selected tile), don't place another tile here.
				--though, if there is a DIFFERENT tile here (different than the selected tile), replace it with the new tile
				for i,tile in ipairs(placedSprites) do
					if tile.isactive and tile.absx == mouseX and tile.absy == mouseY then
						if tile["id"] and tile["id"] == selectedTile then
							alreadyExisting = true
							break

						elseif tile["id"] and tile["id"] ~= selectedTile then
							table.remove(placedSprites, i)
							tile.Remove()
							i = i - 1

						end
					end
				end

				if not alreadyExisting then
					if selectedTile == 1 then

						createWall(mouseX, mouseY)

					elseif selectedTile == 2 then

						for ti,t in ipairs(tiles) do
							if t == 2 then tiles[ti] = 0 end
						end

						createStartPoint(mouseX, mouseY)

					elseif selectedTile == 3 then

						createEnemy(mouseX, mouseY)

						enemyID = enemyID + 1

					elseif selectedTile == 4 then

						createCoin(mouseX, mouseY)

					elseif selectedTile == 5 then

						createCheckpoint(mouseX, mouseY)

					elseif selectedTile == 6 then

						createEndpoint(mouseX, mouseY)

					elseif selectedTile == 7 then

						createKey(mouseX, mouseY)

					elseif selectedTile == 8 then

						createKeyWall(mouseX, mouseY)

					end
				end

			end

			tiles[(30 - (mouseY-8)/16) * 40 + (mouseX-8)/16 - 39] = selectedTile

			updateWallSprites()

		elseif editingMode == 2 and Input.GetKey("Mouse0") == 1 then

			if Input.GetKey("LeftControl") == 0 and Input.GetKey("RightControl") == 0 and tiles[(30 - (mouseY-8)/16) * 40 + (mouseX-8)/16 - 39] == 3 then
				Audio.PlaySound("menuconfirm")

				local tile = getTileAt(mouseX, mouseY)

				local index = tile["index"]

				for _,psprite in ipairs(enemyPoints) do
					psprite.Remove()

				end

				enemyPoints = {}

				local enemyPointsTabl = allEnemyPoints[index]

				for _,pointSet in ipairs(enemyPointsTabl) do

					if type(pointSet) == "table" then

						for _,coords in ipairs(pointSet) do

							if type(coords) == "table" then

								local pSprite = CreateSprite("enemy", "heartL")
								pSprite.color = {1, 1, 0, 0.5}
								pSprite.absx = coords[1]
								pSprite.absy = coords[2]

								table.insert(enemyPoints, pSprite)

							end

						end

					end

				end

				editingEnemy[1] = mouseX
				editingEnemy[2] = mouseY

			elseif editingEnemy[1] then --add enemy point at mouse

				local tile = getTileAt(editingEnemy[1], editingEnemy[2])

				if allEnemyPoints[tile["index"]][1] == 0 or allEnemyPoints[tile["index"]][1] == 1 then

					local pSprite = CreateSprite("enemy", "heartL")
					pSprite.color = {1, 1, 0, 0.5}
					pSprite.absx = mouseX
					pSprite.absy = mouseY

					table.insert(enemyPoints, pSprite)

					updatePoints(tile)

				elseif allEnemyPoints[tile["index"]][1] == 2 then

					for _,p in ipairs(enemyPoints) do
						p.Remove()
						p = nil

					end

					local pSprite = CreateSprite("enemy", "heartL")
					pSprite.color = {1, 1, 0, 0.5}
					pSprite.absx = mouseX
					pSprite.absy = mouseY

					enemyPoints = {pSprite}
					updatePoints(tile)

				end

			end

		elseif editingMode == 2 and Input.GetKey("Mouse1") == 1 then

			if editingEnemy[1] then --remove enemy point at mouse
				local tile = getTileAt(editingEnemy[1], editingEnemy[2])

				for i,pSprite in ipairs(enemyPoints) do
					if pSprite.absx == mouseX and pSprite.absy == mouseY then

						table.remove(enemyPoints, i)

						updatePoints(tile, false, i)

						pSprite.Remove()

						i = i - 1

					end

				end

			end

		end

		hologram.MoveTo(mouseX, mouseY)


		if editingMode == 2 then

			if Input.Cancel == 1 then Audio.PlaySound("menuconfirm") editingEnemy = {} end

			if editingEnemy[1] then
				hologram.absx = editingEnemy[1]
				hologram.absy = editingEnemy[2]

				if Input.GetKey("C") == 1 then

					local enemy = getTileAt(editingEnemy[1], editingEnemy[2])

					if enemy.sprite.color[1] == 1 and enemy.sprite.color[2] == 1 then enemy.sprite.color = {0, 1, 1}
					elseif enemy.sprite.color[1] == 0 and enemy.sprite.color[2] == 1 then enemy.sprite.color = {1, 0.5, 0}
					else enemy.sprite.color = {1, 1, 1}
					end

				end

				if Input.GetKey("B") == 1 then

					local enemy = getTileAt(editingEnemy[1], editingEnemy[2])

					if allEnemyPoints[enemy["index"]][1] == 0 then allEnemyPoints[enemy["index"]][1] = 1
					elseif allEnemyPoints[enemy["index"]][1] == 1 then allEnemyPoints[enemy["index"]][1] = 2 for _,p in ipairs(enemyPoints) do p.Remove() end enemyPoints = {}
					elseif allEnemyPoints[enemy["index"]][1] == 2 then allEnemyPoints[enemy["index"]][1] = 0
					end

				end

			end

			hologram.alpha = 0

			if tiles[(30 - (mouseY-8)/16) * 40 + (mouseX-8)/16 - 39] == 3 then

				hologram.alpha = 1

			end

		end

	end

	if editingEnemy[1] then
		for _,p in ipairs(enemyPoints) do
			if p.isactive then
				p.alpha = 0.5
			end
		end

	else

		for _,p in ipairs(enemyPoints) do
			if p.isactive then
				p.Remove()
			end
		end

		enemyPoints = {}

	end

	for _,t in ipairs({initialMenuSprites, initialMenuSprites2, editorUI}) do

		for _,s in ipairs(t) do
			s.alpha = 0

		end

	end


	if editingStage == 1 then

		for _,s in ipairs(initialMenuSprites) do
			s.alpha = 1

		end

		for _,n in ipairs(names) do
			n.alpha = 0

		end

		back2.alpha = 0
		pageText.alpha = 0
		pageText2.alpha = 0
		heart2.alpha = 0
		title2.alpha = 0

	elseif editingStage == 2 then

		for _,s in ipairs(initialMenuSprites2) do
			s.alpha = 1

		end

		for _,n in ipairs(names) do
			n.alpha = 0

		end

		back2.alpha = 0
		pageText.alpha = 0
		pageText2.alpha = 0
		heart2.alpha = 0
		title2.alpha = 0

	elseif editingStage == 3 then

		for _,n in ipairs(names) do
			n.alpha = 1

		end

		back2.alpha = 1
		pageText.alpha = 1
		pageText2.alpha = 1
		heart2.alpha = 1
		title2.alpha = 1


	elseif editingStage == 4 then

		for _,n in ipairs(names) do
			n.alpha = 0

		end

		back2.alpha = 0
		pageText.alpha = 0
		pageText2.alpha = 0
		heart2.alpha = 0
		title2.alpha = 0

		for _,s in ipairs(editorUI) do

			if s.layer ~= "heartL" then
				if s == posText then
					s.alpha = 0.5

				else
					s.alpha = 1

				end
			else

				local overlappingEnemy = false

				for _,e in ipairs(placedSprites) do
					if e and e.isactive and e["id"] == 3 and e.absx == s.absx and e.absy == s.absy then
						overlappingEnemy = true
						break
					end

				end

				if overlappingEnemy and editingMode == 2 then
					s.alpha = 1
				elseif editingMode == 1 then
					s.alpha = 0.5
				else
					s.alpha = 0
				end

			end

		end

	end

	lastEditingEnemy[1] = editingEnemy[1]
	lastEditingEnemy[2] = editingEnemy[2]

	if editingStage == 4 and editingEnemy[1] then
		speedT.alpha = 1
		modeT.alpha = 1

		local tile = getTileAt(hologram.absx, hologram.absy)

		if speedTimer == 0 then

			local factor = 1

			if Input.GetKey("LeftControl") > 0 or Input.GetKey("RightControl") > 0 then factor = 0.05
			elseif Input.GetKey("LeftAlt") > 0 or Input.GetKey("RightAlt") > 0 then factor = 0.1 end

			if Input.GetKey("UpArrow") > 0 then
				speedTimer = 10
				tile["speed"] = tile["speed"] + factor

			elseif Input.GetKey("DownArrow") > 0 then
				speedTimer = 10
				tile["speed"] = tile["speed"] - factor

			end

		end

		local spdClmpd = Clamp(tile["speed"], 0.1, tile["speed"]+1)

		if allEnemyPoints[tile["index"]][1] ~= 2 then

			tile["speed"] = tonumber(string.format("%.2f", spdClmpd))

		else

			tile["speed"] = tonumber(string.format("%.2f", tile["speed"]))

		end

		speedT.SetText("[instant][effect:none]Speed: " .. tile["speed"])

		local modes = {"Continuous", "Back and forth", "Circle"}

		modeT.SetText("[instant][effect:none]Mode: " .. modes[allEnemyPoints[tile["index"]][1]+1])
		modeT.absx = 632 - modeT.GetTextWidth()

		updatePoints(tile)

	else
		speedT.SetText("")
		modeT.SetText("")

	end

	if editingStage ~= 4 or not isActivated then
		helpT.HideBubble()
		helpT.SetText("")

	end

	if not isActivated then
		for _,s in ipairs(initialMenuSprites) do
			s.alpha = 0

		end

	end

end

function self.getActive()
	return isActivated
end

function self.setActive(bool)
	if type(bool) ~= "boolean" then bool = false end

	isActivated = bool

	Discord.SetDetails("Making a level")
end

return self