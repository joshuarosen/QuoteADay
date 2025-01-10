import "util/table_util"

local datastore <const> = playdate.datastore

local DATA_DIR <const> = "data/"
local QUOTE_DIR <const> = "quotes/"
local quoteScheduleDataFilename <const> = "data/quote_schedule_data"

QuoteData = {}

-- Pass an index representing the weekday (1 for Monday, 7 for Sunday).
function QuoteData:loadData(today_index)
    -- Set "random" as the first category.
    self.categories = { "random" }
    local quote_file_names = playdate.file.listFiles(DATA_DIR .. QUOTE_DIR)
    for i, file_name in ipairs(quote_file_names) do
        self.categories[i + 1] = file_name:match("(.+)%..+$")
    end

    -- Validate quote schedule data here, after we know all the valid categories.
    -- It's possible that one of the categories listed in the schedule is no longer valid,
    -- since the user may have deleted/renamed that category file. If that happens,
    -- replace the invalid entry with a "random" entry.
    self.quoteScheduleData = datastore.read(quoteScheduleDataFilename)
    for i, category in ipairs(self.quoteScheduleData) do
        if not contains(self.categories, category) then
            self.quoteScheduleData[i] = "random"
        end
    end

    self.todayCategory = self.quoteScheduleData[today_index]
    print("Today's category: " .. self.todayCategory)

    -- Load all category files.
    -- The quoteData table contains all categories with all quotes.
    self.quoteData = {}
    for i, category in ipairs(self.categories) do
        self.quoteData[category] = datastore.read(DATA_DIR .. QUOTE_DIR .. category)
    end
end

function QuoteData:saveQuoteScheduleData()
    local result = datastore.write(self.quoteScheduleData, quoteScheduleDataFilename)
    print("Save quote schedule data result: " .. tostring(result))
end