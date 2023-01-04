using Pkg; Pkg.activate(".")
using Toolips
using VultaTest

IP = "127.0.0.1"
PORT = 8000
VultaTestServer = VultaTest.start(IP, PORT)
