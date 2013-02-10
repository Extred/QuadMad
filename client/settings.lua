function setScale()
	if love.filesystem.exists("video.ini") then
		local file = love.filesystem.newFile("video.ini")
		file:open('r')
		local x = {file:read(1), file:read(1), file:read(1)}
		file:close()
		
		return (tonumber(x[1])+tonumber(x[2])/10), x[3]
	else
		return 0.5, 0
	end
end