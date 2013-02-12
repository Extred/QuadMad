require "socket.core"
require "cls"

local address, workport = "127.0.0.1", 12345
local scale = 0.5
local updaterate = 0.018 -- �� ������ 0.018

local physics, p, buf = {}, {}, {} -- empty world and players (p)
local t, id, pid, x, y, fX, fY, angle, spin = 1, 0
local sign, int, precision
local data, ip, port, code

function love.load()
	udp = socket.udp()
	udp:settimeout(0)
	udp:setsockname('*', workport)
	physics = love.physics.newWorld(0, 0)
	borders()
end

function love.update(dt)
	t = t + dt
	if t > updaterate then
		while true do
			data, ip, port = udp:receivefrom()
			if data then DD() else break end
		end
			
		for i=1, #p do if p[i].connected then 
				if p[i].bore > 100 then p[i]:kill() end
				p[i].bore = p[i].bore + 1
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
		broadcast_updates()
		t = 0
	end
end					
   
function DD() --data director
	code = data:sub(1,1)
	if (code == "C") then 
		id = id + 1
		udp:sendto(string.format("i%u", id), ip, port)
		buf.name, buf.R, buf.G, buf.B, buf.face, buf.speed, buf.scale, buf.density = data:match(" (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)")
		buf.scale = stof(buf.scale)
		buf.density = stof(buf.density)
		p[id] = Player(id, buf.name, buf.R, buf.G, buf.B, buf.face, buf.speed, buf.scale, buf.density, ip, port)
		p[id]:update(0, 0, 0, 0, 0, 0)
		broadcast_players()
	end
	if (code == "U") then 
		pid, x, y, fX, fY, angle, spin = data:match(" (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)")
		if p[pid+0] then p[pid+0]:update(x, y, fX, fY, stof(angle), stof(spin)) end
		print(pid.." upd")
	end
end

function broadcast_updates()
	for i=1, #p do if p[i].connected then
		for j=1, #p do if p[j].connected then
			if i ~= j then udp:sendto(string.format("u %u %u %u %d %d %f %f", p[j].id, p[j].body:getX(), p[j].body:getY(), p[j].fX, p[j].fY, p[j].body:getAngle()%(math.pi*2), p[j].body:getAngularVelocity()), p[i].ip, p[i].port) end
		end end
	end	end
end

function broadcast_players()
	for i=1, #p do if p[i].connected then
		for j=1, #p do if p[j].connected then
			udp:sendto(string.format("p %u %s %u %u %u %u %u %g %g", p[j].id, p[j].name, p[j].R, p[j].G, p[j].B, p[j].face, p[j].speed, p[j].scale, p[j].density), p[i].ip, p[i].port)
		end end
	end	end
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
   __init__ = function(self, id, name, R, G, B, face, speed, scale, density, ip, port) 
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
		self.ip = ip
		self.port = port
			
		self.body = love.physics.newBody(physics, 0, 0, "dynamic") --��������� ������� ���� �� x � y, � ������ ��� "������������"
		self.body:setLinearDamping(2)
		self.body:setAngularDamping(1)
		self.shape = love.physics.newRectangleShape(50*scale,50*scale) --������� 50*50*scale
		self.f = love.physics.newFixture(self.body, self.shape) --��������� ���� � �����
		self.f:setRestitution(0.4) --���� ����� �����������
		self.body:setMass(density*scale*scale) --��������� ��
		self.f:setUserData("p["..id.."]")
	end;
	
	update = function(self, x, y, fX, fY, angle, spin)
		if self.connected then
			self.fX = fX
			self.fY = fY
			self.body:setAngle(angle)
			self.body:setPosition(x, y)
			self.body:setAngularVelocity(spin)
			self.bore = 0 --����������� � ��������, ��� ��, ������� ���������
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
