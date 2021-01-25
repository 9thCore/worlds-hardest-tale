self = {}

local sprites = {} --stores all sprites to make it easy to hide/show them
local names = {} --is used for making the list of packs

local menuSprites1 = {} --stores the sprites that show up when you initially enter the editor (new & load)
local menuSprites2 = {} --stores the sprites that show up when you make a new pack
local menuSprites3 = {} --stores the sprites that show up when you load an existing pack
local menuSprites4 = {} --stores the sprites that show up when you edit a pack

--[[
editingStage governs what stuff should appear 
1st is the initial menu;
2nd is inputting pack name (when selecting New Pack);
3rd is selecting pack (when selecting Load Pack);
4th is choosing what to edit in the pack; (when you can select if you want to edit a message or a level)
5th is editing a pack; (when you can select a level/message to edit/add)
6th is editing a string (level name or message).
]]--
local editingStage = 1

--All things for determining which pack to load
local totalPageCount = 1
local page = 1
local page2 = 1
local pos = 1
local pos2 = 1
local pos3 = 1
local pos4 = 1
local levelCountOnPage = 0 --How many levels are on this page.
local pageLimit = 6 --The limit on the amount of packs per page.

local editingID = 1 --1 when you want to edit levels and 2 when you want to edit messages

local editingString = "" --used for storing the level name/message when editing one of these

local levels = {}
local messages = {}

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

totalPageCount = math.floor(#linkFiles/pageLimit+1)

for i=1,6 do
	local txtobj = CreateText("[instant][effect:none]bad thing occured", {280, 330 - i*40}, 300, "ui")
	txtobj.alpha = 0
	txtobj.HideBubble()
	txtobj.progressmode = "none"
	txtobj.Scale(2,2)

	table.insert(sprites, txtobj)
	table.insert(menuSprites3, txtobj)
	table.insert(menuSprites4, txtobj)
	table.insert(names, txtobj)
end

local saveT = CreateText("[instant][effect:none]This should absolutely NOT appear.", {540, 456}, 300, "top_ui")
saveT.color = {1,1,0}
saveT.alpha = 0
saveT.HideBubble()
saveT.progressmode = "none"
saveT.Scale(2,2)
saveT.MoveToAbs(320 - saveT.GetTextWidth(), 340)

local levelName = "Unnamed Level " .. #linkFiles+1

local saveText = ""

local function Save(name, startTime)

	local dir = ""

	for _,lvl in ipairs(linkFiles) do

		if lvl[2] == levelName .. ".json" then

			if lvl[3] then dir = lvl[3] break end

		end

	end

	local file = Misc.OpenFile("Levels/" .. dir .. levelName .. ".json", "w")

	file.Delete()

	file.Write("{\n\"levels\": " .. "[\n")

	file.Write(lunajson.encode(levels):sub(2, -2))

	file.Write("\n]" .. ",\n\"messages\": [\n")

	file.Write(lunajson.encode(messages):sub(2, -2))

	file.Write("\n]\n")

	file.Write("}\n")

	Audio.PlaySound("save")

	saveT.alpha = 1
	saveText = "[instant][effect:none]Saved to \"" .. name .. ".json\". Took " .. tostring(os.clock() - startTime):sub(1,5) .. " seconds."
	saveT.absx = 320 - saveT.GetTextWidth()

end

local function setLevelCount(bool)

	if not bool then

		if page > #linkFiles / pageLimit then
			levelCountOnPage = #linkFiles % pageLimit
		else
			levelCountOnPage = pageLimit
		end

	else

		local t = {levels, messages}

		if page > #t[editingID] / pageLimit then
			levelCountOnPage = #t[editingID] % pageLimit
		else
			levelCountOnPage = pageLimit
		end

	end

end

local active = false

local back = CreateText("[instant][effect:none]Go Back", {280, 280}, 300, "ui")
back.alpha = 0
back.HideBubble()
back.progressmode = "none"
back.Scale(2,2)

table.insert(sprites, back)
table.insert(menuSprites1, back)

local btn1 = CreateText("[instant][effect:none]New Pack", {280, 240}, 300, "ui")
btn1.alpha = 0
btn1.HideBubble()
btn1.progressmode = "none"
btn1.Scale(2,2)

table.insert(sprites, btn1)
table.insert(menuSprites1, btn1)
table.insert(menuSprites4, btn1)

local btn2 = CreateText("[instant][effect:none]Load Pack", {280, 200}, 300, "ui")
btn2.alpha = 0
btn2.HideBubble()
btn2.progressmode = "none"
btn2.Scale(2,2)

table.insert(sprites, btn2)
table.insert(menuSprites1, btn2)
table.insert(menuSprites4, btn2)

local heart = CreateSprite("ut-heart", "cover")
heart.alpha = 0
heart.color = {1,0,0}
heart.Scale(1.5, 1.5)
heart.absx = 250

table.insert(sprites, heart)
table.insert(menuSprites1, heart)
table.insert(menuSprites4, heart)

local title = CreateText("[instant][effect:none]Level Pack Editor", {320, 400}, 300, "ui")
title.alpha = 0
title.HideBubble()
title.progressmode = "none"
title.Scale(2,2)
title.absx = 320 - title.GetTextWidth()

table.insert(sprites, title)
table.insert(menuSprites1, title)
table.insert(menuSprites4, title)

local title2 = CreateText("[instant][effect:none]   Input a name\nfor the level pack", {320, 400}, 300, "ui")
title2.alpha = 0
title2.HideBubble()
title2.progressmode = "none"
title2.Scale(2,2)
title2.absx = 320 - title2.GetTextWidth()

table.insert(sprites, title2)
table.insert(menuSprites2, title2)

local input = CreateText("[instant][effect:none]", {320, 240}, 300, "ui")
input.alpha = 0
input.HideBubble()
input.progressmode = "none"
input.Scale(2,2)
input.absx = 320 - title.GetTextWidth()

table.insert(sprites, input)
table.insert(menuSprites2, input)

local title3 = CreateText("[instant][effect:none]Select a pack", {320, 440}, 300, "ui")
title3.alpha = 0
title3.HideBubble()
title3.progressmode = "none"
title3.Scale(2,2)
title3.absx = 320 - title2.GetTextWidth()

table.insert(sprites, title3)
table.insert(menuSprites3, title3)

local back2 = CreateText("[instant][effect:none]Go Back", {280, 330}, 300, "ui")
back2.alpha = 0
back2.HideBubble()
back2.progressmode = "none"
back2.Scale(2,2)

table.insert(sprites, back2)
table.insert(menuSprites3, back2)

local pageText = CreateText("[instant][effect:none]Page ", {280, 370}, 300, "ui")
pageText.alpha = 0
pageText.HideBubble()
pageText.progressmode = "none"
pageText.Scale(2,2)

table.insert(sprites, pageText)
table.insert(menuSprites3, pageText)

local pageText2 = CreateText("[instant][effect:none]Press arrow keys to change page", {90, 410}, 500, "ui")
pageText2.alpha = 0
pageText2.HideBubble()
pageText2.progressmode = "none"
pageText2.Scale(1.5,1.5)

table.insert(sprites, pageText2)
table.insert(menuSprites3, pageText2)

local back3 = CreateText("[instant][effect:none]Exit Without Saving", {280, 320}, 300, "ui")
back3.alpha = 0
back3.HideBubble()
back3.progressmode = "none"
back3.Scale(2,2)

table.insert(sprites, back3)
table.insert(menuSprites4, back3)

local saveT2 = CreateText("[instant][effect:none]Save", {280, 280}, 300, "ui")
saveT2.alpha = 0
saveT2.HideBubble()
saveT2.progressmode = "none"
saveT2.Scale(2,2)

table.insert(sprites, saveT2)
table.insert(menuSprites4, saveT2)

local heart2 = CreateSprite("ut-heart", "cover")
heart2.alpha = 0
heart2.color = {1,0,0}
heart2.Scale(1.5, 1.5)
heart2.absx = 250

table.insert(sprites, heart2)
table.insert(menuSprites3, heart2)

local newLvlT = CreateText("", {100, 16}, 500, "ui")
newLvlT.color = {1,1,1}
newLvlT.HideBubble()
newLvlT.progressmode = "none"
newLvlT.Scale(1.5,1.5)

table.insert(sprites, newLvlT)

function self.Update()

	saveT.alpha = saveT.alpha - 1/90
	saveT.SetText(saveText)
	saveT.absx = 320 - saveT.GetTextWidth()

	if editingStage ~= 2 and editingStage < 4 then

		levels = {}
		messages = {}
		levelName = "Unnamed Level " .. #linkFiles+1

	end

	if Input.GetKey("Escape") == 1 then

		saveT.SetText("")
		saveT.alpha = 0

		Audio.PlaySound("menuconfirm")

		if editingStage == 1 then
			active = false

		elseif editingStage <= 4 then
			editingStage = 1

		else
			editingStage = 4

		end

	end

	for i=1,6 do
		names[i].SetText("")
	end

	input.SetText("")

	btn1.SetText("")
	btn2.SetText("")

	title.SetText("")

	pageText.SetText("")

	input.SetText("")
	title2.SetText("")

	newLvlT.SetText("")

	for _,t in ipairs({menuSprites1, menuSprites2, menuSprites3, menuSprites4}) do
		for _,s in ipairs(t) do
			s.alpha = 0 --make all sprites invisible, then turn them back on later if needed

		end

	end

	if editingStage == 1 then
		for _,s in ipairs(menuSprites1) do
			s.alpha = 1

		end

		btn1.SetText("[instant][effect:none]New Pack")
		btn2.SetText("[instant][effect:none]Load Pack")
		title.SetText("[instant][effect:none]Level Pack Editor")

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
			if pos == 1 then active = false
			else editingStage = pos end

		end

		heart.absy = 332 - pos*40

	elseif editingStage == 2 then
		for _,s in ipairs(menuSprites2) do
			s.alpha = 1

		end

		levelName = key.DetectInput(levelName)
		input.SetText("[instant][effect:none]" .. levelName)
		input.absx = 320 - input.GetTextWidth()

		title2.SetText("[instant][effect:none]   Input a name\nfor the level pack")

		if Input.GetKey("Return") == 1 then

			--if the level name is banned/disallowed in Windows, it'll revert it back to a normal name.
			for _,n in ipairs(bannedNames) do
				if levelName == n then
					DEBUG("That name is banned! The level name has been reverted to \"Unnamed Level " .. #linkFiles+1 .. "\"")
					levelName = "Unnamed Level " .. #linkFiles+1
					break

				end

			end

			if levelName:sub(-1) == " " then levelName = levelName:sub(1, -2) end

			if levelName == "" then levelName = "Unnamed Level " .. #linkFiles+1 end

			editingStage = 4

		end

	elseif editingStage == 3 then

		if Input.GetKey("R") == 1 then

			page = Clamp(page, 1, math.ceil(#linkFiles / pageLimit))
			reloadAllLevels()

			DEBUG("Reloaded all levels.")

		end

		setLevelCount()

		for _,s in ipairs(menuSprites3) do
			s.alpha = 1

		end

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

			if page < 1 then page = math.ceil(#linkFiles / pageLimit) end
			setLevelCount()

			if pos2 > math.min(levelCountOnPage+1, 7) then pos2 = math.min(levelCountOnPage+1, 7) end

		elseif Input.Right == 1 then
			Audio.PlaySound("menuconfirm")
			page = page + 1

			if page > math.ceil(#linkFiles / pageLimit) then page = 1 end
			setLevelCount()

			if pos2 > math.min(levelCountOnPage+1, 7) then pos2 = math.min(levelCountOnPage+1, 7) end

		elseif Input.Confirm == 1 then --OPEN / LOAD A PACK IN THE EDITOR--
			Audio.PlaySound("menuconfirm")

			if pos2 == 1 then editingStage = 1 else

				local elem = linkFiles[pos2-1 + (page-1)*pageLimit]

				local lvl = elem[1]
				levelName = elem[2]:sub(1, -6)

				local str = lunajson.decode(getFullStringFromFile(lvl))
				levels = str["levels"]
				messages = str["messages"]

				editingStage = 4

			end

		end

		heart2.absy = 342 - (pos2-1)*40

		for i=(page-1)*pageLimit+1, math.min(#linkFiles, (page-1)*pageLimit+6) do
			local lvl = linkFiles[i]
			
			names[i - (page-1)*pageLimit].SetText("[instant][effect:none]" .. lvl[2]:match("(.+)%..+"))

		end

		pageText.SetText("[instant][effect:none]Page " .. page)

	elseif editingStage == 4 then

		for _,s in ipairs(menuSprites4) do
			s.alpha = 1

		end

		if Input.Up == 1 then

			Audio.PlaySound("menuconfirm")
			pos3 = pos3 - 1

			if pos3 < 1 then pos3 = 4 end

		elseif Input.Down == 1 then

			Audio.PlaySound("menuconfirm")
			pos3 = pos3 + 1

			if pos3 > 4 then pos3 = 1 end

		elseif Input.Confirm == 1 then

			cooldown = 10
			Audio.PlaySound("menuconfirm")
			if pos3 == 1 then
				editingStage = 1

			elseif pos3 == 2 then
				Save(levelName, os.clock())

			else
				editingStage = 5
				editingID = pos3 - 2

			end

		end

		btn1.SetText("[instant][effect:none]Edit Levels")
		btn2.SetText("[instant][effect:none]Edit Messages")
		title.SetText("[instant][effect:none]Select What To Edit")

		heart.absy = 372 - pos3*40

	elseif editingStage == 5 then

		for _,s in ipairs(menuSprites3) do
			s.alpha = 1

		end

		if Input.GetKey("N") == 1 then Audio.PlaySound("menuconfirm") editingString = "" editingStage = 6
		else

			local tabl = {"level", "message"}
			local t = {levels, messages}
			local usedT = t[editingID]

			setLevelCount(true)

			for i=(page2-1)*pageLimit+1, math.min(#usedT, (page2-1)*pageLimit+6) do

				local lvl = usedT[i]
				
				names[i - (page2-1)*pageLimit].SetText("[instant][effect:none]" .. lvl)

			end

			if Input.Up == 1 then
				Audio.PlaySound("menuconfirm")
				pos4 = pos4 - 1

				if pos4 < 1 then pos4 = math.min(levelCountOnPage+1, 7) end

			elseif Input.Down == 1 then
				Audio.PlaySound("menuconfirm")
				pos4 = pos4 + 1

				if pos4 > math.min(levelCountOnPage+1, 7) then pos4 = 1 end

			elseif Input.Left == 1 then
				Audio.PlaySound("menuconfirm")
				page2 = page2 - 1

				if page2 < 1 then page2 = math.floor(#usedT / pageLimit) + 1 end
				setLevelCount()

				if pos4 > math.min(levelCountOnPage+1, 7) then pos4 = math.min(levelCountOnPage+1, 7) end

			elseif Input.Right == 1 then
				Audio.PlaySound("menuconfirm")
				page2 = page2 + 1

				if page2 > math.floor(#usedT / pageLimit) + 1 then page2 = 1 end
				setLevelCount()

				if pos4 > math.min(levelCountOnPage+1, 7) then pos4 = math.min(levelCountOnPage+1, 7) end

			elseif Input.Confirm == 1 then --EDIT A LEVEL/MESSAGE--
				Audio.PlaySound("menuconfirm")

				if pos4 == 1 then editingStage = 4
				else editingStage = 6 editingString =  usedT[(page2-1)*pageLimit+pos4-1] end

			end

			heart2.absy = 342 - (pos4-1)*40

			pageText.SetText("[instant][effect:none]Page " .. page2)

			newLvlT.SetText("[instant][effect:none]Press \'N\' to add another " .. tabl[editingID] .. "!")

		end

	elseif editingStage == 6 then

		for _,s in ipairs(menuSprites2) do
			s.alpha = 1

		end

		editingString = key.DetectInput(editingString)
		input.SetText("[instant][effect:none]" .. editingString)
		input.absx = 320 - input.GetTextWidth()

		if editingID == 1 then

			title2.SetText("[instant][effect:none]Type the level's name")

			if Input.GetKey("Return") == 1 then

				local found = false

				for _,l in ipairs(levelFiles) do

					if l[2]:sub(1, -6) == editingString then

						found = true
						break

					end

				end

				if found then

					local alreadyInTable = false

					for _,l in ipairs(levels) do
						if l == editingString then
							alreadyInTable = true
							break

						end

					end

					if not alreadyInTable then
						table.insert(levels, editingString)

					end

					editingStage = 4

				else
					DEBUG("This is not a valid level! (Are you sure you typed the level name right?)")

				end

			end

		else

			title2.SetText("[instant][effect:none]Type the message")

			if Input.GetKey("Return") == 1 then

				table.insert(messages, editingString)
				editingStage = 4

			end

		end

	end

	title.absx = 320 - title.GetTextWidth()

	if not active then
		for _,s in ipairs(sprites) do s.alpha = 0 end

		btn1.SetText("")
		btn2.SetText("")

		title.SetText("")

		pageText.SetText("")

		input.SetText("")
		title2.SetText("")

		newLvlT.SetText("")

	end

end

function self.getActive()
	return active

end

function self.setActive(bool)
	active = bool

	Discord.SetDetails("Making a level pack")
end

return self