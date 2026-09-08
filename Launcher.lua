local _, addon = ...

local Launcher = {}

local function positionButton(button, angle)
    local shape = _G.GetMinimapShape and _G.GetMinimapShape()
        or "ROUND"
    local x, y = addon.MinimapPosition.Calculate(
        angle,
        Minimap:GetWidth(),
        Minimap:GetHeight(),
        shape,
        5
    )

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function Launcher:Create()
    SLASH_BETTERBEJEWELED1 = "/bb"
    SlashCmdList.BETTERBEJEWELED = function()
        addon.UI:Toggle()
    end

    local button = CreateFrame(
        "Button",
        "BetterBejeweledMinimapButton",
        Minimap
    )
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture(136477)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT", button, "TOPLEFT")
    border:SetTexture(136430)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(24, 24)
    background:SetPoint("CENTER")
    background:SetTexture(136467)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexture(
        "Interface\\AddOns\\BetterBejeweled\\Media\\Gems64\\Blue.png"
    )
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    button:SetScript("OnClick", function()
        if not button.isDragging then
            addon.UI:Toggle()
        end
        button.isDragging = false
    end)
    button:SetScript("OnDragStart", function()
        button.isDragging = true
        button:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local centerX, centerY = Minimap:GetCenter()
            local angle = math.deg(math.atan2(y / scale - centerY,
                x / scale - centerX))

            BetterBejeweledDB.minimapAngle = angle
            positionButton(button, angle)
        end)
    end)
    button:SetScript("OnDragStop", function()
        button:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("BetterBejeweled")
        GameTooltip:AddLine("Click to play. Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:RegisterEvent("PLAYER_ENTERING_WORLD")
    button:SetScript("OnEvent", function()
        positionButton(button, BetterBejeweledDB.minimapAngle)
    end)

    positionButton(button, BetterBejeweledDB.minimapAngle)
    self.button = button
end

addon.Launcher = Launcher
