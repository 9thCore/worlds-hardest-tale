--Library created by RickG00 and WD200019

--	WARNING: this library requires the version of CYF 0.6.3 or higher, lower versions or Unitale won't work.

--	How to use:
--		1)Put this file into the "Libraries" folder of your mod;
--		2)In the encounter script, write " require "Libraries/Preload" " in the "EncounterStarting" function;
--		3)Profit??

--	Mods with tons of sprites, musics and sounds might take a while to start, but they will be lag-free when those files are used later.


function Search_Folders(path, searching_for)

	local temp_table = Misc.ListDir(path, true)
	for i = 1, #temp_table do
		local temp_table2 = Misc.ListDir(path .. "/" .. temp_table[i], false)
		local new_path = string.gsub(path, searching_for, "", 1) .. "/" .. temp_table[i] .. "/"
		Load_Files(temp_table2, new_path, searching_for)
		Search_Folders(path .. "/" .. temp_table[i], searching_for)
	end

end

function Load_Files(t, path, searching_for)

	for j = 1, #t do
		if searching_for == "Sprites" then
			
			if string.endsWith(t[j], ".png") then
				Sprite_File.Set(path .. t[j]:gsub(".png", ''))
			end
			
		elseif searching_for == "Sounds" or searching_for == "Audio" then
		
			local file_type = nil
			if string.endsWith(t[j], ".wav") then
				file_type = "wav"
			elseif string.endsWith(t[j], ".ogg") then
				file_type = "ogg"
			end
			
			if file_type == "wav" or file_type == "ogg" then
				if searching_for == "Sounds" then
					NewAudio.PlaySound("|__Preload_Channel__|", path .. t[j]:gsub("." .. file_type, ''), false, 0)
				else
					NewAudio.PlayMusic("|__Preload_Channel__|", path .. t[j]:gsub("." .. file_type, ''), false, 0)
				end
			end

		end
	end

end

if isCYF == true then
	if CYFversion >= "0.6.3" and CYFversion != "1.0" then
	
		if CYFversion == "0.6.3" or Misc.DirExists("Sprites") then
			Sprite_File = CreateSprite("empty")
			
			Load_Files(Misc.ListDir("Sprites", false), "", "Sprites")
			Search_Folders("Sprites", "Sprites")
			
			Sprite_File.Remove()
		end

		NewAudio.CreateChannel("|__Preload_Channel__|")
		
		if CYFversion == "0.6.3" or Misc.DirExists("Sounds") then
			Load_Files(Misc.ListDir("Sounds", false), "", "Sounds")
			Search_Folders("Sounds", "Sounds")
		end
		
		if CYFversion == "0.6.3" or Misc.DirExists("Audio") then
			Load_Files(Misc.ListDir("Audio", false), "", "Audio")
			Search_Folders("Audio", "Audio")
		end

		NewAudio.DestroyChannel("|__Preload_Channel__|")
	else
		DEBUG("Your CYF version is too outdated, it was not possible to preload anything.")
	end
else
	DEBUG("You are not using CYF, it was not possible to preload anything.")
end