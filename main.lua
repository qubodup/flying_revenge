function love.load()
	math.randomseed( os.time() )
	window = {love.graphics.getWidth(), love.graphics.getHeight()}
	debug = true -- debug mode for testing you see.
	loadStuff()
	prepareLevel("easy") -- easy or hard
end

-- stuff that neads to be loaded once
function loadStuff()
	-- game mode refers to controls and random movement. it can be easy or hard.
	gameModeText = {
		easy = "press and hold space",
		hard = "press and hold space\nagain",
	}
	font = love.graphics.newImageFont("font-handirt-padding.png", "0123456789.,:;()abcdefghijklmnopqrstuvwxyz'!?/_ ")
	love.graphics.setFont(font)
	gfx = {
		title = love.graphics.newImage("title.png"),
		instructions = love.graphics.newImage("instructions.png"),
		fly = {
			{ -- animation step 1
				a_1_1 = love.graphics.newImage("fly1-tl.png"),
				a_11 = love.graphics.newImage("fly1-bl.png"),
				a11 = love.graphics.newImage("fly1-br.png"),
				a1_1 = love.graphics.newImage("fly1-tr.png"),
			},
			{ -- animation step 2
				a_1_1 = love.graphics.newImage("fly2-tl.png"),
				a_11 = love.graphics.newImage("fly2-bl.png"),
				a11 = love.graphics.newImage("fly2-br.png"),
				a1_1 = love.graphics.newImage("fly2-tr.png"),
			},
		},
		human = {
			love.graphics.newImage("human1.gif"),
			love.graphics.newImage("human2.gif"),
		},
		blood = love.graphics.newImage("blood.gif"),
		bg = {
			easy = love.graphics.newImage("smearGreen.png"),
			hard = love.graphics.newImage("smear.png"),
		},
		explosion = {
			love.graphics.newImage("nexplosion1.png"),
			love.graphics.newImage("nexplosion2.png"),
			love.graphics.newImage("nexplosion3.png"),
			love.graphics.newImage("nexplosion4.png"),
			love.graphics.newImage("nexplosion5.png"),
		},
		boss = {
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
			pain = {
				head = love.graphics.newImage("boss-head-pain.png"),
			},
			deathpain = {
				head = love.graphics.newImage("boss-head-deathpain.png"),
			},
		},
	}
	-- nicer scaled up fly
	for i,v in pairs(gfx.fly[2]) do
		v:setFilter("nearest","nearest")
	end
	for i,v in pairs(gfx.fly[1]) do
		v:setFilter("nearest","nearest")
	end
	website = {
		text = "qubodup.github.com/\n   flying_revenge",
		pos = {104, 396},
	}
	sfx = {
		vomit = love.audio.newSource("vomit.ogg", stream),
		bzzz = love.audio.newSource("bzzz.ogg", stream),
		splash = love.audio.newSource("splash.ogg", stream),
		suck = love.audio.newSource("suck.ogg", stream),
		scream = {
			love.audio.newSource("scream1.ogg", stream),
			love.audio.newSource("scream2.ogg", stream),
		},
		boom = love.audio.newSource("boom.ogg", stream),
		kaboom = love.audio.newSource("kaboom.ogg", stream),
		boss = {
			pain = {
				love.audio.newSource("scream1.ogg", stream),
				love.audio.newSource("scream2.ogg", stream),
			},
			head = love.audio.newSource("splashplus.ogg", stream),
			body = love.audio.newSource("screamBoss.ogg", stream),
			grunt = {
				love.audio.newSource("grunt1.ogg", stream),
				love.audio.newSource("grunt2.ogg", stream),
			},
		},
	}
	sfx.boss.pain[1]:setPitch(.5)
	sfx.boss.pain[2]:setPitch(.5)
	sfx.boss.grunt[1]:setPitch(.5)
	sfx.boss.grunt[2]:setPitch(.5)
end

function prepareLevel(mode)
	gameMode = mode
	-- text for 'tip'
	if gameMode == "easy" then
		nextGameMode = "hard"
	elseif gameMode == "hard" then
		nextGameMode = "easy"
	end
	-- game status can be title, instructions, sequence, game or gameover
	status = "title"
	timerGameover = 0
	-- post-game screen progress
	gameoverStep = {false,false,false,false,false,false}
	timerPreGameover = 0 -- for the seconds after boss death, before gameover
	timerPreGameoverLimit = 2
	boss = {
		stage = "sleeping", -- can be sleeping, active, limbless or dead
		status = { -- can be fit, dead or pain
			head = "fit",
			body = "fit",
			armRight = "fit",
			armLeft = "fit",
			legRight = "fit",
			legLeft = "fit",
		},
		speedInitial = 35, -- initial speed of boss
		speed = 35,
		pos = { 256, 256 },
		dir = {oneOrMinusOne(), oneOrMinusOne()},
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
		pain = {
			timer = 0,
			limit = 1,
		},
		size = {
			half = 98, -- 'radius'
			scale = 1,
		},
		grunt = {
			timer = 0,
			limit = math.random(3,6),
		},
	}
	timingExplosion = {0,.50,1,2,4,6}
	currentExplosion = 0
	currentFly = 1
	humanSpeed = 25
	humanLimitMax = 8
	fly = {
		speed = 100,
		pos = {math.random(128, 384), math.random(128,384)},
		dir = {oneOrMinusOne(), oneOrMinusOne() },
		size = {
			half = 32, -- 'radius'
			scale = 1,
		},
	}
	humans = {}
	for count = 1, math.random(9,18), 1 do
		table.insert(humans, { pos = {math.random(32, 480), math.random(32, 480)}, dir = {oneOrMinusOne(), oneOrMinusOne()}, limit = math.random(1,humanLimitMax) })
	end
	humansBase = #humans -- ammount of humans at game start
	puddles = {}
	spacePressed = false
	flyFreakTimer = 0
	flyFreakTimerLimit = { easy=.5, hard=1.25 }
	flyFreakTimerLimit = flyFreakTimerLimit[gameMode]
	flyFreakTimerMax = 2
	-- killing one human makes fly change dir less (by flyFreakTimerIncrease)
	flyFreakTimerIncrease = (flyFreakTimerMax - flyFreakTimerMax)/humansBase
	flyAnimationTimer = 0
	sfx.bzzz:setLooping( true )
	muteBuzz = false
	textOver = {
		{
		pos = {32,48},
		text = "you showed those humans!"
		},
		{
		pos = {32,96 + 48},
		text = " sucktions performed",
		},
		{
		pos = {32, 96 + 96 + 48},
		text = " minutes played",
		},
		{
		pos = {32, 96 + 96*2 + 48},
		text = "game made with love2d.org",
		},
		{
		pos = {32, 96 + 96*3 + 48},
		text = "play " .. nextGameMode .. " by pressing space",
		},
	}
	score = { -- consists of sucks and time
		time = 0,
		sucks = 0,
	}
	sequence = {
		time = 0,
		limit = 1,
	}
	dirs = {{1,1},{1,-1},{-1,1},{-1,-1},}
end

function love.update(dt)
	if status == "game" then
		-- score time counter
		score.time = score.time + dt
		-- humans
		for i,v in ipairs(humans) do
			-- random direction changes
			humans[i].limit = v.limit +  dt
			if v.limit > humanLimitMax then
				humans[i].dir = changeDir(v.dir)
				humans[i].limit = 0
			end
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
		if boss.stage == "active" then
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
			-- boss pain and grunt timer
			if boss.pain.timer > 0 then
				boss.pain.timer = boss.pain.timer - dt
			elseif boss.pain.timer <= 0 and boss.grunt.timer <= 0 then
				boss.status.head = "fit"
			end
		end
		-- fly
		-- random direction changes (are supposed to happen while stopping
		if gameMode == "hard" then
			flyFreakTimer = flyFreakTimer + (dt * (1 + math.random()))
			if flyFreakTimer > flyFreakTimerLimit then
				-- old, hard navigation
				--fly.dir = {oneOrMinusOne(), oneOrMinusOne()} 
				fly.dir = changeDirEven(fly.dir)
				flyFreakTimer = 0
			end
		elseif gameMode == "easy" then
			-- in easy mode, movement only changes while holding down space
			if spacePressed then
				flyFreakTimer = flyFreakTimer + dt
				if flyFreakTimer > flyFreakTimerLimit then
					fly.dir = rotateDir(fly.dir)
					flyFreakTimer = 0
				end
			end
		end
		if not spacePressed then -- check for borders only when not sucking
			-- border direction changes
			newPos = step(fly, fly.speed, dt)
			if newPos[1] < 0 and fly.dir[1] == -1 or newPos[1] > 512 and fly.dir[1] == 1 then
				fly.dir[1] = -fly.dir[1]
				newPosNeeded = true
			end
			if newPos[2] < 0 and fly.dir[2] == -1 or newPos[2] > 502 and fly.dir[2] == 1 then
				fly.dir[2] = -fly.dir[2]
				newPosNeeded = true
			end
			if newPosNeeded then
				newPos = step(fly, fly.speed, dt)
			end
			fly.pos = newPos
		end
		-- fly over humans scream
		for i,v in ipairs(humans) do
			if flyOver(v) and sfx.scream[1]:isStopped() and sfx.scream[2]:isStopped() then
				love.audio.play(sfx.scream[math.random(1,2)])
			end
		end
		-- fly over boss grunt
		if boss.stage ~= "sleeping" then
			boss.grunt.timer = boss.grunt.timer - dt
			for i,v in pairs(boss.status) do
				bossPart = {
					pos = {
						boss.pos[1] + boss.offset[i][1] + 32,
						boss.pos[2] + boss.offset[i][2] + 32,
					},
				}
				if flyOver(bossPart) and v == "fit" then
					if boss.grunt.timer <= 0 then
						love.audio.play(sfx.boss.grunt[math.random(1,2)])
						boss.status.head = "pain"
						boss.grunt.timer = boss.grunt.limit
					end
				end
			end
		end
	-- sequence movement
	elseif status == "sequence" then
		sequence.time = sequence.time + dt
		boss.pos = {boss.pos[1] + (boss.speed * dt * fly.dir[1]), boss.pos[2] + (boss.speed * dt * fly.dir[2]) }
		if sequence.time > sequence.limit then
			finishSequenceBossSpit()
		end
		if boss.size.scale < 1 then
			boss.size.scale = boss.size.scale + dt/sequence.limit
		else
			boss.size.scale = 1
		end
		if fly.size.scale > 1 then
			fly.size.scale = fly.size.scale - dt/sequence.limit
		else
			fly.size.scale = 1
		end
	end
	if not spacePressed then -- fly animation should run when not sucking
		flyAnimationTimer = flyAnimationTimer + dt
		if flyAnimationTimer > .1 then
			currentFly = math.mod(currentFly,2)+1
			flyAnimationTimer = math.mod(flyAnimationTimer - .2,.2)
		end
	end
	-- pre-gameover timerrrrrrrrrrr (sorry, listening to some dnb while writing this comment)
	if boss.stage == "dead" and status == "game" then
		gameOver()
	elseif status == "gameover" then
		timerGameover = timerGameover + dt
		if timerGameover > 6.5 and not gameoverStep[6] then
			love.audio.play(sfx.kaboom)
			gameoverStep[6] = true
		elseif timerGameover > 5 and not gameoverStep[5] then
			soundPlay(sfx.boom)
			gameoverStep[5] = true
		elseif timerGameover > 4 and not gameoverStep[4] then
			soundPlay(sfx.boom)
			gameoverStep[4] = true
		elseif timerGameover > 3 and not gameoverStep[3] then
			soundPlay(sfx.boom)
			gameoverStep[3] = true
		elseif timerGameover > 2 and not gameoverStep[2] then
			soundPlay(sfx.boom)
			gameoverStep[2] = true
		elseif timerGameover > 1 and not gameoverStep[1] then
			soundPlay(sfx.boom)
			gameoverStep[1] = true
			love.audio.resume(sfx.bzzz)
		end
		-- explosion animation
		if gameoverStep[6] and currentExplosion < 6 then
			if timerGameover > timingExplosion[currentExplosion + 1] + 6.5 then
				currentExplosion = currentExplosion + 1
			end
			sfx.bzzz:stop()
		end
	end
end

function love.draw()
	-- bg, might cause massive slowdown
	 for i = 0, 512, 64 do
		for j = 0, 512, 64 do
			love.graphics.draw(gfx.bg[gameMode], i, j)
		end
	end
	if status == "title" then
		love.graphics.draw(gfx.title, 128, 112)
		love.graphics.print(website.text, website.pos[1], website.pos[2])
	elseif status == "instructions" then
		love.graphics.draw(gfx.instructions, 128, 112)
		love.graphics.print(website.text, website.pos[1], website.pos[2])
	elseif status == "game" or status == "sequence" or status == "gameover" then
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
				love.graphics.draw(gfx.boss[v][i], math.floor(boss.pos[1]) + (boss.offset[i][1] * boss.size.scale), math.floor(boss.pos[2] + (boss.offset[i][2]) * boss.size.scale), 0, boss.size.scale, boss.size.scale)
			end
		end
		-- fly
		if currentExplosion < 1 then
			love.graphics.draw(gfx.fly[currentFly][string.gsub("a"..fly.dir[1]..fly.dir[2],"-","_")], math.floor(fly.pos[1]-(fly.size.half * fly.size.scale)), math.floor(fly.pos[2]-(fly.size.half * fly.size.scale)), 0, fly.size.scale, fly.size.scale)
		end
		-- instructions (only during game)
		if (status == "game" or status == "sequence") then
			if score.time <= 8 and score.time > 2 then
				love.graphics.print(gameModeText[gameMode],80,32)
			-- lol
			elseif score.time < 110 and score.time > 95 then
				love.graphics.print("take your time,\nyou can't lose this game\nyou see...",80,32)
			elseif score.time < 125 and score.time >= 111 then
				love.graphics.print("but seriously, consider\nmaking more use of\nthe spacebar perhaps",80,32)
			end
		end
	end
	if status == "gameover" then
		-- gameover text
		for i,v in ipairs(textOver) do
			if gameoverStep[i] then
				love.graphics.print(v.text, v.pos[1], v.pos[2])
			end
		end
		-- explosion animation
		if gameoverStep[6] and currentExplosion > 0 and currentExplosion < 6 then
				love.graphics.draw(gfx.explosion[currentExplosion],math.floor(fly.pos[1] - 64) ,math.floor(fly.pos[2] - 96))
		end
	end
end


function love.keypressed(key, unicode)
	if status ~= "title" and (key == 'q' or key == 'escape') then
		love.event.push('q') -- quit the game 
	end
	if status == "title" then
		status = "instructions"
		love.audio.play(sfx.boom)
	elseif status == "instructions" then
		status = "game"
		sfx.boom:stop()
		love.audio.play(sfx.boom)
		love.audio.play(sfx.bzzz)
	else
		if key == ' ' and status == "sequence" then
			-- interrupt likely to be accidental
			--finishSequenceBossSpit()
		elseif key == ' ' and status ~= "gameover" then
			spacePressed = true
			love.audio.pause(sfx.bzzz)
			smashThem()
			score.sucks = score.sucks + 1
		-- skip gameoverStep timer
		elseif key == ' ' and not gameoverStep[6] then
			timerGameover = math.floor(timerGameover + 1)
		-- restart game
		elseif key == ' ' and gameoverStep[5] then
			if gameMode == "easy" then
				prepareLevel("hard")
			elseif gameMode == "hard" then
				prepareLevel("easy")
			end
		end
		-- boss debug
		if key == 'd' and debug then
			humans = {}
			playSequenceBossSpit()
		end
		-- game over debug
		if key == 'g' and debug then
			humans = {}
			boss.stage = "active"
			gameOver()
		end
		-- no buzz sound debug
		if key == 's' and debug then
			muteBzzz = not muteBzzz
			love.audio.pause(sfx.bzzz)
			if not muteBzzz then love.audio.resume(sfx.bzzz) end
		end
	end
end

function love.keyreleased(key, unicode)
	if key == ' ' then
		spacePressed = false
		if not muteBzzz then
			love.audio.resume(sfx.bzzz)
		end
		if gameMode == "easy" then
			flyFreakTimer = flyFreakTimerLimit/2
		end
	end
end

function smashThem()
	humansKilled = false
	bossHurt = false
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
			if flyOver(bossPart) and v ~= "dead" then
				-- head/body exceptions
				if boss.stage == "limbless" or ( i ~= "body" and i ~= "head" ) then
					table.insert(puddles, bossPart)
					boss.status[i] = "dead"
					-- slow down boss when limb is destroyed
					if boss.stage ~= "limbless" then
						boss.speed = boss.speed - (boss.speedInitial/4)
						bossHurt = true
					else
						boss.stage = "dead"
						if boss.status.head == "dead" then
							love.audio.play(sfx.boss.head)
						else
							love.audio.play(sfx.boss.pain[2])
							boss.status.head = "deathpain"
						end
					end
				end
			end
		end
		-- limbless check
		if boss.stage == "active" and (boss.status.armLeft == "dead" and  boss.status.armRight == "dead" and  boss.status.legLeft == "dead" and boss.status.legRight == "dead") then
			boss.stage = "limbless"
		end
	end
	-- sound
	if humansKilled then
		love.audio.stop(sfx.splash)
		love.audio.play(sfx.splash)
		flyFreakTimer = flyFreakTimer + flyFreakTimerIncrease
		fly.size.scale = fly.size.scale + 1/humansBase
	elseif bossHurt then
		boss.status.head = "pain"
		boss.pain.timer = boss.pain.limit
		love.audio.stop(sfx.boss.pain[1])
		love.audio.play(sfx.boss.pain[1])
	else
		love.audio.stop(sfx.suck)
		love.audio.play(sfx.suck)
	end
	-- boss spawn check
	if humansKilled and #humans == 0 then
		playSequenceBossSpit()
	end
end

-- debug fly positioning via mouse 
function love.mousepressed( x, y, button )
	if debug then
		fly.pos={ x, y }
	end
end

function flyOver(targetVector)
	if targetVector.pos[1] < fly.pos[1] + (fly.size.half * fly.size.scale)  and targetVector.pos[1] > fly.pos[1] - (fly.size.half * fly.size.scale) and targetVector.pos[2] < fly.pos[2] + (fly.size.half * fly.size.scale) and targetVector.pos[2] > fly.pos[2] - (fly.size.half * fly.size.scale) then
		return true
	else
		return false 
	end
end

-- moves human or boss
function step( table, speed, dt )
	return ({
		table.pos[1] + (table.dir[1] * dt * speed),
		table.pos[2] + (table.dir[2] * dt * speed),
	})
end

function oneOrMinusOne()
	if math.random(1, 2) == 2 then return(-1) else return(1) end
end

-- changes a direction vector randomly
function changeDir(currVec)
	local newVec = {oneOrMinusOne(),0}
	if newVec[1] == currVec[1] then
		newVec = {newVec[1], -1 * currVec[2]}
	else
		newVec = {newVec[1], oneOrMinusOne()}
	end
	return newVec
end

-- changes a direction vector kind of randomly but 'evenly'
function changeDirEven(currVec)
	local newVec = {}
	if #dirs > 1 then
		local rand = math.random(1, #dirs)
		newVec = dirs[rand]
		table.remove(dirs, rand)
	else
		newVec = dirs[1]
		dirs = {{1,1},{1,-1},{-1,1},{-1,-1},}
	end
	return newVec
end

-- rotates a direction vector clockwise
function rotateDir(currVec)
	local newVec = currVec
	if currVec[1] == -1 then
		if currVec[2] == -1 then
			newVec[1] = 1
		else
			newVec[2] = -1
		end
	else
		if currVec[2] == 1 then
			newVec[1] = -1
		else
			newVec[2] = 1
		end
	end
	return newVec
end

function gameOver()
	textOver[2].text = math.floor(score.sucks)..textOver[2].text
	-- calc/format played time
	local seconds = math.floor(score.time%60)
	if seconds < 10 then seconds = "0"..seconds end
	textOver[3].text = math.floor(score.time/60)..":"..seconds..textOver[3].text
	status = "gameover"
	--love.audio.pause(sfx.bzzz)
end

-- stops and plays a sound (saves me a line and some characters)
function soundPlay(sound)
	love.audio.stop(sound)
	love.audio.play(sound)
end

-- returns the direction to face the window's center
function dirFaceCenter(pos)
	newDir = {}
	if pos[1] < window[1]/2 then
		newDir[1] = 1
	else
		newDir[1] = -1
	end
	if pos[2] < window[2]/2 then
		newDir[2] = 1
	else
		newDir[2] = -1
	end
	return newDir
end

function playSequenceBossSpit()
	spacePressed = true
	love.audio.stop(sfx.bzzz)
	love.audio.play(sfx.vomit)
	status = "sequence"
	boss.size.scale = 0.25
	boss.stage = "immobile"
	fly.dir = dirFaceCenter(fly.pos)
	fly.size.scale = 2
	boss.pos = { fly.pos[1] + (fly.dir[1] * fly.size.half), fly.pos[2] + (fly.dir[2] * fly.size.half) }
end

function finishSequenceBossSpit()
	spacePressed = false
	love.audio.play(sfx.bzzz)
	status = "game"
	boss.stage = "active"
	boss.size.scale = 1
	fly.size.scale = 1
end
