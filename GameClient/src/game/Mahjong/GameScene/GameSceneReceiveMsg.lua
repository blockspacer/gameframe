local GameScene = Game.GameScene or {}

local Cmd               	= require("game.net.protocol.Cmd")
local Respones          	= require("game.net.Respones")
local cmd_name_map      	= require("game.net.protocol.cmd_name_map")
local UserRoomInfo          = require("game.clientdata.UserRoomInfo")
local UserInfo              = require("game.clientdata.UserInfo")
local LogicServiceProxy     = require("game.modules.LogicServiceProxy")
local AuthServiceProxy      = require("game.modules.AuthServiceProxy")
local HeartBeat             = require('game.Lobby.Base.HeartBeat')

local MAX_PLAYER_NUM        = 4

function GameScene:addServerEventListener()
    addEvent(ServerEvents.ON_SERVER_EVENT_DATA, self, self.onEventData)
    addEvent(ServerEvents.ON_SERVER_EVENT_NET_CONNECT, self, self.onEventNetConnect)
    addEvent(ServerEvents.ON_SERVER_EVENT_NET_CONNECT_FAIL, self, self.onEventNetConnectFail)
    addEvent(ServerEvents.ON_SERVER_EVENT_NET_CLOSE, self, self.onEventClose)
    addEvent(ServerEvents.ON_SERVER_EVENT_NET_CLOSED, self, self.onEventClosed)
end

function GameScene:addClientEventListener()
    addEvent(ClientEvents.ON_NETWORK_OFF, self, self.onEventNetWorkOff)
    addEvent("DessolveRes",self, self.onEventDessolve)
    addEvent("ExitRoomRes",self, self.onEventExitRoom)
    addEvent('Relogin',self, self.onEvnetRelogin)
    addEvent('JoinRoomRes',self, self.onEventJoinRoom)
    addEvent('BackRoomRes',self, self.onEventBackRoom)
    addEvent('UserArrived',self, self.onEventUserArrived)
    addEvent('UserOffLine',self, self.onEventUserOffline)
    addEvent('UserReconnected',self, self.onEventUserReconnected)
    addEvent("LoginLogicRes",self, self.onEventLoginLogic)

    addEvent("GuestLoginRes", self, self.onEventGuestLogin)
    addEvent("UnameLoginRes", self, self.onEventUnameLogin)
end

function GameScene:onEventData(event)
    local data = event._usedata
    if not data then return end
    dump(data)
    postEvent(cmd_name_map[data.ctype], data.body)  -- post all client event to evety poplayer
end

function GameScene:onEventNetConnect(event)
    Game.showPopLayer('TipsLayer',{"网络连接成功!"})
    --重新登录
    local loginType = UserInfo.getLoginType()
    print('loginType: '.. loginType)
    if loginType == 'uname' then
        local name  = UserInfo.getUserAccount() 
        local pwd   = UserInfo.getUserPwd()
        print('hcc>>111 ' .. tostring(name) .. '  pwd:' .. tostring(pwd))
        AuthServiceProxy:getInstance():sendUnameLogin(name,pwd)
    elseif loginType == 'guest' then
        local guestkey = UserInfo.getUserGuestKey()
        print('hcc>>222 guestKey ' .. tostring(guestKey))
        AuthServiceProxy:getInstance():sendGuestLogin(guestkey)
    end
end

function GameScene:onEventNetConnectFail(event)
    Game.showPopLayer('TipsLayer',{"网络连接失败!"}) 
end

function GameScene:onEventClose(event)
    Game.showPopLayer('TipsLayer',{"网络连接关闭111!"})
end

function GameScene:onEventClosed(event)
    Game.showPopLayer('TipsLayer',{"网络连接关闭222!"})
end

function GameScene:onEvnetRelogin(event)
    self:enterScene('game.Lobby.LobbyScene.LoginScene')
    Game.showPopLayer('TipsLayer',{'帐号在其他地方登录!'})
end

function GameScene:onEventDessolve(event)
    print('hcc>> GameScene:onEventDessolve')
    local data = event._usedata
    if data.status == Respones.OK then  --只有房主才能解散房间
        self:popScene()
    else
        Game.showPopLayer('TipsLayer',{"解散房间失败"})
    end
end

function GameScene:onEventExitRoom(event)
    local data = event._usedata
    if data.status == Respones.OK then
        local user_info = data.user_info
        local seatid = user_info.seatid
        local unick  = tostring(user_info.unick)
        local ishost = user_info.ishost
        if ishost then
            UserRoomInfo.setUserRoomInfoBySeatId(user_info.seatid, user_info)
        else
            UserRoomInfo.removeUserRoomInfoBySeatId(seatid)
        end
        if unick == tostring(UserInfo.getUserName()) then
            self:popScene()
        end
    else
        Game.showPopLayer('TipsLayer',{"退出房间失败!"})
    end
    self:showAllExistUserInfo()
end

function GameScene:onEventJoinRoom(event)
    print('GameScene:onEventJoinRoom')
    local data = event._usedata
    local status = data.status
    if status == Respones.OK then
        UserRoomInfo.setRoomInfo(data.room_info)
        local users_info = data.users_info
        if next(users_info) then
            for i,v in ipairs(users_info) do
                dump(v)
                UserRoomInfo.setUserRoomInfoBySeatId(v.seatid, v)
            end
        end
    end
    self:showAllExistUserInfo()
end

function GameScene:onEventBackRoom(event)
    print('hcc>> GameScene:onEventBackRoom')
    local data = event._usedata
    local status = data.status
    if status == Respones.OK then
        UserRoomInfo.setRoomInfo(data.room_info)
        local users_info = data.users_info
        if next(users_info) then
            for i,v in ipairs(users_info) do
                UserRoomInfo.setUserRoomInfoBySeatId(v.seatid, v)
            end
        end
        self:pushScene('game.Mahjong.GameScene.GameScene')
    end
    self:showAllExistUserInfo()
end

function GameScene:onEventUserArrived(event)
    local data = event._usedata
    if next(data) then
        UserRoomInfo.setUserRoomInfoBySeatId(data.seatid, data)
    end
    self:showAllExistUserInfo()
end

function GameScene:onEventUserOffline(event)
    print('hcc>> GameScene:onEventUserOffline')
    local data = event._usedata
    local user_info = data.user_info
    if next(user_info) then
        UserRoomInfo.setUserRoomInfoBySeatId(user_info.seatid, user_info)
    end
    self:showAllExistUserInfo()
end

function GameScene:onEventUserReconnected(event)
    print('hcc>> GameScene:onEventUserReconnected')
end

function GameScene:onEventNetWorkOff(event)
    local layer = Game.getLayer('LoadingLayer')
    if not layer then
        Game.showPopLayer('LoadingLayer')
    end
    -- LogicServiceProxy:getInstance():sendLoginLogicServer() -- login gateway first TODO
end

function GameScene:onEventLoginLogic(event)
    Game.popLayer('LoadingLayer')
    local data = event._usedata
    if data.status == Respones.OK then
        Game.showPopLayer('TipsLayer',{"登录逻辑服成功!"})
        LogicServiceProxy:getInstance():sendBackRoomReq()
    else
        Game.showPopLayer('TipsLayer',{"登录逻辑服failed!"})
        LogicServiceProxy:getInstance():sendLoginLogicServer()  
    end
end

function GameScene:onEventGuestLogin(event)
    local body = event._usedata
    if body then
        Game.popLayer('LoadingLayer')
        if body.status == Respones.OK then
            local uinfo = body.uinfo
            UserInfo.setUserName(uinfo.unick)
            UserInfo.setUserface(uinfo.uface)
            UserInfo.setUserSex(uinfo.usex)
            UserInfo.setUserVip(uinfo.uvip)
            UserInfo.setUserId(uinfo.uid)
            UserInfo.setUserIsGuest(true)
            UserInfo.flush()
            LogicServiceProxy:getInstance():sendLoginLogicServer()
            Game.showPopLayer('TipsLayer',{"游客登录成功!"})
        else
            Game.showPopLayer('TipsLayer',{"游客登录失败，您帐号已升级成正式帐号!"})
        end
    end
end

function GameScene:onEventUnameLogin(event)
    local body = event._usedata
    Game.popLayer('LoadingLayer')
    if body.status == Respones.OK then
        local uinfo = body.uinfo
        UserInfo.setUserName(uinfo.unick)
        UserInfo.setUserface(uinfo.uface)
        UserInfo.setUserSex(uinfo.usex)
        UserInfo.setUserVip(uinfo.uvip)
        UserInfo.setUserId(uinfo.uid)
        UserInfo.flush()
        LogicServiceProxy:getInstance():sendLoginLogicServer()
        Game.showPopLayer('TipsLayer',{"登录成功!"})
    else
        Game.showPopLayer('TipsLayer',{"登录失败,帐号或密码错误!"})
    end
end