-- Returns true if table contains the value, false otherwise.
function contains(table, value)
    return indexOf(table, value) ~= nil
end

-- Returns the index in the table of the given value, or returns nil if value is not 
-- present in the table.
function indexOf(table, value)
    for i = 1, #table do
        if (table[i] == value) then
            return i
        end
    end
    return nil
end