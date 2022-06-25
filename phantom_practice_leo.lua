require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls'

local PhantomPracticeGame = GameMode:extend()

PhantomPracticeGame.name = "Phantom Practice Leo"
PhantomPracticeGame.hash = "PhantomPracticeLeo"
PhantomPracticeGame.tagline = "Just like the TE:C boss!"

function PhantomPracticeGame:new()
	PhantomPracticeGame.super:new()

	self.lock_drop = true
	self.lock_hard_drop = true
	self.next_queue_length = 3
	self.enable_hold = true
	
	self.SGnames = {
		"S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9",
		"M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9",
		"GM"
	}

	self.roll_frames = 0
	self.combo = 1
	self.randomizer = History6RollsRandomizer()
	
	self.visible = 0
	self.chain = 0
end

function PhantomPracticeGame:getARE()
	return 6
end

function PhantomPracticeGame:getLineARE()
	return 6
end

function PhantomPracticeGame:getDasLimit()
	return math.max(7, config.das)
end

function PhantomPracticeGame:getLineClearDelay()
	return self:getLineARE() - 2
end

function PhantomPracticeGame:getLockDelay()
	return math.huge
end

function PhantomPracticeGame:getGravity()
	return 20
end

function PhantomPracticeGame:advanceOneFrame()
	if self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
	if self.visible > 0 then
		self.visible = self.visible - 1
	end
	return true
end

function PhantomPracticeGame:onPieceEnter()
	if (self.level % 100 ~= 99) and self.frames ~= 0 then
		self.level = self.level + 1
	end
	
	if self.chain >= math.floor(self.level / 100) + 1 then
		self.visible = 40
		self.chain = 0
	else
		if self.visible == 0 then
			self.visible = -1
		end
		self.chain = self.chain + 1
	end
end

function PhantomPracticeGame:onLineClear(cleared_row_count)
	self.level = self.level + cleared_row_count
end

function PhantomPracticeGame:drawGrid()
	PhantomPracticeGame.rollOpacityFunction = function(age)
		if self.visible > -1 then return 1
		elseif age > 4 then return 0
		else return 1 - age / 4 end
	end
	if self.game_over or self.completed or self.clear then
		self.grid:draw()
	else
		self.grid:drawInvisible(self.rollOpacityFunction, nil, true)
	end
end

function PhantomPracticeGame:drawScoringInfo()
	PhantomPracticeGame.super.drawScoringInfo(self)

	local text_x = config["side_next"] and 320 or 240

	love.graphics.setFont(font_3x5_2)
	love.graphics.printf("LEVEL", text_x, 320, 40, "left")
	local sg = self.grid:checkSecretGrade()
	if sg >= 5 then 
		love.graphics.printf("SECRET GRADE", 240, 430, 180, "left")
	end

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.level, text_x, 340, 90, "left")
	if self.clear then
		love.graphics.printf(self.level, text_x, 370, 90, "left")
	else
		love.graphics.printf(self:getSectionEndLevel(), text_x, 370, 90, "left")
	end

	if sg >= 5 then
		love.graphics.printf(self.SGnames[sg], 240, 450, 180, "left")
	end
end

function PhantomPracticeGame:getSectionEndLevel()
	return math.floor(self.level / 100 + 1) * 100
end

function PhantomPracticeGame:getBackground()
	return math.floor((self.level / 100) % 20)
end

function PhantomPracticeGame:getHighscoreData()
	return {
		level = self.level,
	}
end

return PhantomPracticeGame