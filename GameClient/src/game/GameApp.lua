local GameApp 		= class("GameApp")
local ProtoMan 		= require("game.utils.ProtoMan")
local NetWork       = require("game.net.NetWork")
local NetWorkUDP    = require("game.net.NetWorkUDP")

Lobby = {}
Game = {}

local Function 		= require('game.Base.Function')
local UIFunction 	= require('game.Base.UIFunction')

function GameApp:ctor()
    math.randomseed(os.time())

    ProtoMan:getInstance():regist_pb()
    NetWork:getInstance():start()
    -- NetWorkUDP:getInstance():start()  --UDP test

    Lobby.showPopLayer 		= Function.showPopLayer
    Lobby.popLayer 			= Function.popLayer
    Lobby.getLayer 			= Function.getLayer
end

function GameApp:showScene(transition, time, more)
    local loginScene = require("game.Lobby.LobbyScene.LoginScene"):create()
    loginScene:run()
end

return GameApp
