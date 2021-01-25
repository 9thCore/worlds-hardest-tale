self = {}

local holdTime = 30

function self.DetectInput(str)

	local before = str
	local shift = false

	if Input.GetKey("Backspace") > 0 then
		holdTime = holdTime - 1
	else
		holdTime = 30
	end

	if string.len(str:gsub("", '')) < 24 then

		shift = false

		if Input.GetKey("LeftShift") > 0 or Input.GetKey("RightShift") > 0 then
			shift = true
		end

		if Input.GetKey("A") == 1 then
			str = str .. "A"
		elseif Input.GetKey("B") == 1 then
			str = str .. "B"
		elseif Input.GetKey("C") == 1 then
			str = str .. "C"
		elseif Input.GetKey("D") == 1 then
			str = str .. "D"
		elseif Input.GetKey("E") == 1 then
			str = str .. "E"
		elseif Input.GetKey("F") == 1 then
			str = str .. "F"
		elseif Input.GetKey("G") == 1 then
			str = str .. "G"
		elseif Input.GetKey("H") == 1 then
			str = str .. "H"
		elseif Input.GetKey("I") == 1 then
			str = str .. "I"
		elseif Input.GetKey("J") == 1 then
			str = str .. "J"
		elseif Input.GetKey("K") == 1 then
			str = str .. "K"
		elseif Input.GetKey("L") == 1 then
			str = str .. "L"
		elseif Input.GetKey("M") == 1 then
			str = str .. "M"
		elseif Input.GetKey("N") == 1 then
			str = str .. "N"
		elseif Input.GetKey("O") == 1 then
			str = str .. "O"
		elseif Input.GetKey("P") == 1 then
			str = str .. "P"
		elseif Input.GetKey("Q") == 1 then
			str = str .. "Q"
		elseif Input.GetKey("R") == 1 then
			str = str .. "R"
		elseif Input.GetKey("S") == 1 then
			str = str .. "S"
		elseif Input.GetKey("T") == 1 then
			str = str .. "T"
		elseif Input.GetKey("U") == 1 then
			str = str .. "U"
		elseif Input.GetKey("V") == 1 then
			str = str .. "V"
		elseif Input.GetKey("W") == 1 then
			str = str .. "W"
		elseif Input.GetKey("X") == 1 then
			str = str .. "X"
		elseif Input.GetKey("Y") == 1 then
			str = str .. "Y"
		elseif Input.GetKey("Z") == 1 then
			str = str .. "Z"
		elseif Input.GetKey("Minus") == 1 then
			str = str .. "-"
		elseif Input.GetKey("Alpha9") == 1 and shift then
			str = str .. "("
		elseif Input.GetKey("Alpha0") == 1 and shift then
			str = str .. ")"
		elseif Input.GetKey("Alpha0") == 1 then
			str = str .. "0"
		elseif Input.GetKey("Alpha1") == 1 then
			str = str .. "1"
		elseif Input.GetKey("Alpha2") == 1 then
			str = str .. "2"
		elseif Input.GetKey("Alpha3") == 1 then
			str = str .. "3"
		elseif Input.GetKey("Alpha4") == 1 then
			str = str .. "4"
		elseif Input.GetKey("Alpha5") == 1 then
			str = str .. "5"
		elseif Input.GetKey("Alpha6") == 1 then
			str = str .. "6"
		elseif Input.GetKey("Alpha7") == 1 then
			str = str .. "7"
		elseif Input.GetKey("Alpha8") == 1 then
			str = str .. "8"
		elseif Input.GetKey("Alpha9") == 1 then
			str = str .. "9"
		elseif Input.GetKey("Space") == 1 and str:len() > 0 then
			str = str .. " "
		end
	end

	if str ~= before and not shift then
		str = str:sub(1, -2) .. str:sub(-1):lower()
	end

	if str:len() > 0 then
		if Input.GetKey("Backspace") == 1 then
			str = str:sub(1, -2)
		elseif Input.GetKey("Backspace") > 0 and holdTime == 0 then
			str = str:sub(1, -2)
			holdTime = 2
		end
	end

	return str
end

return self