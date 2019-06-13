local GameScene = Game.GameScene or {}

local Respones          	= require("game.net.Respones")
local RoomData              = require("game.clientdata.RoomData")
local UserInfo              = require("game.clientdata.UserInfo")
local LogicServiceProxy     = require("game.modules.LogicServiceProxy")
local AuthServiceProxy      = require("game.modules.AuthServiceProxy")
local GameFunction          = require("game.Mahjong.Base.GameFunction")

local FLOAT_SCALE = 100000000

function GameScene:addServerEventListener()
    addEvent(ServerEvents.ON_SERVER_EVENT_NET_CONNECT, self, self.onEventNetConnect)
    addEvent(ServerEvents.ON_SERVER_EVENT_NET_CONNECT_FAIL, self, self.onEventNetConnectFail)
    addEvent(ServerEvents.ON_SERVER_EVENT_NET_CLOSE, self, self.onEventClose)
    addEvent(ServerEvents.ON_SERVER_EVENT_NET_CLOSED, self, self.onEventClosed)
end

function GameScene:addClientEventListener()
    addEvent("CheckLinkGameRes",self, self.onEventCheckLinkGame)
    addEvent("RoomInfoRes",self, self.onEventRoomInfo)
    addEvent("RoomIdRes",self, self.onEventRoomId)
    addEvent("PlayCountRes",self, self.onEventPlayCount)

    addEvent("DessolveRes",self, self.onEventDessolve)
    addEvent("ExitRoomRes",self, self.onEventExitRoom)
    addEvent('JoinRoomRes',self, self.onEventJoinRoom)
    addEvent('BackRoomRes',self, self.onEventBackRoom)
    addEvent('UserArrived',self, self.onEventUserArrived)
    addEvent("GameStart", self, self.onEventGameStart)
    
    addEvent('Relogin',self, self.onEvnetRelogin)
    addEvent('UserOffLine',self, self.onEventUserOffline)
    addEvent("LoginLogicRes",self, self.onEventLoginLogic)
    addEvent("GuestLoginRes", self, self.onEventGuestLogin)
    addEvent("UnameLoginRes", self, self.onEventUnameLogin)
    addEvent("HeartBeatRes", self, self.onEventHeartBeat)
    addEvent("UserReconnectedRes", self, self.onEventReconnect)
    addEvent("UserReadyRes", self, self.onEventUserReady)
    addEvent("LogicFrame", self, self.onEventServerLogicFrame)
end

function GameScene:onEventNetConnect(event)
    Game.showPopLayer('TipsLayer',{"网络连接成功!"})
    Game.popLayer('LoadingLayer')
    --重新登录
    local loginType = UserInfo.getLoginType()
    if loginType == 'uname' then
        local name  = UserInfo.getUserAccount() 
        local pwd   = UserInfo.getUserPwd()
        AuthServiceProxy:getInstance():sendUnameLogin(name,pwd)
    elseif loginType == 'guest' then
        local guestkey = UserInfo.getUserGuestKey()
        AuthServiceProxy:getInstance():sendGuestLogin(guestkey)
    end
end

function GameScene:onEventNetConnectFail(event)
    Game.showPopLayer('TipsLayer',{"网络连接失败!"}) 
    Game.showPopLayer('LoadingLayer')
end

function GameScene:onEventClose(event)
    Game.showPopLayer('LoadingLayer')
end

function GameScene:onEventClosed(event)
    Game.showPopLayer('LoadingLayer')
end

function GameScene:onEvnetRelogin(event)
    self:enterScene('game.Lobby.LobbyScene.LoginScene')
    -- Game.showPopLayer('TipsLayer',{'帐号在其他地方登录!'})
end
-----------------------------------------------------

function GameScene:onEventCheckLinkGame(event)
    local data = event._usedata
    if data.status == Respones.OK then
        print('link game logic success')
    else
        print('link game logic failed')
    end
end

function GameScene:onEventRoomInfo(event)
    local data = event._usedata
    local room_info = data.room_info
    print('room_info: ' .. tostring(room_info))
end

function GameScene:onEventRoomId(event)
    local data = event._usedata
    local room_id = data.room_id
    print('room_id: ' .. tostring(room_id))
end

function GameScene:onEventPlayCount(event)
    local data = event._usedata
    local play_count = data.play_count
    print('play_count: ' .. tostring(play_count))
end

function GameScene:onEventDessolve(event)
    local data = event._usedata
    if data.status == Respones.OK then  --只有房主才能解散房间
        RoomData:getInstance():reset()
        self:popScene()
    else
        Game.showPopLayer('TipsLayer',{"解散房间失败"})
    end
end

function GameScene:onEventExitRoom(event)
    local data = event._usedata
    if data.status == Respones.OK then
        local user_info = data.user_info
        local serverSeat = user_info.seatid
        local brandid = user_info.brandid
        local ishost = user_info.ishost
        local isoffline = user_info.isoffline

        if ishost or isoffline then
            RoomData:getInstance():updatePlayerByUserInfo(user_info)
        else
            RoomData:getInstance():removePlayerBySeatId(serverSeat)
        end
        self:showAllExistUserInfo()
        if tonumber(brandid) == tonumber(UserInfo.getBrandId()) then
            self:popScene()
        end
    else
        Game.showPopLayer('TipsLayer',{"退出房间失败!"})
    end
end

function GameScene:onEventJoinRoom(event)
    local data = event._usedata
    local status = data.status
    if status == Respones.OK then
        RoomData:getInstance():setRoomInfo(data.room_info)
        local users_info = data.users_info
        if next(users_info) then
            for _,info in ipairs(users_info) do
                RoomData:getInstance():createPlayerByUserInfo(info)
            end
        end
    end
    self:showAllExistUserInfo()
    self:onEventJoinRoom()
    self:showHostImag()
end

function GameScene:onEventBackRoom(event)
    local data = event._usedata
    local status = data.status
    if status == Respones.OK then
        RoomData:getInstance():reset()
        RoomData:getInstance():setRoomInfo(data.room_info)
        local users_info = data.users_info
        if next(users_info) then
            for _,info in ipairs(users_info) do
                RoomData:getInstance():createPlayerByUserInfo(info)
            end
        end
        LogicServiceProxy:getInstance():sendReconnect()
    end
    self:showRoomInfo()
    self:showAllExistUserInfo()
    self:showReadyBtn()
    self:showReadyImag()
    self:showHostImag()
end

function GameScene:onEventUserArrived(event)
    local data = event._usedata
    if next(data) then
        RoomData:getInstance():createPlayerByUserInfo(data)
    end
    self:showAllExistUserInfo()
    self:showReadyImag()
    self:showHostImag()
    print('hcc>>onEventUserArrived')
end

function GameScene:onEventUserOffline(event)
    local data = event._usedata
    local user_info = data.user_info
    if next(user_info) then
        RoomData:getInstance():updatePlayerByUserInfo(user_info)
    end
    self:showAllExistUserInfo()
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
    Game.popLayer('LoadingLayer')
    if body then
        if body.status == Respones.OK then
            UserInfo.setUInfo(body.uinfo)
            UserInfo.setUserIsGuest(true)
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
        UserInfo.setUInfo(body.uinfo)
        LogicServiceProxy:getInstance():sendLoginLogicServer()
        Game.showPopLayer('TipsLayer',{"登录成功!"})
    else
        Game.showPopLayer('TipsLayer',{"登录失败,帐号或密码错误!"})
    end
end

function GameScene:onEventHeartBeat(event)
    local body = event._usedata
    if body.status == Respones.OK then
        LogicServiceProxy:getInstance():sendHeartBeat()
    end
end

function GameScene:onEventReconnect(event)
    local body = event._usedata
    if body.status == Respones.OK then
    end
end

function GameScene:onEventUserReady(event)
    local body = event._usedata
    if body.status == Respones.OK then
       local brandid = body.brandid
       local serverSeat = body.seatid
       local user_state = body.user_state
       local player = RoomData:getInstance():getPlayerBySeatId(serverSeat)
       if player then
           if player:getBrandId() == brandid then
                player:setState(user_state)
                self:showReadyBtn()
                self:showReadyImag()
           end
       end
    end
end

function GameScene:onEventGameStart(event)
    local body = event._usedata    
    if next(body.users_state) then
        for serverSeat,state in pairs(body.users_state) do
            local player = RoomData:getInstance():getPlayerBySeatId(serverSeat)
            if player then
                player:setState(state)
            end
        end
    end
    self:showReadyImag()
end

function GameScene:onEventServerLogicFrame(event)
    local body = event._usedata
    if not body then return end
    -- dump(body,"onEventServerLogicFrame",5)
    local frameid = body.frameid
    if not frameid then return end

    local unsync_frames = body.unsync_frames
    -- print("recvSer>>fid: " .. tostring(frameid) .. ' ,syncfid: ' .. self._sync_frameid .. ' ,unsync_size: ' .. tostring(#unsync_frames))
    if frameid < self._sync_frameid then
        return
    end

    --同步自己客户端上一帧逻辑操作, 
    --调整我们的位置; 调成完以后, 客户端同步到的是 sync_frameid
    -- 位置,同步到正确的逻辑位置
    if self._last_frame_opt then
        self:on_sync_last_logic_frame(self.last_frame_opt)
    end
    -- 从sync_frameid + 1 开始 ----> frame.frameid - 1; 
    -- 同步丢失的帧, 所有客户端数据--》同步到 frame.frameid - 1;
    -- 跳到你收到的最新的一个帧之前
    for i =1 , #unsync_frames do
        if unsync_frames[i].frameid >= frameid then
            -- print('hcc<<111')
            break
        end
        if self._sync_frameid < unsync_frames[i].frameid then
            -- dump(unsync_frames[i],'hcc<<222')
            --同步客户端
             self:on_handler_frame_event(unsync_frames[i])
        end
    end
    -- 获取 最后一个操作  frameid 操作,根据这个操作，来处理，来播放动画;
    self._sync_frameid = frameid
    if #unsync_frames > 0 then
        self._last_frame_opt = unsync_frames[#unsync_frames]
        --同步客户端
         self:on_handler_frame_event(self._last_frame_opt)
         -- dump(unsync_frames,'hcc<<333',5)
    else
        self._last_frame_opt = nil
    end
    -- 采集下一个帧的事件，发送给服务器;
    self:capture_player_opts()
end

function GameScene:capture_player_opts()
    local room_id = RoomData:getInstance():getRoomId()
    local seat_id = GameFunction.getSelfSeat()
    local dir = self:getJoyStick():getDir()
    local pix = FLOAT_SCALE
    -- print('hcc>>pos: x : ' .. dir.x .. ' ,y : ' .. dir.y)
    -- print('hcc>>pos: x: ' .. dir.x * pix .. ' ,y: ' .. dir.y* pix)
    local opts_table = {}
    local opts_1 = {
        seatid = seat_id,
        opt_type = 0,
        x = dir.x * pix,
        y = dir.y * pix,
    }

    table.insert(opts_table,opts_1)
    local msg = {
        frameid = self._sync_frameid + 1,
        roomid = room_id,
        seatid = seat_id,
        opts = opts_table,
    }
    LogicServiceProxy:getInstance():sendNextFrame(msg)
end