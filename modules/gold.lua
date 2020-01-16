local addOnName, XB = ...;

local Gold = XB:RegisterModule("Gold")

----------------------------------------------------------------------------------------------------------
-- Imports
----------------------------------------------------------------------------------------------------------
local floor, abs = math.floor, math.abs
local format = string.format

----------------------------------------------------------------------------------------------------------
-- Local variables
----------------------------------------------------------------------------------------------------------
local ccR,ccG,ccB = GetClassColor(XB.playerClass)
local libTT
local gold_config
local goldFrame, goldIcon, goldText
local Bar, BarFrame
local weekday, month, day, year = C_Calendar.GetDate().weekday, C_Calendar.GetDate().month, C_Calendar.GetDate().monthDay, C_Calendar.GetDate().year

----------------------------------------------------------------------------------------------------------
-- Private functions
----------------------------------------------------------------------------------------------------------
local function ConvertDateToNumber(month, day, year)
    month = gsub(month, "(%d)(%d?)", function(d1, d2) return d2 == "" and "0"..d1 or d1..d2 end) -- converts M to MM
    day = gsub(day, "(%d)(%d?)", function(d1, d2) return d2 == "" and "0"..d1 or d1..d2 end) -- converts D to DD

    return tonumber(year..month..day)
end

local today = ConvertDateToNumber(month, day, year)

local function shortenGoldNumber(num)
  if num < 1000 then
    return tostring(num)
  elseif num < 1000000 then
    return format("%.1f "..'k', num/1000)
  elseif num < 1000000000 then
    return format("%.2f "..'M', num/1000000)
  else
    return format("%.3f "..'B', num/1000000000)
  end
end

local function separateCoins(money)
  local gold, silver, copper = floor(abs(money / 10000)), floor(abs(mod(money / 100, 100))), floor(abs(mod(money, 100)))
  return gold, silver, copper
end

local function formatCoinText(money)
  local showSC = Gold.settings.showSmallCoins
  local shortAmount = Gold.settings.shortAmount
  local g, s, c = separateCoins(money)
  local formattedString = ''
  if g > 0 then
    formattedString = '%s '..GOLD_AMOUNT_SYMBOL
    if g > 1000 and shortAmount then
      formattedString = shortenGoldNumber(g)..GOLD_AMOUNT_SYMBOL
    end
  end
  if s > 0 and (g < 1 or showSC) then
    if g >= 1 then
      formattedString = formattedString..' '
    end
    formattedString = formattedString..'%d '..SILVER_AMOUNT_SYMBOL
  end
  if c > 0 and (s < 1 or showSC) then
    if g > 1 or s > 1 then
      formattedString = formattedString..' '
    end
    formattedString = formattedString..'%d '..COPPER_AMOUNT_SYMBOL
  end

  local ret = string.format(formattedString, BreakUpLargeNumbers(g), s, c)
  if money < 0 then
    ret = '-'..ret
  end
  return ret
end

local function getGoldText() 
  local currentMoneyAmount = GetMoney()
  return formatCoinText(currentMoneyAmount)
end

local function getFreeBagSpace()
  local bagFreeSpace = 0
  for i = 0, 4 do
    bagFreeSpace = bagFreeSpace + GetContainerNumFreeSlots(i)
  end
  return '('..tostring(bagFreeSpace)..')'
end


local function getYearBeginDayOfWeek(tm)
  local yearBegin = time{year=date("*t",tm).year,month=1,day=1}
  local yearBeginDayOfWeek = tonumber(date("%w",yearBegin))
  -- sunday correct from 0 -> 7
  if(yearBeginDayOfWeek == 0) then yearBeginDayOfWeek = 7 end
  return yearBeginDayOfWeek
end

local function getDayAdd(tm)
  local yearBeginDayOfWeek = getYearBeginDayOfWeek(tm)
  local dayAdd
  if(yearBeginDayOfWeek < 5 ) then
    -- first day is week 1
    dayAdd = (yearBeginDayOfWeek - 2)
  else
    -- first day is week 52 or 53
    dayAdd = (yearBeginDayOfWeek - 9)
  end
  return dayAdd
end

local function getWeekNumberOfYear(tm)
  local dayOfYear = date("%j",tm)
  local dayAdd = getDayAdd(tm)
  local dayOfYearCorrected = dayOfYear + dayAdd
  if(dayOfYearCorrected < 0) then
    -- week of last year - decide if 52 or 53
    local lastYearBegin = time{year=date("*t",tm).year-1,month=1,day=1}
    local lastYearEnd = time{year=date("*t",tm).year-1,month=12,day=31}
    dayAdd = getDayAdd(lastYearBegin)
    dayOfYear = dayOfYear + date("%j",lastYearEnd)
    dayOfYearCorrected = dayOfYear + dayAdd
  end
  local weekNum = math.floor((dayOfYearCorrected) / 7) + 1
  if( (dayOfYearCorrected > 0) and weekNum == 53) then
    -- check if it is not considered as part of week 1 of next year
    local nextYearBegin = time{year=date("*t",tm).year+1,month=1,day=1}
    local yearBeginDayOfWeek = getYearBeginDayOfWeek(nextYearBegin)
    if(yearBeginDayOfWeek < 5 ) then
      weekNum = 1
    end
  end
  return weekNum
end

local function getOrCreatePlayerGoldData()
  if Gold.db.profile then
    if Gold.db.profile[XB.playerRealm] then
      if Gold.db.profile[XB.playerRealm][XB.playerFaction] then
        if Gold.db.profile[XB.playerRealm][XB.playerFaction][XB.playerName] then
          return Gold.db.profile[XB.playerRealm][XB.playerFaction][XB.playerName]
        else
          Gold.db.profile[XB.playerRealm][XB.playerFaction][XB.playerName] = {
            sessionStartMoney = GetMoney(),
            currentMoney = GetMoney(),
            lastLoginDate = today,
            dailyMoney = 0,
            lasWeekLoginDate = getWeekNumberOfYear(time()),
            weeklyMoney = 0
          }
          return Gold.db.profile[XB.playerRealm][XB.playerFaction][XB.playerName]
        end
      else
        Gold.db.profile[XB.playerRealm][XB.playerFaction] = {}
      end
    else
      Gold.db.profile[XB.playerRealm] = {}
    end
  else
    print("Cannot retrieve gold data")
  end
end

local function tooltipData(tooltip)
  tooltip:AddLine("[|cff6699FF"..BONUS_ROLL_REWARD_MONEY.."|r "," |cff82c5ff"..XB.playerFaction.." "..XB.playerRealm.."|r]")
  tooltip:AddLine(" ")

  tooltip:AddLine('Session Balance', formatCoinText(Gold.settings[XB.playerRealm][XB.playerFaction][XB.playerName].sessionMoney))
  tooltip:AddLine(" ")

  local totalGold = 0
  for charName, goldData in pairs(Gold.settings[XB.playerRealm][XB.playerFaction]) do
    print(charName)
    print(goldData)
    tooltip:AddLine(charName, formatCoinText(goldData.currentMoney))
    totalGold = totalGold + goldData.currentMoney
  end
  tooltip:AddLine(" ")
  tooltip:AddLine(TOTAL, formatCoinText(totalGold))
  tooltip:AddLine('<'..'Left-Click'..'>', 'Toggle Bags')
  tooltip:Show()
end

local function tooltip()
  if libTT:IsAcquired("GoldTip") then
    libTT:Release(libTT:Acquire("GoldTip"))
  end
  local tooltip = libTT:Acquire("GoldTip", 2, "LEFT")
  tooltip:SmartAnchorTo(goldFrame)
  tooltip:SetAutoHideDelay(.1, goldFrame)
  tooltipData(tooltip)
  XB:SkinTooltip(tooltip,"GoldTip")
  tooltip:Show()
end

local function refreshOptions()
  Bar, BarFrame = XB:GetModule("Bar"), XB:GetModule("Bar"):GetFrame()
end

----------------------------------------------------------------------------------------------------------
-- Options
----------------------------------------------------------------------------------------------------------
local gold_default = {
  profile = {
    enable = true,
    lock = true,
    x = -150,
    y = 0,
    w = 32,
    h = 32,
    anchor = "RIGHT",
    combatEn = false,
    tooltip = false,
    color = {1,1,1,.75},
    colorCC = false,
    hover = XB.playerClass == "PRIEST" and {.5,.5,0,.75} or {ccR,ccG,ccB,.75},
    hoverCC = not (XB.playerClass == "PRIEST"),
    showSmallCoins = true,
    shortAmount = true,
    showBagFreeSpace = true,
    currentMoneyAmount = 0,
    moneyAmountFirstLoginDay = 0,
    moneyAmountFirstLoginWeek = 0,
    currentDay = 1,
    currentWeek = 15
  }
}

gold_config = {}

----------------------------------------------------------------------------------------------------------
-- Module functions
----------------------------------------------------------------------------------------------------------
function Gold:OnInitialize()
    libTT = LibStub('LibQTip-1.0')
    self.db = XB.db:RegisterNamespace("Gold", gold_default)
    self.settings = self.db.profile
    getOrCreatePlayerGoldData()
end

function Gold:OnEnable()
    Gold.settings.lock = Gold.settings.lock or not Gold.settings.lock --Locking frame if it was not locked on reload/relog
    refreshOptions()
    XB.Config:Register("Gold", gold_config)
    if self.settings.enable then
        self:CreateFrames()
    else
        self:Disable()
    end
end

function Gold:OnDisable()
  if goldFrame and goldFrame:IsShown() then
    goldFrame:Hide()
  end
end

function Gold:CreateFrames()
  if not self.settings.enable then
    if goldFrame and goldFrame:IsVisible() then
      goldFrame:Hide()
    end
    return
  end

  local x,y,w,h,a,color,hover = self.settings.x,self.settings.y,self.settings.w,self.settings.h,self.settings.anchor,self.settings.color,self.settings.hover

  goldFrame = goldFrame or CreateFrame("Button","GoldFrame", BarFrame)
  goldFrame:SetPoint(a, x, y)
  goldFrame:SetSize(w, h)
  goldFrame:SetMovable(true)
  goldFrame:SetClampedToScreen(true)
  goldFrame:EnableMouse(true)
  goldFrame:RegisterForClicks("AnyUp")
  goldFrame:Show()
  XB:AddOverlay(self,goldFrame,a)

  goldIcon = goldIcon or goldFrame:CreateTexture(nil,"OVERLAY",nil,7)
  goldIcon:SetPoint("LEFT")
  goldIcon:SetTexture(XB.mediaFold.."datatexts\\gold")
  goldIcon:SetVertexColor(unpack(color))

  goldText = goldText or goldFrame:CreateFontString(nil, "OVERLAY")
  goldText:SetFont(XB.mediaFold.."font\\homizio_bold.ttf", 12)
  goldText:SetPoint("RIGHT", goldFrame, 2,0)
  goldText:SetTextColor(unpack(color))

  goldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  goldFrame:RegisterEvent("PLAYER_MONEY")
  goldFrame:RegisterEvent("BAG_UPDATE")
  goldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

  goldFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
      print("log/relog")
      Gold:registerSessionGold()
    end

    goldText:SetText(getGoldText())
    if self.settings.showBagFreeSpace then
      goldText:SetText(goldText:GetText().." "..getFreeBagSpace())
    end
    goldFrame:SetWidth(goldText:GetStringWidth() + h/2)
  end)

  goldFrame:SetScript("OnEnter", function() 
    goldIcon:SetVertexColor(unpack(hover))
    tooltip()
  end)

  goldFrame:SetScript("OnLeave", function()
    goldIcon:SetVertexColor(unpack(color))
  end)

  goldFrame:SetScript("OnMouseUp", function() 
    ToggleAllBags()
  end)

  if not self.settings.lock then
    goldFrame.overlay:Show()
    goldFrame.overlay.anchor:Show()
  else
    goldFrame.overlay:Hide()
    goldFrame.overlay.anchor:Hide()
  end
end

function Gold:registerSessionGold()
  local playerData = getOrCreatePlayerGoldData()

  local updateData

  if playerData.lastLoginDate then
      if playerData.lastLoginDate < today then -- is true, if last time player logged in was the day before or even earlier
          playerData.lastLoginDate = today
          updateData = true
      end
  else
      playerData.lastLoginDate = today
      playerData.sessionMoney = GetMoney()
      updateData = true
  end
end

--[[local AddOnName, XIVBar = ...;
local _G = _G;
local xb = XIVBar;
local L = XIVBar.L;

local GoldModule = xb:NewModule("GoldModule", 'AceEvent-3.0')

local isSessionNegative, isDailyNegative = false, false
local positiveSign = "|cff00ff00+ "
local negativeSign = "|cffff0000- "

local function shortenNumber(num)
  if num < 1000 then
    return tostring(num)
  elseif num < 1000000 then
    return format("%.1f"..L['k'],num/1000)
  elseif num < 1000000000 then
    return format("%.2f"..L['M'],num/1000000)
  else
    return format("%.3f"..L['B'],num/1000000000)
  end
end

local function moneyWithTexture(amount,session)
  local copper, silver = 0,0;
  local showSC = xb.db.profile.modules.gold.showSmallCoins
  local shortThousands = xb.db.profile.modules.gold.shortThousands
  local shortGold = ""

  amount, copper = math.modf(amount/100.0)
  amount, silver = math.modf(amount/100.0)

  silver = silver * 100
  copper = copper * 100

  silver = string.format("%02d",silver)
  copper = string.format("%02d",copper)

  amount = string.format("%.0f",amount)
  
  if not showSC then
    silver,copper = "00","00"
  end

  amountStringTexture = GetCoinTextureString(amount..""..silver..""..copper)

  if shortThousands then
    shortGold = shortenNumber(tonumber(amount))
    amountStringTexture = amountStringTexture:gsub(amount.."|T",shortGold.."|T")
  end

  if not session then
    return amountStringTexture
  else
    return isSessionNegative and negativeSign..amountStringTexture or amountStringTexture
  end
end

local function ConvertDateToNumber(month, day, year)
  month = gsub(month, "(%d)(%d?)", function(d1, d2) return d2 == "" and "0"..d1 or d1..d2 end) -- converts M to MM
  day = gsub(day, "(%d)(%d?)", function(d1, d2) return d2 == "" and "0"..d1 or d1..d2 end) -- converts D to DD

  return tonumber(year..month..day)
end

function GoldModule:GetName()
  return BONUS_ROLL_REWARD_MONEY;
end

function GoldModule:OnInitialize()
  if not xb.db.factionrealm[xb.constants.playerName] then
    xb.db.factionrealm[xb.constants.playerName] = { currentMoney = 0, sessionMoney = 0, dailyMoney = 0 }
  else
    if not xb.db.factionrealm[xb.constants.playerName].dailyMoney then
      xb.db.factionrealm[xb.constants.playerName].dailyMoney = 0
    end
  end
  
  local playerData = xb.db.factionrealm[xb.constants.playerName]

  local curDate = C_Calendar.GetDate()
  local today = ConvertDateToNumber(curDate.month, curDate.monthDay, curDate.year)
  
  if playerData.lastLoginDate then
      if playerData.lastLoginDate < today then -- is true, if last time player logged in was the day before or even earlier
          playerData.lastLoginDate = today
          playerData.daily = 0
      end
  else
    playerData.lastLoginDate = today
  end
end

function GoldModule:OnEnable()
  if self.goldFrame == nil then
    self.goldFrame = CreateFrame("FRAME", nil, xb:GetFrame('bar'))
    xb:RegisterFrame('goldFrame', self.goldFrame)
  end
  self.goldFrame:Show()

  xb.db.factionrealm[xb.constants.playerName].sessionMoney = 0
  xb.db.factionrealm[xb.constants.playerName].currentMoney = GetMoney()

  self:CreateFrames()
  self:RegisterFrameEvents()
  self:Refresh()
  listAllCharactersByFactionRealm()
end

function GoldModule:OnDisable()
  self.goldFrame:Hide()
  self:UnregisterEvent('PLAYER_MONEY')
  self:UnregisterEvent('BAG_UPDATE')
end

function GoldModule:Refresh()
  local db = xb.db.profile
  if self.goldFrame == nil then return; end
  if not db.modules.gold.enabled then self:Disable(); return; end

  if InCombatLockdown() then
    self.goldText:SetFont(xb:GetFont(db.text.fontSize))
    self.goldText:SetText(self:FormatCoinText(GetMoney()))
    if db.modules.gold.showFreeBagSpace then
      local freeSpace = 0
      for i = 0, 4 do
        freeSpace = freeSpace + GetContainerNumFreeSlots(i)
      end
      self.bagText:SetFont(xb:GetFont(db.text.fontSize))
      self.bagText:SetText('('..tostring(freeSpace)..')')
    end
    return
  end

  local iconSize = db.text.fontSize + db.general.barPadding
  self.goldIcon:SetTexture(xb.constants.mediaPath..'datatexts\\gold')
  self.goldIcon:SetSize(iconSize, iconSize)
  self.goldIcon:SetPoint('LEFT')
  self.goldIcon:SetVertexColor(db.color.normal.r, db.color.normal.g, db.color.normal.b, db.color.normal.a)

  self.goldText:SetFont(xb:GetFont(db.text.fontSize))
  self.goldText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
  self.goldText:SetText(self:FormatCoinText(GetMoney()))
  self.goldText:SetPoint('LEFT', self.goldIcon, 'RIGHT', 5, 0)

  local bagWidth = 0
  if db.modules.gold.showFreeBagSpace then
    local freeSpace = 0
    for i = 0, 4 do
      freeSpace = freeSpace + GetContainerNumFreeSlots(i)
    end
    self.bagText:SetFont(xb:GetFont(db.text.fontSize))
    self.bagText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
    self.bagText:SetText('('..tostring(freeSpace)..')')
    self.bagText:SetPoint('LEFT', self.goldText, 'RIGHT', 5, 0)
    bagWidth = self.bagText:GetStringWidth()
  else
	self.bagText:SetFont(xb:GetFont(db.text.fontSize))
    self.bagText:SetText('')
    self.bagText:SetSize(0, 0)
  end

  self.goldButton:SetSize(self.goldText:GetStringWidth() + iconSize + 10 + bagWidth, iconSize)
  self.goldButton:SetPoint('LEFT')

  self.goldFrame:SetSize(self.goldButton:GetSize())

  local relativeAnchorPoint = 'LEFT'
  local xOffset = db.general.moduleSpacing
  local parentFrame = xb:GetFrame('travelFrame')
  if not true then --xb.db.profile.modules.travel.enabled
    parentFrame = self.goldFrame:GetParent()
    relativeAnchorPoint = 'RIGHT'
    xOffset = 0
  end
  self.goldFrame:SetPoint('RIGHT', parentFrame, relativeAnchorPoint, -(xOffset), 0)
end

function GoldModule:CreateFrames()
  self.goldButton = self.goldButton or CreateFrame("BUTTON", nil, self.goldFrame)
  self.goldIcon = self.goldIcon or self.goldButton:CreateTexture(nil, 'OVERLAY')
  self.goldText = self.goldText or self.goldButton:CreateFontString(nil, "OVERLAY")
  self.bagText = self.bagText or self.goldButton:CreateFontString(nil, "OVERLAY")
end

function GoldModule:RegisterFrameEvents()

  self.goldButton:EnableMouse(true)
  self.goldButton:RegisterForClicks("AnyUp")

  self:RegisterEvent('PLAYER_MONEY')
  self:RegisterEvent('BAG_UPDATE', 'Refresh')

  self.goldButton:SetScript('OnEnter', function()
    if InCombatLockdown() then return; end
    self.goldText:SetTextColor(unpack(xb:HoverColors()))
    self.bagText:SetTextColor(unpack(xb:HoverColors()))

    GameTooltip:SetOwner(GoldModule.goldFrame, 'ANCHOR_'..xb.miniTextPosition)
    GameTooltip:AddLine("[|cff6699FF"..BONUS_ROLL_REWARD_MONEY.."|r - |cff82c5ff"..xb.constants.playerFactionLocal.." "..xb.constants.playerRealm.."|r]")
    if not xb.db.profile.modules.gold.showSmallCoins then
      GameTooltip:AddLine(L["Gold rounded values"])
    end
    GameTooltip:AddLine(" ")

    GameTooltip:AddDoubleLine(L['Session Total'], moneyWithTexture(math.abs(xb.db.factionrealm[xb.constants.playerName].sessionMoney),true), 1, 1, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L['Daily Total'], moneyWithTexture(math.abs(xb.db.factionrealm[xb.constants.playerName].dailyMoney),true), 1, 1, 0, 1, 1, 1)
    GameTooltip:AddLine(" ")

    local totalGold = 0
    for charName, goldData in pairs(xb.db.factionrealm) do
      GameTooltip:AddDoubleLine(charName, moneyWithTexture(goldData.currentMoney), 1, 1, 0, 1, 1, 1)
      totalGold = totalGold + goldData.currentMoney
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(TOTAL, GoldModule:FormatCoinText(totalGold), 1, 1, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine('<'..L['Left-Click']..'>', L['Toggle Bags'], 1, 1, 0, 1, 1, 1)
    GameTooltip:Show()
  end)

  self.goldButton:SetScript('OnLeave', function()
    if InCombatLockdown() then return; end
    local db = xb.db.profile
    self.goldText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
    self.bagText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
    GameTooltip:Hide()
  end)

  self.goldButton:SetScript('OnClick', function(_, button)
    if InCombatLockdown() then return; end
    ToggleAllBags()
  end)

  self:RegisterMessage('XIVBar_FrameHide', function(_, name)
    if name == 'travelFrame' then
      self:Refresh()
    end
  end)

  self:RegisterMessage('XIVBar_FrameShow', function(_, name)
    if name == 'travelFrame' then
      self:Refresh()
    end
  end)
end

function GoldModule:PLAYER_MONEY()
  local gdb = xb.db.factionrealm[xb.constants.playerName]
  local curMoney = gdb.currentMoney
  local tmpMoney = GetMoney()
  local moneyDiff = tmpMoney - curMoney
  
  gdb.sessionMoney = gdb.sessionMoney + moneyDiff
  gdb.dailyMoney = gdb.dailyMoney + moneyDiff

  --[local weekday, month, day, year = CalendarGetDate()

  if gdb.curDay == nil or (gdb.curMonth == month and gdb.curDay < day) or (gdb.curMonth < month) or gdb.curYear < year then
    if gdb.curDay then
      gdb.
    end
  end]--
  gdb.currentMoney = tmpMoney
  self:Refresh()
end

function GoldModule:FormatCoinText(money)
  local showSC = xb.db.profile.modules.gold.showSmallCoins
  if money == 0 then
	return showSC and string.format("%s"..GOLD_AMOUNT_SYMBOL.." %s"..SILVER_AMOUNT_SYMBOL.." %s"..COPPER_AMOUNT_SYMBOL,0,0,0) or money..GOLD_AMOUNT_SYMBOL
  end

  local shortThousands = xb.db.profile.modules.gold.shortThousands
  local g, s, c = self:SeparateCoins(money)

  if showSC then
	return (shortThousands and shortenNumber(g) or BreakUpLargeNumbers(g))..GOLD_AMOUNT_SYMBOL..' '..s..SILVER_AMOUNT_SYMBOL..' '..c..COPPER_AMOUNT_SYMBOL
  else
	return g > 0 and (shortThousands and shortenNumber(g)..GOLD_AMOUNT_SYMBOL) or BreakUpLargeNumbers(g)..GOLD_AMOUNT_SYMBOL
  end
end

function GoldModule:SeparateCoins(money)
  local gold, silver, copper = floor(abs(money / 10000)), floor(abs(mod(money / 100, 100))), floor(abs(mod(money, 100)))
  return gold, silver, copper
end

function listAllCharactersByFactionRealm()
  local optTable = {
    header = {
      name = "|cff82c5ff"..xb.constants.playerFactionLocal.." "..xb.constants.playerRealm.."|r",
      type = "header",
      order = 0
    },
    footer = {
      name = "All the characters listed above are currently registered in the gold database. To delete one or several character, plase uncheck the box correponding to the character(s) to delete.\nThe boxes will remain unchecked for the deleted character(s), untill you reload or logout/login",
      type = "description",
      order = -1
    }
  }

  for k,v in pairs(xb.db.factionrealm) do
    optTable[k]={
      name = k,
      width = "full",
      type = "toggle",
      get = function() return xb.db.factionrealm[k] ~= nil; end,
      set = function(_,val) if not val and xb.db.factionrealm[k] ~= nil then xb.db.factionrealm[k] = nil; end end
    }
  end
  return optTable;
end

function GoldModule:GetDefaultOptions()
  return 'gold', {
      enabled = true,
      showSmallCoins = false,
      showFreeBagSpace = true,
      shortThousands = false
    }
end

function GoldModule:GetConfig()
  return {
    name = self:GetName(),
    type = "group",
    args = {
      enable = {
        name = ENABLE,
        order = 0,
        type = "toggle",
        get = function() return xb.db.profile.modules.gold.enabled; end,
        set = function(_, val)
          xb.db.profile.modules.gold.enabled = val
          if val then
            self:Enable()
          else
            self:Disable()
          end
        end,
        width = "full"
      },
      showSmallCoins = {
        name = L['Always Show Silver and Copper'],
        order = 1,
        type = "toggle",
        get = function() return xb.db.profile.modules.gold.showSmallCoins; end,
        set = function(_, val) xb.db.profile.modules.gold.showSmallCoins = val; self:Refresh(); end
      },
      showFreeBagSpace = {
        name = DISPLAY_FREE_BAG_SLOTS,
        order = 1,
        type = "toggle",
        get = function() return xb.db.profile.modules.gold.showFreeBagSpace; end,
        set = function(_, val) xb.db.profile.modules.gold.showFreeBagSpace = val; self:Refresh(); end
      },
      shortThousands = {
        name = L['Shorten Gold'],
        order = 1,
        type = "toggle",
        get = function() return xb.db.profile.modules.gold.shortThousands; end,
        set = function(_, val) xb.db.profile.modules.gold.shortThousands = val; self:Refresh(); end
      },
      listPlayers = {
        name = "Registered characters",
        type = "group",
        order = 1,
        args = listAllCharactersByFactionRealm()
      }
    }
  }
end
--]]