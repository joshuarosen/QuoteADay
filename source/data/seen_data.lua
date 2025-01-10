import "util/table_util"

local datastore <const> = playdate.datastore

local SEEN_TABLE_DIR <const> = "data/seen_data"

-- Data container managing whether or not the user has seen a quote in a given category.
SeenData = {}

function SeenData:loadData()
    self.seenTablePath = SEEN_TABLE_DIR
    self.seenTable = datastore.read(self.seenTablePath)
    if (self.seenTable == nil) then
        self.seenTable = {}
    end
end

function SeenData:markSeenQuote(quote, attribution)
    table.insert(self.seenTable, quote .. " - " .. attribution)
end

-- Return true if user has already seen this quote.
function SeenData:hasSeenQuote(quote, attribution)
    return contains(self.seenTable, quote .. " - " .. attribution)
end

function SeenData:clear()
    self.seenTable = {}
end

function SeenData:writeToDisk()
    local result = datastore.write(self.seenTable, self.seenTablePath)
    print("Seen data write to disk: " .. tostring(result))
end