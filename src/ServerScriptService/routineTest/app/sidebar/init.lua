local function sidebar()
	print("sidebar background color is:", coroutine.yield("background"))
end

return sidebar
