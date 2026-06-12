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

local function reskinTalentFrameDialog(dialog)
    F.StripTextures(dialog)
    F.SetBD(dialog)
    if dialog.AcceptButton then
        F.ReskinButton(dialog.AcceptButton)
    end
    if dialog.CancelButton then
        F.ReskinButton(dialog.CancelButton)
    end
    if dialog.DeleteButton then
        F.ReskinButton(dialog.DeleteButton)
    end

    if dialog.NameControl and dialog.NameControl.EditBox then
        F.ReskinEditbox(dialog.NameControl.EditBox)
        dialog.NameControl.EditBox.__bg:SetPoint('TOPLEFT', -5, -10)
        dialog.NameControl.EditBox.__bg:SetPoint('BOTTOMRIGHT', 5, 10)
    end
end

local function reskinSpellBook(spellBook)
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

local function reskinTalents(talents)
    if talents.Background then
        talents.Background:SetAlpha(0.4)
    end
    if talents.BlackBG then
        talents.BlackBG:SetAlpha(0)
    end
    if talents.BottomBar then
        talents.BottomBar:SetAlpha(0)
    end

    if talents.ApplyButton then
        F.ReskinButton(talents.ApplyButton)
    end
    if talents.InspectCopyButton then
        F.ReskinButton(talents.InspectCopyButton)
    end
    if talents.LoadSystem and talents.LoadSystem.Dropdown then
        F.ReskinDropdown(talents.LoadSystem.Dropdown)
    end
    if talents.SearchBox then
        F.ReskinEditbox(talents.SearchBox)
        talents.SearchBox.__bg:SetPoint('TOPLEFT', -4, -5)
        talents.SearchBox.__bg:SetPoint('BOTTOMRIGHT', 0, 5)
    end
end

local function reskinSpec(spec)
    hooksecurefunc(spec, 'UpdateSpecFrame', function(self)
        if not self.SpecContentFramePool then
            return
        end

        for specContentFrame in self.SpecContentFramePool:EnumerateActive() do
            if not specContentFrame.styled then
                if specContentFrame.ActivateButton then
                    F.ReskinButton(specContentFrame.ActivateButton)
                end

                local role = GetSpecializationRole(specContentFrame.specIndex)
                if role and specContentFrame.RoleIcon then
                    F.ReskinSmallRole(specContentFrame.RoleIcon, role)
                end

                if specContentFrame.SpellButtonPool then
                    for button in specContentFrame.SpellButtonPool:EnumerateActive() do
                        if button.Ring then
                            button.Ring:Hide()
                        end
                        if button.Icon then
                            F.ReskinIcon(button.Icon)
                        end
                    end
                end

                specContentFrame.styled = true
            end
        end
    end)
end

C.Themes['Blizzard_PlayerSpells'] = function()
    local PlayerSpellsFrame = _G.PlayerSpellsFrame
    if not PlayerSpellsFrame then
        return
    end

    F.ReskinPortraitFrame(PlayerSpellsFrame)

    if PlayerSpellsFrame.TabSystem and PlayerSpellsFrame.TabSystem.GetChildren then
        for _, tab in pairs({ PlayerSpellsFrame.TabSystem:GetChildren() }) do
            if tab.GetName then
                F.ReskinTab(tab)
            end
        end
    end

    if PlayerSpellsFrame.SpellBookFrame then
        reskinSpellBook(PlayerSpellsFrame.SpellBookFrame)
    end

    if PlayerSpellsFrame.TalentsFrame then
        reskinTalents(PlayerSpellsFrame.TalentsFrame)
    end

    if PlayerSpellsFrame.SpecFrame then
        reskinSpec(PlayerSpellsFrame.SpecFrame)
    end

    local importDialog = _G.ClassTalentLoadoutImportDialog
    if importDialog then
        reskinTalentFrameDialog(importDialog)

        if importDialog.ImportControl and importDialog.ImportControl.InputContainer then
            F.StripTextures(importDialog.ImportControl.InputContainer)
            F.CreateBDFrame(importDialog.ImportControl.InputContainer, 0.25)
        end
    end

    local createDialog = _G.ClassTalentLoadoutCreateDialog
    if createDialog then
        reskinTalentFrameDialog(createDialog)
    end

    local editDialog = _G.ClassTalentLoadoutEditDialog
    if editDialog then
        reskinTalentFrameDialog(editDialog)

        local editbox = editDialog.LoadoutName
        if editbox then
            F.ReskinEditbox(editbox)
            editbox.__bg:SetPoint('TOPLEFT', -5, -5)
            editbox.__bg:SetPoint('BOTTOMRIGHT', 5, 5)
        end

        local check = editDialog.UsesSharedActionBars
        if check and check.CheckButton then
            F.ReskinCheckbox(check.CheckButton)
            check.CheckButton.bg:SetInside(nil, 6, 6)
        end
    end
end
