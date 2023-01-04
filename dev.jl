using Pkg; Pkg.activate(".")
using Toolips
using Revise
using VultaPong

IP = "127.0.0.1"
PORT = 8000
VultaTestServer = VultaPong.start(IP, PORT)
