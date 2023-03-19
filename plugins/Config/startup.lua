-- Plugin name: LuaScript

-- Startup script
-- Changes will take effect once Notepad++ is restarted

-- Documentation
-- https://dail8859.github.io/LuaScript/index.html

-- BEGIN: Copy/Cut Line
-- https://dail8859.github.io/LuaScript/examples/visualstudiolinecopy.lua.html
-- Mimic Visual Studio's "Ctrl+C" that copies the entire line if nothing is selected
npp.AddShortcut("Copy Allow Line", "Ctrl+C", function()
    editor:CopyAllowLine()
end)

-- Mimic Visual Studio's "Ctrl+X" that cuts the line if nothing is selected
npp.AddShortcut("Cut Allow Line", "Ctrl+X", function()
    if editor.SelectionEmpty then
        editor:CopyAllowLine()
        editor:LineDelete()
    else
        editor:Cut()
    end
end)
-- END: Copy/Cut Line


-- BEGIN: Colour Convert [Alt+Shift+x]
function hextorgb(hex)
    if (hex ~= nil and ((string.len(hex) >= 6 and string.len(hex) <= 8)
        or (string.sub(hex, 0, 1) == "#" and string.len(hex) >= 7 and string.len(hex) <= 9)))
    then
       local rgb = {}

        for val in string.gmatch(hex, "%x%x")
        do
            table.insert(rgb, tonumber(val, 16))
        end
        
        if (#rgb == 3 or #rgb == 4)
        then
            return rgb
        else
            return nil
        end 
    else
        return nil
    end
end

npp.AddShortcut("HEX -> RGB", "Alt+Shift+x", function()
    if not editor.SelectionEmpty
    then
        local converted = hextorgb(editor:GetSelText())
        if (converted ~= nil)
        then
            if (#converted == 3)
            then
                editor:ReplaceSel("rgb(" .. table.concat(converted, ",") .. ")")
            elseif (#converted == 4)
            then
                editor:ReplaceSel("rgba(" .. table.concat(converted, ",") .. ")")
            end
        end
    else
        print("[hextorgb]: No Selection")
    end
end)

npp.AddEventHandler("OnUpdateUI", function()
    local function getRangeOnScreen()
        local firstLine = editor.FirstVisibleLine
        local lastLine = firstLine + editor.LinesOnScreen
        local startPos = editor:PositionFromLine(firstLine)
        local endPos = editor.LineEndPosition[lastLine]
        return startPos, endPos
    end
    
    local function clearIndicatorOnScreen()
        local s, e = getRangeOnScreen()
        local indicator = 12 -- not sure what one is best to use but this works
        editor.IndicatorCurrent = indicator
        editor:IndicatorClearRange(s, e - s)
    end

    local wordStart = nil
    local wordEnd = nil
    local word = nil
    if not editor.SelectionEmpty
    then
        wordStart = editor.SelectionStart
        wordEnd = editor.SelectionEnd
        word = editor:GetSelText()
    else
        wordStart = editor:WordStartPosition(editor.CurrentPos, true)
        wordEnd = editor:WordEndPosition(editor.CurrentPos, true)
        word = editor:textrange(wordStart, wordEnd)
        -- Not a word
    end
    
    if wordStart == wordEnd then
        clearIndicatorOnScreen()
        editor:CallTipCancel()
        return false
    end
    
    clearIndicatorOnScreen()
    editor:CallTipCancel()
    
    local convertRGB = hextorgb(word)
    if (convertRGB ~= nil)
    then
        if (#convertRGB == 3)
        then
            local backcolour = convertRGB[1] + (convertRGB[2] << 8) + (convertRGB[3] << 16)
            
            local indicator = 12 -- not sure what one is best to use but this works
            editor.IndicatorCurrent = indicator
            
            editor.IndicStyle[indicator] = INDIC_ROUNDBOX
            editor.IndicFore[indicator] = backcolour
            editor.IndicAlpha[indicator] = 127
            
            editor.CallTipBack = backcolour
            editor.CallTipFore = 0xffffff - backcolour
            editor:CallTipShow(editor.CurrentPos, "rgb(" .. table.concat(convertRGB, ",") .. ")")
            
            -- for each match on screen turn on the indicator
            local startPos, endPos = getRangeOnScreen()
            local s, e = editor:findtext(word, SCFIND_WHOLEWORD | SCFIND_MATCHCASE, startPos, endPos)
            while s ~= nil do
                editor:IndicatorFillRange(s, e - s)
                s, e = editor:findtext(word, SCFIND_WHOLEWORD | SCFIND_MATCHCASE, e, endPos)
            end
        elseif (#convertRGB == 4)
        then
            local backcolour = convertRGB[1] + (convertRGB[2] << 8) + (convertRGB[3] << 16)
            
            local indicator = 12 -- not sure what one is best to use but this works
            editor.IndicatorCurrent = indicator
            
            editor.IndicStyle[indicator] = INDIC_ROUNDBOX
            editor.IndicFore[indicator] = backcolour
            editor.IndicAlpha[indicator] = 200
            
            editor.CallTipBack = backcolour
            editor.CallTipFore = 0xffffff - backcolour
            editor:CallTipShow(editor.CurrentPos, "rgba(" .. table.concat(convertRGB, ",") .. ")")
            
            -- for each match on screen turn on the indicator
            local startPos, endPos = getRangeOnScreen()
            local s, e = editor:findtext(word, SCFIND_WHOLEWORD | SCFIND_MATCHCASE, startPos, endPos)
            while s ~= nil do
                editor:IndicatorFillRange(s, e - s)
                s, e = editor:findtext(word, SCFIND_WHOLEWORD | SCFIND_MATCHCASE, e, endPos)
            end
        end
    end
end)
-- END: Colour Convert
