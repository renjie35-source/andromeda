local F, C = unpack(select(2, ...))

local function handleSkillButton(button)
    if not button then
        return
    end
    button:SetCheckedTexture(0)
    button:SetPushedTexture(0)
    button.IconTexture:SetInside()
    button.bg = F.ReskinIcon(button.IconTexture)
    button.highlightTexture:SetInside(button.bg)

    local nameFrame = _G[button:GetName() .. 'NameFrame']
    if nameFrame then
        nameFrame:Hide()
    end
end

C.Themes['Blizzard_ProfessionsBook'] = function()
    local ProfessionsBookFrame = _G.ProfessionsBookFrame
    if not ProfessionsBookFrame then
        return
    end

    F.ReskinPortraitFrame(ProfessionsBookFrame)

    local professions = {
        'PrimaryProfession1',
        'PrimaryProfession2',
        'SecondaryProfession1',
        'SecondaryProfession2',
        'SecondaryProfession3',
    }

    for i, button in pairs(professions) do
        local bu = _G[button]
        if bu then
            bu.professionName:SetTextColor(1, 1, 1)
            bu.missingHeader:SetTextColor(1, 1, 1)
            bu.missingText:SetTextColor(1, 1, 1)

            F.StripTextures(bu.statusBar)
            bu.statusBar:SetHeight(10)
            bu.statusBar:SetStatusBarTexture(C.Assets.Textures.Backdrop)
            bu.statusBar:GetStatusBarTexture():SetGradient('VERTICAL', CreateColor(0, 0.6, 0, 1), CreateColor(0, 0.8, 0, 1))

            bu.statusBar.rankText:SetPoint('CENTER')
            F.CreateBDFrame(bu.statusBar, 0.25)
            if i > 2 then
                bu.statusBar:ClearAllPoints()
                bu.statusBar:SetPoint('BOTTOMLEFT', 16, 3)
            end

            handleSkillButton(bu.SpellButton1)
            handleSkillButton(bu.SpellButton2)
        end
    end

    for i = 1, 2 do
        local bu = _G['PrimaryProfession' .. i]
        if bu then
            local iconBorder = _G['PrimaryProfession' .. i .. 'IconBorder']
            if iconBorder then
                iconBorder:Hide()
            end

            bu.professionName:ClearAllPoints()
            bu.professionName:SetPoint('TOPLEFT', 100, -4)
            bu.icon:SetAlpha(1)
            bu.icon:SetDesaturated(false)
            F.ReskinIcon(bu.icon)

            local bg = F.CreateBDFrame(bu, 0.25)
            bg:SetPoint('TOPLEFT')
            bg:SetPoint('BOTTOMRIGHT', 0, -5)
        end
    end

    hooksecurefunc('FormatProfession', function(frame, index)
        if index then
            local _, texture = GetProfessionInfo(index)

            if frame.icon and texture then
                frame.icon:SetTexture(texture)
            end
        end
    end)

    if _G.SecondaryProfession1 then
        F.CreateBDFrame(_G.SecondaryProfession1, 0.25)
        F.CreateBDFrame(_G.SecondaryProfession2, 0.25)
        F.CreateBDFrame(_G.SecondaryProfession3, 0.25)
    end

    hooksecurefunc('UpdateProfessionButton', function(self)
        local spellIndex = self:GetID() + self:GetParent().spellOffset
        local isPassive = C_SpellBook.IsSpellBookItemPassive(spellIndex, Enum.SpellBookSpellBank.Player)
        if isPassive then
            self.highlightTexture:SetColorTexture(1, 1, 1, 0)
        else
            self.highlightTexture:SetColorTexture(1, 1, 1, 0.25)
        end
        if self.spellString then
            self.spellString:SetTextColor(1, 1, 1)
        end
        if self.subSpellString then
            self.subSpellString:SetTextColor(1, 1, 1)
        end
    end)
end
