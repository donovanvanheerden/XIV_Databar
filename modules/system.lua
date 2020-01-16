local addOnName, XB = ...;

local System = XB:RegisterModule("System")

----------------------------------------------------------------------------------------------------------
-- Local variables
----------------------------------------------------------------------------------------------------------
local ccR,ccG,ccB = GetClassColor(XB.playerClass)
local libTT
local system_config
local groupFrame, moduleFrames, moduleIcons, moduleTexts, moduleFunctions
local moduleHovered = false
local Bar, BarFrame
local systemElements = {"fps", "ping"}

moduleFrames, moduleIcons, moduleTexts = {}, {}, {}


----------------------------------------------------------------------------------------------------------
-- Private functions
----------------------------------------------------------------------------------------------------------
local addonMemoryCompare = function(a, b)
  return a.memory > b.memory
end

local function formatMemoryValue(value)
  local memoryValue = string.format("%.2f KB",value)

  if value >= 1000 then
    memoryValue = string.format("%.2f MB", value/1000)
  elseif value >= 1000000 then
    memoryValue = string.format("%.2f GB", value/1000000)
  end
  return memoryValue
end

local function tooltipHeader(tooltip, addonListLength)
  tooltip:AddHeader('[|cff6699FF'.."Performance"..'|r]')
  tooltip:AddLine(' ',' ')
  if IsShiftKeyDown() then
    tooltip:AddLine("|cff6699FFAddOns", "|cff6699FFMemory usage|r")
  else
    tooltip:AddLine("|cff6699FFTop "..addonListLength.." AddOns|r", "|cff6699FFMemory usage|r")
  end
  tooltip:AddLine("")
end

local function tooltipAddonsMemoryUsed(tooltip, addonListLength)
  UpdateAddOnMemoryUsage()
  local blizz = collectgarbage("count")
  local addons = {}
  local totalMemoryAddons = 0

  for i=1, GetNumAddOns(), 1 do
    local addonMemoryUsage = GetAddOnMemoryUsage(i)
    totalMemoryAddons = totalMemoryAddons + addonMemoryUsage
    if addonMemoryUsage > 0 then
      table.insert(addons, {["addonName"] = GetAddOnInfo(i), ["memory"] = addonMemoryUsage})
    end
  end

  table.sort(addons, addonMemoryCompare)

  if IsShiftKeyDown() then
    addonListLength = #addons
  end

  local addonRowDisplayed = 0 
  for _, addonEntry in pairs(addons) do
    if addonRowDisplayed < addonListLength then
      tooltip:AddLine("|cffffff00"..addonEntry["addonName"].."|r", formatMemoryValue(addonEntry["memory"]))
    end
    addonRowDisplayed = addonRowDisplayed +1 
  end

  return blizz, totalMemoryAddons
end

local function tooltipFooter(tooltip, blizzMemory, addonsMemory)
  tooltip:AddLine("")
  tooltip:AddLine("")
  tooltip:AddLine("|cffffff00Blizzard|r", formatMemoryValue(blizzMemory))
  tooltip:AddLine("")
  tooltip:AddLine("")
  tooltip:AddLine("|cffffff00Total AddOns|r", formatMemoryValue(addonsMemory))
  tooltip:AddLine("|cffffff00Total incl. Blizzard|r", formatMemoryValue(addonsMemory+blizzMemory))
  tooltip:AddLine("")
  tooltip:AddLine("")
  tooltip:AddLine("|cffffff00<Left-click>|r","Force garbage collection")
  tooltip:AddLine("|cffffff00<Right-click>|r","Open System options")
  tooltip:AddLine("|cffffff00<Shift-hold>|r","Show all addons")
end

local function tooltipData(tooltip, addonListDefaultLength)
  tooltipHeader(tooltip, addonListDefaultLength)
  local blizzUi, addons = tooltipAddonsMemoryUsed(tooltip, addonListDefaultLength)
  tooltipFooter(tooltip, blizzUi, addons)
end

local function tooltip()
  if libTT:IsAcquired("SystemTip") then
    libTT:Release(libTT:Acquire("SystemTip"))
  end
  local tooltip = libTT:Acquire("SystemTip", 2, "LEFT")
  tooltip:SmartAnchorTo(groupFrame)
  tooltip:SetAutoHideDelay(.1, groupFrame)
  tooltipData(tooltip, 10)
  XB:SkinTooltip(tooltip,"SystemTip")
  tooltip:Show()
end

local function refreshOptions()
    Bar,BarFrame = XB:GetModule("Bar"), XB:GetModule("Bar"):GetFrame()
end

local function frameRate()
  return floor(GetFramerate()).." fps"
end

local function getWorldPing()
  local _, _, _, latencyWorld = GetNetStats()
  return latencyHome
end

local function getLocalPing()
  local _, _, latencyHome, _ = GetNetStats()
  return latencyHome
end

local function ping(isWorld)
  local latency = 0
  if isWorld then
    latency = getWorldPing()
  else
    latency = getLocalPing()
  end
  return latency.." ms"
end

moduleFunctions = {["ping"] = ping, ["fps"] = frameRate}

----------------------------------------------------------------------------------------------------------
-- Options
----------------------------------------------------------------------------------------------------------
local system_default = {
    profile = {
      enable = {
        group = true,
        fps = true,
        ping = true
        },
      lock = true,
      x = {
        group = -290,
        fps = 0,
        ping = 18
      },
      y = {
        group = 0,
        fps = 0,
        ping = 0
      },
      w = {
        group = 120,
        fps = 16,
        ping = 16
      },
      h = {
        group = 16,
        fps = 16,
        ping = 16
      },
      anchor = {
        group = "RIGHT",
        fps = "LEFT",
        ping = "CENTER"
      },
      color = {
        group = {1,1,1,.75},
        fps = {1,1,1,.75},
        ping = {1,1,1,.75}
      },
      colorCC = false,
      hover = {
        group = XB.playerClass == "PRIEST" and {.5,.5,0,.75} or {ccR,ccG,ccB,.75},
        fps = XB.playerClass == "PRIEST" and {.5,.5,0,.75} or {ccR,ccG,ccB,.75},
        ping = XB.playerClass == "PRIEST" and {.5,.5,0,.75} or {ccR,ccG,ccB,.75}
      },
      hoverCC = not (XB.playerClass == "PRIEST"),
      refreshRate = {
        group = 1,
        fps = 1,
        ping = 1
      }
    }
  }

system_config = {

}

----------------------------------------------------------------------------------------------------------
-- Module functions
----------------------------------------------------------------------------------------------------------
function System:OnInitialize()
    libTT = LibStub('LibQTip-1.0')
    self.db = XB.db:RegisterNamespace("System", system_default)
    self.settings = self.db.profile
end

function System:OnEnable()
    System.settings.lock = System.settings.lock or not System.settings.lock --Locking frame if it was not locked on reload/relog
    refreshOptions()
    XB.Config:Register("System",system_config)
    if self.settings.enable then
        self:CreateFrames()
    else
        self:Disable()
    end
end

function System:OnDisable()
  if groupFrame:IsShown() then
    groupFrame:Hide()
  end
end

function System:CreateFrames()
  self:CreateGroupFrame()
  for _, element in ipairs(systemElements) do
    self:CreateElementFrame(element)
  end
end

function System:CreateGroupFrame()
  if not self.settings.enable then
    if groupFrame and groupFrame:IsVisible() then
    groupFrame:Hide()
    end
    return
  end

  local x,y,w,h,a = self.settings.x.group,self.settings.y.group,self.settings.w.group,self.settings.h.group,self.settings.anchor.group

  groupFrame = groupFrame or CreateFrame("Frame","SystemGroupFrame", BarFrame)
  groupFrame:SetPoint(a, x, y)
  groupFrame:SetSize(w, h)
  groupFrame:SetMovable(true)
  groupFrame:SetClampedToScreen(true)
  groupFrame:Show()
  XB:AddOverlay(self,groupFrame,a)
  
  groupFrame:SetScript("OnEnter", function()
    tooltip()
    moduleHovered = true
  end)

  groupFrame:SetScript("OnLeave", function()
    moduleHovered = false
  end)

  local elapsed = 0
  groupFrame:SetScript("OnUpdate", function(_, e)
    elapsed = elapsed + e
    if elapsed >= 1 and moduleHovered then
      tooltip()
      elapsed = 0
    end
  end)

  groupFrame:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
      UpdateAddOnMemoryUsage()
      local before = gcinfo()
      collectgarbage()
      UpdateAddOnMemoryUsage()
      local after = gcinfo()
      DEFAULT_CHAT_FRAME:AddMessage("|cff6699FFXIV Databar|r: Cleaned: |cffffff00"..formatMemoryValue(before-after))
    elseif button == "RightButton" then
      ToggleFrame(VideoOptionsFrame)
    end
  end)

  if not self.settings.lock then
    groupFrame.overlay:Show()
    groupFrame.overlay.anchor:Show()
  else
    groupFrame.overlay:Hide()
    groupFrame.overlay.anchor:Hide()
  end
end

function System:CreateElementFrame(element)
  if not self.settings.enable[element] then
    if moduleFrames[element] and moduleFrames[element]:IsVisible() then
      moduleFrames[element]:Hide()
    end
    return
  end
  
  local x,y,w,h,a,color,hover,refreshRate = self.settings.x[element],self.settings.y[element],self.settings.w[element],self.settings.h[element],self.settings.anchor[element],self.settings.color[element],self.settings.hover[element], self.settings.refreshRate[element]
  moduleFrames[element] = moduleFrames[element] or CreateFrame("Button", element.."Frame", groupFrame)
  local frame = moduleFrames[element];
  frame:SetSize(w, h)
  frame:SetPoint(a,x,y)
  frame:EnableMouse(true)
  frame:RegisterForClicks("AnyUp")
  frame:Show()
  
  moduleIcons[element] = moduleIcons[element] or frame:CreateTexture(nil,"OVERLAY",nil,7)
  local icon = moduleIcons[element];
  icon:SetSize(w,h)
  icon:SetPoint("CENTER")
  icon:SetTexture(XB.systemIcons[element])
  icon:SetVertexColor(unpack(color))

  moduleTexts[element] = moduleTexts[element] or frame:CreateFontString(nil, "OVERLAY")
  local text = moduleTexts[element]
  text:SetFont(XB.mediaFold.."font\\homizio_bold.ttf", 12)
  text:SetPoint("LEFT", icon, "RIGHT",2,0)
  text:SetTextColor(unpack(color))

  local elapsed = 0
  frame:SetScript("OnUpdate", function(_, e) 
    elapsed = elapsed + e
    if elapsed >= refreshRate then
      text:SetText(moduleFunctions[element]())
      elapsed = 0
    end
  end)

   frame:SetScript("OnMouseUp", function(_, button) 
    print(button)
  end)

   frame:SetScript("OnEnter", function() icon:SetVertexColor(unpack(hover)) end)
   frame:SetScript("Onleave", function() icon:SetVertexColor(unpack(color)) end)
  
end

--[[local AddOnName, XIVBar = ...;
local _G = _G;
local xb = XIVBar;
local L = XIVBar.L;

local SystemModule = xb:NewModule("SystemModule", 'AceEvent-3.0', 'AceHook-3.0')

function SystemModule:GetName()
  return SYSTEMOPTIONS_MENU;
end

function SystemModule:OnInitialize()
  self.elapsed = 0
end

function SystemModule:OnEnable()
  if self.systemFrame == nil then
    self.systemFrame = CreateFrame("FRAME", nil, xb:GetFrame('bar'))
    xb:RegisterFrame('systemFrame', self.systemFrame)
  end

  self.systemFrame:Show()
  self:CreateFrames()
  self:RegisterFrameEvents()
  self:Refresh()
end

function SystemModule:OnDisable()
  self.systemFrame:Hide()
  self.fpsFrame:SetScript('OnUpdate', nil)
end

function SystemModule:Refresh()
  local db = xb.db.profile
  if self.systemFrame == nil then return; end
  if not db.modules.system.enabled then self:Disable(); return; end 

  if InCombatLockdown() then
    self:UpdateTexts()
    return
  end

  local iconSize = db.text.fontSize --+ db.general.barPadding

  self.fpsIcon:SetTexture(xb.constants.mediaPath..'datatexts\\fps')
  self.fpsIcon:SetSize(iconSize, iconSize)
  self.fpsIcon:SetPoint('LEFT')
  self.fpsIcon:SetVertexColor(db.color.normal.r, db.color.normal.g, db.color.normal.b, db.color.normal.a)

  self.fpsText:SetFont(xb:GetFont(db.text.fontSize))

  self.fpsText:SetPoint('RIGHT', -5, 0)
  self.fpsText:SetText('000'..FPS_ABBR) -- get the widest we can be
  local fpsWidest = self.fpsText:GetStringWidth() + 5

  self.pingIcon:SetTexture(xb.constants.mediaPath..'datatexts\\ping')
  self.pingIcon:SetSize(iconSize, iconSize)
  self.pingIcon:SetPoint('LEFT')
  self.pingIcon:SetVertexColor(db.color.normal.r, db.color.normal.g, db.color.normal.b, db.color.normal.a)

  self.pingText:SetFont(xb:GetFont(db.text.fontSize))
  if db.modules.system.showWorld then
	self.worldPingText:SetFont(xb:GetFont(db.text.fontSize))
  end
  self.fpsText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
  self.pingText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
  if db.modules.system.showWorld then
	self.worldPingText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
  end
  if self.fpsFrame:IsMouseOver() then
    self.fpsText:SetTextColor(unpack(xb:HoverColors()))
  end
  if self.pingFrame:IsMouseOver() then
    self.pingText:SetTextColor(unpack(xb:HoverColors()))
	if db.modules.system.showWorld then
		self.worldPingText:SetTextColor(unpack(xb:HoverColors()))
	end
  end

  if db.modules.system.showWorld then
	self.worldPingText:SetText('000'..MILLISECONDS_ABBR)
  else
	if self.worldPing then
		self.worldPingText:SetText('')
	end
  end
  self.pingText:SetText('000'..MILLISECONDS_ABBR) -- get the widest we can be

  local pingWidest = self.pingText:GetStringWidth() + 5
  if db.modules.system.showWorld then
    self.worldPingText:SetPoint('LEFT', self.pingText, 'RIGHT', 5, 0)
    pingWidest = pingWidest + self.worldPingText:GetStringWidth() + 5
  end
  self.pingText:SetPoint('LEFT', self.pingIcon, 'RIGHT', 5, 0)

  self:UpdateTexts()

  self.fpsFrame:SetSize(fpsWidest + iconSize + 5, xb:GetHeight())
  self.fpsFrame:SetPoint('LEFT')

  self.pingFrame:SetSize(pingWidest + iconSize, xb:GetHeight())
  self.pingFrame:SetPoint('LEFT', self.fpsFrame, 'RIGHT', 5, 0)

  self.systemFrame:SetSize(self.fpsFrame:GetWidth() + self.pingFrame:GetWidth(), xb:GetHeight())

  --self.systemFrame:SetSize()
  local relativeAnchorPoint = 'LEFT'
  local xOffset = db.general.moduleSpacing
  local parentFrame = xb:GetFrame('goldFrame');
  if not xb.db.profile.modules.gold.enabled then
	if xb.db.profile.modules.travel.enabled then
	  parentFrame = xb:GetFrame('travelFrame');
	else
	  relativeAnchorPoint = 'RIGHT'
	  xOffset = 0
	  parentFrame = self.systemFrame:GetParent();
	end
  end
  self.systemFrame:SetPoint('RIGHT', parentFrame, relativeAnchorPoint, -(xOffset), 0)
end

function SystemModule:UpdateTexts()
  local db = xb.db.profile
  if not db.modules.system.enabled then return; end
  
  self.fpsText:SetText(floor(GetFramerate())..FPS_ABBR)
  local _, _, homePing, worldPing = GetNetStats()
  self.pingText:SetText(L['L']..": "..floor(homePing)..MILLISECONDS_ABBR)
  if xb.db.profile.modules.system.showWorld then
	self.worldPingText:SetText(L['W']..": "..floor(worldPing)..MILLISECONDS_ABBR)
  end
end

function SystemModule:CreateFrames()
  self.fpsFrame = self.fpsFrame or CreateFrame('BUTTON', nil, self.systemFrame)
  self.fpsIcon = self.fpsIcon or self.fpsFrame:CreateTexture(nil, 'OVERLAY')
  self.fpsText = self.fpsText or self.fpsFrame:CreateFontString(nil, 'OVERLAY')

  self.pingFrame = self.pingFrame or CreateFrame('BUTTON', nil, self.systemFrame)
  self.pingIcon = self.pingIcon or self.pingFrame:CreateTexture(nil, 'OVERLAY')
  self.pingText = self.pingText or self.pingFrame:CreateFontString(nil, 'OVERLAY')
  self.worldPingText = self.worldPingText or self.pingFrame:CreateFontString(nil, 'OVERLAY')
end

function SystemModule:HoverFunction()
  if InCombatLockdown() then return; end
  if self.fpsFrame:IsMouseOver() then
    self.fpsText:SetTextColor(unpack(xb:HoverColors()))
  end
  if self.pingFrame:IsMouseOver() then
    self.pingText:SetTextColor(unpack(xb:HoverColors()))
	if xb.db.profile.modules.system.showWorld then
		self.worldPingText:SetTextColor(unpack(xb:HoverColors()))
	end
  end
  if xb.db.profile.modules.system.showTooltip and not self.fpsFrame:IsMouseOver() then
    self:ShowTooltip()
  end
end

function SystemModule:LeaveFunction()
  if InCombatLockdown() then return; end
  local db = xb.db.profile
  self.fpsText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
  self.pingText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
  if xb.db.profile.modules.system.showWorld then
	self.worldPingText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
  end
  if xb.db.profile.modules.system.showTooltip then
    GameTooltip:Hide()
  end
end

function SystemModule:RegisterFrameEvents()

  self.fpsFrame:EnableMouse(true)
  self.fpsFrame:RegisterForClicks("AnyUp")

  self.pingFrame:EnableMouse(true)
  self.pingFrame:RegisterForClicks("AnyUp")

  self.fpsFrame:SetScript('OnEnter', function()
    self:HoverFunction()
  end)
  self.fpsFrame:SetScript('OnLeave', function()
    self:LeaveFunction()
  end)

  self.pingFrame:SetScript('OnEnter', function()
    self:HoverFunction()
  end)
  self.pingFrame:SetScript('OnLeave', function()
    self:LeaveFunction()
  end)

  --[self.fpsFrame:SetScript('OnKeyDown', function()
    if IsShiftKeyDown() and self.fpsFrame:IsMouseOver() then
      if xb.db.profile.modules.system.showTooltip then
        self:ShowTooltip()
      end
    end
  end)

  self.pingFrame:SetScript('OnKeyDown', function()
    if IsShiftKeyDown() and self.pingFrame:IsMouseOver() then
      if xb.db.profile.modules.system.showTooltip then
        self:ShowTooltip()
      end
    end
  end)

  self.fpsFrame:SetScript('OnKeyUp', function()
    if self.fpsFrame:IsMouseOver() then
      if xb.db.profile.modules.system.showTooltip then
        self:ShowTooltip()
      end
    end
  end)

  self.pingFrame:SetScript('OnKeyUp', function()
    if self.pingFrame:IsMouseOver() then
      if xb.db.profile.modules.system.showTooltip then
        self:ShowTooltip()
      end
    end
  end)]--

  self.fpsFrame:SetScript('OnClick', function(_, button)
    if InCombatLockdown() then return; end
    if button == 'LeftButton' then
      UpdateAddOnMemoryUsage()
      local before = collectgarbage('count')
      collectgarbage()
      local after = collectgarbage('count')
      local memDiff = before - after
      local memString = ''
      if memDiff > 1024 then
        memString = string.format("%.2f MB", (memDiff / 1024))
      else
        memString = string.format("%.0f KB", floor(memDiff))
      end
      print("|cff6699FFXIV_Databar|r: "..L['Cleaned']..": |cffffff00"..memString)
    end
  end)

  self.pingFrame:SetScript('OnClick', function(_, button)
    if InCombatLockdown() then return; end
    if button == 'LeftButton' then
      collectgarbage()
    end
  end)

  self.fpsFrame:SetScript('OnUpdate', function(self, elapsed)
    SystemModule.elapsed = SystemModule.elapsed + elapsed
    if SystemModule.elapsed >= 1 then
      if InCombatLockdown() then
        SystemModule:UpdateTexts()
      else
        SystemModule:Refresh()
      end
      SystemModule.elapsed = 0
    end
  end)

  self:RegisterMessage('XIVBar_FrameHide', function(_, name)
    if name == 'goldFrame' then
      self:Refresh()
    end
  end)

  self:RegisterMessage('XIVBar_FrameShow', function(_, name)
    if name == 'goldFrame' then
      self:Refresh()
    end
  end)
end

function SystemModule:ShowTooltip()
  local totalAddons = GetNumAddOns()
  local totalUsage = 0
  local memTable = {}

  UpdateAddOnMemoryUsage()

  for i = 1, totalAddons do
    local _, aoName, _ = GetAddOnInfo(i)
    local mem = GetAddOnMemoryUsage(i)
    table.insert(memTable, {memory = mem, name = aoName})
  end

  table.sort(memTable, function(a, b)
    return a.memory > b.memory
  end)

  GameTooltip:SetOwner(self.systemFrame, 'ANCHOR_'..xb.miniTextPosition)
  GameTooltip:ClearLines()
  GameTooltip:AddLine("[|cff6699FF"..L['Memory Usage'].."|r]")

  local toLoop = xb.db.profile.modules.system.addonsToShow
  if IsShiftKeyDown() and xb.db.profile.modules.system.showAllOnShift then
    toLoop = totalAddons
  end

  for i = 1, toLoop do
    local memString = ''
    if memTable[i] then
      if memTable[i].memory > 0 then
        if memTable[i].memory > 1024 then
          memString = string.format("%.2f MB", (memTable[i].memory / 1024))
        else
          memString = string.format("%.0f KB", floor(memTable[i].memory))
        end
        GameTooltip:AddDoubleLine(memTable[i].name, memString, 1, 1, 0, 1, 1, 1)
      end
    end
  end

  GameTooltip:AddLine(" ")
  GameTooltip:AddDoubleLine('<'..L['Left-Click']..'>', L['Garbage Collect'], 1, 1, 0, 1, 1, 1)
  GameTooltip:Show()
end

function SystemModule:GetDefaultOptions()
  return 'system', {
      enabled = true,
      showTooltip = true,
      showWorld = true,
      addonsToShow = 10,
      showAllOnShift = true
    }
end

function SystemModule:GetConfig()
  return {
    name = self:GetName(),
    type = "group",
    args = {
      enable = {
        name = ENABLE,
        order = 0,
        type = "toggle",
        get = function() return xb.db.profile.modules.system.enabled; end,
        set = function(_, val)
          xb.db.profile.modules.system.enabled = val
          if val then
            self:Enable()
          else
            self:Disable()
          end
        end,
        width = "full"
      },
      showTooltip = {
        name = L['Show Tooltips'],
        order = 1,
        type = "toggle",
        get = function() return xb.db.profile.modules.system.showTooltip; end,
        set = function(_, val) xb.db.profile.modules.system.showTooltip = val; self:Refresh(); end
      },
      showWorld = {
        name = L['Show World Ping'],
        order = 2,
        type = "toggle",
        get = function() return xb.db.profile.modules.system.showWorld; end,
        set = function(_, val) xb.db.profile.modules.system.showWorld = val; self:Refresh(); end
      },
      addonsToShow = {
        name = L['Addons to Show in Tooltip'], -- DROPDOWN, GoldModule:GetCurrencyOptions
        type = "range",
        order = 3,
        min = 1,
        max = 25,
        step = 1,
        get = function() return xb.db.profile.modules.system.addonsToShow; end,
        set = function(info, value) xb.db.profile.modules.system.addonsToShow = value; self:Refresh(); end,
      },
      showAllOnShift = {
        name = L['Show All Addons in Tooltip with Shift'],
        order = 4,
        type = "toggle",
        get = function() return xb.db.profile.modules.system.showAllOnShift; end,
        set = function(_, val) xb.db.profile.modules.system.showAllOnShift = val; self:Refresh(); end
      }
    }
  }
end
--]]