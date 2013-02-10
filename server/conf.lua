function love.conf(t)
    t.title = "QuadMad - server"
    t.author = "Exindel & Extred"
    t.url = nil
    t.identity = nil
    t.version = "0.8.0"
    t.console = true
    t.release = false
    t.screen.width = 640
    t.screen.height = 360
    t.screen.fullscreen = false
    t.screen.vsync = true
    t.screen.fsaa = 0
    t.modules.joystick = false
    t.modules.audio = true
    t.modules.keyboard = true
    t.modules.event = true
    t.modules.image = true
    t.modules.graphics = true
    t.modules.timer = true
    t.modules.mouse = true
    t.modules.sound = true
    t.modules.physics = true
end
