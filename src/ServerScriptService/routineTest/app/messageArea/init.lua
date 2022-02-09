local function messageArea()
	print("messageArea background color is:", coroutine.yield("background"))
end

return messageArea
