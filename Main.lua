
-- Main.lua

-- Implements the entire EBW-TurnToNearest AI controller





--- Returns the square of the distance between two bots
local function botDistance(a_Bot1, a_Bot2)
	assert(type(a_Bot1) == "table")
	assert(type(a_Bot2) == "table")
	
	return (a_Bot1.x - a_Bot2.x) * (a_Bot1.x - a_Bot2.x) + (a_Bot1.y - a_Bot2.y) * (a_Bot1.y - a_Bot2.y)
end





--- Returns the command for srcBot to target dstBot
local function cmdTargetBot(a_SrcBot, a_DstBot, a_Game)
	-- Check params:
	assert(type(a_SrcBot) == "table")
	assert(type(a_DstBot) == "table")
	assert(type(a_Game) == "table")
	
	-- Calculate the required angle:
	local wantAngle = math.atan2(a_DstBot.y - a_SrcBot.y, a_DstBot.x - a_SrcBot.x) * 180 / math.pi
	local angleDiff = wantAngle - a_SrcBot.angle
	if (angleDiff < -180) then
		angleDiff = angleDiff + 360
	elseif (angleDiff > 180) then
		angleDiff = angleDiff - 360
	end
	
	return { cmd = "steer", angle = angleDiff }
end





--- Converts bot speed to speed level index:
local function getSpeedLevelIdxFromSpeed(a_Game, a_Speed)
	-- Try the direct lookup first:
	local level = a_Game.speedToSpeedLevel[a_Speed]
	if (level) then
		return level
	end
	
	-- Direct lookup failed, do a manual lookup:
	print("speed level lookup failed for speed " .. a_Speed)
	for idx, level in ipairs(a_Game.speedLevels) do
		if (a_Speed <= level.linearSpeed) then
			print("Manual speed lookup for speed " .. a_Speed .. " is idx " .. idx .. ", linear speed " .. level.linearSpeed)
			return idx
		end
	end
	return 1
end





--- Updates each bot to target the nearest enemy:
local function updateTargets(a_Game)
	-- Check params:
	assert(type(a_Game) == "table")
	
	-- Update the targets:
	for idx, m in ipairs(a_Game.myBots) do
		-- Pick the nearest target:
		local minDist = a_Game.world.width * a_Game.world.width + a_Game.world.height * a_Game.world.height
		local target
		for idx2, e in ipairs(a_Game.enemyBots) do
			local dist = botDistance(m, e)
			if (dist < minDist) then
				minDist = dist
				target = e
			end
		end  -- for idx2, e - enemyBots[]
		
		-- Navigate towards the target:
		if (target) then
			aiLog(m.id, "Targetting enemy #" .. target.id)
			a_Game.botCommands[m.id] = cmdTargetBot(m, target, a_Game)
		end
	end
end





function onGameStarted(a_Game)
	-- Collect all my bots into an array, and enemy bots to another array:
	a_Game.myBots = {}
	a_Game.enemyBots = {}
	for _, bot in pairs(a_Game.allBots) do
		if (bot.isEnemy) then
			table.insert(a_Game.enemyBots, bot)
		else
			table.insert(a_Game.myBots, bot)
		end
	end
end





function onGameUpdate(a_Game)
	-- Nothing needed yet
end





function onGameFinished(a_Game)
	-- Nothing needed yet
end





function onBotDied(a_Game, a_BotID)
	-- Remove the bot from one of the myBots / enemyBots arrays:
	local whichArray
	if (a_Game.allBots[a_BotID].isEnemy) then
		whichArray = a_Game.enemyBots
	else
		whichArray = a_Game.myBots
	end
	for idx, bot in ipairs(whichArray) do
		if (bot.id == a_BotID) then
			table.remove(whichArray, idx)
			break;
		end
	end  -- for idx, bot - whichArray[]
	
	-- Update the bot targets:
	updateTargets(a_Game)

	-- Print an info message:
	local friendliness
	if (a_Game.allBots[a_BotID].isEnemy) then
		friendliness = "(enemy)"
	else
		friendliness = "(my)"
	end
	print("LUA: onBotDied: bot #" .. a_BotID .. friendliness)
end





function onCommandsSent(a_Game)
	-- Nothing needed
end





function onSendingCommands(a_Game)
	-- Update the commands just as they are about to be sent
	commentLog("Sending commands: server time " .. a_Game.serverTime .. ", local time " .. a_Game.localTime .. ", diff = " .. a_Game.localTime - a_Game.serverTime .. " msec")
	updateTargets(a_Game)
end




