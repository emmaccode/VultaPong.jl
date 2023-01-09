module VultaPong
using Toolips
using ToolipsSession
using ToolipsSVG
using ToolipsDefaults
using Vulta

global games = Dict{String, Dict{String, Any}}()
global names = Dict{String, String}()
function home(c::Connection)
    write!(c, ToolipsDefaults.sheet("pongsheet"))
    mainbod = body("mainbody")
    namelabel = h("namelabel", 3, text = "enter a name:")
    okbutton = button("okbutton", text = "continue")
    style!(okbutton, "margin-top" => 10px, "font-size" => 14pt)
    namebox = ToolipsDefaults.textdiv("namebox")
    maindiv = div("maindiv", align = "center")
    style!(maindiv, "background-color" => "darkgray", "margin-top" => 10percent,
    "border-width" => 3px, "border-style" => "solid")
    push!(maindiv, namelabel, namebox, okbutton)
    push!(mainbod, maindiv)
    gamesbox = div("gamesbox", align = "left")
    for game in games
        gamediv = div(game[1])
        if game[2]["peers"] != ""
            style!(gamediv, "background-color" => "red")
        end
        push!(gamediv, a("gamelabel", text = game[1]))
        joinbutton = button("$(game[1])joinbutton", text = "join")
        on(c, joinbutton, "click") do cm::ComponentModifier
            game[2]["peer"] = getip(c)
            redirect!(cm, "/game")
        end
        push!(gamesbox, gamediv, joinbutton)
    end
    hostbutton = button("hostbutton", text = "host")
    on(c, hostbutton, "click") do cm::ComponentModifier
        push!(games,
        getip(c) => Dict{String, Any}("peer" => ""))
        redirect!(cm, "/game")
    end
    hostslide = div("hostslide")
    push!(hostslide, hostbutton)
    push!(gamesbox, hostslide)
    if getip(c) in keys(names)
        maindiv[:children] = Vector{Servable}([gamesbox])
    end
    on(c, okbutton, "click") do cm::ComponentModifier
        username = cm["namebox"]["text"]
        push!(names, getip(c) => username)
        set_children!(cm, maindiv, [gamesbox])
    end
    write!(c, maindiv)
end

"""
home(c::Connection) -> _
--------------------
The home function is served as a route inside of your server by default. To
    change this, view the start method below.
"""
function main(c::Connection)
    player_force::Int64 = 60
    pongbod = body("mainbody", "margin-top" => 10px)
    joincheck =  findall(x -> x["peer"] == getip(c),
    games)
    pongpaddle_left = rect("paddleleft", width = 40,
    height = 160)
    pongpaddle_right = rect("paddleright", width = 40, height = 160)
    pongball = circle("mycirc", "stroke-width" => 5px, "r" => 20)
    goal_left = rect("goal_left", height = 720, width = 20)
    goal_right = rect("goal_right", height = 720, width = 20)
    topbar = rect("topbar", height = 20, width = 1280)
    leftscore = a("leftscore", text = "0")
    rightscore = a("rightscore", text = "0")
    style!(leftscore, "color" => "green", "font-size" => 20pt)
    style!(rightscore, "color" => "lightblue", "font-size" => 20pt,
    "margin-left" => 15px)
    scorebox = div("scorebox", align = "center")
    push!(scorebox, leftscore, rightscore)
    push!(pongbod, scorebox)
    bottombar = rect("bottombar", height = 20, width = 1280)
    style!(pongball, "fill" => "red")
    style!(pongpaddle_right, "fill" => "lightblue")
    style!(pongpaddle_left, "fill" => "green")
    km = ToolipsSession.KeyMap()
    serving = true
    on(c, "unload") do cm::ComponentModifier
        delete!(games, getip(c))
    end
    if getip(c) in keys(games)
        games[getip(c)]["score"] = [0, 0]
        bind!(km, "w") do cm::ComponentModifier
            hard_force!(cm, pongpaddle_left, Vec2(0, -15))
            rpc!(c, cm)
        end
        bind!(km, "s") do cm::ComponentModifier
            hard_force!(cm, pongpaddle_left, Vec2(0, 25))
            rpc!(c, cm)
        end
        on(c, pongbod, "click") do cm::ComponentModifier
            if serving == true
                force!(cm, pongball, Vec2(50, 0))
                rpc!(c, cm)
                serving = false
            end
        end
        Vulta.initialize(c, pongbod, 1280, 720) do cm::ComponentModifier
            if initializing(c)
                bind!(c, cm, km, on = :press)
                spawn!(c, cm, pongpaddle_right, Vec2(1165, 360))
                spawn!(c, cm, pongpaddle_left, Vec2(75, 360))
                spawn!(c, cm, goal_left, Vec2(0, 0))
                spawn!(c, cm, goal_right, Vec2(1260, 0))
                spawn!(c, cm, pongball, Vec2(150, 360), decay = 1)
                spawn!(c, cm, topbar, Vec2(0, 0))
                spawn!(c, cm, bottombar, Vec2(0, 700))
            end
            if pongpaddle_left.name in keys(cm.rootc)
                if is_colliding(cm, pongpaddle_left, pongball)
                    cm[pongpaddle_left] = "fx" => "0"
                    cm[pongpaddle_left] = "fy" => "0"
                    momentum_y = parse(Int64, cm[pongpaddle_left]["fy"])
                    hard_force!(cm, pongball, Vec2(player_force, momentum_y * 2))
                end
                if is_colliding(cm, pongpaddle_right, pongball)
                    cm[pongpaddle_right] = "fx" => "0"
                    cm[pongpaddle_right] = "fy" => "0"
                    momentum_y = parse(Int64, cm[pongpaddle_right]["fy"])
                    hard_force!(cm, pongball, Vec2(-player_force, momentum_y * 2))
                end
                if is_colliding(cm, topbar, pongball)
                    hard_force!(cm, pongball, (Vec2(0, 20)))
                end
                if is_colliding(cm, bottombar, pongball)
                    hard_force!(cm, pongball, (Vec2(0, -20)))
                end
                if is_colliding(cm, goal_left, pongball)
                    games[getip(c)]["score"][2] = games[getip(c)]["score"][2] + 1
                    set_text!(cm, rightscore, string(games[getip(c)]["score"][2]))
                    serving = true
                    translate!(cm, pongball, Vec2(170, parse(Int64,
                    cm[pongpaddle_left]["y"])))
                    hard_force!(cm, pongball, Vec2(0, 0))
                end
                if is_colliding(cm, goal_right, pongball)
                    games[getip(c)]["score"][1] = games[getip(c)]["score"][1] + 1
                    set_text!(cm, leftscore, string(games[getip(c)]["score"][1]))
                    translate!(cm, pongball, Vec2(170, parse(Int64,
                    cm[pongpaddle_left]["y"])))
                    hard_force!(cm, pongball, Vec2(0, 0))
                    serving = true
                end
                if is_colliding(cm, topbar, pongpaddle_right)
                    hard_force!(cm, pongpaddle_right, Vec2(0, 1))
                end
                if is_colliding(cm, topbar, pongpaddle_left)
                    hard_force!(cm, pongpaddle_left, Vec2(0, 1))
                end
                if is_colliding(cm, bottombar, pongpaddle_right)
                    hard_force!(cm, pongpaddle_right, Vec2(0, -2))
                end
                if is_colliding(cm, bottombar, pongpaddle_left)
                    hard_force!(cm, pongpaddle_left, Vec2(0, -2))
                end
                rpc!(c, cm)
            end
        end
    elseif length(joincheck) == 1
        bind!(km, "w") do cm::ComponentModifier
            force!(cm, pongpaddle_right, Vec2(0, -20))
            rpc!(c, cm)
        end
        bind!(km, "s") do cm::ComponentModifier
            force!(cm, pongpaddle_right, Vec2(0, 10))
            rpc!(c, cm)
        end
        Vulta.join(c, joincheck, bod)
    else
        return
    end
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end

routes = [route("/", home), route("/game", main), fourofour]
extensions = Vector{ServerExtension}([Logger(), Files(), Session(["/", "/game"]), VultaCore()])
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
