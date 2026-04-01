local api = require("api")

local better_raid_info_addon = {
	name = "Better Raid Info",
	author = "Michaelqt",
	version = "1.1.1",
	desc = "Raid Manager UI, export raid lists, average stats."
}

local lastRadiusReset = api.Time:GetUiMsec()
local raidManagerWnd
local maxRaidMemberCount = 50
local gearscores = {}
local lootdrops = {}
local betterRaidInfoEventWnd


local function getAverageGearscoreInRaid(raidManagerWnd)
	for i=1, maxRaidMemberCount do
		local partyIndex = math.ceil(i / 5)
		local memberIndex = i % 5
		if memberIndex == 0 then
			-- displayString = displayString .. "\n"
			  memberIndex = 5
		end
		local memberList = {}
		local member = raidManagerWnd.party[partyIndex].member[memberIndex]
		if member ~= nil then 
			local nameLabelVisible = raidManagerWnd.party[partyIndex].member[memberIndex].nameLabel:IsVisible()
			if nameLabelVisible and api.Unit:GetUnitId("team" .. tostring(i)) ~= nil then 
				local memberName = raidManagerWnd.party[partyIndex].member[memberIndex].nameLabel:GetText()
				local memberGearscore = api.Unit:UnitGearScore("team" .. tostring(i))
				if memberGearscore ~= nil and memberGearscore ~= false then 
					gearscores[memberName] = memberGearscore 
					
				end 
			else
				-- Skip the player
				-- displayString = displayString .. tostring("skipped") .. "\n"
			end
		else
			-- api.Log:Info("empty member slot...")
		end
	end
	local playerGearscoresRecorded = 0
	local totalGearscore = 0
	
	for key, value in pairs(gearscores) do 
		if api.Team:GetMemberIndexByName(key) ~= nil then
			totalGearscore = totalGearscore + value
			playerGearscoresRecorded = playerGearscoresRecorded + 1
		else 
			gearscores[key] = nil
		end 
	end
	
	return tostring(math.floor(totalGearscore / playerGearscoresRecorded))
end 
local function getAverageLootdropInRaid(raidManagerWnd)
	for i=1, maxRaidMemberCount do
		local partyIndex = math.ceil(i / 5)
		local memberIndex = i % 5
		if memberIndex == 0 then
			-- displayString = displayString .. "\n"
			  memberIndex = 5
		end
		local memberList = {}
		local member = raidManagerWnd.party[partyIndex].member[memberIndex]
		if member ~= nil then 
			local nameLabelVisible = raidManagerWnd.party[partyIndex].member[memberIndex].nameLabel:IsVisible()
			if nameLabelVisible and api.Unit:GetUnitId("team" .. tostring(i)) ~= nil then 
				local memberName = raidManagerWnd.party[partyIndex].member[memberIndex].nameLabel:GetText()
				local memberInfo = api.Unit:UnitInfo("team" .. tostring(i))
				if memberInfo ~= nil and memberInfo ~= 0 then 
					local memberLootdrop = memberInfo["drop_rate_mul"]
					-- for key,value in pairs(memberInfo) do
					--     api.Log:Info("found member " .. key);
					-- end
					lootdrops[memberName] = tonumber(memberLootdrop) 
					
				end 
			else
				-- Skip the player
				-- displayString = displayString .. tostring("skipped") .. "\n"
			end
		else
			-- api.Log:Info("empty member slot...")
		end
	end
	local playerLootdropsRecorded = 0
	local totalLootdrop = 0
	
	for key, value in pairs(lootdrops) do 
		if api.Team:GetMemberIndexByName(key) ~= nil then
			totalLootdrop = totalLootdrop + value
			playerLootdropsRecorded = playerLootdropsRecorded + 1
		else 
			lootdrops[key] = nil
		end 
	end
	
	return tostring(math.floor(totalLootdrop / playerLootdropsRecorded))
end 
local radiusResetRate = 5000
local function OnUpdate(dt)
	lastRadiusReset = lastRadiusReset + dt
	if lastRadiusReset > radiusResetRate then
		-- raidManagerWnd = ADDON:GetContent(UIC.RAID_MANAGER)
		-- raidManagerWnd:CheckAuthority()
		
		dismissRaidBtnText = raidManagerWnd.dismissRaidBtn:GetText()
		if dismissRaidBtnText == "Disband Raid" then 
			-- if we're able to disband the raid, then we can invite as well
			raidManagerWnd.rangeInviteBtn:Enable(true)
		end 
		
		averageGearscore = getAverageGearscoreInRaid(raidManagerWnd)
		averageLootdrop = getAverageLootdropInRaid(raidManagerWnd)
		raidManagerWnd.avgGsLabel:SetText("Avg Gearscore: " .. averageGearscore)
		raidManagerWnd.avgLootDropLabel:SetText("Avg Loot Drop: " .. averageLootdrop .. "%")
		
		lastRadiusReset = dt
	end
end

local function OnLoad()
	local settings = api.GetSettings("better_raid_info")

	betterRaidInfoEventWnd = api.Interface:CreateEmptyWindow("betterRaidInfoEventWnd", "UIParent")
	raidManagerWnd = ADDON:GetContent(UIC.RAID_MANAGER)

	local avgGsLabel = raidManagerWnd:CreateChildWidget("label", "avgGsLabel", 0, 0)
	avgGsLabel:SetText("Avg Gearscore: ")
	avgGsLabel.style:SetAlign(ALIGN.LEFT)
	ApplyTextColor(avgGsLabel, FONT_COLOR.DEFAULT)
	avgGsLabel:AddAnchor("TOPLEFT", raidManagerWnd, 30, 30)
	raidManagerWnd.avgGsLabel = avgGsLabel

	local avgLootDropLabel = raidManagerWnd:CreateChildWidget("label", "avgLootDropLabel", 0, 0)
	avgLootDropLabel:SetText("Avg Loot Drop: ")
	avgLootDropLabel.style:SetAlign(ALIGN.LEFT)
	ApplyTextColor(avgLootDropLabel, FONT_COLOR.DEFAULT)
	avgLootDropLabel:AddAnchor("TOPLEFT", raidManagerWnd, 30, 46)
	raidManagerWnd.avgLootDropLabel = avgLootDropLabel

	local exportRaidTextBtn = raidManagerWnd:CreateChildWidget("button", "minimizeButton", 0, true)
	exportRaidTextBtn:SetText("Export Raid List")
	exportRaidTextBtn:AddAnchor("TOPRIGHT", raidManagerWnd, -30, 30)
	api.Interface:ApplyButtonSkin(exportRaidTextBtn, BUTTON_BASIC.DEFAULT)


	local exportRaidTextWnd = api.Interface:CreateWindow("exportRaidTextWnd", "Exported Raid List")
	exportRaidTextWnd:AddAnchor("RIGHT", raidManagerWnd, 0, 0)
	exportRaidTextWnd:SetExtent(300, 1000)

	local raidListTextEdit = W_CTRL.CreateMultiLineEdit("raidListTextEdit", exportRaidTextWnd)
	local sizeX, sizeY = exportRaidTextWnd:GetExtent()
	sizeX = sizeX - 30
	sizeY = sizeY - 60
	raidListTextEdit:SetExtent(sizeX, sizeY)
	raidListTextEdit:SetMaxTextLength(5000)
	-- raidListTextEdit:SetMaxLines(50)
	raidListTextEdit:AddAnchor("TOPLEFT", exportRaidTextWnd, 15, 45)


	exportRaidTextBtn:SetHandler("OnClick", function()
		local maxRaidMemberCount = 50
		local displayString = ""
		
		for i=1, maxRaidMemberCount do
			local partyIndex = math.ceil(i / 5)
			local memberIndex = i % 5
			if memberIndex == 0 then
				-- displayString = displayString .. "\n"
			  	memberIndex = 5
			end
			local member = raidManagerWnd.party[partyIndex].member[memberIndex]
			if member ~= nil then 
				local nameLabelVisible = raidManagerWnd.party[partyIndex].member[memberIndex].nameLabel:IsVisible()
				if nameLabelVisible and api.Unit:GetUnitId("team" .. tostring(i)) ~= nil then 
					local memberName = raidManagerWnd.party[partyIndex].member[memberIndex].nameLabel:GetText()
					displayString = displayString .. tostring(memberName) .. "\n"
				else
					-- Skip the player
					-- displayString = displayString .. tostring("skipped") .. "\n"
				end
			else
				-- api.Log:Info("empty member slot...")
			end
			-- displayString = displayString .. "raidMember" .. tostring(i) .. "\n"
		end 
		raidListTextEdit:SetText(displayString)
		exportRaidTextWnd:Show(true)

		api.File:Write("better_raid_info/raid_lists/" .. tostring("last_raid_list.txt"), displayString)
	end)

	function onRaidFrameToggle(frame, show)
		api.Log:Info("frame")
		for key, value in pairs(frame) do
			api.Log:Info("key: " .. tostring(key) .. ", value: " .. tostring(value))
		end
        raidManagerWnd.rangeInviteBtn:Enable(true)
    end

	api.On("raid_frame_toggle", onRaidFrameToggle)
	--api.On("UPDATE", OnUpdate)
	api.SaveSettings()
end
api.On("UPDATE", OnUpdate)
local function OnUnload()
	local settings = api.GetSettings("better_raid_info")
	raidManagerWnd = ADDON:GetContent(UIC.RAID_MANAGER)
	raidManagerWnd.avgGsLabel:SetText("")
	raidManagerWnd.avgLootDropLabel:SetText("")
end

better_raid_info_addon.OnLoad = OnLoad
better_raid_info_addon.OnUnload = OnUnload

return better_raid_info_addon
