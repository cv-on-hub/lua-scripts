function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.58"
    finaleplugin.Date = "2024/04/17"
    finaleplugin.CategoryTags = "Measures, Region, Selection"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        The selected score area can be refined in Finale by measure and 
        either __beat__ or __EDU__ at _Edit_ → _Select Region..._. 
        This script offers a more organic option for precise positioning with 
        slider controls to change the beat and EDU position in each measure, 
        updating the score highlighting as the selection changes.

        Note that when one slider overlaps the other in the same 
        measure, it will push it out of the way creating a __null__ 
        selection (start = end). This doesn't break anything 
        but the selection contains no notes. 

        __Beat Boundaries__  
        The duration of a Finale quarter note is 1024 EDUs, 
        but to select all of of the first beat in a 4/4 measure the 
        selection must be from 0 to 1023 EDU, otherwise it will 
        include notes starting __on__ the second beat. 
        This "minus one" adjustment is applied to all __end__ positions 
        relative to the beat, as happens when entering beat numbers 
        on the inbuilt _Select Region_ option.

        > __Key Commands__: 

        > - __w / s__: Start Staff up/down 
        > - __d / f__: Start Measure left/right 
        > - __g / h__: Start increments -/+ 
        > - __j / k__: Start one EDU -/+ 
        > - (__- / +__: Start one EDU  -/+)  
        > - __a / z__: End Staff up/down 
        > - __x / c__: End Measure left/right 
        > - __v / b__: End increments -/+ 
        > - __n / m__: End one EDU -/+ 
        > - (__[ / ]__: End one EDU  -/+)  
        > - __e__: toggle the "follow selection" checkbox 
        > - __q__: show these script notes 
    ]]
    return "Selection Refiner...", "Selection Refiner", "Refine the selected music area with visual feedback"
end

local config = {
    follow_measure = 0, -- follow selection beyond the visible screen? (== 1)
    window_pos_x = false,
    window_pos_y = false
}

local mixin = require("library.mixin")
local configuration = require("library.configuration")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used

local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function power_of_two(duration)
    local smallest = finale.NOTE_128TH / 2 -- smallest duration = 256th note
    local power = 1
    while smallest < duration and power < 10 do
        smallest = smallest * 2
        power = power + 1
    end
    return power -- 256th note = 1; 128th note = 2, ... breve = 10
end

local function score_limits(rgn)
    local staff = finale.FCStaff()
    local staff_list = {}
    local stack = mixin.FCMMusicRegion()
    stack:SetRegion(rgn):SetFullDocument()
    for staff_number in eachstaff(stack) do
        staff:Load(staff_number)
        -- {staff_list} #index = SLOT number
        table.insert(staff_list, staff:CreateDisplayFullNameString())
    end
    local max_slot = stack.EndSlot
    return stack.EndMeasure, max_slot, staff_list
end

local function compile_rest_strings(power)
    power = math.min(math.max(power, 1), 10) -- maximum exponent of 2 as "beat" rhythm
    -- non-SMuFL font REST characters first
    local rests = { "…", "Â", "Ù", "®", "≈", "‰", "Œ", "Ó", "∑", "„" } -- 256th to breve
    local array = { dot = "k", space = " ", vert = 18 }
    if library.is_font_smufl_font() then -- SMuFL
        rests = {
            "\u{E4EB}", "\u{E4EA}", "\u{E4E9}", "\u{E4E8}", "\u{E4E7}",
            "\u{E4E6}", "\u{E4E5}", "\u{E4E4}", "\u{E4E3}", "\u{E4E2}"
        }
        array = { dot = "\u{E044}", space = "\u{E548}", vert = 0 }
    end
    array.gap = array.space .. array.space
    local p = power - 3           -- (divide beat duration by 8)
    array.div = { -- rest characters for each beat division
        rests[p], -- smallest
        rests[p + 1],
        rests[p + 1] .. array.space .. array.dot,
        rests[p + 2], -- "compound" rest values stop here
        rests[p + 2] .. array.space .. rests[p],
        rests[p + 2] .. array.space .. array.dot,
        rests[p + 2] .. array.space .. array.dot .. array.space .. array. dot
    }
    array.div[8] = rests[power]
    array.beat = rests[power] -- abbreviation
    return array
end

local function get_measure_details(region, is_start_sector)
    local measure = finale.FCMeasure()
    measure:Load(is_start_sector and region.StartMeasure or region.EndMeasure)
    local time_sig = measure:GetTimeSignature()
    local md = { -- "Measure Details"
        dur = measure:GetDuration(),
        beats = time_sig.Beats,
        compound = false,
        beatdur = time_sig.BeatDuration,
        composite = time_sig.CompositeTop
    }
    if is_start_sector then
        md.measure = region.StartMeasure
        md.pos = region.StartMeasurePos
        md.slot = region.StartSlot
    else
        md.measure = region.EndMeasure
        md.pos = region.EndMeasurePos
        md.slot = region.EndSlot
    end
    md.pos = math.min(md.pos, md.dur) -- position <= measure duration
    if time_sig.CompositeBottom then -- use beat of first COMPOSITE group
        md.beatdur = time_sig:CreateCompositeBottom():GetGroupElementBeatDuration(0, 0)
    end
    if md.beatdur % 3 == 0 then
        md.compound = true -- compound meter
        md.mark = md.beatdur / 3 -- compound first-division marker 1/3rd of beat
        md.steps = 12 -- divisions per beat
    else
        md.mark = md.beatdur / 2 -- first-division marker = half of beat
        md.steps = 8 -- divisions per beat
    end
    local power = power_of_two(md.mark * 2) -- 2 ^ power exponent to index notehead durations
    md.div_dur = md.beatdur / md.steps -- duration of each division
    md.divisions = md.beats * md.steps -- total number of divisions
    if md.composite then
        md.divisions = md.dur / md.div_dur -- recalc across whole measure
        while md.divisions < 32 and md.div_dur >= 32 do
            -- get largest slider positions ("divisions") <= 64
            md.beats = md.beats * 2
            md.beatdur = md.beatdur / 2
            power = power - 1
            md.div_dur = md.div_dur / 2
            md.divisions = md.divisions * 2
        end
    end
    md.rests = compile_rest_strings(power)
    return md
end

local function convert_edu_to_rest_string(index, md, backwards)
    if backwards then index = md.divisions - index end
    local beat = md.rests.beat
    if md.compound then beat = beat .. md.rests.space .. md.rests.dot end

    local rest_string = ""
    for _ = 1, math.floor(index / md.steps) do
        rest_string = rest_string .. beat .. md.rests.gap
    end
    index = index % md.steps
    if md.compound then -- compound meter, beats divided by three then 4
        for _ = 1, math.floor(index / 4) do
            if backwards then
                rest_string = md.rests.div[4] .. md.rests.space .. rest_string
            else
                rest_string = rest_string .. md.rests.div[4] .. md.rests.space
            end
        end
        index = index % 4
    end
    if index > 0 then -- add remaining rest element
        if backwards then
            rest_string = md.rests.div[index] .. md.rests.space .. rest_string
        else
            rest_string = rest_string .. md.rests.div[index]
        end
    end
    return rest_string
end

local function user_chooses(rgn)
    local y, rest_wide, x_wide =  40, 130, 236
    local x_offset = finenv.UI():IsOnMac() and 0 or 3
    local name = plugindef():gsub("%.%.%.", "")

    -- indicator and control arrays for "start" [1] and "end" [2]:
    local measure, sliders, offset, save_off = {}, {}, {}, {}
    local rest, buttons, index, staff_sel, actions = {}, {}, {}, {}, {}
    local follow
    local max_measure, max_slot, staff_list = score_limits(rgn)

    -- MD :: MEASURE DETAILS md = { {start}, {end} }
    local md = { get_measure_details(rgn, true), get_measure_details(rgn, false) }
    local function pos_to_index(side) -- convert selection position (edu) to thumb index
        return math.floor(md[side].pos * md[side].divisions / md[side].dur)
    end
    index[1] = pos_to_index(1)
    index[2] = pos_to_index(2)

    -- start dialog
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 500, 440)
            refocus_document = true
        end
        local function set_measure_pos(side)
            if side == 1 then rgn.StartMeasurePos = md[side].pos
            else rgn.EndMeasurePos = md[side].pos
            end
        end
        local function set_rest_and_offset(side, thumb)
            rest[side]:SetText(convert_edu_to_rest_string(thumb, md[side], false))
            local edu = thumb * md[side].div_dur
            if side == 2 and edu > 0 and edu < md[2].dur and edu > offset[1]:GetInteger() then
                edu = edu - 1
            end
            md[side].pos = edu
            set_measure_pos(side)
            offset[side]:SetInteger(edu)
            save_off[side] = offset[side]:GetText()
        end
        local function set_indicators(side)
            local thumb = pos_to_index(side)
            sliders[side]:SetMaxValue(md[side].divisions):SetThumbPosition(thumb)
            rest[side]:SetText(convert_edu_to_rest_string(thumb, md[side], false))
            offset[side]:SetInteger(md[side].pos)
            save_off[side] = offset[side]:GetText()
            measure[side]:SetText("m. " .. md[side].measure)
        end
        local function swap_pos()
            local save_pos = md[1].pos
            md[1].pos = md[2].pos
            md[2].pos = save_pos
            set_measure_pos(1)
            set_measure_pos(2)
        end
        local function clamp_measure_pos(side)
            md[side] = get_measure_details(rgn, (side == 1))
            if md[side].pos > md[side].dur then
                md[side].pos = md[side].dur
                set_measure_pos(side)
            end
            set_indicators(side)
        end
        local function measure_button_visibility(clamp_side)
            for side = 1, 2 do
                buttons[side].left:SetEnable(md[side].measure > 1)
                buttons[side].right:SetEnable(md[side].measure < max_measure)
            end
            clamp_measure_pos(clamp_side)
            if follow:GetCheck() == 1 then -- follow selection to off-screen measures
                finenv.UI():MoveToMeasure(md[clamp_side].measure, 0)
            end
            rgn:SetInDocument()
            rgn:Redraw()
        end
        local function position_increment(side, add)
            if (add > 0 and md[side].pos < md[side].dur)
                or (add < 0 and md[side].pos > 0) then
                md[side].pos = md[side].pos + add
                set_indicators(side)
                set_measure_pos(side)
                rgn:SetInDocument()
                rgn:Redraw()
            end
        end

    ---- "action" routines for buttons and keystrokes
    actions = {
        staff = function(a_side) -- a staff popup has changed
            local new_slot = staff_sel[a_side]:GetSelectedItem() + 1
            if new_slot == md[a_side].slot then return end -- no change
            if a_side == 1 then -- "start" staff popup
                rgn.StartSlot = new_slot
                if new_slot > (staff_sel[2]:GetSelectedItem() + 1) then
                    staff_sel[2]:SetSelectedItem(new_slot - 1)
                    md[2].slot = new_slot
                    rgn.EndSlot = new_slot
                end
            else -- a_side == 2 / "end" staff popup
                rgn.EndSlot = new_slot
                if new_slot < (staff_sel[1]:GetSelectedItem() + 1) then
                    staff_sel[1]:SetSelectedItem(new_slot - 1)
                    md[1].slot = new_slot
                    rgn.StartSlot = new_slot
                end
            end
            staff_sel[a_side]:SetSelectedItem(new_slot - 1)
            md[a_side].slot = new_slot
            rgn:SetInDocument()
            rgn:Redraw()
        end,
        -------
        change_staff = function(a_side, diff) -- change index of staff popup
            local slot = staff_sel[a_side]:GetSelectedItem() + 1
            if (slot > 1 and diff < 0) or (slot < max_slot and diff > 0) then
                staff_sel[a_side]:SetSelectedItem(slot + diff - 1)
            end
            actions.staff(a_side) -- register this index change
        end,
        -------
        left = function(a_side) -- move measure to left
            local other_side = (a_side % 2) + 1
            if md[a_side].measure > 1 then
                md[a_side].measure = md[a_side].measure - 1
                md[a_side].pos = offset[a_side]:GetInteger()
                md[other_side].pos = offset[other_side]:GetInteger()
                if a_side == 1 then
                    rgn.StartMeasure = md[1].measure
                else -- side 2
                    rgn.EndMeasure = md[2].measure
                    if md[2].measure < md[1].measure then -- also shift the start to the left
                        md[1].measure = md[2].measure
                        rgn.StartMeasure = md[1].measure
                        clamp_measure_pos(1)
                    end
                    if md[1].measure == md[2].measure and md[2].pos < md[1].pos then
                        swap_pos()
                        set_indicators(1)
                    end
                end
                measure_button_visibility(a_side)
            end
        end,
        -------
        right = function(a_side) -- move measure to right
            local other_side = (a_side % 2) + 1
            if md[a_side].measure < max_measure then
                md[a_side].measure = md[a_side].measure + 1
                md[a_side].pos = offset[a_side]:GetInteger()
                md[other_side].pos = offset[other_side]:GetInteger()
                if a_side == 1 then
                    rgn.StartMeasure = md[1].measure
                    if md[1].measure > md[2].measure then -- also shift the end to the right
                        md[2].measure = md[1].measure
                        rgn.EndMeasure = md[2].measure
                        clamp_measure_pos(2)
                    end
                    if md[1].measure == md[2].measure and md[1].pos > md[2].pos then
                        swap_pos()
                        set_indicators(2)
                    end
                else -- side 2
                    rgn.EndMeasure = md[2].measure
                end
                measure_button_visibility(a_side)
            end
        end,
        -------
        slide = function(i) -- a slider has changed
            local thumb = sliders[i]:GetThumbPosition()
            local other_side = (i % 2) + 1
            set_rest_and_offset(i, thumb)
            if (rgn.StartMeasure == rgn.EndMeasure) then -- start and end in same measure
                local other_thumb = sliders[other_side]:GetThumbPosition()
                if i == 1 then
                    if thumb > other_thumb or md[1].pos > md[2].pos then
                        if thumb <= md[2].divisions then other_thumb = thumb end
                        set_rest_and_offset(2, other_thumb)
                        sliders[2]:SetThumbPosition(other_thumb)
                    end
                else -- side 2
                    if thumb < other_thumb or md[2].pos < md[1].pos then
                        if thumb > 0 then other_thumb = thumb end
                        set_rest_and_offset(1, other_thumb)
                        sliders[1]:SetThumbPosition(other_thumb)
                    end
                end
            end
            rgn:SetInDocument()
            rgn:Redraw()
        end,
        ------
        thumb = function(i, dir) -- move slider thumb by discrete amount
            local n = sliders[i]:GetThumbPosition()
            sliders[i]:SetThumbPosition(n + dir)
            actions.slide(i)
        end,
        ------
        offset = function(i) -- "offset" numeric edit boxes: key command substitution
            local s = offset[i]:GetText():lower()
            if s:find("[^0-9]") then
                if s:find("[?q]") then show_info()
                elseif s:find("w") then actions.change_staff(1, -1)
                elseif s:find("s") then actions.change_staff(1, 1)
                elseif s:find("d") then actions.left(1)
                elseif s:find("f") then actions.right(1)
                elseif s:find("g") then actions.thumb(1, -1)
                elseif s:find("h") then actions.thumb(1, 1)
                elseif s:find("a") then actions.change_staff(2, -1)
                elseif s:find("z") then actions.change_staff(2, 1)
                elseif s:find("x") then actions.left(2)
                elseif s:find("c") then actions.right(2)
                elseif s:find("b") then actions.thumb(2, 1)
                elseif s:find("v") then actions.thumb(2, -1)
                elseif s:find("[-_j]") then position_increment(1, -1)
                elseif s:find("[+=k]") then position_increment(1, 1)
                elseif s:find("[%[n]") then position_increment(2, -1)
                elseif s:find("[%]m]") then position_increment(2, 1)
                elseif s:find("e") then
                    follow:SetCheck((follow:GetCheck() + 1) % 2)
                end
                offset[i]:SetText(save_off[i])
            elseif s ~= "" then
                s = s:sub(1, 5) -- max 5 digits
                local n = tonumber(s) or 0
                n = math.min(math.max(n, 0), md[i].dur) -- 0 <= n <= measure_duration
                offset[i]:SetInteger(n)
                md[i].pos = n
                set_indicators(i)
                set_measure_pos(i)
                rgn:SetInDocument()
                rgn:Redraw()
                save_off[i] = offset[i]:GetText()
            end
        end
    }

    local default_font = finale.FCFontInfo()
    default_font:LoadFontPrefs(finale.FONTPREF_MUSIC)
    local button_x = (x_wide + rest_wide + 14) / 5 -- space buttons evenly in fifths

        local function make_rest_text(i, y_off)
            rest[i] = dialog:CreateStatic(x_wide + 65, y_off + md[i].rests.vert)
                :SetWidth(rest_wide):SetHeight(80):SetFont(default_font)
                :SetText(convert_edu_to_rest_string(index[i], md[i], false))
        end

        local function make_slider_and_offset(i)
            sliders[i] = dialog:CreateSlider(0, y):SetMinValue(0)
                :SetWidth(x_wide):SetMaxValue(md[i].divisions)
                :SetThumbPosition(index[i]):AddHandleCommand(function() actions.slide(i) end)
            save_off[i] = tostring(md[i].pos)
            offset[i] = dialog:CreateEdit(x_wide + 7, y - x_offset):SetInteger(md[i].pos)
                :AddHandleCommand(function() actions.offset(i) end):SetWidth(50)
        end

        local function make_buttons(i)
            -- first the staff-name popup menu
            staff_sel[i] = dialog:CreatePopup(0, y)
                :AddStrings(table.unpack(staff_list)):SetWidth(button_x * 2) -- 2 fifths
                :SetSelectedItem(md[i].slot - 1)
                :AddHandleCommand(function() actions.staff(i) end)
            -- then the two "measure" buttons
            buttons[i] = {}
            for k, v in pairs{
                left = { button_x * 2 + 5, "← Measure" }, right = { button_x * 3 + 5, "Measure →" }
            } do
                buttons[i][k] = dialog:CreateButton(v[1], y):SetWidth(button_x - 5)
                    :AddHandleCommand(function() actions[k](i) end):SetText(v[2])
            end
            measure[i] = dialog:CreateStatic(button_x * 4 + 5, y):SetWidth(button_x - 5)
                :SetText("m. " .. md[2].measure)
        end

    -- "rest" static texts go first so high MUSIC font height doesn't overlap buttons
    make_rest_text(1, 0)
    make_rest_text(2, 78)
    -- "start" components
    dialog:CreateStatic(0, y, "head_1"):SetText("START of Selection:"):SetWidth(x_wide)
    dialog:CreateButton(x_wide + rest_wide + 30, y, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    local function yd(diff)
        y = diff and y + diff or y + 16
    end
    yd(14)
    make_slider_and_offset(1)
    yd(30)
    make_buttons(1)
    yd(30)
    dialog:CreateHorizontalLine(0, y, button_x * 5)
    yd(5)
    -- "end" components
    dialog:CreateStatic(0, y, "head_2"):SetText("END of Selection:"):SetWidth(x_wide)
    yd(14)
    make_slider_and_offset(2)
    yd(30)
    make_buttons(2)
    yd(30)
    follow = dialog:CreateCheckbox(0, y, "follow_measure"):SetWidth(x_wide)
        :SetText("Follow selection to off-screen measures"):SetCheck(config.follow_measure)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        config.follow_measure = follow:GetCheck()
    end)
    dialog:RegisterInitWindow(function(self)
        local h = self:GetControl("head_1")
        local bold = h:CreateFontInfo():SetBold(true)
        h:SetFont(bold)
        self:GetControl("head_2"):SetFont(bold)
        self:GetControl("q"):SetFont(bold)
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK)
end

local function refine_selection()
    configuration.get_user_settings(script_name, config)
    local rgn = mixin.FCMMusicRegion()
    rgn:SetCurrentSelection()
    if rgn:IsEmpty() then
        finenv.UI():AlertError("Please select some music\nbefore running this script",
            plugindef():gsub("%.%.%.", "")
        )
        return
    end
    if not user_chooses(rgn) then -- cancelled, so restore original selection
        rgn:SetRegion(finenv.Region())
    end
    rgn:SetInDocument() -- otherwise set new selection
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

refine_selection()
