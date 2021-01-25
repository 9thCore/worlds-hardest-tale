self = {}

local sprites = {} --stores all sprites to make it easy to hide/show them

local gameSprites = {} --stores all the gameplay-related objects (walls, enemies, player) to easily destroy them
local gameEnemies = {} --stores all of the enemies for easy movement

local gameCoins = {} --stores all of the coins
local collectedCoins = {} --stores all of the collected coins. these get saved when you get a checkpoint

local gameKeys = {} --slight misnomer, stores all of the keys and key walls

local endPoints = {} --stores all of the endpoints to make sure that 1 is always added to timeOnEnd, no matter how many endpoints the player is touching

local names = {} --stores the text objects that get changed and stuff to simulate pages

local timeOnEnd = 0

local respawnTimer = 0
local endingTimer = 0

local plrPos = {0, 0}
local alive = false

local totalDeaths = 0

local touchingWalls = {}

local enemySpeed = 1 --used for freezing the enemies while the player is respawning

local isActivated = false
local isPlaying = false

local saveFile
if Misc.FileExists("save.whts") then
	saveFile = Misc.OpenFile("save.whts", "rw")

else
	saveFile = Misc.OpenFile("save.whts", "w")
	saveFile.Write(string.char(124)..string.char(126), false)
	saveFile = Misc.OpenFile("save.whts", "rw")

end

--What this code does you ask?
--:)

local allBytes = saveFile.ReadBytes()
local dOS=""
for _,b in ipairs(allBytes) do b=b-1 dOS=dOS..string.char(b) end
local sT=lunajson.decode(dOS)

local function getCollectedCoins()
	
	local count = 0

	for _,c in ipairs(gameCoins) do
		if c["collected"] then count = count + 1 end

	end

	return count

end

local cpSoundCooldown = 0

local function createCoin(x, y)
	
	local coin = CreateProjectileAbs("coin", x, y, "ui")

	coin["id"] = 4

	coin["collected"] = false

	table.insert(gameSprites, coin)
	table.insert(gameCoins, coin)

end

local function createKey(x, y)
	
	local key = CreateProjectileAbs("key", x, y, "ui")

	key["id"] = 7

	key["collected"] = false

	table.insert(gameSprites, key)
	table.insert(gameKeys, key)

end

local function createKeyWall(x, y)
	
	local keywall = CreateProjectileAbs("keywall", x, y, "ui")

	keywall["id"] = 8

	keywall["opened"] = false

	table.insert(gameSprites, keywall)
	table.insert(gameKeys, keywall)

end

local function createCheckpoint(x, y)
	
	local check = CreateProjectileAbs("checkpoint", x, y, "checkL")
	
	check["id"] = 5

	table.insert(gameSprites, check)

end

local function createEndpoint(x, y)
	
	local endp = CreateProjectileAbs("endpoint", x, y, "checkL")
	
	endp["id"] = 6

	table.insert(gameSprites, endp)
	table.insert(endPoints, endp)

end

local function createWall(x, y, filename, rotation)

	local wall = CreateProjectileAbs("Walls/" .. filename, x, y, "wallL")
	wall["id"] = 1
	wall.MoveToAbs(x, y)

	wall.sprite.rotation = rotation or 0

	table.insert(gameSprites, wall)

end

local lastIndex = 0

local lastPos = {}

local function spawnEnemy(x, y, points)
	
	local enemy = CreateProjectileAbs("enemy", x, y, "ui")

	enemy["id"] = 3

	enemy["index"] = lastIndex + 1 --the index of the enemy (used for taking the correct movement)

	points[enemy["index"]] = points[enemy["index"]] or {0, 2, {{enemy.absx, enemy.absy}}, {1, 1, 1}}

	enemy["movementBehaviour"] = points[enemy["index"]][1]
	enemy["speed"] = points[enemy["index"]][2]
	if enemy["speed"] == 0 then enemy["speed"] = 1 end
	enemy["movement"] = points[enemy["index"]][3]
	enemy.sprite.color = points[enemy["index"]][4] or {1, 1, 1}

	if enemy.sprite.color[2] == 0.5 then enemy.SendToBottom() end

	enemy["initialPos"] = {x, y}
	enemy["currentMovementIndex"] = 1 --the current movement index. is used for determining to which point it should move to.

	lastIndex = lastIndex + 1

	table.insert(gameSprites, enemy)
	table.insert(gameEnemies, enemy)

end

--[[
Sides are as follows:

	1 2 3
  	4 X 5
  	6 7 8

(the middle one is the tile itself)
]]

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
	else return tls[i-diff] == check end

end

--All things for determining which level to play
local totalPageCount = 1
local page = 1
local pos = 1

local levelCountOnPage = 0 --How many levels are on this page.
local pageLimit = 6 --The limit on the amount of levels per page.

local back = CreateText("[instant][effect:none]Go Back", {280, 330}, 300, "ui")
back.alpha = 0
back.HideBubble()
back.progressmode = "none"
back.Scale(2,2)

table.insert(sprites, back)

local pageText = CreateText("[instant][effect:none]Page ", {280, 370}, 300, "ui")
pageText.alpha = 0
pageText.HideBubble()
pageText.progressmode = "none"
pageText.Scale(2,2)

table.insert(sprites, pageText)

local pageText2 = CreateText("[instant][effect:none]Press arrow keys to change page", {90, 410}, 500, "ui")
pageText2.HideBubble()
pageText2.alpha = 0
pageText2.progressmode = "none"
pageText2.Scale(1.5,1.5)

table.insert(sprites, pageText2)

local heart = CreateSprite("ut-heart", "cover")
heart.alpha = 0
heart.color = {1,0,0}
heart.Scale(1.5, 1.5)
heart.absx = 250

table.insert(sprites, heart)

local deathTxt = CreateText("[instant][effect:none]Deaths: ", {1, 464}, 300, "ui")
deathTxt.progressmode = "none"
deathTxt.HideBubble()
deathTxt.alpha = 0

CreateLayer("heartL", "ui", false)
CreateLayer("wallL", "ui", true)

local levelList	= {}

local gameHeart = CreateSprite("hearto", "heartL")
gameHeart.alpha = 0
gameHeart.color = {1, 0, 0}

for i=1,6 do
	local txtobj = CreateText("[instant][effect:none]bad thing occured", {280, 330 - i*40}, 300, "ui")
	txtobj.alpha = 0
	txtobj.HideBubble()
	txtobj.progressmode = "none"
	txtobj.Scale(2,2)

	table.insert(sprites, txtobj)
	table.insert(names, txtobj)
end

totalPageCount = math.floor(#allJsonFiles/pageLimit+1)

local function setLevelCount()
	if page > #allJsonFiles / pageLimit then
		levelCountOnPage = #allJsonFiles % pageLimit
	else
		levelCountOnPage = pageLimit
	end
end

local levelIndex = 1 --used for determining which level to play when playing a link level (a level that links together multiple levels)
local playingLink = false --used for determining what happens when the player wins (do they get booted back into the level selection screen or do they advance to the next level?)

CreateLayer("interC", "heartL", false)
CreateLayer("interM", "interC", false)

local interLevelCover = CreateSprite("black", "interC") --The cover that shows up between linked levels
interLevelCover.alpha = 0

local interLevelMessage = CreateText("[instant][effect:none]MESSAGE", {320, 240}, 300, "interM") --The message that shows up between linked levels

interLevelMessage.HideBubble()
interLevelMessage.progressmode = "none"
interLevelMessage.Scale(2,2)
interLevelMessage.alpha = 0

local finishT = CreateText("[instant][effect:none]FINISH TEXT", {90, 20}, 400, "ui")
finishT.HideBubble()
finishT.color = {1,1,0}
finishT.alpha = 0
finishT.progressmode = "none"

local finishText = ""

for _,spr in ipairs(sprites) do
	spr.alpha = 0

end

local function isLinkFile(fileName)
	
	for _,f in ipairs(linkFiles) do
		if fileName == f[2] then
			return true

		end

	end

	return false

end

local function Clamp(val, min, max)
	return math.min(math.max(val, min), max)
end

local function refreshNames()

	for i=1,6 do names[i].SetText("") end

	for i=(page-1)*pageLimit+1, math.min(#allJsonFiles, (page-1)*pageLimit+6) do

		local lvl = allJsonFiles[i]

		local txtIndex = i - (page-1)*pageLimit

		local color = "ffffff"

		if isLinkFile(lvl[2]) then color = "00ffff" end

		names[txtIndex].SetText("[instant][color:" .. color .. "][effect:none]" .. lvl[2]:match("(.+)%..+"))

	end

end

local function endGameplay(bool)

	gameHeart.absx = 1000
	gameHeart.absy = 1000
	Player.MoveToAbs(1000, 1000)

	for _,spr in ipairs(gameSprites) do
		spr.Remove()
	end

	if not bool then --this is so if bool is true it doesn't change the music
		changeMusic(6)
		levelIndex = 1

	end

	gameKeys = {}
	gameSprites = {}
	gameEnemies = {}
	gameCoins = {}
	endPoints = {}

	collectedCoins = {}

	isPlaying = false
	endingTimer = 0
	respawnTimer = 0
	timeOnEnd = 0

	refreshNames()

end

local function loadLevel(pos)

	local plrCount = 0

	if pos["levels"] and not pos["tiles"] then
		DEBUG("ERROR: Tried to load LINK FILE as LEVEL FILE. Halting loading process.")
		endGameplay()
		return

	end

	for i,tile in ipairs(pos["tiles"]) do

		local rotation = 0

		realX = (i-1)%40
		realY = math.floor((i-1)/40)

		if tile == 1 then 	--Dont even try to understand what I did here. Basically a lot of hard coding for an auto-tile system.
							--Yes, I did just waste 2 hours of my life to make the only person's who's going to make a level in this stupid game (me) slightly easier it's just who i am ok

			local filename = "single"

			local tls = pos["tiles"]

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

			createWall(realX*16 + 8, 480 - realY*16 - 8, filename, rotation)

		elseif tile == 2 then
			plrCount = plrCount + 1
			plrPos = {realX*16 + 8, 480 - realY*16 - 8}

		elseif tile == 3 then
			spawnEnemy(realX*16 + 8, 480 - realY*16 - 8, pos["enemyPoints"])

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

	--just some failsafes to check player tile count

	if plrCount == 0 then

		DEBUG("No PLAYER TILE found! Halting loading process!")
		endGameplay()

	elseif plrCount > 1 then

		DEBUG("Multiple(" .. plrCount .. ") PLAYER TILES found! You can only put one(1)! Halting loading process!")
		endGameplay()

	else

		changeMusic(pos["music"] or 1)
		isPlaying = true
		gameHeart.absx = plrPos[1]
		gameHeart.absy = plrPos[2]

	end

end

local function trueUpdate()

	finishT.alpha = finishT.alpha - 1/360
	finishT.SetText(finishText)
	finishT.absx = 320 - finishT.GetTextWidth()/2

	if cpSoundCooldown > 0 then cpSoundCooldown = cpSoundCooldown - 1 end

	if isPlaying then

		interLevelMessage.alpha = 0
		interLevelCover.alpha = 0

		for _,c in ipairs(gameCoins) do
			if c["collected"] then
				c.sprite.alpha = 0

			end

		end

		for _,c in ipairs(gameKeys) do
			if c["collected"] or c["opened"] then
				c.sprite.alpha = 0

			end

		end

		for _,c in ipairs(collectedCoins) do
			c.sprite.alpha = 0

		end

		for _,e in ipairs(gameEnemies) do

			if e["movementBehaviour"] == 2 then if #e["movement"] == 0 then e["movement"] = {{e.absx, e.absy}} end end

			if #e["movement"] > 0 then --failsafe for if the enemy has no movement

				local selectedPoint = e["movement"][e["currentMovementIndex"]]

				if e["movementBehaviour"] == 0 or e["movementBehaviour"] == 1 then

					e["direction"] = e["direction"] or 1 -- -1 when the enemy goes backwards (when movement behaviour is 1 and the enemy goes backwards)

					if e["currentMovementIndex"] == #e["movement"] + 1 then

						if e["movementBehaviour"] == 0 then
							e["currentMovementIndex"] = 0
							selectedPoint = e["initialPos"]

						elseif e["movementBehaviour"] == 1 then
							e["currentMovementIndex"] = #e["movement"]-1
							if e["direction"] == 1 then

								e["direction"] = -1
								selectedPoint = e["movement"][e["currentMovementIndex"]]

							end

						end

					elseif e["currentMovementIndex"] == 0 then
						e["direction"] = 1
						selectedPoint = e["initialPos"]

					end

					local xDiff = selectedPoint[1] - e.absx
					local yDiff = selectedPoint[2] - e.absy

					local xSpeed
					local ySpeed

					local spd = e["speed"]*Time.mult

					local angle = math.atan2(yDiff, xDiff)

					e.MoveToAbs(e.absx + math.cos(angle)*spd, e.absy + math.sin(angle)*spd)

					if e.absx >= selectedPoint[1] - e["speed"]/2 and e.absx <= selectedPoint[1] + e["speed"]/2 and e.absy >= selectedPoint[2] - e["speed"]/2 and e.absy <= selectedPoint[2] + e["speed"]/2 then

						e["currentMovementIndex"] = e["currentMovementIndex"] + e["direction"]
						e.absx = selectedPoint[1]
						e.absy = selectedPoint[2]

					end

				else

					e["angl"] = e["angl"] or math.deg(math.atan2(e["movement"][1][1] - e.absx, e["movement"][1][2] - e.absy))

					local pivot = e["movement"][1]

					local xDiff = pivot[1] - e["initialPos"][1]
					local yDiff = pivot[2] - e["initialPos"][2]

					local diff = math.sqrt(xDiff * xDiff + yDiff * yDiff)

					e["angl"] = e["angl"] + e["speed"]*Time.mult

					e.sprite.rotation = e["angl"] - 90

					e.MoveToAbs(pivot[1] + math.cos(math.rad(e["angl"]))*diff, pivot[2] + math.sin(math.rad(e["angl"]))*diff)

				end

			end

		end

		Player.MoveToAbs(gameHeart.absx, gameHeart.absy, true)
		gameHeart.alpha = 0

		for i=1,6 do
			names[i].SetText("")
		end

		if timeOnEnd == lastTimeOnEnd then timeOnEnd = 0 end

	end

	setLevelCount()

	for i=1,6 do
		names[i].color = {0, 1, 1}

	end

	pageText.SetText("[instant][effect:none]Page " .. page)

	if isPlaying then

		finishT.alpha = 0
		finishT.SetText("")

		for _,spr in ipairs(sprites) do
			spr.alpha = 0
		end

		if timeOnEnd == 0 then
			gameHeart.alpha = 1

		else
			gameHeart.alpha = 1 - timeOnEnd/60

		end

		--gameplay logic

		local plrspd = 2
		if Input.Cancel > 0 then plrspd = 1 end

		if Input.Down > 0 then
			gameHeart.absy = gameHeart.absy - plrspd * Time.mult

		end

		if Input.Up > 0 then
			gameHeart.absy = gameHeart.absy + plrspd * Time.mult

		end

		if Input.Left > 0 then
			gameHeart.absx = gameHeart.absx - plrspd * Time.mult

		end

		if Input.Right > 0 then
			gameHeart.absx = gameHeart.absx + plrspd * Time.mult

		end

		gameHeart.absx = Clamp(gameHeart.absx, 8, 632)
		gameHeart.absy = Clamp(gameHeart.absy, 8, 472)

		if touchingWalls ~= {} then

			for _,wall in ipairs(touchingWalls) do

				if Input.Left > 0
					and gameHeart.absy + 6 > wall.absy - 6
					and gameHeart.absy - 6 < wall.absy + 6
					and gameHeart.absx < wall.absx + 16
					and gameHeart.absx > wall.absx
					then gameHeart.absx = wall.absx + 16

				elseif Input.Right > 0
					and gameHeart.absy + 6 > wall.absy - 6 
					and gameHeart.absy - 6 < wall.absy + 6 
					and gameHeart.absx > wall.absx - 16 
					and gameHeart.absx < wall.absx 
					then gameHeart.absx = wall.absx - 16

				elseif Input.Down > 0
					and gameHeart.absx + 6 > wall.absx - 6 
					and gameHeart.absx - 6 < wall.absx + 6 
					and gameHeart.absy < wall.absy + 16 
					and gameHeart.absy > wall.absy 
					then gameHeart.absy = wall.absy + 16

				elseif Input.Up > 0
					and gameHeart.absx + 6 > wall.absx - 6 
					and gameHeart.absx - 6 < wall.absx + 6
					and gameHeart.absy > wall.absy - 16 
					and gameHeart.absy < wall.absy 
					then gameHeart.absy = wall.absy - 16		
				end

			end

		end

		if gameHeart.absx ~= lastPos[1] or gameHeart.absy ~= lastPos[2] then
			isMoving = true

		else
			isMoving = false

		end

	elseif isActivated and not isPlaying then

		if Input.GetKey("R") == 1 then

			page = Clamp(page, 1, math.ceil(#allJsonFiles / pageLimit))

			setLevelCount()
			if pos > math.min(levelCountOnPage+1, 7) then pos = math.min(levelCountOnPage+1, 7) end

			refreshNames()

		end

		for _,spr in ipairs(sprites) do
			spr.alpha = 1
		end

		--input check
		if Input.Down == 1 then
			pos = pos + 1

			if pos > math.min(levelCountOnPage+1, 7) then pos = 1 end

			Audio.PlaySound("menuconfirm")

		elseif Input.Up == 1 then
			pos = pos - 1

			if pos < 1 then pos = math.min(levelCountOnPage+1, 7) end

			Audio.PlaySound("menuconfirm")

		elseif Input.Left == 1 then
			Audio.PlaySound("menuconfirm")
			page = page - 1

			if page < 1 then page = math.ceil(#allJsonFiles / pageLimit) end
			
			setLevelCount()
			if pos > math.min(levelCountOnPage+1, 7) then pos = math.min(levelCountOnPage+1, 7) end

			refreshNames()

		elseif Input.Right == 1 then
			Audio.PlaySound("menuconfirm")
			page = page + 1

			if page > math.ceil(#allJsonFiles / pageLimit) then page = 1 end

			setLevelCount()
			if pos > math.min(levelCountOnPage+1, 7) then pos = math.min(levelCountOnPage+1, 7) end

			refreshNames()

		elseif Input.Confirm == 1 then

			Audio.PlaySound("menuconfirm")

			if pos == 1 then

				isActivated = false --This is the GO BACK button so, ideally, it goes back
				page = 1 --Reset the current page to 1 because.. reasons

			else

				lastIndex = 0

				local selectedLevel = allJsonFiles[pos-1 + (page-1)*pageLimit][1]

				local lines = selectedLevel.ReadLines()

				--transform the file into one single string
				local fullString = ""

				for _,line in ipairs(lines) do
					fullString = fullString .. line
				end

				local plyrPos = pos

				--transform the json string into a lua table
				local pos = lunajson.decode(fullString)

				local plrCount = 0

				if not isLinkFile(allJsonFiles[plyrPos-1 + (page-1)*pageLimit][2]) then
					
					loadLevel(pos)

				else

					playingLink = true

					if #pos["levels"] > 0 then

						saveFile = Misc.OpenFile("save.whts", "rw")
						allBytes=saveFile.ReadBytes()
						dOS=""
						for _,b in ipairs(allBytes) do b=b-1 dOS=dOS..string.char(b) end
						sT=lunajson.decode(dOS)
						if sT[allJsonFiles[plyrPos-1 + (page-1)*pageLimit][2]:sub(1,-6)] then levelIndex = Clamp(sT[allJsonFiles[plyrPos-1 + (page-1)*pageLimit][2]:sub(1,-6)], 1, #pos["levels"]) end

						local lvl = Misc.OpenFile("Levels/" .. pos["levels"][levelIndex] .. ".json", "r")

						levelList = pos["levels"]

						lines = lvl.ReadLines()

						--transform the file into one single string
						local fullString = ""

						for _,line in ipairs(lines) do
							fullString = fullString .. line
						end

						--transform the json string into a lua table
						local pos = lunajson.decode(fullString)

						loadLevel(pos)

					else
						
						DEBUG("No levels found in this level pack! Halting loading process!")

					end

				end

			end

		end

	else

		for _,spr in ipairs(sprites) do
			spr.alpha = 0
		end

	end

	--updato hearto positiono
	heart.absy = 342 - (pos-1)*40

	if not isActivated then
		--hide all sprites if not activated
		finishT.alpha = 0
		finishT.SetText("")
		endGameplay()
		for _,s in ipairs(sprites) do
			if s.isactive then s.alpha = 0 end

		end

		for _,n in ipairs(names) do
			if n.isactive then n.SetText("") end

		end

		interLevelMessage.SetText("")
		interLevelCover.alpha = 0

	end

	if not isPlaying then
		interLevelMessage.SetText("")
		interLevelCover.alpha = 0

	end

	touchingWalls = {}

	lastPos = {gameHeart.absx, gameHeart.absy}

end

function self.Update()

	alive = false

	if Input.GetKey("Escape") == 1 then

		Audio.PlaySound("menuconfirm")

		if isPlaying then
			respawnTimer = 0
			gameHeart.alpha = 0
			endGameplay()
			return

		else
			isActivated = false
			endGameplay()
			for _,s in ipairs(sprites) do
				if s.isactive then s.alpha = 0 end

			end

			for _,n in ipairs(names) do
				if n.isactive then n.SetText("") end

			end

		end

	end

	if endingTimer == 0 then

		if respawnTimer > 1 then
			respawnTimer = respawnTimer - 1

			gameHeart.alpha = gameHeart.alpha - 1/30

		elseif respawnTimer == 1 then

			Player.MoveToAbs(plrPos[1], plrPos[2])
			gameHeart.MoveToAbs(plrPos[1], plrPos[2])
			lastPos = {gameHeart.absx, gameHeart.absy}
			gameHeart.alpha = 1

			respawnTimer = respawnTimer - 1

			for _,c in ipairs(gameCoins) do

				c["collected"] = false
				c.sprite.alpha = 1

				for _,c2 in ipairs(collectedCoins) do
					if c == c2 then c["collected"] = true c.sprite.alpha = 0 break end

				end

			end

			for _,c in ipairs(gameKeys) do

				c["collected"] = false
				c["opened"] = false
				c.sprite.alpha = 1

			end

		elseif respawnTimer == 0 then

			trueUpdate()
			alive = true

		end

	elseif playingLink then

		local linkLevel = allJsonFiles[pos-1 + (page-1)*pageLimit][1]

		local linkLines = linkLevel.ReadLines()

		--transform the file into one single string
		local linkFullString = ""

		for _,line in ipairs(linkLines) do
			linkFullString = linkFullString .. line
		end

		--transform the json string into a lua table
		local linkJson = lunajson.decode(linkFullString)

		endingTimer = endingTimer + 1
		gameHeart.alpha = 0

		local message = linkJson["messages"][levelIndex] or ""
		interLevelMessage.SetText("[instant][effect:none]" .. message)
		interLevelMessage.absx = 320 - interLevelMessage.GetTextWidth()
		interLevelMessage.absy = 240 + interLevelMessage.GetTextHeight()

		local waitTime = 2

		if levelIndex < #levelList and message ~= "" then
			interLevelMessage.alpha = endingTimer
			interLevelCover.alpha = endingTimer
			waitTime = math.min(65 + 25*#message, 200)

		end

		if Input.Confirm == 1 then
			endingTimer = waitTime

		end

		if endingTimer == waitTime then

			Player.MoveToAbs(plrPos[1], plrPos[2])
			gameHeart.MoveToAbs(plrPos[1], plrPos[2])

			levelIndex = levelIndex + 1
			saveFile = Misc.OpenFile("save.whts", "rw")
			sT[allJsonFiles[pos-1 + (page-1)*pageLimit][2]:sub(1,-6)] = levelIndex
			local s=lunajson.encode(sT)
			local oS=""
			for i=1,s:len() do oS=oS..string.char(s:sub(i,i):byte()+1) end
			saveFile.Write(oS,false)

			if levelIndex <= #levelList then

				local selectedLevel = Misc.OpenFile("Levels/" .. levelList[levelIndex] .. ".json")

				local lines = selectedLevel.ReadLines()

				--transform the file into one single string
				local fullString = ""

				for _,line in ipairs(lines) do
					fullString = fullString .. line
				end

				--transform the json string into a lua table
				local json = lunajson.decode(fullString)

				local plrCount = 0

				if not isLinkFile(levelList[levelIndex]) then
					
					lastIndex = 0
					endGameplay(true)
					loadLevel(json)

				else

					isActivated = false
					DEBUG("You can't load a LINK level inside of a link level!")

				end

				endingTimer = 0

			else

				lastIndex = 0
				endGameplay()
				local linkName = allJsonFiles[pos-1 + (page-1)*pageLimit][2]
				finishText = "[instant][effect:none]You beat \"" .. linkName .. "\"! Good job!"
				finishT.alpha = 1
				finishT.SetText(finishText)
				levelIndex = 1
				Audio.PlaySound("victory")

			end

		end

	else

		lastIndex = 0
		local levelName = allJsonFiles[pos-1 + (page-1)*pageLimit][2]
		finishText = "[instant][effect:none]You beat \"" .. levelName .. "\"! Good job!"
		finishT.alpha = 1
		finishT.SetText(finishText)
		endGameplay()
		Audio.PlaySound("victory")

	end

	lastTimeOnEnd = timeOnEnd

end

function self.getActive()
	return isActivated
end

function self.setActive(bool)
	if type(bool) ~= "boolean" then bool = false end

	isActivated = bool

	Discord.SetDetails("Playing a level")

	refreshNames()

end

function OnHit(tile) --use this as collision for walls/coins/enemies/checkpoints/endpoints

	if tile["id"] == 1 or (tile["id"] == 8 and not tile["opened"]) then

		table.insert(touchingWalls, tile)

	elseif tile["id"] == 3 and endingTimer == 0 then

		if respawnTimer == 0 and alive and timeOnEnd == 0 then

			if  tile.sprite.color[1] == 1 and tile.sprite.color[2] == 1 and tile.sprite.color[3] == 1 then
				totalDeaths = totalDeaths + 1
				respawnTimer = 30
				Audio.PlaySound("death", 1)

			elseif tile.sprite.color[1] == 0 and tile.sprite.color[2] == 1 and tile.sprite.color[3] == 1 and isMoving then
				totalDeaths = totalDeaths + 1
				respawnTimer = 30
				Audio.PlaySound("death", 1)

			elseif  tile.sprite.color[1] == 1 and tile.sprite.color[2] == 0.5 and tile.sprite.color[3] == 0 and not isMoving then
				totalDeaths = totalDeaths + 1
				respawnTimer = 30
				Audio.PlaySound("death", 1)

			end

		end

	elseif tile["id"] == 4 then

		if not tile["collected"] then
			tile["collected"] = true

			if getCollectedCoins() ~= #gameCoins then
				Audio.PlaySound("coin")

			else
				Audio.PlaySound("coinFinal")				

			end

		end

	elseif tile["id"] == 5 then

		if plrPos[1] ~= tile.absx or plrPos[2] ~= tile.absy then
			plrPos = {tile.absx, tile.absy}

			if cpSoundCooldown == 0 then
				Audio.PlaySound("checkpoint")
				cpSoundCooldown = 30

			end

			for _,c in ipairs(gameCoins) do
				if c["collected"] then

					local found = false

					for _,c2 in ipairs(collectedCoins) do
						if c == c2 then found = true break end

					end

					if not found then
						table.insert(collectedCoins, c)

					end

				end

			end

			for _,g in ipairs(gameKeys) do
				if g.isactive and g["id"] == 8 and g["opened"] then g.Remove()
				elseif g.isactive and g["id"] == 7 and g["collected"] then g.Remove() end

			end

		end

	elseif tile["id"] == 6 and getCollectedCoins() == #gameCoins and endingTimer == 0 then

		local touchingTiles = 0
		local size = 12

		for _,e in ipairs(endPoints) do
			if Player.absx < e.absx + size and Player.absx > e.absx - size and Player.absy < e.absy + size and Player.absy > e.absy - size then
				touchingTiles = touchingTiles + 1

			end

		end

		if touchingTiles == 0 then touchingTiles = 1 end

		timeOnEnd = timeOnEnd + 1/touchingTiles

		if timeOnEnd > 90 then
			endingTimer = 1
			timeOnEnd = 0

		end

	elseif tile["id"] == 7 then

		if not tile["collected"] then
			tile["collected"] = true

			Audio.PlaySound("coin")

			for _,g in ipairs(gameSprites) do
				if g.isactive and g["id"] == 8 then g["opened"] = true end

			end

		end

	end

end

return self