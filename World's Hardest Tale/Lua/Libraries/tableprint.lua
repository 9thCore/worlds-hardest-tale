
local function getTableElementsAsString(tbl)
	local str = ""

	for _,elem in ipairs(tbl) do
		if type(elem) == "table" then
			elem = "{" .. getTableElementsAsString(elem) .. "}"

		end

		str = str .. tostring(elem) .. ", "

	end

	return str:sub(1,-3)

end

function printTable(tbl)

	local str = "{" .. getTableElementsAsString(tbl) .. "}"

	DEBUG(str)

end

_DEBUG_ORIGINAL_ = DEBUG
function DEBUG(param)
	if type(param) == "table" then
		printTable(param)

	else
		_DEBUG_ORIGINAL_(param)

	end
end
