-- Core achievements script with icon support and network strings
local achievements = {}

if SERVER then
    util.AddNetworkString("SendAchievementsData")
    util.AddNetworkString("UnlockAchievement")
    util.AddNetworkString("ResetAchievements") 
	util.AddNetworkString("ResetStarAchievements") 

    AddCSLuaFile("autorun/client/achievements_tab.lua")
	
    function RegisterAchievement(id, name, description, icon, callback)
        if type(icon) == "function" then
            callback = icon
            icon = nil
        end

        achievements[id] = {
            name = name,
            description = description,
            icon = icon,
            callback = callback,
            unlocked = {} -- Table of players who have unlocked this achievement
        }
    end
    
    -- Function to save player achievements to a file
    local function SavePlayerAchievements(ply)
        local sid = ply:SteamID()
        local data = {}
        -- Go through each achievement and if it is unlocked for the player, save it
        for id, ach in pairs(achievements) do
            if ach.unlocked[sid] then
                table.insert(data, id)
            end
        end
        -- Create the directory if necessary
        if not file.IsDir("vpachievements", "DATA") then
            file.CreateDir("vpachievements")
        end
        local fileName = "vpachievements/" .. string.Replace(sid, ":", "_") .. ".txt"
        file.Write(fileName, util.TableToJSON(data, true))  -- Save in JSON format
    end

    -- Function to load player achievements from file
    local function LoadPlayerAchievements(ply)
        local sid = ply:SteamID()
        local fileName = "vpachievements/" .. string.Replace(sid, ":", "_") .. ".txt"
        if file.Exists(fileName, "DATA") then
            local json = file.Read(fileName, "DATA")
            --print(json)
            local data = util.JSONToTable(json)
            if data then
                for _, id in pairs(data) do
                    if achievements[id] then
                        achievements[id].unlocked[sid] = true
                    end
                end
            end
        end
    end

    local function RefreshAchievements(ply)
    	timer.Simple(1, function()
			if IsValid(ply) then
				LoadPlayerAchievements(ply)
				
				-- Scroll through each achievement to create a list of unlocked achievements for this player.
				local sid = ply:SteamID()
				local unlockedList = {}
				for id, ach in pairs(achievements) do
					if ach.unlocked[sid] then
						table.insert(unlockedList, id)
					end
				end
				--PrintTable(achievements)
				print("Found " .. #unlockedList .. " unlocked achievements for " .. sid)
				
				-- Send the list via the net message "SendAchievementsData"
				net.Start("SendAchievementsData")
					net.WriteTable(unlockedList)
				net.Send(ply)
			end
		end)
    end

    -- Load the player's achievements upon entering the game
	hook.Add("PlayerInitialSpawn", "LoadPlayerAchievements", RefreshAchievements)

	concommand.Add("ach_load", function(ply, cmd, args, str)
		RefreshAchievements(ply)
	end)

    -- We modified UnlockAchievement to save the achievement after unlocking it.
	function UnlockAchievement(ply, id)
		local sid = ply:SteamID()
		if achievements[id] and not achievements[id].unlocked[sid] then
			achievements[id].unlocked[sid] = true

			-- Create a session-only table on the player if it doesn't exist and mark this achievement.
			ply._sessionAchievements = ply._sessionAchievements or {}
			ply._sessionAchievements[id] = true

			net.Start("UnlockAchievement")
				net.WriteString(id)
			net.Send(ply)
			
			ply:ChatPrint("[Achievements] " .. ply:Nick() .. " unlocked: " .. achievements[id].name)
			
			SavePlayerAchievements(ply)
		end
	end

    -- Handler to reset achievements (this message is triggered by pressing the button in the UI)
    net.Receive("ResetAchievements", function(len, ply)
        local sid = ply:SteamID()
        for id, ach in pairs(achievements) do
            if ach.unlocked[sid] and not ach.secret then
                ach.unlocked[sid] = nil
            end
        end

        -- Reset any custom flags or variables
        ply.__spawned_npc = false
        ply.__mapStartTime = nil
		ply._NoClipUsed = false
		
		if _G.playersDrivingAirboatInWater then
			_G.playersDrivingAirboatInWater[sid] = nil
		end
		
		if _G.vehiclesParked then
			_G.vehiclesParked[sid] = nil
		end
		
		if _G.playersAchievedSpeed then
			_G.playersAchievedSpeed[sid] = nil
		end
		
		if _G.AreaLightsCount then
			_G.AreaLightsCount[sid] = nil
		end
		
		-- Clear session achievements for normal (non-secret) achievements.
		if ply._sessionAchievements then
			for id, ach in pairs(achievements) do
				if not ach.secret then
					ply._sessionAchievements[id] = nil
				end
			end
		end

        net.Start("ResetAchievements")
        net.Send(ply)
        
        SavePlayerAchievements(ply)
    end)
	
	net.Receive("ResetStarAchievements", function(len, ply)
		local sid = ply:SteamID()
		for id, ach in pairs(achievements) do
			if ach.unlocked[sid] and ach.secret then
				ach.unlocked[sid] = nil
			end
		end
		
		ply._sessionAchievements = {}
		
		net.Start("ResetStarAchievements")
		net.Send(ply)
		
		SavePlayerAchievements(ply)
	end)
	

	RegisterAchievement("wanderer_space", "SPAAAAAACE", "Wait, there are spaceships in the Void?", function(ply)
		if game.GetMap() == "vpc_wanderer" then
			UnlockAchievement(ply, "wanderer_space")
		end
	end)

	RegisterAchievement("skytech_enter", "Why are these guys still using Windows XP anyway?", "Visit Skytech", function(ply)
		if game.GetMap() == "vp_skytech" then
			UnlockAchievement(ply, "skytech_enter")
		end
	end)

	RegisterAchievement("struggle_enter", "This looks normal", "gm_struggle is actually a Voidplaces map", function(ply)
		if game.GetMap() == "gm_struggle" then
			UnlockAchievement(ply, "struggle_enter")
		end
	end)

	RegisterAchievement("inno_n_out_number9", "I'll have two number 9, a number 9 large...", "A number 6 with extra dip, a number 7, two number 45s, one with cheese, and a large soda.", function(ply)
		if game.GetMap() == "vpc_inno_n_out" then
			UnlockAchievement(ply, "inno_n_out_number9")
		end
	end)

	RegisterAchievement("whitecomplex_enter", "White Complex? I find it quite simple", "Visit White Complex", function(ply)
		if game.GetMap() == "vp_whitecomplex" then
			UnlockAchievement(ply, "whitecomplex_enter")
		end
	end)

	RegisterAchievement("downcorridors_enter", "The Sun is not a lie", "But the cake is.", function(ply)
		if game.GetMap() == "vp_downcorridors" then
			UnlockAchievement(ply, "downcorridors_enter")
		end
	end)

	RegisterAchievement("ucomplex_enter", "MEDIC!", "Visit the Moonlit Medical Station", function(ply)
		if game.GetMap() == "vp_04_ucomplex" then
			UnlockAchievement(ply, "ucomplex_enter")
		end
	end)

	RegisterAchievement("whitecorridors_enter", "I hate offices", "Visit White Corridors", function(ply)
		if game.GetMap() == "vp_01_whitecorridors" then
			UnlockAchievement(ply, "whitecorridors_enter")
		end
	end)

	RegisterAchievement("darklight_illumi", "Need a hand?", "Encounter Illumi", function(ply)
		if game.GetMap() == "vpc_darklight_final" then
			local pos = ply:GetPos()
			if pos:WithinAABox(Vector(2556, -4, 515), Vector(1887, -402, -145)) then
				UnlockAchievement(ply, "darklight_illumi")
			end
		end
	end)

	RegisterAchievement("voidmall_watched", "Im feeling watched", "Was that cutout always looking this way?", function(ply)
		if game.GetMap() == "vp_voidmall" then
			local pos = ply:GetPos()
			if pos:WithinAABox(Vector(3521, 3529, -479), Vector(3662, 4016, -620)) then
				UnlockAchievement(ply, "voidmall_watched")
			end
		end
	end)

	RegisterAchievement("voidmall_illbeback", "I'll be back", "Disappoint the Innocence", function(ply)
		if game.GetMap() == "vp_voidmall" then
			local pos = ply:GetPos()
			if pos:WithinAABox(Vector(-712, 1791, -1213), Vector(-1281, 2049, -1086)) then
				UnlockAchievement(ply, "voidmall_illbeback")
			end
		end
	end)

	RegisterAchievement("nowheremall_enter", "This wasn't here before", "Enter Nowheremall from Otherside", function(ply)
		if game.GetMap() == "vp_nowheremall" then
			local pos = ply:GetPos()
			if pos:WithinAABox(Vector(2723, 6542, -1263), Vector(2648, 5545, -1135)) then
				UnlockAchievement(ply, "nowheremall_enter")
			end
		end
	end)

	RegisterAchievement("deletedsector_oob", "You weren't meant to be here, you know? (=", "Get out of the map in Deleted Sector", function(ply)
		if game.GetMap() == "vp_deletedsector" then
			local pos = ply:GetPos()
			if pos:WithinAABox(Vector(-4162, -3453, 100), Vector(-5052, -2627, 300)) then
				UnlockAchievement(ply, "deletedsector_oob")
			end
		end
	end)

	RegisterAchievement("otherside_uncomplicated_guy", "Uncomplicated Guy", "Show up in Simple Man's den cosplaying Simple Man", function(ply)
		if game.GetMap() == "otherside" then
			local pos = ply:GetPos()
			if pos:WithinAABox(Vector(2535, 1407, 363), Vector(2144, 3171, 950)) and
				ply:GetModel() == "models/kuruka_cheyn/pnk_black/pnk_black_pm.mdl" and
				ply:GetActiveWeapon():GetClass() == "ironlady"
			then
				UnlockAchievement(ply, "otherside_uncomplicated_guy")
			end
		end
	end)

	RegisterAchievement("otherside_texas_massacre", "Void Chainsaw Massacre", "Survive the Simple Man", function(ply)
		if game.GetMap() == "otherside" then
			local pos = ply:GetPos()
			local pnk_not_spawned = false
			for _, ent in ents.Iterator() do
				if ent:GetName() == "pdr_pnkblast_d1" then pnk_not_spawned = true end
			end
			if pos:WithinAABox(Vector(9492, 2695, 569), Vector(9670, 2350, 725)) and
				not pnk_not_spawned
			then
				UnlockAchievement(ply, "otherside_texas_massacre")
			end
		end
	end)

	RegisterAchievement("pinkplace_67", "Aint funny", "Die from cringe on Pinkplace", function(ply)
		if game.GetMap() == "vp_pinkplace_v2" then
			local pos = ply:GetPos()
			local num = 0
			local number1, number2, number3
			if pos:WithinAABox(Vector(2609, 1226, 322), Vector(2815, 1340, 503)) then
				for _, ent in ents.Iterator() do
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_1" and ent:GetSkin() == 0 then
						num = num + tonumber(ent:GetSkin()) * 100
						number1 = ent
					end
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_2" and ent:GetSkin() < 10 then
						num = num + tonumber(ent:GetSkin()) * 10
						number2 = ent
					end
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_3" and ent:GetSkin() < 10 then
						num = num + tonumber(ent:GetSkin()) * 1
						number3 = ent
					end
				end
				if
					num == 67
				then
					if ply:Alive() then
						UnlockAchievement(ply, "pinkplace_67")
					end
					if not timer.Exists("NotFunnyKill") then
						timer.Create("NotFunnyKill", 3, 1, function()
							ply:Kill()
							number1:SetSkin(11)
							number2:SetSkin(11)
							number3:SetSkin(11)
						end)
					end
				end
			end
		end
	end)

	RegisterAchievement("pinkplace_222", "Oh my Sun", "Roll 222 in Fear a Number", function(ply)
		if game.GetMap() == "vp_pinkplace_v2" then
			local pos = ply:GetPos()
			local num = 0
			if pos:WithinAABox(Vector(2609, 1226, 322), Vector(2815, 1340, 503)) then
				for _, ent in ents.Iterator() do
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_1" and ent:GetSkin() < 10 then
						num = num + tonumber(ent:GetSkin()) * 100
					end
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_2" and ent:GetSkin() < 10 then
						num = num + tonumber(ent:GetSkin()) * 10
					end
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_3" and ent:GetSkin() < 10 then
						num = num + tonumber(ent:GetSkin()) * 1
					end
				end
				if
					num == 222
				then
					UnlockAchievement(ply, "pinkplace_222")
				end
			end
		end
	end)

	RegisterAchievement("pinkplace_69", "Nice!", "Roll 69 in Fear a Number", function(ply)
		if game.GetMap() == "vp_pinkplace_v2" then
			local pos = ply:GetPos()
			local num = 0
			if pos:WithinAABox(Vector(2609, 1226, 322), Vector(2815, 1340, 503)) then
				for _, ent in ents.Iterator() do
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_1" and ent:GetSkin() < 10 then
						num = num + tonumber(ent:GetSkin()) * 100
					end
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_2" and ent:GetSkin() < 10 then
						num = num + tonumber(ent:GetSkin()) * 10
					end
					if ent:GetName() == "InstanceAuto28-pdy_r_numberslot_3" and ent:GetSkin() < 10 then
						num = num + tonumber(ent:GetSkin()) * 1
					end
				end
				if
					num == 69
				then
					UnlockAchievement(ply, "pinkplace_69")
				end
			end
		end
	end)
	
	RegisterAchievement("downstreets_bigbrother", "The Big Brother?", "Encounter Him on Downstreets", function(ply)
		if game.GetMap() == "vpc_downstreets" then
			local pnkT2 = false
			local pnkTO = false
			for _, ent in ents.Iterator() do
				if ent:GetName() == "pnkgoodbye" then pnkTO = true end
				if ent:GetName() == "pnktrigger_2" then pnkT2 = true end
			end
			if pnkTO and not pnkT2 then
				UnlockAchievement(ply, "downstreets_bigbrother")
			end
		end
	end)

	RegisterAchievement("pinkplace_backrooms", "Its like someone described pink to a dog that has never seen one...", "Find a Backrooms reference", function(ply)
		if game.GetMap() == "vp_pinkplace_v2" then
			local doorClosing = false
			for _, ent in ents.Iterator() do
				if ent:GetName() == "pdr_backrooms" and ent:GetAngles().y > -85 and ent:GetAngles().y < -5 then doorClosing = true end
			end
			if doorClosing and ply:GetPos():WithinAABox(Vector(-1024, -1815, 13), Vector(463, -1630, 155)) then
				UnlockAchievement(ply, "pinkplace_backrooms")
			end
		end
	end)

	RegisterAchievement("blue_broadcast_imblue", "I'm blue, da ba dee da ba die", "Turn off all TVs on Blue Broadcast", function(ply)
		if game.GetMap() == "vpc_blue_broadcast" then
			local AntennaBroken = false
			for _, ent in ents.Iterator() do
				if ent:GetName() == "tower_fence_door" and ent:GetAngles().y == -90 then AntennaBroken = true end
			end
			if AntennaBroken then
				UnlockAchievement(ply, "blue_broadcast_imblue")
			end
		end
	end)

	RegisterAchievement("downcorridors_stuck", "Like the good old days", "Get softlocked on Down Corridors", function(ply)
		if game.GetMap() == "vp_downcorridors" then
			local door1lck = false
			local door2lck = false
			local door1 = nil
			if ply:GetPos():WithinAABox(Vector(1470, -2012, -791), Vector(1773, -2280, -525)) then
				for _, ent in ents.Iterator() do
					if ent:GetName() == "bstdoor_friends_phase3" and ent:GetInternalVariable( "m_bLocked" ) then 
						door1lck = true 
						door1 = ent
					end
					if ent:GetName() == "bstdoor_friends_phase2" and ent:GetInternalVariable( "m_bLocked" ) then door2lck = true end
				end
				if door1lck and door2lck then
					UnlockAchievement(ply, "downcorridors_stuck")
					door1:Fire("Unlock")
				end
			end
		end
	end)

end

-- Shared functions (client and server)
function CheckAchievements(ply)
    for id, ach in pairs(achievements) do
        ach.callback(ply)
    end
end

local allHooks = hook.GetTable()

if allHooks.Think and allHooks.Think["AchievementThink"] then
    return
end

hook.Add("Think", "AchievementThink", function()
    for _, ply in ipairs(player.GetAll()) do
    	if not timer.Exists("AchievementUpdate") then
    		-- do it with a timer to throttle the logic so toasters like mine dont blow up
    		timer.Create("AchievementUpdate", 1, 0, function()
        		CheckAchievements(ply)
        	end)
    	end
    end
end)

_G.RegisterAchievement = RegisterAchievement
_G.UnlockAchievement = UnlockAchievement