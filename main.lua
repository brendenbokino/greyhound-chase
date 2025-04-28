local Globals = require "src.Globals"
local Camera = require "libs.sxcamera"
local Push = require "libs.push"


local Player = require "src.game.Player"
local StageHandler = require "src.game.stages.StageHandler"
local DialogueHandler = require "src.game.dialogue.DialogueHandler"
local CutsceneHandler = require "src.game.dialogue.CutsceneHandler"
local TitleScreen = require "src.game.stages.TitleScreen"
local GameOverScreen = require "src.game.stages.GameOverScreen"
local TransitionScreen = require "src.game.TransitionScreen"
local SFX = require "src.game.SFX"
local Timer = require "libs.hump.timer"

local timer = Timer.new()
local transitioning = false

function love.load()
    love.window.setTitle("Greyhound Chase")
    Push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {fullscreen = false, resizable = true})
    
    player = Player(0, 0)
    camera = Camera( gameWidth / 2, gameHeight / 2, gameWidth, gameHeight)

    camera:setFollowStyle('PLATFORMER')

    stageHandler = StageHandler(player, camera)
    dialogueHandler = DialogueHandler()
    cutsceneHandler = CutsceneHandler()

    SFX.load()
    TitleScreen.load()
end

function love.resize(w,h)
    Push:resize(w,h)
end


function love.update(dt)
    timer:update(dt)
    
    if gameState == "start" then
        TitleScreen.update(dt)
        if not SFX.Sounds.menu:isPlaying() and not TransitionScreen.isTransitioning() then
            SFX.Sounds.menu:play()
        end
    elseif gameState == "play" then
        stageHandler:currentStage():update(dt)
        player:update(dt, stageHandler:currentStage())

        cutsceneHandler:update(dt)
        dialogueHandler:update(dt)

        camera:update(dt)
        camera:follow(math.floor(player.x + 50), math.floor(player.y))

        if player.dead then
            gameState = "over"
        end
    elseif gameState == "over" then
        
    end

    SFX.update(dt)
    TransitionScreen.update(dt)
end

function love.draw()
    Push:start()
    
    if gameState == "start" then
        drawStartState()
    elseif gameState == "play" then
        drawPlayState()
        dialogueHandler:draw()
    elseif gameState == "over" then
        drawOverState()
    end

    TransitionScreen.draw()
    Push:finish()
    
end

function love.keypressed(key)

    if key == "escape" then
        love.event.quit()
    elseif key == "return" then
        if TransitionScreen.isTransitioning() then return end
        if gameState == "start" or gameState == "over" then
            TransitionScreen.start(1, 1)
            SFX.Sounds.select:play()
            SFX.Sounds.menu:stop()
            

            timer:after(1, function()
                player:reset(stageHandler:currentStage())
                gameState = "play"
                
                if stageHandler:currentStage().startCutscene then
                    stageHandler:currentStage().startCutscene()
                end
            end)
        end
    end

    if key == "k" then
        player.godded = true
    end

    if gameState == "play" then
        cutsceneHandler:keyPressed(key)
    end
    
end

function drawStartState()
    TitleScreen.drawBackground()
    TitleScreen.draw()
end

function drawPlayState()
    stageHandler:currentStage():drawBackground()

    camera:attach()

    stageHandler:currentStage():draw()
    player:draw()

    camera:detach()
end

function drawOverState()
    GameOverScreen.drawBackground()
    GameOverScreen.draw()
end