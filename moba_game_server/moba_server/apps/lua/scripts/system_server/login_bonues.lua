local Respones 	= require("Respones")
local Stype 	= require("Stype")
local Cmd 		= require("Cmd")
local mysql_game 	= require("database/mysql_game")
local redis_game 	= require("database/redis_game")
local moba_game_config = require("moba_game_config")

local function send_bonues_to_user(uid, bonues_info, ret_handler)
	-- 要更新发放奖励;
	if bonues_info.bonues_time < Utils.timestamp_today() then -- TODO
		if bonues_info.bonues_time >= Utils.timestamp_yesterday() then -- 连续登陆
			bonues_info.days = bonues_info.days + 1
		else -- 重新开始计算
			bonues_info.days = 1
		end	 

		if bonues_info.days > #moba_game_config.login_bonues then 
			bonues_info.days = 1
		end

		bonues_info.status = 0
		bonues_info.bonues_time = Utils.timestamp()
		bonues_info.bonues = moba_game_config.login_bonues[bonues_info.days]
		mysql_game.update_login_bonues(uid, bonues_info, function (err, ret)
		if err then 
				ret_handler(err, nil)
				return
			end

			ret_handler(nil, bonues_info)
		end)	
		return	
	end 

	-- 把登陆奖励信息会给ugame
	ret_handler(nil, bonues_info)
end

-- ret_handler(err, bonues_info)
local function check_login_bonues(uid, ret_handler)
	mysql_game.get_bonues_info(uid, function (err, bonues_info)
		if err then
			ret_handler(err, nil)
			return 
		end
		
		-- 这个用户还是第一次来登陆，
		if bonues_info == nil then
			mysql_game.insert_bonues_info(uid, function (err, ret)
				if err then
					ret_handler(err, nil)
					return
				end
				check_login_bonues(uid, ret_handler)
			end)
			return
		end

		send_bonues_to_user(uid, bonues_info, ret_handler)
	end)
end

-- {stype, ctype, utag, body}
local function recv_login_bonues(s, req)
	local uid = req[3];
	mysql_game.get_bonues_info(uid, function (err, bonues_info)
		if err then
			local msg = {Stype.System, Cmd.eRecvLoginBonuesRes, uid, {
				status = Respones.SystemErr,
			}}

			Session.send_msg(s, msg)
			return
		end
		-- 1 no take , 0 already take 
		if bonues_info == nil or bonues_info.status ~= 0 then
			local msg = {Stype.System, Cmd.eRecvLoginBonuesRes, uid, {
				status = Respones.InvalidOpt,
			}}

			Session.send_msg(s, msg)
			return
		end

		-- 有奖励可以领取
		mysql_game.update_login_bonues_status(uid, function (err, ret) 
			if err then
				local msg = {Stype.System, Cmd.eRecvLoginBonuesRes, uid, {
					status = Respones.SystemErr,
				}}
				Session.send_msg(s, msg)
				return
			end

			-- 更新数据的uchip
			mysql_game.add_chip(uid, bonues_info.bonues, nil)
			-- 更新reids 的uchip
			redis_game.add_chip_inredis(uid, bonues_info.bonues);

			local msg = {Stype.System, Cmd.eRecvLoginBonuesRes, uid, {
				status = Respones.OK,
			}}
			Session.send_msg(s, msg)
		end)
	end)

end

local login_bonues = {
	check_login_bonues = check_login_bonues,
	recv_login_bonues = recv_login_bonues,
}

return login_bonues