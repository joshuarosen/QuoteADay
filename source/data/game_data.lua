local datastore <const> = playdate.datastore

GameData = {}

function GameData:loadData(time)
    self.today_date = time.year .. "-" .. time.month .. "-" .. time.day

    self.data = datastore.read()
    if self.data == nil then
        self.data = {
            -- No previous data, must be the first time the app is launched.
            first_app_launched = true
        }
    end
end

-- Returns true if the user has opened the app today AND at least dismissed the intro and
-- seen the quote.
function GameData:hasSeenTodayQuote()
    if self.data.date ~= nil then
        return self.today_date == self.data.date
    end
    return false
end

function GameData:markDismissedIntro()
    self.data.date = self.today_date
end

function GameData:markSeenQuote(quote, attribution)
    self.data.latest_quote = {quote = quote, attribution = attribution}
end

-- Marks that the user has launched the app for the first time.
function GameData:markAppLaunched()
    self.data.first_app_launched = false
end

function GameData:getLatestQuote()
    if (self.data.latest_quote ~= nil) then
        return self.data.latest_quote.quote, self.data.latest_quote.attribution
    end
    
    return nil
end

-- Returns true if this is the first time the user has launched this app.
function GameData:isFirstAppLaunch()
    return self.data.first_app_launched
end

function GameData:writeToDisk()
    local result = datastore.write(self.data)
    print("Game data write to disk result: " .. tostring(result))
end