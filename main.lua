
local width = 0
local height = 0

local acceleration = 300
local maximumSpeed = 5000
local minimumSpeed = 500

local minimumPaddleSpeed = 800
local maximumPaddleSpeed = 3000

local paddleMargin = 20

local scoreFont
local backgroundImage

local paddleA = {
    x = 20,
    y = 250,
    width = 15,
    height = 100,
    speed = minimumPaddleSpeed
}

local paddleB = {
    x = 765,
    y = 250,
    width = 15,
    height = 100,
    speed = minimumPaddleSpeed
}

local ball = {
    x = 400,
    y = 300,
    radius = 5,
    speed = 500,
    dirX = 1,
    dirY = 1
}

local score = {
    playerA = 0,
    playerB = 0,
    maxRounds = 5
}

local gameState = {
    isStarted = false,
    isPaused = false,
    isGameOver = false
}

local ballSpeedTimerSettings = {
    interval = 10, -- Zeitintervall in Sekunden, nach dem die Geschwindigkeit erhöht wird
    speedIncrease = 50, -- Betrag, um den die Geschwindigkeit erhöht wird
    timer = 0 -- Timer-Variable, um die Zeit zu verfolgen
}

function love.resize(w, h)
    width = w
    height = h

    updateBallSpeed()
    updatePaddleSpeed()
    positionPaddles()
    
    paddleA.y = math.min(paddleA.y, height - paddleA.height)
    paddleB.y = math.min(paddleB.y, height - paddleB.height)
end

function love.keypressed(key)

    local _, _, flags = love.window.getMode()

    if key == "+" and flags.fullscreen == false then
        love.window.setFullscreen(true)
        width  = love.graphics.getWidth()
        height = love.graphics.getHeight()
    elseif key == "-" and flags.fullscreen == true then
        love.window.setFullscreen(false)
        width  = love.graphics.getWidth()
        height = love.graphics.getHeight()
    elseif key == "space" and (gameState.isGameOver or gameState.isStarted == false) then        
        -- Spiel neustarten: alle Werte zurücksetzen

        gameState.isStarted = true
        resetPaddles()
        score.playerA = 0
        score.playerB = 0
        gameState.isGameOver = false
        ball.speed = minimumSpeed
        local randomX = math.random(0, 1) * 2 - 1
        resetBall(randomX)
        -- Sound abspielen
        playSound:play()
    elseif key == "p" then
        gameState.isPaused = not gameState.isPaused
    elseif key == "escape" then
        love.event.quit()
    end
end

function positionPaddles()
    -- x-Position der Paddles immer an den Seiten, damit sie auch bei Änderung der Fenstergröße an der richtigen Stelle bleiben
    paddleA.x = paddleMargin
    paddleB.x = width - paddleMargin - paddleB.width
end

function resetPaddles()
    positionPaddles()

    paddleA.y = (height - paddleA.height) / 2
    paddleB.y = (height - paddleB.height) / 2
end

function normalize(x, y)
    -- Normierung ist das Umwandeln eines Vektors in einen Einheitsvektor, wobei die Richtung erhalten bleibt und die Länge auf 1 gesetzt wird.
    local len = math.sqrt(x * x + y * y)

    return (x / len), (y / len)
end

function love.load()

    smallFont = love.graphics.newFont(12)
    scoreFont = love.graphics.newFont(48)

    backgroundImage = love.graphics.newImage("assets/graphics/emmi_1.jpg")
    
    math.randomseed(os.time()) -- Zufallszahlengenerator mit aktuellem Zeitpunkt initialisieren, damit die Richtung des Balls nicht immer gleich ist

    love.window.setTitle("Emmi Pong")

    width = love.graphics.getWidth()
    height = love.graphics.getHeight()

    startSound = love.audio.newSource("assets/sounds/game_starter.mp3", "static")
    startSound:play()

    gameOverSound = love.audio.newSource("assets/sounds/game_over.mp3", "static")

    hitSound = love.audio.newSource("assets/sounds/hit.ogg", "static")
    playSound = love.audio.newSource("assets/sounds/winner_1.mp3", "static")

    positionPaddles()

    ball.dirX, ball.dirY = normalize(1,1)
    
end

function love.update(dt)

    if gameState.isGameOver or gameState.isPaused or gameState.isStarted == false then
        return
    end

    dt = math.min(dt, 1/30)

    ballSpeedTimerSettings.timer = ballSpeedTimerSettings.timer + dt
    
    if ballSpeedTimerSettings.timer >= ballSpeedTimerSettings.interval then
        ball.speed = math.min(
            ball.speed + ballSpeedTimerSettings.speedIncrease,
            maximumSpeed
        )
        ballSpeedTimerSettings.timer = 0
    end

    if love.keyboard.isDown("s") then
        if paddleA.y + paddleA.height < height then
            paddleA.y = paddleA.y + paddleA.speed * dt
        end
    elseif love.keyboard.isDown("w") and paddleA.y > 0 then 
        paddleA.y = paddleA.y - paddleA.speed * dt
    end

    if love.keyboard.isDown("down") then
        if paddleB.y + paddleB.height < height then
            paddleB.y = paddleB.y + paddleB.speed * dt
        end
    elseif love.keyboard.isDown("up") and paddleB.y > 0 then
        paddleB.y = paddleB.y - paddleB.speed * dt
    end

    -- Gas / Bremse: nur speed anfassen
    if love.keyboard.isDown("right") and ball.speed < maximumSpeed then
        ball.speed = ball.speed + acceleration * dt
    end
    if love.keyboard.isDown("left") and ball.speed > minimumSpeed then
        ball.speed = ball.speed - acceleration * dt
    end
    
    -- Bewegung: aus speed und dir die aktuelle Verschiebung bauen
    ball.x = ball.x + ball.speed * ball.dirX * dt
    ball.y = ball.y + ball.speed * ball.dirY * dt
    
    if ball.x >= width and ball.dirX > 0 then
        scoring("A")
        resetBall(1)
    end
    if ball.x <= 0 and ball.dirX < 0 then
        scoring("B")
        resetBall(-1)
    end
    if ball.y >= height and ball.dirY > 0 then
        ball.y = height
        ball.dirY = -ball.dirY
    end
    if ball.y <= 0 and ball.dirY < 0 then
        ball.y = 0
        ball.dirY = -ball.dirY
    end

    collisionDetection()

end

function love.draw()

    local scaleX = width / backgroundImage:getWidth()
    local scaleY = height / backgroundImage:getHeight()

    love.graphics.draw(backgroundImage, 0, 0, 0, scaleX, scaleY)
    
    love.graphics.setFont(scoreFont)
    love.graphics.print(score.playerA .. " : " .. score.playerB, width / 2 - 50, 20)

    -- love.graphics.print(score.playerA .. " : " .. score.playerB, width / 2 - 20, 20)

    love.graphics.setFont(smallFont)

    if gameState.isGameOver then
        love.graphics.print("GAME OVER - Space zum Neustart", width / 2 - 100, height / 2)
        return
    end

    if gameState.isPaused then
        love.graphics.print("PAUSED - P zum Fortfahren", width / 2 - 100, height / 2)
        return
    end

    if gameState.isStarted == false then
        love.graphics.print("PRESS SPACE TO START", width / 2 - 100, height / 2)
        return
    end

    love.graphics.rectangle("fill", paddleA.x, paddleA.y, paddleA.width, paddleA.height)
    love.graphics.rectangle("fill", paddleB.x, paddleB.y, paddleB.width, paddleB.height)
    
    love.graphics.print("Speed: " .. math.floor(ball.speed), 0, 0)
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- love.graphics.line(20 ,250, 780, 250)
    -- love.graphics.line(paddleA.x + paddleA.width, paddleA.y, width - paddleA.width, paddleA.y)
    -- love.graphics.line(paddleA.x + paddleA.width, paddleA.y + paddleA.height, width - paddleA.width, paddleA.y + paddleA.height)   

end

function collisionDetection()
    -- Kollision mit Paddle A
    if ball.dirX < 0 then
        if ball.x - ball.radius <= paddleA.x + paddleA.width and ball.x - ball.radius >= paddleA.x then
            if ball.y >= paddleA.y and ball.y <= paddleA.y + paddleA.height then
                ball.x = paddleA.x + paddleA.width + ball.radius -- zurück an die Wand setzen
                -- ball.dirX = -ball.dirX            
                ball.dirX, ball.dirY = normalize(-ball.dirX, normalizedHit(ball.y, paddleA.y, paddleA.height))
                hitSound:play()
            end
        end
    end

    -- Kollision mit Paddle B
    if ball.dirX > 0 then
        if ball.x + ball.radius >= paddleB.x and ball.x + ball.radius <= paddleB.x + paddleB.width then
            if ball.y >= paddleB.y and ball.y <= paddleB.y + paddleB.height then
                ball.x = paddleB.x - ball.radius -- zurück an die Wand setzen
                -- ball.dirX = -ball.dirX
                ball.dirX, ball.dirY = normalize(-ball.dirX, normalizedHit(ball.y, paddleB.y, paddleB.height))
                hitSound:play()
            end
        end
    end
end

function normalizedHit(ballY, paddleY, paddleHeight)
    -- Berechnung des Aufprallwinkels: je weiter oben oder unten der Ball auf das Paddle trifft, desto steiler wird der Winkel
    local paddleCenterY = paddleY + paddleHeight / 2
    local hitOffset = ballY - paddleCenterY
    local normalizedHit = hitOffset / (paddleHeight / 2)

    return normalizedHit
end

function updateBallSpeed()
    ball.speed = math.min(width, height) * 0.8
    -- Geschwindigkeit des Balls anpassen, damit er nicht zu schnell oder zu langsam wird
    if ball.speed > maximumSpeed then
        ball.speed = maximumSpeed
    elseif ball.speed < minimumSpeed then
        ball.speed = minimumSpeed
    end
end

function updatePaddleSpeed()
    -- Geschwindigkeit der Paddles anpassen, damit sie nicht zu schnell oder zu langsam werden
   local speed = math.min(width, height) * 1.2
    if speed > maximumPaddleSpeed then
        speed = maximumPaddleSpeed
    elseif speed < minimumPaddleSpeed then
        speed = minimumPaddleSpeed
    end

    paddleA.speed = speed
    paddleB.speed = speed
end

function resetBall(directionX)
    ball.x = width / 2
    ball.y = height / 2
    -- ball.speed = minimumSpeed -- Idee: schneller werden lassen, damit es spannender wird

    local randomY = math.random(0, 1) * 2 - 1 -- Zufällige Richtung auf der Y-Achse, damit es nicht immer gleich ist

    ball.dirX, ball.dirY = normalize(directionX, randomY)
end

function scoring(player)
    if player == "A" then
        score.playerA = score.playerA + 1
    elseif player == "B" then
        score.playerB = score.playerB + 1
    end

    if score.playerA >= score.maxRounds or score.playerB >= score.maxRounds then
        gameState.isGameOver = true
        gameOverSound:play()
    end    
end
