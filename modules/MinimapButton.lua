--[[----------------------------------------------------------------------
      MinimapButton Module - Part of VanasKoS
Creates a MinimapButton with a menu for VanasKoS
------------------------------------------------------------------------]]

local L = LibStub("AceLocale-3.0"):GetLocale("VanasKoS/MinimapButton", false)
local icon = LibStub("LibDBIcon-1.0")
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local VanasKoS = LibStub("AceAddon-3.0"):GetAddon("VanasKoS")
local VanasKoSGUI = VanasKoS:GetModule("GUI")
local VanasKoSMinimapButton = VanasKoS:NewModule("MinimapButton", "AceEvent-3.0", "AceTimer-3.0")

-- Initialized later
local PvPDataGatherer = nil
local warnFrame = nil

-- Declare some common global functions local
local pairs = pairs
local format = format
local time = time
local date = date
local wipe = wipe
local SecondsToTime = SecondsToTime
local IsShiftKeyDown = IsShiftKeyDown
local GetCursorPosition = GetCursorPosition
local hashName = VanasKoS.hashName

-- Local Variables
local attackerMenu = {}
local nearbyKoS = {}
local nearbyEnemies = {}
local nearbyFriendly = {}
local nearbyKoSCount = 0
local nearbyEnemyCount = 0
local nearbyFriendlyCount = 0
local timer = nil
local showWarnFrameInfoText = false

-- Create our Lib Data Broker Object
local Broker = ldb:NewDataObject("VanasKoS", {
	type = "launcher",
	icon = "Interface\\Icons\\Ability_Parry",
	OnClick = function(self, button)
		VanasKoSMinimapButton:OnClick(button)
	end,
	OnTooltipShow = function(tt)
		VanasKoSMinimapButton:OnTooltipShow(tt)
	end
})

function VanasKoSMinimapButton:OnInitialize()
	self.db = VanasKoS.db:RegisterNamespace("MinimapButton", {
		profile = {
			Enabled = true,
			Moved = false,
			ShowWarnFrameInfoText = true,
			button = {},
			ReverseButtons = false,
		}
	})

	self.name = "VanasKoSMinimapButton"

	self.configOptions = {
		type = 'group',
		name = L["Minimap Button"],
		desc = L["Minimap Button"],
		args = {
			showInfo = {
				type = 'toggle',
				name = L["Show information"],
				desc = L["Show Warning Frame Infos as Text and Tooltip"],
				order = 1,
				set = function(frame, v)
					VanasKoSMinimapButton.db.profile.ShowWarnFrameInfoText = v
					if (v) then
						VanasKoSMinimapButton:EnableWarnFrameText()
					else
						VanasKoSMinimapButton:EnableWarnFrameText()
					end
				end,
				get = function()
					return VanasKoSMinimapButton.db.profile.ShowWarnFrameInfoText
				end,
			},
			reverseButtons = {
				type = 'toggle',
				name = L["Reverse Buttons"],
				desc = L["Reverse action of left/right mouse buttons"],
				order = 2,
				set = function(frame, v)
					VanasKoSMinimapButton.db.profile.ReverseButtons = v
				end,
				get = function()
					return VanasKoSMinimapButton.db.profile.ReverseButtons
				end,
			},
		},
	}

	PvPDataGatherer = VanasKoS:GetModule("PvPDataGatherer", false)
	warnFrame = VanasKoS:GetModule("WarnFrame", false)
	VanasKoSGUI:AddModuleToggle("MinimapButton", L["Minimap Button"])
	VanasKoSGUI:AddConfigOption("MinimapButton", self.configOptions)
	self:SetEnabledState(self.db.profile.Enabled)
end

function VanasKoSMinimapButton:Toggle()
	if(icon:IsVisible()) then
		icon:Hide(self.name)
	else
		icon:Show(self.name)
	end
end

function VanasKoSMinimapButton:UpdateOptions()
	if PvPDataGatherer then
		local list = PvPDataGatherer:GetDamageFromArray()

		wipe(attackerMenu)
		if(not list) then
			return
		end

		for _, v in pairs(list) do
			attackerMenu[#attackerMenu+1] = {
				text = format("%s-%s %s", v.name, v.realm, date("%c", v.time)),
				order = #attackerMenu,
				func = function()
					VanasKoSGUI:AddEntry("PLAYERKOS", v.name, v.realm, format(L["Attacked %s on %s"], UnitName("player"), date("%c", v.time)))
				end,
			}
		end
	end
end

function VanasKoSMinimapButton:OnClick(button)
    local action = nil

    -- Determine action based on button and shift key status
    if button == "LeftButton" then
        action = "addkos" 
    elseif button == "RightButton" then
        action = "menu" 
    end

    -- Perform the action
    if action == "menu" then
        self:UpdateOptions()  -- Use `self` to refer to the current object
        local x, y = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
    rootDescription:CreateTitle(VANASKOS.NAME .. " " .. VANASKOS.VERSION)
	rootDescription:CreateButton("Main Window", function() VanasKoSGUI.frame:Show() end)
rootDescription:CreateButton("Warning Window", function() VanasKoS:ToggleModuleActive("WarnFrame") end)
rootDescription:CreateButton("Configuration", function() VanasKoSGUI:OpenConfigWindow() end)
rootDescription:CreateButton("Add Player to KoS", function() VanasKoS:AddEntryFromTarget("PLAYERKOS") end)
rootDescription:CreateButton("Add Guild to KoS", function() VanasKoS:AddEntryFromTarget("GUILDKOS") end)
rootDescription:CreateButton("Add Player to Hatelist", function() VanasKoS:AddEntryFromTarget("HATELIST") end)
rootDescription:CreateButton("Add Player to Nicelist", function() VanasKoS:AddEntryFromTarget("NICELIST") end)
rootDescription:CreateButton("Add Attacker to KoS", function() VanasKoS:AddEntryFromTarget("PLAYERKOS") end)

	
	
end)
    elseif action == "addkos" then
        if UnitExists("target") then  -- Ensure a target exists before adding
            VanasKoS:AddEntryFromTarget("PLAYERKOS")
        else
            print("No valid target selected.")  -- Notify the user if no target is selected
        end
    end
end


function VanasKoSMinimapButton:OnEnable()
	if(not icon:IsRegistered(self.name)) then
		icon:Register(self.name, Broker, self.db.profile.button)
	end
	self.db.profile.button.hide = false
	icon:Refresh(self.name, self.db.profile.button)

	if(self.db.profile.ShowWarnFrameInfoText) then
		self:EnableWarnFrameText()
		if(timer == nil) then
			timer = self:ScheduleRepeatingTimer("UpdateList", 1)
		end
	end
end

function VanasKoSMinimapButton:OnDisable()
	self.db.profile.button.hide = true
	icon:Refresh(self.name, self.db.profile.button)
	self:CancelAllTimers()
	if(self.db.profile.ShowWarnFrameInfoText) then
		self:DisableWarnFrameText()
	end
end

function VanasKoSMinimapButton:EnableWarnFrameText()
	self:RegisterMessage("VanasKoS_Player_Detected", "Player_Detected")
	showWarnFrameInfoText = true
	self:UpdateMyText()
end

function VanasKoSMinimapButton:DisableWarnFrameText()
	self:UnregisterMessage("VanasKoS_Player_Detected")
	showWarnFrameInfoText = false
	Broker.text = nil
end

function VanasKoSMinimapButton:Player_Detected(message, data)
	if(data.name == nil or data.realm == nil or showWarnFrameInfoText == false) then
		return
	end

	if data.list == "PLAYERKOS" or data.list == "GUILDKOS" then
		data.faction = "kos"
	end

	local unitData = {
		name = data.name,
		realm = data.realm,
		faction = data.faction,
		time = time()
	}

	local key = hashName(data.name, data.realm)

	if(data.faction == "kos") then
		if(not nearbyKoS[key]) then
			nearbyKoSCount = nearbyKoSCount + 1
		end
		nearbyKoS[key] = unitData
	elseif(data.faction == "enemy") then
		if(not nearbyEnemies[key]) then
			nearbyEnemyCount = nearbyEnemyCount + 1
		end
		nearbyEnemies[key] = unitData
	elseif(data.faction == "friendly") then
		if(not nearbyFriendly[key]) then
			nearbyFriendlyCount = nearbyFriendlyCount + 1
		end
		nearbyFriendly[key] = unitData
	else
		return
	end
	self:UpdateMyText()
end


function VanasKoSMinimapButton:RemovePlayer(key)
	if (nearbyKoS[key]) then
		nearbyKoS[key] = nil
		nearbyKoSCount = nearbyKoSCount - 1
	end
	if (nearbyEnemies[key]) then
		nearbyEnemies[key] = nil
		nearbyEnemyCount = nearbyEnemyCount - 1
	end
	if (nearbyFriendly[key]) then
		nearbyFriendly[key] = nil
		nearbyFriendlyCount = nearbyFriendlyCount - 1
	end
	self:UpdateMyText()
end

function VanasKoSMinimapButton:UpdateMyText()
	Broker.text = "|cffffff00" .. nearbyKoSCount .. "|r |cffff0000" .. nearbyEnemyCount .. "|r |cff00ff00" .. nearbyFriendlyCount .. "|r"
end

function VanasKoSMinimapButton:OnTooltipShow(tt)
	tt:AddLine(VANASKOS.NAME)

	if PvPDataGatherer then
		local list = PvPDataGatherer:GetDamageFromArray()
		if (#list > 0) then
			tt:AddLine(L["Last Attackers"] .. ":", 1.0, 1.0, 1.0)

			for _, v in pairs(list) do
				tt:AddDoubleLine(v.name .. "-" .. v.realm, format(L["%s ago"], SecondsToTime(time() - v.time)), 1.0, 0.0, 0.0, 1.0, 1.0, 1.0)
			end
		end
	end

	if(showWarnFrameInfoText and (nearbyKoSCount + nearbyEnemyCount + nearbyFriendlyCount) > 0) then
		tt:AddLine(L["Nearby People"] .. ":", 1.0, 1.0, 1.0)
		for _, v in pairs(nearbyKoS) do
			tt:AddLine(v.name, 1.0, 0.0, 1.0)
		end
		for _, v in pairs(nearbyEnemies) do
			tt:AddLine(v.name, 1.0, 0.0, 0.0)
		end
		for _, v in pairs(nearbyFriendly) do
			tt:AddLine(v.name, 0.0, 1.0, 0.0)
		end
	end
end

function VanasKoSMinimapButton:UpdateList()
	local t = time()
	for k, v in pairs(nearbyKoS) do
		if(t - v.time > 60) then
			self:RemovePlayer(k)
		end
	end
	for k, v in pairs(nearbyEnemies) do
		if(t - v.time > 10) then
			self:RemovePlayer(k)
		end
	end
	for k, v in pairs(nearbyFriendly) do
		if(t - v.time > 10) then
			self:RemovePlayer(k)
		end
	end
end
