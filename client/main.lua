require "socket"
require "cls"
require "settings"

local address, port, updaterate, udp, t = "127.0.0.1", 12345, 0.03, socket.udp(), 1
local resScale, data
local keys, state = {w=0, a=0, s=0, d=0}, 10
local world, server, client = {}, {}, {}
local p = {} --players

function love.load()
	local isFull
	resScale, isFull = setScale()
	love.graphics.setMode( love.graphics.getWidth( )*resScale, love.graphics.getHeight( )*resScale, isFull, 1)
	physics = love.physics.newWorld(0, 0)
	client.newPlayer()
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
						p[1].body:applyForce(10000*(keys.d-keys.a)/(1+0.4142*(keys.w+keys.s)), 10000*(keys.s-keys.w)/(1+0.4142*(keys.d+keys.a)))
						physics:update(dt)
						
						t = t + dt
						if t > updaterate then
							client.update()
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
						love.graphics.setColor(p[1].R, p[1].G, p[1].B, 255)
						love.graphics.polygon("fill", p[1].body:getWorldPoints(p[1].shape:getPoints()))
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
		self.fX = fX
		self.fY = fY
		self.body:setAngle(angle)
		self.body:setPosition(x, y)
		self.body:setAngularVelocity(spin)
	end;
	
	status = function(self, hp, mp)
		self.hp = hp
		self.mp = mp
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
	p[1] = Player(1, "tester", 128, 0, 128, 0, 400, 1, 4)
	p[1]:update(400, 400, 0, 0, 0, 0)
end

function client.update()
	data = udp:receive()
	--if data then DD() end
end

function server.enter()
	udp:settimeout(0)
	udp:setpeername(address, port)
	udp:send(string.format("C %s %u %u %u %u %u %g %g", p[1].name, p[1].R, p[1].G, p[1].B, p[1].face, p[1].speed, p[1].scale, p[1].density))
end

function server.update()
	udp:send(string.format("U %u %u %u %d %d %f %f", p[1].id, p[1].body:getX(), p[1].body:getY(), keys.d-keys.a, keys.s-keys.w, p[1].body:getAngle()%(math.pi*2), p[1].body:getAngularVelocity()))
end


















