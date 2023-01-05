module VultaPong
using Toolips
using ToolipsSession
using ToolipsSVG
using Vulta
# welcome to your new toolips project!
"""
home(c::Connection) -> _
--------------------
The home function is served as a route inside of your server by default. To
    change this, view the start method below.
"""
function home(c::Connection)
    player_force::Int64 = 40
    pongbod = body("mainbody")
    pongpaddle_left = rect("paddleleft", width = 40,
    height = 160)
    pongball = circle("mycirc", "stroke-width" => 5px, "r" => 20)
    km = ToolipsSession.KeyMap()
    bind!(km, "w") do cm::ComponentModifier
        force!(cm, pongpaddle_left, Vec2(0, -10))
    end
    on(c, pongbod, "click") do cm::ComponentModifier
        force!(cm, pongball, Vec2(-20, 0))
    end
    bind!(km, "s") do cm::ComponentModifier
        force!(cm, pongpaddle_left, Vec2(0, 10))
    end
    Vulta.initialize(c, pongbod) do cm::ComponentModifier
        if initializing(c)
            bind!(c, cm, km, on = :press)
            spawn!(cm, pongball, Vec2(640, 360))
            spawn!(cm, pongpaddle_left, Vec2(50, 500))
        end
        if pongpaddle_left.name in keys(cm.rootc)
            if is_colliding(cm, pongpaddle_left, pongball)
                cm[pongpaddle_left] = "fx" => "0"
                cm[pongpaddle_left] = "fy" => "0"
                cm[pongball] = "fx" => player_force
                cm[pongball] = "fy" => cm[pongpaddle_left]["fy"]
            end
        end
    end
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end

routes = [route("/", home), fourofour]
extensions = Vector{ServerExtension}([Logger(), Files(), Session(), VultaCore()])
"""
start(IP::String, PORT::Integer, ) -> ::ToolipsServer
--------------------
The start function starts the WebServer.
"""
function start(IP::String = "127.0.0.1", PORT::Integer = 8000)
     ws = WebServer(IP, PORT, routes = routes, extensions = extensions)
     ws.start(); ws
end
end # - module
