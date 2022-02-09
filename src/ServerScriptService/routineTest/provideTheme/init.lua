local themeCols = {
	light = {
		background = "bright",
		text = "dark",
		yourEyes = "burnt to a crisp",
	},

	dark = {
		background = "dark",
		text = "bright",
		yourEyes = "clinically healthy and functional",
	},
}

local function provideTheme(theme: string, callback)
	local routine = coroutine.create(callback)

	local _, arg = coroutine.resume(routine)
	while coroutine.status(routine) ~= "dead" do
		local value = themeCols[theme][arg]
		task.wait()
		print("sent")
		_, arg = coroutine.resume(routine, value)
	end
end

return provideTheme
