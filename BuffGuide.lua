BuffGuide = {};
BuffGuide.fully_loaded = false;
BuffGuide.default_options = {

	-- main frame position
	frameRef = "CENTER",
	frameX = 0,
	frameY = 0,
	hide = false,

	-- sizing
	frameW = 70,
	frameH = 50,
};

BuffGuide.buffs = {
	stats = {
		name = "Stats",
		description = "Strength, Agility, and Intellect increased by 5%",
		buffs = {
			{"Mark of the Wild",		"Druid"},
			{"Legacy of the Emperor",	"Monk"},
			{"Blessing of Kings",		"Paladin"},
			{"Embrace of the Shale Spider",	"BM Hunter (Shale Spider)"},
		},
	},
	stamina = {
		name = "Stamina",
		description = "+10% Stamina",
		buffs = {
			{"Power Word: Fortitude",	"Priest"},
			{"Blood Pact",			"Warlock (Imp)"},
			{"Commanding Shout",		"Warrior"},
			{"Qiraji Fortitude",		"BM Hunter (Silithid)"},
		},
	},
	attack_power = {
		name = "Attack Power",
		description = "10% Melee and Ranged Attack Power",
		buffs = {
			{"Horn of Winter",	"DK"},
			{"Trueshot Aura",	"Hunter"},
			{"Battle Shout",	"Warrior"},
		},
	},
	spell_power = {
		name = "Spell Power",
		description = "+10% spell power",
		buffs = {
			{"Arcane Brilliance",	"Mage"},
			{"Dalaran Brilliance",	"Mage"},
			{"Burning Wrath",	"Shaman"},
			{"Dark Intent",		"Warlock"},
			{"Still Water",		"BM Hunter (Waterstrider)"},
		},
	},
	haste = {
		name = "Haste",
		description = "+10% Melee and Ranged Haste",
		buffs = {
			{"Unholy Aura",			"Frost/Unholy DK"},
			{"Swiftblade's Cunning",	"Rogue"},
			{"Unleashed Rage",		"Enhancement Shaman"},
			{"Cackling Howl",		"Hunter (Hyena)"},
			{"Serpent's Swiftness",		"Hunter (Serpent)"},
		},
	},
	spell_haste = {
		name = "Spell Haste",
		description = "+5% Spell Haste",
		buffs = {
			{"Moonkin Aura",	"Balance Druid"},
			{"Shadowform",		"Shadow Priest"},
			{"Elemental Oath",	"Elemental Shaman"},
		},
	},
	crit = {
		name = "Critical Strike",
		description = "+5% Ranged, Melee, and Spell Critical Chance",
		classes = ", Feral Druid, Mage, Hunter (Hydra, Wolf, Devilsaur, Quilen, Water Strider)",
		buffs = {
			{"Leader of the Pack",	"Guardian/Feral Druid"},
			{"Arcane Brilliance",	"Mage"},
			{"Dalaran Brilliance",	"Mage"},
			{"Bellowing Roar",	"Hunter (Hydra)"},
			{"Furious Howl",	"Hunter (Wolf)"},
			{"Terrifying Roar",	"Hunter (Devilsaur)"},
			{"Fearless Roar",	"Hunter (Quilen)"},
			{"Still Water",		"Hunter (Water Strider)"},
		},
	},
	mastery = {
		name = "Mastery",
		description = "+5 Mastery",
		buffs = {
			{"Blessing of Might",		"Paladin"},
			{"Grace of Air",		"Shaman"},
			{"Roar of Courage",		"Hunter (Cat)"},
			{"Spirit Beast Blessing",	"Hunter (Spirit Beast)"},
		},
	},
};

BuffGuide.status = {};
BuffGuide.last_check = 0;
BuffGuide.time_between_checks = 5; -- only update every 5 seconds
BuffGuide.showing_tooltip = false;

function BuffGuide.OnReady()

	-- set up default options
	_G.BuffGuidePrefs = _G.BuffGuidePrefs or {};

	for k,v in pairs(BuffGuide.default_options) do
		if (not _G.BuffGuidePrefs[k]) then
			_G.BuffGuidePrefs[k] = v;
		end
	end

	BuffGuide.PeriodicCheck();
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
		if (unitId == "player") then
			if (UnitAffectingCombat("player") == nil) then
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

	BuffGuide.Cover:SetHitRectInsets(0, 0, 0, 0)
	BuffGuide.Cover:SetScript("OnEnter", BuffGuide.ShowTooltip);
	BuffGuide.Cover:SetScript("OnLeave", BuffGuide.HideTooltip);

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

	local is_ok = true;

	if (not BuffGuide.status.has_food) then
		is_ok = false;
	end

	if (not BuffGuide.status.has_flask) then
		is_ok = false;
	end

	if (BuffGuide.status.buff_num < 8) then
		is_ok = false;
	end

	-- update the main frame state here
	BuffGuide.Label:SetText(BuffGuide.status.buff_num.."/8");

	if (is_ok) then
		BuffGuide.UIFrame.texture:SetTexture(0, 1, 0, 0.5);
	else
		BuffGuide.UIFrame.texture:SetTexture(1, 0, 0, 0.5);
	end
end

function BuffGuide.ShowTooltip()

	BuffGuide.showing_tooltip = true;

	GameTooltip:SetOwner(BuffGuide.UIFrame, "ANCHOR_BOTTOM");

	BuffGuide.PopulateTooltip();

	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("TOPLEFT", BuffGuide.UIFrame, "BOTTOMLEFT"); 

	GameTooltip:Show()
end

function BuffGuide.HideTooltip()

	BuffGuide.showing_tooltip = false;
	GameTooltip:Hide();
end

function BuffGuide.PopulateTooltip()

	GameTooltip:ClearLines();

	if (BuffGuide.status.buff_num == 8) then
		GameTooltip:AddDoubleLine("Raid Buffs", BuffGuide.status.buff_num.."/8", 0.4,1,0.4, 0.4,1,0.4);
	elseif (BuffGuide.status.buff_num >= 6) then
		GameTooltip:AddDoubleLine("Raid Buffs", BuffGuide.status.buff_num.."/8", 1,1,0.4, 1,1,0.4);
	else
		GameTooltip:AddDoubleLine("Raid Buffs", BuffGuide.status.buff_num.."/8", 1,0.4,0.4, 1,0.4,0.4);
	end

	if (BuffGuide.status.has_food) then
		GameTooltip:AddDoubleLine("Food Buff", "Yes ("..BuffGuide.FormatRemaining(BuffGuide.status.food_remain)..")", 0.4,1,0.4, 0.4,1,0.4);
	else
		GameTooltip:AddDoubleLine("Food Buff", "Missing", 1,0.4,0.4, 1,0.4,0.4);
	end

	if (BuffGuide.status.has_flask) then
		GameTooltip:AddDoubleLine("Flask", "Yes ("..BuffGuide.FormatRemaining(BuffGuide.status.flask_remain)..")", 0.4,1,0.4, 0.4,1,0.4);
	else
		GameTooltip:AddDoubleLine("Flask", "Missing", 1,0.4,0.4, 1,0.4,0.4);
	end


	-- only show raid buff status if we're in a group

	local num = GetNumGroupMembers()
	if (num == 0) then return; end;

	GameTooltip:AddLine(" ");
	

	-- raid buff status

	local k,v;
	for k, v in pairs(BuffGuide.buffs) do

		if (BuffGuide.buffs[k].got) then

			local status = BuffGuide.buffs[k].got_buff;
			local has_time = true;

			if (BuffGuide.buffs[k].remain > 0) then
				status = status.." ("..BuffGuide.FormatRemaining(BuffGuide.buffs[k].remain)..")";
				if (BuffGuide.buffs[k].remain < 5 * 60) then
					has_time = false;
				end
			end

			if (has_time) then
				GameTooltip:AddDoubleLine(BuffGuide.buffs[k].name, status, 0.4,1,0.4, 0.4,1,0.4);
			else
				GameTooltip:AddDoubleLine(BuffGuide.buffs[k].name, status, 0.4,1,0.4, 1,1,0.4);
			end

		else
			GameTooltip:AddDoubleLine(BuffGuide.buffs[k].name, "Missing", 1,0.4,0.4, 1,0.4,0.4);

			local k2, v2;
			for k2, v2 in pairs(BuffGuide.buffs[k].buffs) do

				if (v2[1] == "Dalaran Brilliance") then

				else
					GameTooltip:AddLine("    "..v2[1].." - "..v2[2]);
				end
			end		
		end
	end
end

function BuffGuide.PeriodicCheck()

	-- create a map of all buffs we have

	local buff_map = {};

	local index = 1;
	while UnitBuff("player", index) do
		local name, _, _, count, _, _, buffExpires, caster = UnitBuff("player", index)
		local t = buffExpires - GetTime();
		buff_map[name] = t;
		index = index + 1
	end

	-- now check each raid buff

	BuffGuide.status.buff_num = 0;

	local k,v;
	for k, v in pairs(BuffGuide.buffs) do

		BuffGuide.buffs[k].got = false;

		local k2, v2;
		for k2, v2 in pairs(BuffGuide.buffs[k].buffs) do

			local buff = v2[1];

			if (buff_map[buff]) then
				BuffGuide.buffs[k].got = true;
				BuffGuide.buffs[k].got_buff = buff;
				BuffGuide.buffs[k].remain = buff_map[buff];
			end
		end

		if (BuffGuide.buffs[k].got) then
			BuffGuide.status.buff_num = BuffGuide.status.buff_num + 1;
		end
	end

	-- check food and flask buffs
	BuffGuide.status.has_food = false;
	BuffGuide.status.has_flask = false;

	if (buff_map["Well Fed"]) then
		BuffGuide.status.has_food = true;
		BuffGuide.status.food_remain = buff_map["Well Fed"];
	end

	local k,v;
	for k, v in pairs(buff_map) do
		if (string.find(k, "Flask of")) then
			BuffGuide.status.has_flask = true;
			BuffGuide.status.flask_remain = v;
		end
	end

	if (BuffGuide.showing_tooltip) then
		BuffGuide.ShowTooltip();
	end
end

function BuffGuide.FormatRemaining(t)

	if (t < 90) then
		return t.."s";
	end

	if (t > 60 * 90) then

		local h = math.floor(t / (60 * 60));
		t = t - (h * 60 * 60);
		local m =  math.floor(t / (60));

		return h.."h "..m.."m";
	end

	local m =  math.floor(t / (60));
	return m.."m";
end


BuffGuide.EventFrame = CreateFrame("Frame");
BuffGuide.EventFrame:Show();
BuffGuide.EventFrame:SetScript("OnEvent", BuffGuide.OnEvent);
BuffGuide.EventFrame:SetScript("OnUpdate", BuffGuide.OnUpdate);
BuffGuide.EventFrame:RegisterEvent("ADDON_LOADED");
BuffGuide.EventFrame:RegisterEvent("PLAYER_LOGIN");
BuffGuide.EventFrame:RegisterEvent("PLAYER_LOGOUT");
BuffGuide.EventFrame:RegisterEvent("UNIT_AURA");
