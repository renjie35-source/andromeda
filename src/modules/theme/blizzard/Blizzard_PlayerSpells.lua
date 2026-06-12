local F, C = unpack(select(2, ...))

local function reskinSpellBookItem(frame)
    if frame.styled then
        return
    end

    local button = frame.Button
    if button then
        button:SetCheckedTexture(0)
        button:SetPushedTexture(0)

        if button.Icon then
            button.Icon.bg = F.ReskinIcon(button.Icon)
        end

        if button.Border then
            button.Border:SetAlpha(0)
        end
    end

    if frame.Backplate then
        frame.Backplate:SetAlpha(0)
    end

    local textContainer = frame.TextContainer
    if textContainer then
        if textContainer.Name then
            textContainer.Name:SetTextColor(1, 1, 1)
        end
        if textContainer.SubName then
            textContainer.SubName:SetTextColor(0.7, 0.7, 0.7)
        end
        if textContainer.RequiredLevel then
            textContainer.RequiredLevel:SetTextColor(0.7, 0.7, 0.7)
        end
    end

    frame.styled = true
end

C.Themes['Blizzard_PlayerSpells'] = function()
    local PlayerSpellsFrame = _G.PlayerSpellsFrame
    if not PlayerSpellsFrame then
        return
    end

    F.ReskinPortraitFrame(PlayerSpellsFrame)

    local spellBook = PlayerSpellsFrame.SpellBookFrame
    if not spellBook then
        return
    end

    local pagedSpells = spellBook.PagedSpellsFrame
    if pagedSpells then
        hooksecurefunc(pagedSpells, 'DisplayViewsForCurrentPage', function(self)
            for _, frame in self:EnumerateFrames() do
                if frame.HasValidData and frame:HasValidData() then
                    reskinSpellBookItem(frame)
                end
            end
        end)
    end

    -- category side tabs (CategoryTabSystem inherits TabSystemTemplate)
    local tabSystem = spellBook.CategoryTabSystem
    if tabSystem and tabSystem.GetChildren then
        for _, tab in pairs({ tabSystem:GetChildren() }) do
            if tab.GetNormalTexture and not tab.styled then
                local nt = tab:GetNormalTexture()
                if nt then
                    nt:SetTexCoord(unpack(C.TEX_COORD))
                end
                F.CreateBDFrame(tab, 0.25)

                tab.styled = true
            end
        end
    end
end
