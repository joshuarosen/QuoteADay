WEEKDAY_STRINGS = {
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
}

-- Splits the given text and returns a list of lines that fit in the given dimensions.
function getLines(text, width, height, font)
    local default_width = font:getTextWidth(text)
    if (default_width <= width) then
        return { text }
    end

    local lines = {}
    local cur_line = 1
    local words = text:gmatch("%S+")
    -- Assign first word.
    lines[cur_line] = words()
    for w in words do
        -- String concatenation in a for loop is not great... but the text we're parsing
        -- is short enough (3-4 lines max) that it might actually result in worse
        -- performance to use table.concat().
        local new_line = lines[cur_line] .. " " .. w
        if (font:getTextWidth(new_line) > width) then
            cur_line += 1
            lines[cur_line] = w
        else
            lines[cur_line] = new_line
        end
    end

    return lines
end