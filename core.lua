local AddOnName, Core = ...;
XB = LibStub("AceAddon-3.0"):NewAddon(Core, AddOnName, "AceConsole-3.0", "AceEvent-3.0");
XB:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")
--local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true);
XB.LSM = LibStub('LibSharedMedia-3.0');


----------------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------------
XB.version = "3.0.1"
XB.releaseType = "alpha"

XB.playerName = UnitName("player")
XB.playerClass = select(2, UnitClass("player"))
XB.playerFaction = UnitFactionGroup("player")
XB.playerRealm = GetRealmName()

XB.mediaFold = "Interface\\AddOns\\"..AddOnName.."\\media\\"

XB.icons = {
	anchor = XB.mediaFold.."datatexts\\anchor",
	exp = XB.mediaFold.."datatexts\\exp",
	fps = XB.mediaFold.."datatexts\\fps",
	garr = XB.mediaFold.."datatexts\\garr",
	garres = XB.mediaFold.."datatexts\\garres",
	gold = XB.mediaFold.."datatexts\\gold",
	hearth = XB.mediaFold.."datatexts\\hearth",
	honor = XB.mediaFold.."datatexts\\honor",
	ping = XB.mediaFold.."datatexts\\ping",
	repair = XB.mediaFold.."datatexts\\repair",
	reroll = XB.mediaFold.."datatexts\\reroll",
	seal = XB.mediaFold.."datatexts\\seal",
	shicomp = XB.mediaFold.."datatexts\\shipcomp",
	sound = XB.mediaFold.."datatexts\\sound"
}

XB.menuIcons = {
	menu = XB.mediaFold.."microbar\\menu",
	chat = XB.mediaFold.."microbar\\chat",
	guild = XB.mediaFold.."microbar\\guild",
	social = XB.mediaFold.."microbar\\social",
	character = XB.mediaFold.."microbar\\char",
	spellbook = XB.mediaFold.."microbar\\spell",
	talents = XB.mediaFold.."microbar\\talent",
	achievements = XB.mediaFold.."microbar\\ach",
	quests = XB.mediaFold.."microbar\\quest",
	lfg = XB.mediaFold.."microbar\\lfg",
	pvp = XB.mediaFold.."microbar\\pvp",
	collections = XB.mediaFold.."microbar\\pet",
	adventure = XB.mediaFold.."microbar\\journal",
	shop = XB.mediaFold.."microbar\\shop",
	help = XB.mediaFold.."microbar\\help",
}

XB.systemIcons = {
    fps = XB.mediaFold.."datatexts\\fps",
    ping = XB.mediaFold.."datatexts\\ping"
}

XB.validAnchors = {
    CENTER = "CENTER",
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    TOP = "TOP",
    TOPLEFT = "TOPLEFT",
    TOPRIGHT = "TOPRIGHT",
    BOTTOM = "BOTTOM",
    BOTTOMLEFT = "BOTTOMLEFT",
    BOTTOMRIGHT = "BOTTOMRIGHT",
}

XB.modifiers = {
	 "None",
	SHIFT_KEY_TEXT,
	ALT_KEY_TEXT,
	CTRL_KEY_TEXT
}

XB.mouseButtons = {
	"Left-Click",
	HELPFRAME_REPORT_PLAYER_RIGHT_CLICK
}

XB.gameIcons = {
	app = "Interface\\FriendsFrame\\Battlenet-Battleneticon.blp",
	d3 = "Interface\\FriendsFrame\\Battlenet-D3icon.blp",
	hots = "Interface\\FriendsFrame\\Battlenet-HotSicon.blp",
	hs = "Interface\\FriendsFrame\\Battlenet-WTCGicon.blp",
	overwatch = "Interface\\FriendsFrame\\Battlenet-OVERWATCHicon.blp",
	sc2 = "Interface\\FriendsFrame\\Battlenet-Sc2icon.blp",
	wow = "Interface\\FriendsFrame\\Battlenet-WoWicon.blp"
}
-- TODO: Add an option for that
PlayerFrame.name:SetFont("Interface\\AddOns\\oUF_Drk\\media\\BigNoodleTitling.ttf", 11, "THINOUTLINE")
TargetFrame.name:SetFont("Interface\\AddOns\\oUF_Drk\\media\\BigNoodleTitling.ttf", 11, "THINOUTLINE")

function round(number)
    local int = math.floor(number)
    return number-int <=0.5 and int or int+1
end

-- table functions 
function tableKeys(tbl)
    local out = {}
    for k, _ in pairs(tbl) do
        table.insert(out, k)
    end
end

function tableValues(tbl)
    local out = {}
    for _, v in pairs(tbl) do
        table.insert(out, v)
    end
end

function tableWhereKeyContains(tbl, key_part)
    local out = {}

    for k,v in pairs(tbl) do
        if not tonumber(k) then
            if k:find(key_part) then
                out[k] = v
            end
        end
    end
    return out == {} and nil or out
end

function tableWhereValueContains(tbl, value_part)
    local out = {}

    for k, v in pairs(tbl) do
        if type(v) == "string" and v:find(value_part) then
            out[k] = v
        end
    end
    return out == {} and nil or out
end

function subTableFromKeyMatchings(tbl, matching_keys)
    local out = {}

    for k, v in pairs(tbl) do
        local found = false
        for _, w in pairs(matching_keys) do
            found = found or k == w
        end
        if found then
            out[k] = v
        end
    end
    return out == {} and nil or out
end

function subTableFromKeyExclusions(tbl, exclusion_keys)
    local out = {}

    for k, v in pairs(tbl) do
        local found = false
        for _, w in pairs(exclusion_keys) do
            found = found or k == w
        end
        if not found then
            out[k] = v
        end
    end
    return out == {} and nil or out
end

function subTableFromKeyMatcher(lua_table, key_matcher)
    local all_items = {}
    for k, _ in pairs(lua_table) do
        if(key_matcher(k))then
            table.insert(all_items, k)
        end
    end
    return all_items
end

function subTableFromValueMatcher(lua_table, item_matcher)
    local all_items = {}
    for _, v in pairs(lua_table) do
        if(item_matcher(v))then
            table.insert(all_items, v)
        end
    end
    return all_items
end

function bnetClientVariableMatcher(variable_name)
    local start = "BNET_CLIENT"
    return variable_name:sub(1, #start) == start
end
----------------------------------------------------------------------------------------------------------
-- Private functions
----------------------------------------------------------------------------------------------------------
local function savePosition(parent,module)
	module.settings.anchor,_,_,module.settings.x,module.settings.y = parent:GetPoint()
end

local function frameOnEnter(self)
	if not self:GetParent().isMoving then
		self:SetBackdropBorderColor(0.5, 0.5, 0, 1)
	end
end

local function frameOnLeave(self)
	self:SetBackdropBorderColor(0, 0, 0, 0)
end

local function frameOnDragStart(self)
	local parent = self:GetParent()
	parent:StartMoving()
	self:SetBackdropBorderColor(0, 0, 0, 0)
	parent.isMoving = true
end

----------------------------------------------------------------------------------------------------------
-- Module functions
----------------------------------------------------------------------------------------------------------
function XB:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("XIVBarDB",nil,true)
	self.db.RegisterCallback(self, 'OnProfileReset',function() self:Disable(); self:Enable() end)
	self.db.RegisterCallback(self, 'OnProfileCopied',function() self:Disable(); self:Enable() end)
	self.db.RegisterCallback(self, 'OnProfileChanged',function() self:Disable(); self:Enable() end)
end

function XB:RegisterModule(name, ...)
	local mod = self:NewModule(name, ...)
	self[name] = mod
	return mod
end

function XB:AddOverlay(module,parent,anchor)
	--Overlay for unlocked bar for user positionning
	parent.overlay = parent.overlay or CreateFrame("Button", "Overlay"..parent:GetName(), parent)
	local overlay = parent.overlay
	overlay:EnableMouse(true)
	overlay:RegisterForDrag("LeftButton")
	overlay:RegisterForClicks("LeftButtonUp")
	overlay:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 5, right = 3, top = 3, bottom = 5}
	})
	overlay:SetBackdropColor(0, 1, 0, 0.5)
	overlay:SetBackdropBorderColor(0.5, 0.5, 0, 0)

	overlay:SetFrameLevel(parent:GetFrameLevel() + 10)
	overlay:ClearAllPoints()
	overlay:SetPoint(anchor,parent,anchor)
	overlay:SetSize(parent:GetWidth(), parent:GetHeight())

	overlay.anchor = overlay.anchor or overlay:CreateTexture(nil,"ARTWORK")
	local overlayAnchor = overlay.anchor
	overlayAnchor:SetSize(13,13)
	overlayAnchor:SetTexture(XB.icons.anchor)
	overlayAnchor:ClearAllPoints()
	overlayAnchor:SetPoint(anchor,overlay,anchor)


	if not overlay:GetScript("OnEnter") and overlay:GetScript("OnEnter")~= frameOnEnter then
		overlay:SetScript("OnEnter", frameOnEnter)
		overlay:SetScript("OnLeave", frameOnLeave)
		overlay:SetScript("OnDragStart", frameOnDragStart)
		overlay:SetScript("OnDragStop", function(self)
			local parent = self:GetParent()
			if parent.isMoving then
				parent:StopMovingOrSizing()
				savePosition(parent,module)
				parent.isMoving = nil
				self.anchor:ClearAllPoints()
				self.anchor:SetPoint(module.settings.anchor,self,module.settings.anchor)
			end
		end)
	end
end

function XB:SkinTooltip(frame, name)
	if IsAddOnLoaded("ElvUI") or IsAddOnLoaded("Tukui") then
		if frame.StripTextures then
			frame:StripTextures()
		end
		if frame.SetTemplate then
			frame:SetTemplate("Transparent")
		end

		local close = _G[name.."CloseButton"] or frame.CloseButton
		if close and close.SetAlpha then
			if ElvUI then
				ElvUI[1]:GetModule('Skins'):HandleCloseButton(close)
			end

			if Tukui and Tukui[1] and Tukui[1].SkinCloseButton then
				Tukui[1].SkinCloseButton(close)
			end
			close:SetAlpha(1)
		end
	end
end

--[[
XIVBar.L = L

XIVBar.constants = {
    mediaPath = "Interface\\AddOns\\"..AddOnName.."\\media\\",
    playerName = UnitName("player"),
    playerClass = select(2, UnitClass("player")),
    playerLevel = UnitLevel("player"),
    playerFactionLocal = select(2, UnitFactionGroup("player")),
    playerRealm = GetRealmName(),
    popupPadding = 3
}

XIVBar.defaults = {
    profile = {
        general = {
            barPosition = "BOTTOM",
            barPadding = 3,
            moduleSpacing = 30,
            barFullscreen = true,
            barWidth = GetScreenWidth(),
            barHoriz = 'CENTER',
			barCombatHide = false,
            barFlightHide = false
        },
        color = {
            barColor = {
                r = 0.094,
                g = 0.094,
                b = 0.094,
                a = 0.75
            },
            normal = {
                r = 0.8,
                g = 0.8,
                b = 0.8,
                a = 0.75
            },
            inactive = {
                r = 1,
                g = 1,
                b = 1,
                a = 0.25
            },
            useCC = false,
			useTextCC = false,
            useHoverCC = true,
            hover = {
				r = RAID_CLASS_COLORS[XIVBar.constants.playerClass].r,
				g = RAID_CLASS_COLORS[XIVBar.constants.playerClass].g,
				b = RAID_CLASS_COLORS[XIVBar.constants.playerClass].b,
				a = RAID_CLASS_COLORS[XIVBar.constants.playerClass].a
			}
        },
        text = {
            fontSize = 12,
            smallFontSize = 11,
            font =  'Homizio Bold'
        },
        modules = {

        }
    }
};


function XIVBar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("XIVBarDB", self.defaults)
    self.LSM:Register(self.LSM.MediaType.FONT, 'Homizio Bold', self.constants.mediaPath.."homizio_bold.ttf")
    self.frames = {}

    self.fontFlags = {'', 'OUTLINE', 'THICKOUTLINE', 'MONOCHROME'}

    local options = {
        name = "XIV Bar",
        handler = XIVBar,
        type = 'group',
        args = {
            general = {
                name = GENERAL_LABEL,
                type = "group",
                args = {
                    general = self:GetGeneralOptions()
                }
            }, -- general
            modules = {
                name = L['Modules'],
                type = "group",
                args = {

                }
            } -- modules
        }
    }

    for name, module in self:IterateModules() do
        if module['GetConfig'] ~= nil then
            options.args.modules.args[name] = module:GetConfig()
        end
        if module['GetDefaultOptions'] ~= nil then
            local oName, oTable = module:GetDefaultOptions()
            self.defaults.profile.modules[oName] = oTable
        end
    end

    self.db:RegisterDefaults(self.defaults)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddOnName, options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddOnName, "XIV Bar", nil, "general")

    --options.args.modules = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.modulesOptionFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddOnName, L['Modules'], "XIV Bar", "modules")

    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.profilesOptionFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddOnName, 'Profiles', "XIV Bar", "profiles")

    self.timerRefresh = false

    self:RegisterChatCommand('xivbar', 'ToggleConfig')
    self:RegisterChatCommand('xb', 'ToggleConfig')
end

function XIVBar:OnEnable()
    self:CreateMainBar()
    self:Refresh()

    self.db.RegisterCallback(self, 'OnProfileCopied', 'Refresh')
    self.db.RegisterCallback(self, 'OnProfileChanged', 'Refresh')
    self.db.RegisterCallback(self, 'OnProfileReset', 'Refresh')

    if not self.timerRefresh then
        C_Timer.After(5, function()
            self:Refresh()
            self.timerRefresh = true
        end)
    end
end

function XIVBar:ToggleConfig()
    InterfaceOptionsFrame.selectedTab = 2;
	InterfaceOptionsFrame:Show()--weird hack ; options registration is wrong in some way
	InterfaceOptionsFrame_OpenToCategory("XIV Bar")
end

function XIVBar:SetColor(name, r, g, b, a)
    self.db.profile.color[name].r = r
    self.db.profile.color[name].g = g
    self.db.profile.color[name].b = b
    self.db.profile.color[name].a = a

    self:Refresh()
end

function XIVBar:GetColor(name)
    d = self.db.profile.color[name]
    return d.r, d.g, d.b, d.a
end

function XIVBar:HoverColors()
    local colors = {
        self.db.profile.color.hover.r,
        self.db.profile.color.hover.g,
        self.db.profile.color.hover.b,
        self.db.profile.color.hover.a
    }
    if self.db.profile.color.useHoverCC then
        colors = {
            RAID_CLASS_COLORS[self.constants.playerClass].r,
            RAID_CLASS_COLORS[self.constants.playerClass].g,
            RAID_CLASS_COLORS[self.constants.playerClass].b,
            self.db.profile.color.hover.a
        }
    end
    return colors
end

function XIVBar:RegisterFrame(name, frame)
    frame:SetScript('OnHide', function()
        self:SendMessage('XIVBar_FrameHide', name)
    end)
    frame:SetScript('OnShow', function()
        self:SendMessage('XIVBar_FrameShow', name)
    end)
    self.frames[name] = frame
end

function XIVBar:GetFrame(name)
    return self.frames[name]
end

function XIVBar:CreateMainBar()
    if self.frames.bar == nil then
        self:RegisterFrame('bar', CreateFrame("FRAME", "XIV_Databar", UIParent))
        self.frames.bgTexture = self.frames.bgTexture or self.frames.bar:CreateTexture(nil, "BACKGROUND")
		XIVBar:GetFrame("bar").enableMouse = true
		XIVBar:GetFrame("bar").clampedToScreen = true
		XIVBar:GetFrame("bar").movable = true
		XIVBar:GetFrame("bar"):SetScript("OnMouseDown",function()
			self.frames.bgTexture:SetColorTexture(0,1,0,0.4);
			local curX, curY = GetCursorPosition()
			local uiScale = UIParent:GetEffectiveScale()
			curX, curY = curX / uiScale, curY / uiScale
			local anchor,object,relativeToObj,x,y = self.frames.bar:GetPoint()
			self.frames.bar:SetPoint(anchor,object,relativeToObj,curX,curY)
		end)
    end
end


function XIVBar:GetHeight()
    return (self.db.profile.text.fontSize * 2) + self.db.profile.general.barPadding
end

function XIVBar:Refresh()
    if self.frames.bar == nil then return; end
	
	self:HideBarEvent()
    self.miniTextPosition = "TOP"
    if self.db.profile.general.barPosition == 'TOP' then
		hooksecurefunc("UIParent_UpdateTopFramePositions",function(self)
			if(XIVBar.db.profile.general.barPosition == 'TOP') then
				if OrderHallCommandBar and OrderHallCommandBar:IsVisible() then
					if XIVBar.db.profile.general.ohHide then
						OrderHallCommandBar:Hide()
					end
				end
				OffsetUI()
			end
		end)
		OffsetUI()
        self.miniTextPosition = 'BOTTOM'
	else
		self:ResetUI();
    end

    local barColor = self.db.profile.color.barColor
    self.frames.bar:ClearAllPoints()
    self.frames.bar:SetPoint(self.db.profile.general.barPosition)
    if self.db.profile.general.barFullscreen then
        self.frames.bar:SetPoint("LEFT")
        self.frames.bar:SetPoint("RIGHT")
    else
        local relativePoint = self.db.profile.general.barHoriz
        if relativePoint == 'CENTER' then
            relativePoint = 'BOTTOM'
        end
        self.frames.bar:SetPoint(self.db.profile.general.barHoriz, self.frames.bar:GetParent(), relativePoint)
        self.frames.bar:SetWidth(self.db.profile.general.barWidth)
    end
    self.frames.bar:SetHeight(self:GetHeight())

	self.frames.bgTexture:SetColorTexture(self:GetColor('barColor'))
    self.frames.bgTexture:SetAllPoints()

    for name, module in self:IterateModules() do
        if module['Refresh'] == nil then return; end
        module:Refresh()
    end
end

function XIVBar:GetFont(size)
    return self.LSM:Fetch(self.LSM.MediaType.FONT, self.db.profile.text.font), size, self.fontFlags[self.db.profile.text.flags]
end

function XIVBar:GetClassColors()
    return RAID_CLASS_COLORS[self.constants.playerClass].r, RAID_CLASS_COLORS[self.constants.playerClass].g, RAID_CLASS_COLORS[self.constants.playerClass].b, self.db.profile.color.barColor.a
end

function XIVBar:RGBAToHex(r, g, b, a)
    a = a or 1
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    a = a <= 1 and a >= 0 and a or 1
    return string.format("%02x%02x%02x%02x", r*255, g*255, b*255, a*255)
end

function XIVBar:HexToRGBA(hex)
    local rhex, ghex, bhex, ahex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6), string.sub(hex, 7, 8)
    if not (rhex and ghex and bhex and ahex) then
        return 0, 0, 0, 0
    end
    return (tonumber(rhex, 16) / 255), (tonumber(ghex, 16) / 255), (tonumber(bhex, 16) / 255), (tonumber(ahex, 16) / 255)
end

function XIVBar:PrintTable(table, prefix)
    for k,v in pairs(table) do
        if type(v) == 'table' then
            self:PrintTable(v, prefix..'.'..k)
        else
            print(prefix..'.'..k..': '..tostring(v))
        end
    end
end

function XIVBar:GetGeneralOptions()
    return {
        name = GENERAL_LABEL,
        type = "group",
        inline = true,
        args = {
			positioning = {
				name = L["Positioning"],
				type = "group",
				order = 1,
				inline = true,
				args = {
					barLocation = {
						name = L['Bar Position'],
						type = "select",
						order = 2,
						width = "full",
						values = {TOP = L['Top'], BOTTOM = L['Bottom']},
						style = "dropdown",
						get = function() return self.db.profile.general.barPosition; end,
						set = function(info, value) self.db.profile.general.barPosition = value;
						if value == "TOP" and self.db.profile.general.ohHide then
							LoadAddOn("Blizzard_OrderHallUI"); local b = OrderHallCommandBar; b:Hide();
						end
						self:Refresh(); end,
					},
					ohHide = {
						name = L['Hide order hall bar'],
						type = "toggle",
						order = 3,
						hidden = function() return self.db.profile.general.barPosition == "BOTTOM" end,
						get = function() return self.db.profile.general.ohHide end,
						set = function(_,val) self.db.profile.general.ohHide = val; if val then LoadAddOn("Blizzard_OrderHallUI"); local b = OrderHallCommandBar; b:Hide(); end self:Refresh(); end
					},
                    flightHide = {
                        name = "Hide when in flight",
                        type = "toggle",
                        order = 1,
                        get = function() return self.db.profile.general.barFlightHide end,
                        set = function(_,val) self.db.profile.general.barFlightHide = val; self:Refresh(); end
                    },
					fullScreen = {
						name = VIDEO_OPTIONS_FULLSCREEN,
						type = "toggle",
						order = 4,
						get = function() return self.db.profile.general.barFullscreen; end,
						set = function(info, value) self.db.profile.general.barFullscreen = value; self:Refresh(); end,
					},
					barPosition = {
						name = L['Horizontal Position'],
						type = "select",
						hidden = function() return self.db.profile.general.barFullscreen; end,
						order = 5,
						values = {LEFT = L['Left'], CENTER = L['Center'], RIGHT = L['Right']},
						style = "dropdown",
						get = function() return self.db.profile.general.barHoriz; end,
						set = function(info, value) self.db.profile.general.barHoriz = value; self:Refresh(); end,
						disabled = function() return self.db.profile.general.barFullscreen; end
					},
					barWidth = {
						name = L['Bar Width'],
						type = 'range',
						order = 6,
						hidden = function() return self.db.profile.general.barFullscreen; end,
						min = 200,
						max = GetScreenWidth(),
						step = 1,
						get = function() return self.db.profile.general.barWidth; end,
						set = function(info, val) self.db.profile.general.barWidth = val; self:Refresh(); end,
						disabled = function() return self.db.profile.general.barFullscreen; end
					}
				}
			},
			text = self:GetTextOptions(),
			colors = {
				name = L["Colors"],
				type = "group",
				inline = true,
				order = 3,
				args = {
					barColor = {
						name = L['Bar Color'],
						type = "color",
						order = 1,
						hasAlpha = true,
						set = function(info, r, g, b, a)
							if not self.db.profile.color.useCC then
								self:SetColor('barColor', r, g, b, a)
							else
								local cr,cg,cb,_ = self:GetClassColors()
								self:SetColor('barColor',cr,cg,cb,a)
							end
						end,
						get = function() return XIVBar:GetColor('barColor') end,
					},
					barCC = {
						name = L['Use Class Color for Bar'],
						desc = L["Only the alpha can be set with the color picker"],
						type = "toggle",
						order = 2,
						set = function(info, val) XIVBar:SetColor('barColor',self:GetClassColors()); self.db.profile.color.useCC = val; self:Refresh(); end,
						get = function() return self.db.profile.color.useCC end
					},
					textColors = self:GetTextColorOptions()
				}
			},
			miscellanelous = {
				name = L["Miscellaneous"],
				type = "group",
				inline = true,
				order = 3,
				args = {
					barCombatHide = {
						name = L['Hide Bar in combat'],
						type = "toggle",
						order = 9,
						get = function() return self.db.profile.general.barCombatHide; end,
						set = function(_,val) self.db.profile.general.barCombatHide = val; self:Refresh(); end
					},
					barPadding = {
						name = L['Bar Padding'],
						type = 'range',
						order = 10,
						min = 0,
						max = 10,
						step = 1,
						get = function() return self.db.profile.general.barPadding; end,
						set = function(info, val) self.db.profile.general.barPadding = val; self:Refresh(); end
					},
					moduleSpacing = {
						name = L['Module Spacing'],
						type = 'range',
						order = 11,
						min = 10,
						max = 50,
						step = 1,
						get = function() return self.db.profile.general.moduleSpacing; end,
						set = function(info, val) self.db.profile.general.moduleSpacing = val; self:Refresh(); end
					}
				}
			}
        }
    }
end

function XIVBar:GetTextOptions()
	-- Don't know if this still needed, so i keep it commendet out.
    local t = self.LSM:List(self.LSM.MediaType.FONT);
    local fontList = {};
    for k,v in pairs(t) do
        fontList[v] = v;
    end
    return {
        name = LOCALE_TEXT_LABEL,
        type = "group",
        order = 2,
        inline = true,
        args = {
            font = {
                name = L['Font'],
                type = "select",
				dialogControl = 'LSM30_Font',
                order = 1,
				values = AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or fontList,
                style = "dropdown",
                get = function() return self.db.profile.text.font; end,
                set = function(info, val) self.db.profile.text.font = val; self:Refresh(); end
            },
            fontSize = {
                name = FONT_SIZE,
                type = 'range',
                order = 2,
                min = 10,
                max = 20,
                step = 1,
                get = function() return self.db.profile.text.fontSize; end,
                set = function(info, val) self.db.profile.text.fontSize = val; self:Refresh(); end
            },
            smallFontSize = {
                name = L['Small Font Size'],
                type = 'range',
                order = 2,
                min = 10,
                max = 20,
                step = 1,
                get = function() return self.db.profile.text.smallFontSize; end,
                set = function(info, val) self.db.profile.text.smallFontSize = val; self:Refresh(); end
            },
            textFlags = {
                name = L['Text Style'],
                type = 'select',
                style = 'dropdown',
                order = 3,
                values = self.fontFlags,
                get = function() return self.db.profile.text.flags; end,
                set = function(info, val) self.db.profile.text.flags = val; self:Refresh(); end
            },
        }
    }
end

function XIVBar:GetTextColorOptions()
    return {
        name = L['Text Colors'],
        type = "group",
        order = 3,
        inline = true,
        args = {
            normal = {
                name = L['Normal'],
                type = "color",
                order = 1,
                width = "double",
                hasAlpha = true,
                set = function(info, r, g, b, a)
					if self.db.profile.color.useTextCC then
						r,g,b,_=self:GetClassColors()
					end
                    XIVBar:SetColor('normal', r, g, b, a)
                end,
                get = function() return XIVBar:GetColor('normal') end
            }, -- normal
			textCC = {
				name = L["Use Class Color for Text"],
				desc = L["Only the alpha can be set with the color picker"],
				type = "toggle",
				order = 2,
				set = function(_,val) 
					if val then
						XIVBar:SetColor("normal",self:GetClassColors())
					end 
					self.db.profile.color.useTextCC = val 
				end,
				get = function() return self.db.profile.color.useTextCC end
			},
			hover = {
                name = L['Hover'],
                type = "color",
                order = 3,
				width = "double",
                hasAlpha = true,
                set = function(info, r, g, b, a)
					if self.db.profile.color.useHoverCC then
						r,g,b,_=self:GetClassColors()
					end
                    XIVBar:SetColor('hover', r, g, b, a)
                end,
                get = function() return XIVBar:GetColor('hover') end,
            }, -- normal
            hoverCC = {
                name = L['Use Class Colors for Hover'],
                type = "toggle",
                order = 4,
                set = function(_, val)
					if val then
						XIVBar:SetColor("hover",self:GetClassColors())
					end
				self.db.profile.color.useHoverCC = val; self:Refresh(); end,
                get = function() return self.db.profile.color.useHoverCC end
            }, -- normal
            inactive = {
                name = L['Inactive'],
                type = "color",
                order = 5,
                hasAlpha = true,
                width = "double",
                set = function(info, r, g, b, a)
                    XIVBar:SetColor('inactive', r, g, b, a)
                end,
                get = function() return XIVBar:GetColor('inactive') end
            }, -- normal
        }
    }
end
]]
