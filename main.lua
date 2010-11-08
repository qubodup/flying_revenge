function love.load()
	math.randomseed( os.time() )
	love.graphics.setBackgroundColor( 107, 186, 112 )
	gfx = {
		fly = {
			love.graphics.newImage("fly1.png"),
			love.graphics.newImage("fly2.png"),
		},
		human = {
			love.graphics.newImage("human1.gif"),
			love.graphics.newImage("human2.gif"),
		},
		blood = love.graphics.newImage("blood.gif"),
		bg = love.graphics.newImage("smear.png"),
	}
	currentFly = 1
	sfx = {
		bzzz = love.audio.newSource("bzzz.ogg", stream),
		splash = love.audio.newSource("splash.ogg", stream),
		suck = love.audio.newSource("suck.ogg", stream),
		scream = {
			love.audio.newSource("scream1.ogg", stream),
			love.audio.newSource("scream2.ogg", stream),
		},
	}
	humanSpeed = 25
	flySpeed = 100
	fly = { {math.random(128, 384), math.random(128,384)}, {oneOrMinusOne(), oneOrMinusOne() } }
	humans = {}
	for count = 1, math.random(9,18), 1 do
		table.insert(humans, { {math.random(32, 480), math.random(32, 480)}, {oneOrMinusOne(), oneOrMinusOne()}})
	end
	puddles = {}
	spacePressed = false
	flyFreakTimer = 0
	flyAnimationTimer = 0
	sfx.bzzz:setLooping( true )
	love.audio.play(sfx.bzzz)
end

function love.update(dt)
	-- humans
	for i,v in ipairs(humans) do
		newPos = step(v, humanSpeed, dt)
		if newPos[1] < 32 and v[2][1] == -1 or newPos[1] > 480 and v[2][1] == 1 then
			v[2][1] = -v[2][1] -- reverse direction
			newPosNeeded = true
		end
		if newPos[2] < 32 and v[2][2] == -1 or newPos[2] > 480 and v[2][2] == 1 then
			v[2][2] = -v[2][2] -- reverse direction
			newPosNeeded = true
		end
		if newPosNeeded then
			newPos = step(v, humanSpeed, dt) -- recalculation
		end
		v[1] = newPos
	end
	-- fly
	if not spacePressed then -- change fly movement only when space not pressed
		-- animation
		flyAnimationTimer = flyAnimationTimer + dt
		if flyAnimationTimer > .1 then
			currentFly = math.mod(currentFly,2)+1
			flyAnimationTimer = math.mod(flyAnimationTimer - .2,.2)
		end
		-- random direction changes
		flyFreakTimer = flyFreakTimer + (dt * (1 + math.random()))
		if flyFreakTimer > 1 then
			fly[2] = {oneOrMinusOne(), oneOrMinusOne()}
			flyFreakTimer = 0
		end
		-- border direction changes
		newPos = step(fly, flySpeed, dt)
		if newPos[1] < 128 and fly[2][1] == -1 or newPos[1] > 530 and fly[2][1] == 1 then
			fly[2][1] = -fly[2][1]
			newPosNeeded = true
		end
		if newPos[2] < -18 and fly[2][2] == -1 or newPos[2] > 384 and fly[2][2] == 1 then
			fly[2][2] = -fly[2][2]
			newPosNeeded = true
		end
		if newPosNeeded then
			newPos = step(fly, flySpeed, dt)
		end
		fly[1] = newPos
	end
end

function love.draw()
	-- bg, causes slowdown :(
	--[[for i = 0, 512, 32 do
		for j = 0, 512, 32 do
			love.graphics.draw(gfx.bg, i, j)
		end
	end]]--
	-- dead people
	for i,v in ipairs(puddles) do
		love.graphics.draw(gfx.blood, math.floor(v[1][1]-32), math.floor(v[1][2]-32))
	end
	-- alive people
	for i,v in ipairs(humans) do
		if flyOver(v) then
			love.graphics.draw(gfx.human[1], math.floor(v[1][1]-32), math.floor(v[1][2]-32))
		else
			love.graphics.draw(gfx.human[2], math.floor(v[1][1]-32), math.floor(v[1][2]-32))
		end
	end
	-- fly fly
	love.graphics.draw(gfx.fly[currentFly], math.floor(fly[1][1]-32), math.floor(fly[1][2]-32))
	--love.graphics.rectangle("fill", fly[1][1] - 32 - 96, fly[1][2] - 32 + 96, 64, 64 )
end

function love.keypressed(key, unicode)
        if key == ' ' then
                spacePressed = true
		love.audio.pause(sfx.bzzz)
		smashThem()
        end
	if key == 'q' or key == 'escape' then
                love.event.push('q') -- quit the game 
        end
end

function love.keyreleased(key, unicode)
	if key == ' ' then
		spacePressed = false
		love.audio.resume(sfx.bzzz)
	end
end

function smashThem()
	humansKilled = false
	for i,v in ipairs(humans) do
		if flyOver(v) then
			table.insert(puddles, v)
			table.remove(humans, i)
			humansKilled = true
		end
	end
	if humansKilled then
		love.audio.stop(sfx.splash)
		love.audio.play(sfx.splash)
	else
		love.audio.stop(sfx.suck)
		love.audio.play(sfx.suck)
	end
end

function flyOver(humanVec)
	if humanVec[1][1] < fly[1][1] + 32 and humanVec[1][1] > fly[1][1] - 32 and humanVec[1][2] < fly[1][2] + 32 and humanVec[1][2] > fly[1][2] - 32 then
		-- play scream as well
		if sfx.scream[1]:isStopped() and sfx.scream[2]:isStopped() then
			love.audio.play(sfx.scream[math.random(1,2)])
		end
		return true
	else
		return false
	end
end

function step(table, speed, dt)
	return ({
		table[1][1] + (table[2][1] * dt * speed),
		table[1][2] + (table[2][2] * dt * speed)
	})
end

function oneOrMinusOne()
	if math.random(1, 2) == 2 then return(-1) else return(1) end
end
