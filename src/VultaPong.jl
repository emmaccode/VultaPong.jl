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
    pongbod = body("mainbody")
    on(c, pongbod, "click") do cm::ComponentModifier
        cm["paddle-left"] = "x" => 400
    end
    Vulta.open(c, pongbod) do vm::VultaModifier
        pongpaddle_left = rect("paddle-left", width = 10,
        height = 50)
        pongball = circle("mycirc", "stroke-width" => 5px, "r" => 10)
        if vm.delta == 1
            spawn!(vm, pongball, Vec2(640, 360))

            spawn!(vm, pongpaddle_left, Vec2(620, 360))
        elseif vm.delta == 55
            force!(vm, pongpaddle_left, Vec2(10, 0))
        else
            if is_colliding(vm, pongpaddle_left, pongball)
                style!(vm.cm, pongpaddle_left, "color" => "red")
            else
    #            style!(vm, pongpaddle_left, "color" => "black")
            end
        end

    end
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end

routes = [route("/", home), fourofour]
extensions = Vector{ServerExtension}([Logger(), Files(), Session(), ])
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
