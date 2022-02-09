local sidebar = require(script.sidebar)
local messageArea = require(script.messageArea)

local themeProvider = require(script.Parent.provideTheme)

local function app()
	messageArea()
	themeProvider("dark",sidebar)
end

return app
--talking to him about other options, she tells him what u call him, 1:00 to meet up at rio
