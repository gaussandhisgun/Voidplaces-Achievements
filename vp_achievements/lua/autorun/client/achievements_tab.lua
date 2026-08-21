surface.CreateFont("AchievementNameFont", {
    font = "Trebuchet24",
    size = 22,
    weight = 800
})

surface.CreateFont("AchievementDescFont", {
    font = "Tahoma",
    size = 17,
    weight = 800
})

if CLIENT then

    -- Here you define the list of achievements, their description, icon and if it is secret
    local ACHIEVEMENTS = {
        { id = "pinkplace_222",   name = "Oh my Sun",              description = "Roll 222 in Fear a Number",  icon = "icon16/award_star_gold_3.png" },
        { id = "pinkplace_69",   name = "Nice!",              description = "Roll 69 in Fear a Number",  icon = "icon16/award_star_gold_3.png" },
        { id = "pinkplace_67",   name = "Aint funny",              description = "Die from cringe on Pinkplace",  icon = "icon16/award_star_gold_3.png", secret = true},
        { id = "voidmall_watched",   name = "Im feeling watched",              description = "Was that cutout always looking this way?",  icon = "icon16/award_star_gold_3.png" },
        { id = "nowheremall_enter",   name = "This wasn't here before", description = "Enter Nowheremall from Otherside",  icon = "icon16/award_star_gold_3.png" },
        { id = "otherside_texas_massacre",   name = "Void Chainsaw Massacre", description = "Survive the Simple Man",  icon = "icon16/award_star_gold_3.png" },
        { id = "wanderer_space", name = "SPAAAAAACE", description = "Wait, there are spaceships in the Void?", icon = "icon16/award_star_gold_3.png"},
        { id = "struggle_enter", name = "This looks normal", description = "gm_struggle is actually a Voidplaces map",  icon = "icon16/award_star_gold_3.png" },
        { id = "inno_n_out_number9", name = "I'll have two number 9, a number 9 large...", description = "A number 6 with extra dip, a number 7, two number 45s, one with cheese, and a large soda.",  icon = "icon16/award_star_gold_3.png" },
        { id = "downstreets_bigbrother", name = "The Big Brother?", description = "Encounter Him on Downstreets",  icon = "icon16/award_star_gold_3.png" },
        { id = "blue_broadcast_imblue", name = "I'm blue, da ba dee da ba die", description = "Turn off all TVs on Blue Broadcast",  icon = "icon16/award_star_gold_3.png" },
        { id = "darklight_illumi", name = "Need a hand?", description = "Encounter Illumi",  icon = "icon16/award_star_gold_3.png" },
        { id = "otherside_uncomplicated_guy", name = "Uncomplicated Guy", description = "Show up in Simple Man's den cosplaying Simple Man",  icon = "icon16/award_star_gold_3.png", secret = true},
        { id = "pinkplace_backrooms", name = "Its like someone described pink to a dog that has never seen one...", description = "Find a Backrooms reference",  icon = "icon16/award_star_gold_3.png" },
        { id = "voidmall_illbeback", name = "I'll be back", description = "Disappoint the Innocence",  icon = "icon16/award_star_gold_3.png" },
        { id = "downcorridors_enter", name = "The Sun is not a lie", description = "But the cake is.",  icon = "icon16/award_star_gold_3.png" },
        { id = "ucomplex_enter", name = "MEDIC!", description = "Visit the Moonlit Medical Station",  icon = "icon16/award_star_gold_3.png" },
        { id = "whitecorridors_enter", name = "I hate offices", description = "Visit White Corridors",  icon = "icon16/award_star_gold_3.png" },
        { id = "skytech_enter", name = "Why are these guys still using Windows XP anyway?", description = "Visit Skytech",  icon = "icon16/award_star_gold_3.png" },
        { id = "whitecomplex_enter", name = "White Complex? I find it quite simple", description = "Visit White Complex",  icon = "icon16/award_star_gold_3.png" },
        { id = "deletedsector_oob", name = "You weren't meant to be here, you know? (=", description = "Get out of the map in Deleted Sector", icon = "icon16/award_star_gold_3.png", secret = true},
        { id = "downcorridors_stuck", name = "Like the good old days", description = "Get softlocked on Down Corridors", icon = "icon16/award_star_gold_3.png", secret = true}
    }

    -- Table of unlocked achievements
    local unlocked = {}

    -- References to widgets to be able to refresh them
    local mainPanel, bar, lbl, scroll, trophy

    -- Function that (re)fills the UI according to `unlocked`
	local function RefreshAchievementsUI()
		if not IsValid(scroll) then return end

		-- Calculate progress
		local total, got = 0, 0

		for _, ach in ipairs(ACHIEVEMENTS) do
			if not ach.secret then
				total = total + 1
				if unlocked[ach.id] then
					got = got + 1
				end
			end
		end

		bar:SetFraction(got / total)
		lbl:SetText(string.format("Progress: %d / %d", got, total))

		-- Change the trophy icon to black and white if not all of them have been unlocked.
		if IsValid(trophy) then
			if got < total then
				trophy:SetImageColor(Color(100, 100, 100, 100))
			else
				trophy:SetImageColor(Color(255, 255, 255, 255))
			end
		end

		-- Clear the children of the scroll
		scroll:Clear()

		-- Reconstruct each entry
		for _, ach in ipairs(ACHIEVEMENTS) do
			if not ach.secret or unlocked[ach.id] then
				local pnl = vgui.Create("DPanel", scroll)
				pnl:Dock(TOP)
				pnl:SetTall(64)
				pnl:DockMargin(5,5,5,0)
				pnl:DockPadding(8,8,8,8)
				function pnl:Paint(w, h)
					derma.SkinHook("Paint", "Panel", self, w, h)
					surface.SetDrawColor(241, 241, 241, 255)
					surface.DrawRect(0, 0, w, h)
					if unlocked[ach.id] then
						surface.SetDrawColor(255, 215, 0, 255)
						surface.DrawOutlinedRect(0, 0, w, h)
					end
				end

				local icon = vgui.Create("DImage", pnl)
				icon:Dock(LEFT)
				icon:SetSize(48,48)
				icon:SetImage(ach.icon)
				if not unlocked[ach.id] then
					icon:SetAlpha(100)
					icon:SetImageColor(Color(100, 100, 100))
				else
					icon:SetImageColor(Color(255, 255, 255))
				end

				local title = vgui.Create("DLabel", pnl)
				title:Dock(TOP)
				title:DockMargin(8,0,0,0)
				title:SetFont("AchievementNameFont")
				title:SetText(ach.name)
				title:SetTextColor(Color(102, 102, 102, 255))

				local desc = vgui.Create("DLabel", pnl)
				desc:Dock(BOTTOM)
				desc:DockMargin(8,0,0,0)
				desc:SetFont("AchievementDescFont")
				desc:SetText(ach.description)
			end
		end
	end


    -- Build the panel once, saving references
	local function BuildAchievementsPanel()
		mainPanel = vgui.Create("DPanel")
		mainPanel:Dock(FILL)
		mainPanel:SetPaintBackgroundEnabled(false)
		mainPanel.Paint = function(self, w, h)
			surface.SetDrawColor(156, 159, 164, 255)
			surface.DrawRect(0, 0, w, h)
		end

		-- Progress container: trophy, progress bar, and progress label in one panel.
		local progressContainer = vgui.Create("DPanel", mainPanel)
		progressContainer:Dock(TOP)
		progressContainer:SetTall(68)  -- tall enough for trophy, bar, and label
		progressContainer:DockMargin(10,10,10,5)
		progressContainer.Paint = function() end  -- no background

		-- Trophy icon
		trophy = vgui.Create("DImage", progressContainer)
		trophy:SetImage("icon16/award_star_gold_2.png")
		trophy:SetSize(64,64)
		trophy:Dock(LEFT)
		trophy:DockMargin(0,2,8,2)

		-- Progress bar
		bar = vgui.Create("DProgress", progressContainer)
		bar:Dock(TOP)
		bar:SetTall(40)
		bar:DockMargin(0,0,0,5)
		bar.Paint = function(self, w, h)
			surface.SetDrawColor(240,240,240,255)
			surface.DrawRect(0,0,w,h)
			local fillW = self:GetFraction() * w
			surface.SetDrawColor(180,250,180,255)
			surface.DrawRect(0,0,fillW,h)
			surface.SetDrawColor(59,59,59,255)
			surface.DrawOutlinedRect(0,0,w,h)
		end

		-- Progress label placed immediately below the progress bar
		lbl = vgui.Create("DLabel", progressContainer)
		lbl:Dock(TOP)
		lbl:DockMargin(0,0,0,0)
		lbl:SetContentAlignment(4)  -- center aligned
		-- The text will be updated in RefreshAchievementsUI

		-- Create a horizontal container for the two reset buttons:
		local buttonContainer = vgui.Create("DPanel", mainPanel)
		buttonContainer:Dock(TOP)
		buttonContainer:SetTall(35)
		buttonContainer:DockMargin(10,0,10,10)
		buttonContainer.Paint = function(self, w, h) end  -- transparent

		-- Reset Normal Achievements button (left side)
		local resetButton = vgui.Create("DButton", buttonContainer)
		resetButton:Dock(LEFT)
		resetButton:SetWide(200)
		resetButton:SetText("Reset Normal Achievements")
		resetButton.DoClick = function()
			net.Start("ResetAchievements")
			net.SendToServer()
		end

		-- Reset Secret Achievements button (to the right of the first)
		local resetSecretButton = vgui.Create("DButton", buttonContainer)
		resetSecretButton:Dock(LEFT)
		resetSecretButton:SetWide(200)
		resetSecretButton:SetText("Reset Secret Achievements")
		resetSecretButton.DoClick = function()
			net.Start("ResetStarAchievements")
			net.SendToServer()
		end

		-- Scroll panel for achievement entries
		scroll = vgui.Create("DScrollPanel", mainPanel)
		scroll:Dock(FILL)

		RefreshAchievementsUI()
		return mainPanel
	end

    -- Upon receiving the message, mark and refresh
    net.Receive("UnlockAchievement", function()
        local id = net.ReadString()
        unlocked[id] = true

        if IsValid(mainPanel) then
            RefreshAchievementsUI()
        end
    end)
	
	-- Receive information about unlocked achievements when you log in
	net.Receive("SendAchievementsData", function()
		local data = net.ReadTable() -- data is a table with the IDs of unlocked achievements
		for _, id in ipairs(data) do
			unlocked[id] = true
		end
		RefreshAchievementsUI()
	end)
	
	-- Receiver for normal achievements:
	net.Receive("ResetAchievements", function()
		for k, v in pairs(unlocked) do
			-- Find the achievement in the local ACHIEVEMENTS table.
			local isSecret = false
			for _, ach in ipairs(ACHIEVEMENTS) do
				if ach.id == k then
					isSecret = ach.secret or false
					break
				end
			end
			if not isSecret then
				unlocked[k] = nil
			end
		end
		RefreshAchievementsUI()
	end)

	-- Receiver for secret achievements:
	net.Receive("ResetStarAchievements", function()
		for k, v in pairs(unlocked) do
			local isSecret = false
			for _, ach in ipairs(ACHIEVEMENTS) do
				if ach.id == k then
					isSecret = ach.secret or false
					break
				end
			end
			if isSecret then
				unlocked[k] = nil
			end
		end
		RefreshAchievementsUI()
	end)

    -- Regist the tab
	hook.Add("PopulateToolMenu", "MyAchievementsSpawnmenuTab", function()
		spawnmenu.AddCreationTab("Achievements", BuildAchievementsPanel, "icon16/award_star_gold_1.png", 0)
	end)
end
