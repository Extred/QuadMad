class "Slider"
{
__init__ = function (self,X,Y,SizeX,SizeY,R,G,B,slide) --left top corner
	self.R = R
	self.G = G
	self.B = B
	self.Y=Y
	self.X=X
	self.SizeX=SizeX
	self.SizeY=SizeY
	self.slide=slide
end;

draw = function(self)
	love.graphics.setColor(self.R,self.G,self.B)
	love.graphics.setLine(3, "smooth")
	love.graphics.line(self.X,self.Y+self.SizeY/2,self.X+self.SizeX,self.Y+self.SizeY/2)
	
	love.graphics.setLine(1, "smooth")
	love.graphics.setColor(self.R+5,self.G+5,self.B+5)
	love.graphics.rectangle('line',self.X+self.slide*self.SizeX, self.Y,10,self.SizeY)
	love.graphics.rectangle("fill",self.X+self.slide*self.SizeX, self.Y,10,self.SizeY)
end;


update = function(self)
	X, Y = love.mouse.getPosition()
	if (love.mouse.isDown("l")and(X>=self.X)and(X<=(self.X+self.SizeX))and(Y>=self.Y)and(Y<=(self.Y+self.SizeY))) then
		self.slide=(X-self.X)/self.SizeX
	end;
	if (self.slide<0.52)and(self.slide>0.48) then self.slide=0.5 
	end;
	if (self.slide<0.03) then self.slide=0
	end;
	if (self.slide>0.97) then self.slide=1
	end;
end	
}

class "TextWithTT"
{
__init__ = function (self,text,textTT,X,Y,R,G,B,tR,tG,tB) 
	self.Text=text
	self.TextTT=textTT
	self.R = R
	self.G = G
	self.B = B
	self.Y = Y
	self.X = X
	self.tR = tR
	self.tG = tG
	self.tB = tB
	self.SizeX=Font:getWidth(text)
	self.SizeY=Font:getHeight(text)
	self.TT=0
end;

draw = function(self)
	love.graphics.setColor(self.R,self.G,self.B)
	love.graphics.print(self.Text,self.X,self.Y)
	if self.TT==1 then
		love.graphics.setColor(self.tR,self.tG,self.tB)
		love.graphics.print(self.TextTT,X+7,Y+7)
	end;
end;

update = function(self)
	X, Y = love.mouse.getPosition()
	if (X>=self.X)and(X<=(self.X+self.SizeX))and(Y>=self.Y)and(Y<=(self.Y+self.SizeY)) then
		self.TT=1
	else self.TT=0
	end
	
end;
}


class "Edit"
{
__init__ = function (self,X,Y,SizeX,SizeY,R,G,B,text,size) 
	self.Text=text
	self.R = R
	self.G = G
	self.B = B
	self.Y = Y
	self.X = X
	self.SizeX=SizeX
	self.SizeY=SizeY
	self.Focus=0
	self.Size=size
end;

draw = function(self)
	if self.Focus==0 then
		love.graphics.setLine(2, "smooth")
		love.graphics.setColor(self.R,self.G,self.B)
		love.graphics.rectangle('line',self.X-4,self.Y-4,self.SizeX,self.SizeY)
	else
		love.graphics.setLine(4, "smooth")
		love.graphics.setColor(self.R+15,self.G+14,self.B+15)
		love.graphics.rectangle('line',self.X-4,self.Y-4,self.SizeX,self.SizeY)
	end
	love.graphics.setColor(self.R,self.G,self.B)
	love.graphics.print(self.Text,self.X,self.Y)
end;

update = function(self)
	X, Y = love.mouse.getPosition()
	if (love.mouse.isDown("l")and(X>=self.X)and(X<=(self.X+self.SizeX))and(Y>=self.Y)and(Y<=(self.Y+self.SizeY))) then
		self.Focus=1
	elseif love.mouse.isDown("l") then 
		self.Focus=0
	end
end;

keypressed = function(self,un)
	if string.len(self.Text)<self.Size then
		if un > 31 and un < 127 then
			self.Text = self.Text .. string.char(un)
		end
	end
	if un==8 then
		self.Text=self.Text:sub(1,#self.Text-1)
	end
	
end
}


class "ColorPicker"
{
__init__ = function (self,X,Y,Size,Margin,Chosen) 
	self.Margin=Margin
	self.Y = Y
	self.X = X
	self.Size=Size
	self.Chosen=Chosen
	self.R={100,20,30,5,134,65,200,241,54}
	self.G={56,180,95,24,43,155,67,87,90}
	self.B={156,78,200,10,0,255,56,133,18}
end;

draw = function(self)
	Indent=self.Size+self.Margin
	for i=1,9 do 
		if self.Chosen==i then
			love.graphics.setLine(4)
			love.graphics.setColor(255,160,5)
			love.graphics.rectangle('line',self.X+Indent*((i-1)%3)-2,self.Y+Indent*(math.floor((i-1)/3))-2,self.Size+4,self.Size+4)
			love.graphics.setColor(self.R[i],self.G[i],self.B[i])
			love.graphics.rectangle('fill',self.X+Indent*((i-1)%3),self.Y+Indent*(math.floor((i-1)/3)),self.Size,self.Size)
		else 
			love.graphics.setColor(self.R[i],self.G[i],self.B[i])
			love.graphics.rectangle('fill',self.X+Indent*((i-1)%3),self.Y+Indent*(math.floor((i-1)/3)),self.Size,self.Size)
		end
	
	end
end;

update = function(self)
	X, Y = love.mouse.getPosition()
	if (love.mouse.isDown("l")and(X>=self.X)and(X<=(self.X+3*self.Size+2*self.Margin))and(Y>=self.Y)and(Y<=(self.Y+3*self.Size+2*self.Margin))) then
		for i=1,9 do 
			if (X>=self.X+Indent*((i-1)%3))and(X<=(self.X+Indent*((i-1)%3)+self.Size))and(Y>=self.Y+Indent*(math.floor((i-1)/3)))and(Y<=(self.Y+Indent*(math.floor((i-1)/3))+self.Size)) then
				self.Chosen=i
			end
		end
	end
end
}