local math = require("math")
local Engine = require("Engine")

function whoami()
	return "hello"
end

function draw(tick)
	Engine.drawCircle(400, 300, (math.sin(tick)+1)*200);
end
