function love.load()
	math.randomseed( os.time() )
	love.graphics.setBackgroundColor( 107, 186, 112 )
	gfx = {
		title = love.graphics.newImage("title.png"),
		instructions = love.graphics.newImage("instructions.png"),
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
	boss = {
		stage = "sleeping", -- can be sleeping, active or limbless
		status = {
			head = "fit",
			body = "fit",
			armRight = "fit",
			armLeft = "fit",
			legRight = "fit",
			legLeft = "fit",
		},
		speed = 35,
		pos = { 256, 256 },
		dir = {oneOrMinusOne(), oneOrMinusOne()},
		gfx = {
			fit = {
				head = love.graphics.newImage("boss-head.png"),
				body = love.graphics.newImage("boss-body.png"),
				legLeft = love.graphics.newImage("boss-leg-left.png"),
				legRight = love.graphics.newImage("boss-leg-right.png"),
				armLeft = love.graphics.newImage("boss-arm-left.png"),
				armRight = love.graphics.newImage("boss-arm-right.png"),
			},
			dead = {
				head = love.graphics.newImage("boss-head-dead.png"),
				body = love.graphics.newImage("boss-body-dead.png"),
				legLeft = love.graphics.newImage("boss-leg-left-dead.png"),
				legRight = love.graphics.newImage("boss-leg-right-dead.png"),
				armLeft = love.graphics.newImage("boss-arm-left-dead.png"),
				armRight = love.graphics.newImage("boss-arm-right-dead.png"),
			},
		},
		offset = {
			head = { -32, -96 },
			body = { -32, -32 },
			legLeft = { -64, 32 },
			legRight = { 0, 32 },
			armLeft = { 32, -32 },
			armRight = { -96, -32 },
		},
		-- freaked out'-ness' for random direction changes
		freak = {
			timer = 0,
			limit = 2,
		},
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
		boom = love.audio.newSource("boom.ogg", stream),
		kaboom = love.audio.newSource("kaboom.ogg", stream),
	}
	humanSpeed = 25
	flySpeed = 100
	fly = { pos = {math.random(128, 384), math.random(128,384)}, dir = {oneOrMinusOne(), oneOrMinusOne() } }
	humans = {}
	for count = 1, math.random(9,18), 1 do
		table.insert(humans, { pos = {math.random(32, 480), math.random(32, 480)}, dir = {oneOrMinusOne(), oneOrMinusOne()}})
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
		newPosNeeded = false
		newPos = step(v, humanSpeed, dt)
		if newPos[1] < 32 and v.dir[1] == -1 or newPos[1] > 480 and v.dir[1] == 1 then
			v.dir[1] = -v.dir[1] -- reverse direction
			newPosNeeded = true
		end
		if newPos[2] < 32 and v.dir[2] == -1 or newPos[2] > 480 and v.dir[2] == 1 then
			v.dir[2] = -v.dir[2] -- reverse direction
			newPosNeeded = true
		end
		if newPosNeeded then
			newPos = step(v, humanSpeed, dt) -- recalculation
		end
		v.pos = newPos
	end
	-- boss movement 
	if boss.stage ~= "sleeping" and boss.stage ~= "dead" then
		newPosNeeded = false
		newPos = step(boss, boss.speed, dt)
		if newPos[1] < 96 and boss.dir[1] == -1 or newPos[1] > 512 - 96 and boss.dir[1] == 1 then
			boss.dir[1] = -boss.dir[1] -- reverse direction
			newPosNeeded = true
		end
		if newPos[2] < 96 and boss.dir[2] == -1 or newPos[2] > 512 - 96 and boss.dir[2] == 1 then
			boss.dir[2] = -boss.dir[2] -- reverse direction
			newPosNeeded = true
		end
		if newPosNeeded then
			newPos = step(boss, boss.speed, dt) -- recalculation
		end
		boss.pos = newPos
		-- random direction changes
		boss.freak.timer = boss.freak.timer + (dt * (1 + math.random()))
		if boss.freak.timer > boss.freak.limit then
			boss.dir = {oneOrMinusOne(), oneOrMinusOne()}
			boss.freak.timer = 0
		end
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
			fly.dir = {oneOrMinusOne(), oneOrMinusOne()}
			flyFreakTimer = 0
		end
		-- border direction changes
		newPos = step(fly, flySpeed, dt)
		if newPos[1] < 128 and fly.dir[1] == -1 or newPos[1] > 530 and fly.dir[1] == 1 then
			fly.dir[1] = -fly.dir[1]
			newPosNeeded = true
		end
		if newPos[2] < -18 and fly.dir[2] == -1 or newPos[2] > 384 and fly.dir[2] == 1 then
			fly.dir[2] = -fly.dir[2]
			newPosNeeded = true
		end
		if newPosNeeded then
			newPos = step(fly, flySpeed, dt)
		end
		fly.pos = newPos
	end
	-- fly over humans scream
	for i,v in ipairs(humans) do
		if flyOver(v) and sfx.scream[1]:isStopped() and sfx.scream[2]:isStopped() then
			love.audio.play(sfx.scream[math.random(1,2)])
		end
	end
end

function love.draw()
	-- bg, causes slowdown :(
	--[[ for i = 0, 512, 32 do
		for j = 0, 512, 32 do
			love.graphics.draw(gfx.bg, i, j)
		end
	end ]]--
	-- dead people
	for i,v in ipairs(puddles) do
		love.graphics.draw(gfx.blood, math.floor(v.pos[1]-32), math.floor(v.pos[2]-32))
	end
	-- alive people
	for i,v in ipairs(humans) do
		if flyOver(v) then
			love.graphics.draw(gfx.human[1], math.floor(v.pos[1]-32), math.floor(v.pos[2]-32))
		else
			love.graphics.draw(gfx.human[2], math.floor(v.pos[1]-32), math.floor(v.pos[2]-32))
		end
	end
	-- boss
	if boss.stage ~= "sleeping" then
		for i,v in pairs(boss.status) do
			love.graphics.draw(boss.gfx[v][i], math.floor(boss.pos[1]) + boss.offset[i][1], math.floor(boss.pos[2] + boss.offset[i][2]))
		end
	end
	-- fly
	love.graphics.draw(gfx.fly[currentFly], math.floor(fly.pos[1]-32), math.floor(fly.pos[2]-32))
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
	-- boss debug
	if key == 'd' then
		humans = {}
		boss.stage = "active"
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
	if boss.stage ~= "sleeping" then
		for i,v in pairs(boss.status) do
			bossPart = {
				pos = {
					boss.pos[1] + boss.offset[i][1] + 32,
					boss.pos[2] + boss.offset[i][2] + 32,
				},
			}
			if flyOver(bossPart) and v == "fit" then
				-- head/body exceptions
				if boss.stage == "limbless" or ( i ~= "body" and i ~= "head" ) then
					table.insert(puddles, bossPart)
					boss.status[i] = "dead"
					--if  then boss.stage = "limbless" end
				end
			end
		end
		if boss.status.armLeft == "dead" and  boss.status.armRight == "dead" and  boss.status.legLeft == "dead" and boss.status.legRight == "dead" then
			boss.stage = "limbless"
		end
	end
	-- sound
	if humansKilled then
		love.audio.stop(sfx.splash)
		love.audio.play(sfx.splash)
	else
		love.audio.stop(sfx.suck)
		love.audio.play(sfx.suck)
	end
	-- boss spawn check
	if humansKilled and #humans == 0 then
		boss.stage = active
	end
end

function flyOver(targetVector)
	if targetVector.pos[1] < fly.pos[1] + 32 and targetVector.pos[1] > fly.pos[1] - 32 and targetVector.pos[2] < fly.pos[2] + 32 and targetVector.pos[2] > fly.pos[2] - 32 then
		return true
	else
		return false 
	end
end

-- moves human or boss
function step(table, speed, dt)
	return ({
		table.pos[1] + (table.dir[1] * dt * speed),
		table.pos[2] + (table.dir[2] * dt * speed),
	})
end

function oneOrMinusOne()
	if math.random(1, 2) == 2 then return(-1) else return(1) end
end
