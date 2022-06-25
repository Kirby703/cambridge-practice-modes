require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls'

local PhantomPracticeGame = GameMode:extend()

PhantomPracticeGame.name = "Phantom Practice Fading"
PhantomPracticeGame.hash = "PhantomPractice"
PhantomPracticeGame.tagline = "Goes from fading to invis!"
-- hits a 5s fade (fading roll) at 300 and full invis (M roll) at 900

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
end

function PhantomPracticeGame:getARE()
		if self.level < 100 then return 18
	elseif self.level < 200 then return 14
	elseif self.level < 400 then return 8
	elseif self.level < 500 then return 7
	else return 6 end
end

function PhantomPracticeGame:getLineARE()
		if self.level < 100 then return 14
	elseif self.level < 400 then return 8
	elseif self.level < 500 then return 7
	else return 6 end
end

function PhantomPracticeGame:getDasLimit()
		if self.level < 200 then return 11
	elseif self.level < 300 then return 10
	elseif self.level < 400 then return 9
	else return 7 end
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

function PhantomPracticeGame:hitTorikan(old_level, new_level)
	return false
end

function PhantomPracticeGame:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames < 0 then
			return false
		elseif self.roll_frames > 300 then
			self.completed = true
		end
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
	return true
end

function PhantomPracticeGame:onPieceEnter()
	if (self.level % 100 ~= 99 and self.level ~= 998) and not self.clear and self.frames ~= 0 then
		self.level = self.level + 1
	end
end

function PhantomPracticeGame:onLineClear(cleared_row_count)
	if not self.clear then
		local new_level = self.level + cleared_row_count
		if new_level >= 999 or self:hitTorikan(self.level, new_level) then
			if new_level >= 999 then
				self.level = 999
			end
			self.clear = true
		else
			self.level = new_level
		end
	end
end

function PhantomPracticeGame:updateScore(level, drop_bonus, cleared_lines)
	if not self.clear then
		if cleared_lines > 0 then
			self.combo = self.combo + (cleared_lines - 1) * 2
			self.score = self.score + (
				(math.ceil((level + cleared_lines) / 4) + drop_bonus) *
				cleared_lines * self.combo
			)
		else
			self.combo = 1
		end
		self.drop_bonus = 0
	end
end

function PhantomPracticeGame:drawGrid()
	PhantomPracticeGame.rollOpacityFunction = function(age)
		local visibility = 4 + math.max(0, (900 - self.level) / 2)
		if age > visibility then return 0
		else return 1 - age / visibility end
	end
	if self.game_over or self.completed or self.clear then
		self.grid:draw()
	else
		self.grid:drawInvisible(self.rollOpacityFunction, nil, false)
	end
end

local function getLetterGrade(level, clear)
	return ""
end

function PhantomPracticeGame:drawScoringInfo()
	PhantomPracticeGame.super.drawScoringInfo(self)

	local text_x = config["side_next"] and 320 or 240

	love.graphics.setFont(font_3x5_2)
	love.graphics.printf("SCORE", text_x, 200, 40, "left")
	love.graphics.printf("LEVEL", text_x, 320, 40, "left")
	local sg = self.grid:checkSecretGrade()
	if sg >= 5 then 
		love.graphics.printf("SECRET GRADE", 240, 430, 180, "left")
	end

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.score, text_x, 220, 90, "left")
	love.graphics.printf(self.level, text_x, 340, 40, "right")
	if self.clear then
		love.graphics.printf(self.level, text_x, 370, 40, "right")
	else
		love.graphics.printf(self:getSectionEndLevel(), text_x, 370, 40, "right")
	end

	if sg >= 5 then
		love.graphics.printf(self.SGnames[sg], 240, 450, 180, "left")
	end
end

function PhantomPracticeGame:getSectionEndLevel()
	if self.level >= 900 then return 999
	else return math.floor(self.level / 100 + 1) * 100 end
end

function PhantomPracticeGame:getBackground()
	return math.floor(self.level / 100)
end

function PhantomPracticeGame:getHighscoreData()
	return {
		level = self.level,
		frames = self.frames,
	}
end

return PhantomPracticeGame