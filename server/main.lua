require "socket"
require "cls"

local address, workport = "127.0.0.1", 12345
local scale = 0.5
local updaterate = 0.025 -- не меньше 0.018

local physics, p, buf = {}, {}, {} -- empty world and players (p)
local t, id, pid, x, y, fX, fY, angle, spin = 1, 0
local sign, int, precision
local data, ip, port, code
local connected = {}

function love.load()
	udp = socket.udp()
	udp:settimeout(0)
	udp:setsockname('*', workport)
	physics = love.physics.newWorld(0, 0)
	borders()
	--p[1] = Player(1, "tester", 128, 0, 128, 0, 400, 1, 4)
	--p[1]:update(400, 400, 0, 0, 0, 0)
end

function love.update(dt)
		t = t + dt
		if t > updaterate then
			data, ip, port = udp:receivefrom()
			if data then DD() end
			for i=1, #p do if p[i].connected then 
					if p[i].bore > 100 then p[i]:kill() end
					p[i].bore = p[i].bore + 1 
					print(p[i].bore)
				end 
			end
		end
		
		for i=1, #p do
			if p[i].connected then
				p[i].body:applyForce(10000*(p[i].fX)/(1+0.4142*(p[i].fY*p[i].fY)), 10000*(p[i].fY)/(1+0.4142*(p[i].fX*p[i].fX)))
			end
		end
		
		physics:update(dt)
		
		if t > updaterate then
			broadcast()
			t = 0
		end
end					
   
function DD() --data director
	code = data:sub(1,1)
	if (code == "C") then 
		udp:sendto("1", ip, port)
		id = id + 1
		buf.name, buf.R, buf.G, buf.B, buf.face, buf.speed, buf.scale, buf.density = data:match(" (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)")
		buf.scale = stof(buf.scale)
		buf.density = stof(buf.density)
		p[id] = Player(id, buf.name, buf.R, buf.G, buf.B, buf.face, buf.speed, buf.scale, buf.density)
		p[id]:update(0, 0, 0, 0, 0, 0)
	end
	if (code == "U") then 
		pid, x, y, fX, fY, angle, spin = data:match(" (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)")
		if p[pid+0] then p[pid+0]:update(x, y, fX, fY, stof(angle), stof(spin)) end
	end
end

function broadcast()

end

function love.draw()
		love.graphics.scale(scale, scale)
		love.graphics.setColor(255,0,0,255)
		love.graphics.setLine(2, "smooth")
		love.graphics.line(border.body:getWorldPoints(border.shape:getPoints()))
		love.graphics.circle("fill", 400, 400, 2, 16)
		for i=1, #p do
			if p[i].connected then
				love.graphics.setColor(p[i].R, p[i].G, p[i].B, 255)
				love.graphics.polygon("fill", p[i].body:getWorldPoints(p[i].shape:getPoints()))
			end
		end
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

function stof(str)
	local sign, int = str:match("(%-?)(%d*)")
	if sign=="-" then sign=-1 else sign=1 end
	local precision = str:match("%.(%d*)")
	if precision then str = sign*(int + precision/math.pow(10, precision:len())) else str = int*sign end
	return str
end

function borders()
	local W, H = love.graphics.getWidth( )/scale, love.graphics.getHeight( )/scale 
	border = {}
	border.body = love.physics.newBody(physics, 0, 0, "static")
	border.shape = love.physics.newChainShape(1, 0, 0, W, 0, W, H, 0, H)
	border.f = love.physics.newFixture(border.body, border.shape)
	border.f:setRestitution(1)
end
