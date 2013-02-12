require "socket"
require "cls"
require "settings"

local address, port, updaterate, udp, t = "127.0.0.1", 12345, 0.01, socket.udp(), 1
local resScale, data, code, id
local keys, state = {w=0, a=0, s=0, d=0}, 10
local world, server, client = {}, {}, {}
local p, buf = {}, {} --players

function love.load()
	local isFull
	resScale, isFull = setScale()
	love.graphics.setMode( love.graphics.getWidth( )*resScale, love.graphics.getHeight( )*resScale, isFull, 1)
	physics = love.physics.newWorld(0, 0)
	--client.newPlayer()
	client.borders()
	server.enter()
end

function love.keypressed(k)
  keys[k] = 1
end

function love.keyreleased(k)
  keys[k] = 0
end

update = {}
update[10] = function(dt)
	-- Гейская строчка
	if p[id] then p[id].body:applyForce(10000*(keys.d-keys.a)/(1+0.4142*(keys.w+keys.s)), 10000*(keys.s-keys.w)/(1+0.4142*(keys.d+keys.a))) end
	physics:update(dt)
	
	t = t + dt
	if t > updaterate then
		while true do
			data = udp:receive()
			if data then DD() else break; end
		end
		server.update()
		t = 0
	end
end
					
function love.update(dt)
	update[state](dt)
end

local draw = {}
draw[0] = function() end -- menu
draw[1] = function() end -- character creation
draw[10] = function() 
	love.graphics.scale(resScale, resScale)
	client.loadmap(love.graphics.getWidth( )/resScale, love.graphics.getHeight( )/resScale)
	for key,value in pairs(p) do if p[key].connected then
		love.graphics.setColor(p[key].R, p[key].G, p[key].B, 255)
		love.graphics.polygon("fill", p[key].body:getWorldPoints(p[key].shape:getPoints()))
	end end
	love.graphics.setColor(255,0,0,255)
	love.graphics.setLine(2, "smooth")
	love.graphics.line(border.body:getWorldPoints(border.shape:getPoints()))
	love.graphics.circle("fill", 400, 400, 2, 16)
end
					
function love.draw()	
	draw[state]()
end

class "Player"
{
   __init__ = function(self, id, name, R, G, B, face, speed, scale, density) 
        self.id = id
		self.name = name
		self.R = R
		self.G = G
		self.B = B
		self.face = face
		self.speed = speed
		self.scale = scale
		self.density = density
		self.connected = true
			
		self.body = love.physics.newBody(physics, 0, 0, "dynamic") --Указываем позицию тела по x и y, и делаем его "динамическим"
		self.body:setLinearDamping(2)
		self.body:setAngularDamping(1)
		self.shape = love.physics.newRectangleShape(50*scale,50*scale) --квадрат 50*50*scale
		self.f = love.physics.newFixture(self.body, self.shape) --связываем тело и форму
		self.f:setRestitution(0.4) --тело будет отскакивать
		self.body:setMass(density*scale*scale) --плотность же
		self.f:setUserData("p["..id.."]")
	end;
	
	update = function(self, x, y, fX, fY, angle, spin)
		if self.connected then
			self.fX = fX
			self.fY = fY
			self.body:setAngle(angle)
			self.body:setPosition(x, y)
			self.body:setAngularVelocity(spin)
			self.bore = 0 --Встретились с апдейтом, все ок, скучать перестали
		end
	end;
	
	status = function(self, hp, mp)
		self.hp = hp
		self.mp = mp
	end;
	
	kill = function(self)
		self.body:destroy()
		self.connected = false
	end
}

function client.loadmap(W, H) 
	love.graphics.setBackgroundColor(020, 020, 020)
	love.graphics.setColor(15,15,15)
	love.graphics.setLine( 3, "smooth")
	local w, h = 0, 0
	while h<H do
		love.graphics.line(0, h, W, h)
		h = h + 30
	end	
	while w<W do
		love.graphics.line(w, 0, w, H)
		w = w + 30
	end	
end

function client.borders()
	local W, H = love.graphics.getWidth( )/resScale, love.graphics.getHeight( )/resScale
	border = {}
	border.body = love.physics.newBody(physics, 0, 0, "static")
	border.shape = love.physics.newChainShape(1, 0, 0, W, 0, W, H, 0, H)
	border.f = love.physics.newFixture(border.body, border.shape)
	border.f:setRestitution(1)
end

function client.newPlayer()
	p[id] = Player(1, "tester", 128, 0, 128, 0, 400, 1, 4)
	p[id]:update(400, 400, 0, 0, 0, 0)
end

function DD()
	code = data:sub(1,1)
	if (code == "i") then id = data:match("i(%S*)")+0; print(id) end
	if (code == "u") then 
		buf.id, buf.x, buf.y, buf.fX, buf.fY, buf.angle, buf.spin = data:match(" (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)")
		if p[buf.id+0] then p[buf.id+0]:update(buf.x, buf.y, buf.fX, buf.fY, stof(buf.angle), stof(buf.spin)) end
	end
	if (code == "p") then 
		buf.id, buf.name, buf.R, buf.G, buf.B, buf.face, buf.speed, buf.scale, buf.density = data:match(" (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)")
		p[buf.id+0] = Player(buf.id+0, buf.name, buf.R, buf.G, buf.B, buf.face, buf.speed, stof(buf.scale), stof(buf.density))
		--p[id]:update(400, 400, 0, 0, 0, 0)
		print("ok "..buf.id.." "..id)
	end
end

function server.enter()
	udp:settimeout(0)
	udp:setpeername(address, port)
	--udp:send(string.format("C %s %u %u %u %u %u %g %g", p[id].name, p[id].R, p[id].G, p[id].B, p[id].face, p[id].speed, p[id].scale, p[id].density))
	udp:send(string.format("C %s %u %u %u %u %u %g %g", "tester", 128, 0, 128, 0, 400, 1, 4))
	socket.sleep(0.05)
end

function server.update()
	if p[id] then udp:send(string.format("U %u %u %u %d %d %f %f", p[id].id, p[id].body:getX(), p[id].body:getY(), keys.d-keys.a, keys.s-keys.w, p[id].body:getAngle()%(math.pi*2), p[id].body:getAngularVelocity())) end
end

function stof(str)
	local sign, int = str:match("(%-?)(%d*)")
	if sign=="-" then sign=-1 else sign=1 end
	local precision = str:match("%.(%d*)")
	if precision then str = sign*(int + precision/math.pow(10, precision:len())) else str = int*sign end
	return str
end
















