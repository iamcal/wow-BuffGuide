BuffGuide = {};
BuffGuide.fully_loaded = false;
BuffGuide.default_options = {

	-- main frame position
	frameRef = "CENTER",
	frameX = 0,
	frameY = 0,
	hide = false,

	-- sizing
	frameW = 200,
	frameH = 200,
};

BuffGuide.buffs = {
	stats = {
		name = "Stats",
		description = "Strength, Agility, and Intellect increased by 5%",
		classes = "Druid, Monk, Paladin, BM Hunter (Shale Spider)",
		buffs = {
			"Mark of the Wild",
			"Legacy of the Emperor",
			"Blessing of Kings",
			"Embrace of the Shale Spider",
		},
	},
	stamina = {
		name = "Stamina",
		description = "+10% Stamina",
		classes = "Priest, Warlock, Warrior, BM Hunter (Silithid)",
		buffs = {
			"Power Word: Fortitude",
			"Blood Pact",
			"Commanding Shout",
			"Qiraji Fortitude",
		},
	},
	attack_power = {
		name = "Attack Power",
		description = "10% Melee and Ranged Attack Power",
		classes = "DK, Hunter, Warrior",
		buffs = {
			"Horn of Winter",
			"Trueshot Aura",
			"Battle Shout",
		},
	},
	spell_power = {
		name = "Spell Power",
		description = "+10% spell power",
		classes = "Mage, Shaman, Warlock, BM Hunter (Waterstrider)",
		buffs = {
			"Arcane Brilliance",
			"Dalaran Brilliance",
			"Burning Wrath",
			"Dark Intent",
			"Still Water",
		},
	},
	haste = {
		name = "Haste",
		description = "+10% Melee and Ranged Haste",
		classes = "Frost DK, Unholy DK, Rogue, Enhancement Shaman, Hunter (Hyena, Serpent)",
		buffs = {
			"Unholy Aura",
			"Swiftblade's Cunning",
			"Unleashed Rage",
			"Cackling Howl",
			"Serpent's Swiftness",
		},
	},
	spell_haste = {
		name = "Spell Haste",
		description = "+5% Spell Haste",
		classes = "Balance Druid, Shadow Priest, Elemental Shaman",
		buffs = {
			"Moonkin Aura",
			"Shadowform",
			"Elemental Oath",
		},
	},
	crit = {
		name = "Critical Strike",
		description = "+5% Ranged, Melee, and Spell Critical Chance",
		classes = "Guardian Druid, Feral Druid, Mage, Hunter (Hydra, Wolf, Devilsaur, Quilen, Water Strider)",
		buffs = {
			"Leader of the Pack",
			"Arcane Brilliance",
			"Dalaran Brilliance",
			"Bellowing Roar",
			"Furious Howl",
			"Terrifying Roar",
			"Fearless Roar",
			"Still Water",
		},
	},
	mastery = {
		name = "Mastery",
		description = "+5 Mastery",
		classes = "Paladin, Shaman, Hunter (Cat, Spirit Beast)",
		buffs = {
			"Blessing of Might",
			"Grace of Air",
			"Roar of Courage",
			"Spirit Beast Blessing",
		},
	},
};

BuffGuide.last_check = 0;
BuffGuide.time_between_checks = 5; -- only update every 5 seconds

function BuffGuide.OnReady()

	-- set up default options
	_G.BuffGuidePrefs = _G.BuffGuidePrefs or {};

	for k,v in pairs(BuffGuide.default_options) do
		if (not _G.BuffGuidePrefs[k]) then
			_G.BuffGuidePrefs[k] = v;
		end
	end

	BuffGuide.CreateUIFrame();
end

function BuffGuide.OnSaving()

	if (BuffGuide.UIFrame) then
		local point, relativeTo, relativePoint, xOfs, yOfs = BuffGuide.UIFrame:GetPoint()
		_G.BuffGuidePrefs.frameRef = relativePoint;
		_G.BuffGuidePrefs.frameX = xOfs;
		_G.BuffGuidePrefs.frameY = yOfs;
	end
end

function BuffGuide.OnUpdate()
	if (not BuffGuide.fully_loaded) then
		return;
	end

	if (BuffGuidePrefs.hide) then 
		return;
	end

	if (BuffGuide.last_check + BuffGuide.time_between_checks < GetTime()) then
		BuffGuide.last_check = GetTime();
		BuffGuide.PeriodicCheck();
	end

	BuffGuide.UpdateFrame();
end

function BuffGuide.OnEvent(frame, event, ...)

	if (event == 'ADDON_LOADED') then
		local name = ...;
		if name == 'BuffGuide' then
			BuffGuide.OnReady();
		end
		return;
	end

	if (event == 'PLAYER_LOGIN') then

		BuffGuide.fully_loaded = true;
		return;
	end

	if (event == 'PLAYER_LOGOUT') then
		BuffGuide.OnSaving();
		return;
	end

	-- if our buff status changes and we're *not* in combat, update
	-- immediately (so buffing before pull is real-time)

	if (event == 'UNIT_AURA') then
		local unitId = ...;
		if (unitId == UnitGUID("player")) then
			if (not UnitAffectingCombat("player")) then
				BuffGuide.PeriodicCheck();
			end
		end
	end
end

function BuffGuide.CreateUIFrame()

	-- create the UI frame
	BuffGuide.UIFrame = CreateFrame("Frame",nil,UIParent);
	BuffGuide.UIFrame:SetFrameStrata("BACKGROUND")
	BuffGuide.UIFrame:SetWidth(_G.BuffGuidePrefs.frameW);
	BuffGuide.UIFrame:SetHeight(_G.BuffGuidePrefs.frameH);

	-- make it black
	BuffGuide.UIFrame.texture = BuffGuide.UIFrame:CreateTexture();
	BuffGuide.UIFrame.texture:SetAllPoints(BuffGuide.UIFrame);
	BuffGuide.UIFrame.texture:SetTexture(0, 0, 0);

	-- position it
	BuffGuide.UIFrame:SetPoint(_G.BuffGuidePrefs.frameRef, _G.BuffGuidePrefs.frameX, _G.BuffGuidePrefs.frameY);

	-- make it draggable
	BuffGuide.UIFrame:SetMovable(true);
	BuffGuide.UIFrame:EnableMouse(true);

	-- create a button that covers the entire addon
	BuffGuide.Cover = CreateFrame("Button", nil, BuffGuide.UIFrame);
	BuffGuide.Cover:SetFrameLevel(128);
	BuffGuide.Cover:SetPoint("TOPLEFT", 0, 0);
	BuffGuide.Cover:SetWidth(_G.BuffGuidePrefs.frameW);
	BuffGuide.Cover:SetHeight(_G.BuffGuidePrefs.frameH);
	BuffGuide.Cover:EnableMouse(true);
	BuffGuide.Cover:RegisterForClicks("AnyUp");
	BuffGuide.Cover:RegisterForDrag("LeftButton");
	BuffGuide.Cover:SetScript("OnDragStart", BuffGuide.OnDragStart);
	BuffGuide.Cover:SetScript("OnDragStop", BuffGuide.OnDragStop);
	BuffGuide.Cover:SetScript("OnClick", BuffGuide.OnClick);

	-- add a main label - just so we can show something
	BuffGuide.Label = BuffGuide.Cover:CreateFontString(nil, "OVERLAY");
	BuffGuide.Label:SetPoint("CENTER", BuffGuide.UIFrame, "CENTER", 2, 0);
	BuffGuide.Label:SetJustifyH("LEFT");
	BuffGuide.Label:SetFont([[Fonts\FRIZQT__.TTF]], 12, "OUTLINE");
	BuffGuide.Label:SetText(" ");
	BuffGuide.Label:SetTextColor(1,1,1,1);
	BuffGuide.SetFontSize(BuffGuide.Label, 20);
end

function BuffGuide.SetFontSize(string, size)

	local Font, Height, Flags = string:GetFont()
	if (not (Height == size)) then
		string:SetFont(Font, size, Flags)
	end
end

function BuffGuide.OnDragStart(frame)
	BuffGuide.UIFrame:StartMoving();
	BuffGuide.UIFrame.isMoving = true;
	GameTooltip:Hide()
end

function BuffGuide.OnDragStop(frame)
	BuffGuide.UIFrame:StopMovingOrSizing();
	BuffGuide.UIFrame.isMoving = false;
end

function BuffGuide.OnClick(self, aButton)
	if (aButton == "RightButton") then
		print("show menu here!");
	end
end

function BuffGuide.UpdateFrame()

	-- update the main frame state here
	BuffGuide.Label:SetText(string.format("%d", GetTime()));
end

function BuffGuide.PeriodicCheck()

end


BuffGuide.EventFrame = CreateFrame("Frame");
BuffGuide.EventFrame:Show();
BuffGuide.EventFrame:SetScript("OnEvent", BuffGuide.OnEvent);
BuffGuide.EventFrame:SetScript("OnUpdate", BuffGuide.OnUpdate);
BuffGuide.EventFrame:RegisterEvent("ADDON_LOADED");
BuffGuide.EventFrame:RegisterEvent("PLAYER_LOGIN");
BuffGuide.EventFrame:RegisterEvent("PLAYER_LOGOUT");
BuffGuide.EventFrame:RegisterEvent("UNIT_AURA");
