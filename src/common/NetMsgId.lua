local NetMsgId = {  
    
    --系统
    MDM_KN_COMMAND = 0,                         --心跳主消息
    SUB_KN_DETECT_SOCKET = 1,                   --心跳
    SUB_KN_NETWORK_DELAY = 3,                   --网络延迟
    
    --登陆服登陆消息
    MDM_GP_LOGON = 10,                          --登陆服主消息
    SUB_GP_LOGON_ACCOUNTS = 100,                --登陆服登录
    SUB_GP_LOGON_SUCCESS = 1000,                --登录服登录成功
    SUB_GP_LOGON_FAILURE = 1001,                --登录登录服失败

    --逻辑服登陆消息
    MDM_CL_LOGON = 100,                         --逻辑主消息
    REQ_CL_LOGON_USERID = 1000,                 --逻辑服登录
    SUB_CL_LOGON_SUCCESS = 10000,               --登陆逻辑服成功
    SUB_CL_LOGON_ERROR = 10001,                 --登陆逻辑服失败
        
    --逻辑服大厅消息
    MDM_CL_HALL                     = 110,      --大厅消息
    REQ_CL_SERVER_TIME              = 1100,     --请求服务器时间
    REQ_CL_GOLDROOM_CONFIG          = 1101,     --请求金币房间配置
    SUB_CL_GOLDROOM_CONFIG          = 11013,    --金币房配置
    SUB_CL_GOLDROOM_CONFIG_END      = 11014,    --金币房配置结束
    REQ_CL_USER_LOCK_SERVER         = 1102,     --请求用户锁定房间
    REQ_CL_GAME_SERVER              = 1103,     --请求游戏房间结构
    REQ_CL_GAME_SERVER_BY_ID        = 1104,     --请求游戏房间ByServerID
    REQ_CL_FRIENDROOM_CONFIG        = 1105,     --请求好友房配置
    REQ_CL_NOTICE_CONFIG            = 1106,     --请求公告配置
    REQ_CL_RECHARGE_CONFIG          = 1107,     --请求充值配置
    REQ_CL_SHARE_CONFIG             = 1108,     --请求分享配置
    REQ_CL_NEW_SHARE_CONFIG2        = 1116,     --请求新分享配置
    REQ_SHARE                       = 1118,     --请求最新分享配置
    RET_SHARE                       = 11018,    --返回最新分享配置
    REQ_CL_PROP_CONFIG              = 1109,     --请求道具配置
    REQ_CS_SUB_GET_PROXY_RECORD     = 1711,     --请求公会房记录
    RET_SC_SUB_GET_PROXY_RECORD     = 17011,    --公会房记录返回       
    REQ_CS_SUB_GET_PROXY_TABLE      = 1714,     --请求代开房信息 
    RET_SC_SUB_GET_PROXY_TABLE      = 17014,    --请求代开房信息结果
    SUB_CL_SERVER_TIME              = 11000,    --服务器时间
    SUB_CL_USER_LOCK_SERVER         = 11002,    --用户锁定房间
    SUB_CL_GAME_SERVER              = 11003,    --游戏房间结构
    SUB_CL_GAME_SERVER_ERROR        = 11004,    --游戏房间未开启
    SUB_CL_FRIENDROOM_CONFIG        = 11005,    --好友房配置
    SUB_CL_FRIENDROOM_CONFIG_END    = 11006,    --好友房配置结束
    SUB_CL_NOTICE_CONFIG            = 11007,    --公告配置
    SUB_CL_RECHARGE_CONFIG          = 11008,    --充值配置
    SUB_CL_SHARE_CONFIG             = 11009,    --分享配置
    SUB_CL_PROP_CONFIG              = 11010,    --道具配置
    REQ_CL_USER_GAMEING             = 1110,                            --请求用户锁定房间（是否在游戏中）
    SUB_CL_USER_GAMEING             = 11011,                           --用户锁定房间（是否在游戏中）
    REQ_CL_BROADCAST_CONFIG         = 1111,                            --请求广播配置
    SUB_CL_BROADCAST_CONFIG         = 11012,                           --请求广播配置
    --商城
    MDM_CL_MALL                     = 130,                            --商城消息
    REQ_CL_RECHARGE_CONFIG          = 1300,                           --请求充值配置
    REQ_CL_MALL_CONFIG              = 1301,                           --请求商城配置
    REQ_CL_MALL_BUYGOODS            = 1302,                           --请求购买商品
    SUB_CL_RECHARGE_CONFIG          = 13000,                          --充值配置
    SUB_CL_MALL_CONFIG              = 13001,                          --商城配置
    SUB_CL_MALL_BUYGOODS            = 13002,                          --购买商品
    
    --逻辑服用户消息
    MDM_CL_USER                     = 120,                             --用户消息
    REQ_CL_USER_PROP                = 1202,                            --请求用户道具   
    
    REQ_CL_USER_DETAIL              = 1203,                            --请求用户资料
    REQ_CL_SET_USER_DETAIL          = 1204,                            --设置用户资料
    SUB_CL_USER_DETAIL              = 12003,                           --用户资料
    SUB_CL_SET_USER_DETAIL          = 12004,                           --设置用户资料    

    SUB_CL_USER_PROP                = 12002,                           --用户道具
    REQ_CL_USER_INFO                = 1200,                            --请求用户信息
    SUB_CL_USER_INFO                = 12000,                           --用户信息
    
    --充值
    MDM_CL_RECHARGE                 = 130,                            --商城消息
    REQ_CL_RECHARGE_CONFIG          = 1300,                           --请求充值配置
    REQ_CL_RECHARGE_RECORD          = 1301,                           --请求充值记录
    SUB_CL_RECHARGE_CONFIG          = 13000,                          --充值配置
    SUB_CL_RECHARGE_RECORD          = 13001,                          --充值记录
    
    --商城
    MDM_CL_MALL                     = 140,                             --商城消息
    REQ_CL_MALL_CONFIG              = 1400,                            --请求商城配置
    REQ_CL_MALL_BUYGOODS            = 1401,                            --请求购买商品
    SUB_CL_MALL_CONFIG              = 14000,                           --商城配置
    SUB_CL_MALL_BUYGOODS            = 14001,                           --购买商品
    REQ_MALL_CONFIG                 = 1402,                            --请求商场配置
    RET_MALL_CONFIG                 = 14002,                           --返回商城配置
    REQ_MALL_FIRST_CHARGE_RECORD    = 1403,                            --请求首冲记录
    RET_MALL_FIRST_CHARGE_RECORD    = 14003,                           --返回首冲记录

    REQ_MALL_EXCHANGE_REDENVELOPE	= 1404,							   --请求兑换红包
    RET_MALL_EXCHANGE_REDENVELOPE	= 14004,						   --返回兑换红包   

    REQ_GET_MALL_LOG				= 1405,						       --请求商场记录
    RET_GET_MALL_LOG				= 14005,						   --/返回商场记录
    RET_GET_MALL_LOG_FINISH			= 14006,						   --返回商场记录完成

    --福利
    MDM_CL_ACTIVE                   = 150,                             --福利活动
    SUB_CS_GETACTIVECONFIG          = 1500,                            --获取福利配置
    SUB_SC_ACTIVECONFIG             = 1501,                            --配置反馈
    SUB_CS_GETACTIVERECORD          = 1502,                            --获取福利数据    
    SUB_SC_ACTIVERECORD             = 1503,                            --福利数据反馈
    SUB_CS_ACTIONACTIVE             = 1503,                            --福利相应操作
    SUB_SC_ACTIONRESULT             = 1504,                            --操作反馈

    --签到
    MDM_CL_CHECKIN                  = 151,                             --签到消息
    SUB_CL_GETCHECKIN               = 1500,                            --签到操作
    SUB_CL_CHECKINRECORD            = 1501,                            --本人签到数据
    SUB_CL_CHECKRESULT              = 1502,                            --签到操作返回
    SUB_CL_FLUSHCHECKRECORD         = 1503,                            --签到 补签 领奖后的数据刷新

    REQ_CL_SETTINT_CONFIG           = 1107,                            --请求设置配置
    SUB_CL_SETTING_CONFIG           = 11008 ,                          --设置配置
    
    --邮箱
    MDM_CL_MAIL                     = 190,                              --邮件消息
    REQ_GET_MAIL_LIST               = 1901,                             --获取邮件列表
    RET_GET_MAIL_LIST               = 19001,                            --返回邮件列表
    REQ_DEL_MAIL                    = 1902,                             --删除邮件
    RET_DEL_MAIL                    = 19002,                            --返回删除邮件
    REQ_READ_MAIL                   = 1904,                             --读取邮件
    RET_READ_MAIL                   = 19004,                            --返回读取邮件

    REQ_HAVE_UNREAD_MAIL			= 1905,						        --是否有未读邮件
    RET_HAVE_UNREAD_MAIL			= 19005,						    --返回是否有未读邮件

    --公会
    MDM_CL_GUILD                        = 210,                         --公会消息
    REQ_GET_GUILD_INFO                  = 2101,                        --获取公会信息
    RET_GET_GUILD_INFO                  = 21001,                       --返回公会信息
    REQ_JOIN_GUILD                      = 2102,                        --加入公会
    RET_JOIN_GUILD                      = 21002,                       --返回加入公会结果
    REQ_SETTINGS_GUILD                  = 2103,                        --设置公会
    RET_SETTINGS_GUILD                  = 21003,                       --返回设置公会
    REQ_GET_GUILD_MEMBER                = 2104,                        --获取公会成员列表
    RET_GET_GUILD_MEMBER                = 21004,                       --返回公会成员列表
    REQ_GET_GUILD_INFO_BY_GUILDID       = 2105,                        --根据公会ID获取公会信息
    RET_GET_GUILD_INFO_BY_GUILDID       = 21005,                       --根据公会ID返回公会信息    
    REQ_UPDATE_GUILD                    = 2106,                        --请求修改公会公告
    RET_UPDATE_GUILD                    = 21006,                       --返回修改公会公告
    
    MDM_CL_CLUB                         = 160,                             --亲友圈
--    REQ_GET_CLUB_LIST                   = 1600,                            --获取亲友圈列表
--    RET_GET_CLUB_LIST                   = 16000,                           --返回亲友圈列表
    RET_GET_CLUB_MEMBER_FINISH          = 16039,                              --返回亲友圈成员列表完成
    RET_GET_CLUB_MEMBER_EX_FINISH       = 16040,                            --返回亲友圈以外可以导入的成员	                            
    REQ_JOIN_CLUB                       = 1601,                            --请求加入亲友圈
    RET_JOIN_CLUB                       = 16001,                           --返回加入亲友圈
    REQ_QUIT_CLUB                       = 1602,                            --请求退出亲友圈
    RET_QUIT_CLUB                       = 16002,                           --返回退出亲友圈
    REQ_REMOVE_CLUB_MEMBER              = 1603,                            --请求删除亲友圈成员
    RET_REMOVE_CLUB_MEMBER              = 16003,                           --返回删除亲友圈成员
    REQ_GET_CLUB_TABLE                  = 1604,                            --获取亲友圈桌子列表
    RET_GET_CLUB_TABLE                  = 16004,                           --返回亲友圈桌子列表
    REQ_GET_CLUB_MEMBER                 = 1605,                            --获取亲友圈成员列表
    RET_GET_CLUB_MEMBER                 = 16005,                           --返回亲友圈成员列表
--    REQ_SETTINGS_CLUB                   = 1606,                            --设置亲友圈桌子信息
--    RET_SETTINGS_CLUB                   = 16006,                           --返回设置亲友圈桌子信息
    --REQ_CREATE_CLUB                     = 1607,                            --请求创建亲友圈
    RET_CREATE_CLUB                     = 16007,                           --返回创建亲友圈
--    REQ_REFRESH_CLUB                    = 1608,                            --请求刷新亲友圈
--    RET_REFRESH_CLUB                    = 16008,                           --返回刷新亲友圈
    REQ_REMOVE_CLUB                     = 1609,                            --请求解散亲友圈
    RET_REMOVE_CLUB                     = 16009,                           --返回解散亲友圈
    REQ_GET_CLUB_LIST_BY_USERID         = 1610,                            --获取他人的创建的亲友圈列表
    RET_GET_CLUB_LIST_BY_USERID         = 16010,                           --返回他人的创建的亲友圈列表
    REQ_CLUB_CHECK_LIST                 = 1611,                            --获取申请加入亲友圈列表--亲友圈部长可见
    RET_CLUB_CHECK_LIST                 = 16011,                           --返回申请加入亲友圈列表--亲友圈部长可见
    REQ_CLUB_CHECK_RESULT               = 1612,                            --请求同意或拒绝加入亲友圈
    RET_CLUB_CHECK_RESULT               = 16012,                           --返回同意或拒绝加入亲友圈
    --REQ_GET_CLUB_LIST2					= 1620,                            --获取亲友圈列表
    --RET_GET_CLUB_LIST2					= 16020,						   --返回亲友圈列表
    --REQ_REFRESH_CLUB2					= 1621,							   --请求刷新亲友圈
    --RET_REFRESH_CLUB2					= 16021,						   --返回刷新亲友圈
    --REQ_SETTINGS_CLUB2                  = 1622,                            --设置亲友圈桌子信息
    --RET_SETTINGS_CLUB2                  = 16022,                           --返回设置亲友圈桌子信息
    -- REQ_CREATE_CLUB2                    = 1623,                            --请求创建亲友圈
    --RET_CREATE_CLUB2                    = 16023,                           --返回创建亲友圈
    --RET_ADDED_CLUB                      = 16029,                           --被添加亲友圈
    RET_GET_CLUB_LIST_FAIL              = 16032,                           --请求亲友圈列表返回(没有亲友圈情况)
    REQ_GET_CLUB_MEMBER_EX              = 1633,                            --获取亲友圈以外可以导入的成员
    RET_GET_CLUB_MEMBER_EX              = 16033,                           --返回亲友圈以外可以导入的成员
    RET_GET_CLUB_MEMBER_EX_FAIL         = 16034,                           --返回没有亲友圈以外可以导入的成员
    REQ_ADD_CLUB_MEMBER                 = 1628,                            --添加亲友圈成员
    RET_ADD_CLUB_MEMBER                 = 16028,                           --返回添加亲友圈成员
    RET_REFUSE_JOIN_CLUB                = 16030,                           --被拒绝加入亲友圈

    RET_ADD_CLUB_TABLE                  = 16024,                           --添加亲友圈牌桌
    RET_UPDATE_CLUB_TABLE               = 16025,                           --刷新亲友圈牌桌
    RET_DEL_CLUB_TABLE                  = 16026,                           --删除亲友圈牌桌
    -- RET_UPDATE_CLUB_INFO                = 16027,                           --更新亲友圈信息
    RET_DELED_CLUB                      = 16031,                           --被删除亲友圈

    REQ_ADD_CLUB_REFRESH_MEMBER         = 1635,                            --添加亲友圈及时刷新列表
    REQ_DEL_CLUB_REFRESH_MEMBER         = 1636,                            --删除亲友圈及时刷新列表
    REQ_DISBAND_CLUB_TABLE              = 1637,                            --请求解散亲友圈桌子
    RET_DISBAND_CLUB_TABLE              = 16037,                           --返回解散亲友圈桌子结果

    REQ_UPDATE_CLUB_ROOMCARD            = 1638,                            --获取亲友圈的房卡
    RET_UPDATE_CLUB_ROOMCARD            = 16038,                           --返回亲友圈的房卡
    REQ_GET_CLUB_APPLICATION_RECORD     = 1643,                            --获取亲友圈的申请记录
    RET_GET_CLUB_APPLICATION_RECORD     = 16043,                           --返回亲友圈的申请记录
    REQ_FIND_CLUB_MEMBER                = 1641,                            --查看亲友圈成员列表
    RET_FIND_CLUB_MEMBER                = 16041,                           --查看亲友圈成员列表
    
    REQ_GET_CLUB_OPERATE_RECORD         = 1651,                            --获取俱乐部操作记录
    RET_GET_CLUB_OPERATE_RECORD         = 16051,                           --返回俱乐部操作记录
    RET_GET_CLUB_OPERATE_RECORD_FINISH  = 16056,                           --返回俱乐部操作记录
    
    REQ_CREATE_CLUB3                    = 2214,                            --请求创建亲友圈
    RET_CREATE_CLUB3                    = 22014,                           --返回创建亲友圈
    REQ_SETTINGS_CLUB3                  = 2215,                            --设置亲友圈桌子信息
    RET_SETTINGS_CLUB3                  = 22015,                           --返回设置亲友圈桌子信息
    RET_UPDATE_CLUB_INFO3               = 22016,                           --更新亲友圈信息
    RET_ADDED_CLUB3                     = 22017,                           --被添加亲友圈
    REQ_GET_CLUB_LIST3                  = 2218,                            --获取亲友圈列表
    RET_GET_CLUB_LIST3                  = 22018,                           --返回亲友圈列表
    REQ_REFRESH_CLUB3                   = 2219,                            --请求刷新亲友圈
    RET_REFRESH_CLUB3                   = 22019,                           --返回刷新亲友圈
    REQ_SETTINGS_CLUB_PLAY              = 2220,                            --请求设置亲友圈玩法
    RET_SETTINGS_CLUB_PLAY              = 22020,                           --返回设置亲友圈玩法
    REQ_REFRESH_CLUB_PLAY3              = 2221,                            --请求刷新俱乐部玩法
    RET_REFRESH_CLUB_PLAY               = 22021,                           --返回刷新俱乐部玩法
    
    REQ_GET_CLUB_MEMBER_FATIGUE_RECORD  = 1677,                            --请求俱乐部成员疲劳值记录
    RET_GET_CLUB_MEMBER_FATIGUE_RECORD  = 16077,                           --返回俱乐部成员疲劳值记录
    RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH = 16078,                     --返回俱乐部成员疲劳值记录
    REQ_UPDATE_CLUB_PLAYER_INFO         = 1695,                            --刷新用户所在俱乐部信息
    RET_UPDATE_CLUB_PLAYER_INFO         = 16095,                           --刷新用户所在俱乐部信息

    REQ_GET_CLUB_ONLINE_MEMBER          = 35,                              --获取亲友圈在线成员
    RET_GET_CLUB_ONLINE_MEMBER          = 138,                             --获取亲友圈在线成员
    RET_GET_CLUB_ONLINE_MEMBER_FINISH   = 139,                             --获取亲友圈在线成员完成

    REQ_INVITE_CLUB_ONLINE_MEMBER       = 36,                              --邀请亲友圈在线成员

    REQ_FIND_CLUB_ONLINE_MEMBER         = 37,                              --查找亲友圈在线成员
    RET_FIND_CLUB_ONLINE_MEMBER         = 140,                             --查找亲友圈在线成员

    --统计
    REQ_GET_CLUB_STATISTICS_MYSELF      = 1657,                             --//请求亲友圈统计个人

    RET_GET_CLUB_STATISTICS_MYSELF		= 16057,						--返回亲友圈统计个人

    REQ_GET_CLUB_STATISTICS_MEMBER		= 1658,						--请求亲友圈统计成员

    RET_GET_CLUB_STATISTICS_MEMBER		    =16058,						--返回亲友圈统计成员
    RET_GET_CLUB_STATISTICS_MEMBER_FINISH	= 16059,						--返回亲友圈统计成员
    RET_GET_CLUB_STATISTICS_MYSELF_FINISH = 16073,
    REQ_GET_CLUB_STATISTICS					=1660,						--请求亲友圈统计成员
    RET_GET_CLUB_STATISTICS					=16061,						--返回亲友圈统计成员
    RET_GET_CLUB_STATISTICS_FINISH			=16062,						--返回亲友圈统计成员
    REQ_GET_CLUB_STATISTICS_ALL				=1663,						--请求亲友圈统计成员
    RET_GET_CLUB_STATISTICS_ALL				=16063,						--返回亲友圈统计成员

    -----------------------------------------
    --合伙人
    REQ_SETTINGS_CLUB_MEMBER            = 1664,                            --请求修改亲友圈成员
    RET_SETTINGS_CLUB_MEMBER            = 16064,                           --返回修改亲友圈成员
    REQ_SETTINGS_CLUB_PARTNER           = 1665,                            --请求修改亲友圈合伙人
    RET_SETTINGS_CLUB_PARTNER           = 16065,                           --返回修改亲友圈合伙人
    REQ_GET_CLUB_PARTNER                = 1666,                            --请求亲友圈合伙人
    RET_GET_CLUB_PARTNER                = 16066,                           --返回亲友圈合伙人
    RET_GET_CLUB_PARTNER_FINISH         = 16067,                           --返回亲友圈合伙人
    REQ_GET_CLUB_PARTNER_MEMBER         = 1668,                            --请求亲友圈合伙人成员
    RET_GET_CLUB_PARTNER_MEMBER         = 16068,                           --返回亲友圈合伙人成员
    RET_GET_CLUB_PARTNER_MEMBER_FINISH  = 16069,                           --返回亲友圈合伙人成员
    REQ_GET_CLUB_NOT_PARTNER_MEMBER     = 1670,                            --请求亲友圈非合伙人成员
    RET_GET_CLUB_NOT_PARTNER_MEMBER     = 16070,                           --返回亲友圈非合伙人成员
    RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH = 16071,                        --返回亲友圈非合伙人成员
    REQ_FIND_CLUB_NOT_PARTNER_MEMBER    = 1672,                            --请求查找亲友圈非合伙人成员
    RET_FIND_CLUB_NOT_PARTNER_MEMBER    = 16072,                           --返回查找亲友圈非合伙人成员
    REQ_FIND_CLUB_PARTNER_MEMBER        = 1674,                            --查找亲友圈合伙人成员
    RET_FIND_CLUB_PARTNER_MEMBER        = 16074,                           --返回查找亲友圈合伙人成员

    REQ_GET_CLUB_FATIGUE_STATISTICS     = 2212,                            --亲友圈疲劳值统计
    RET_GET_CLUB_FATIGUE_STATISTICS     = 22012,                           --亲友圈疲劳值统计
    REQ_GET_CLUB_FATIGUE_DETAILS        = 2213,                            --亲友圈疲劳值详情
    RET_GET_CLUB_FATIGUE_DETAILS        = 22013,                           --亲友圈疲劳值详情


    --竞技
    MDM_CL_SPORTS                       = 180,                              --竞技
    REQ_SPORTS_LIST                     = 1801,                             --请求竞技列表
    RET_SPORTS_LIST                     = 18001,                            --返回竞技列表
    REQ_SPORTS_LIST_BY_USER_ID          = 1802,                             --请求已参与的竞技列表
    RET_SPORTS_LIST_BY_USER_ID          = 18002,                            --返回已参与的竞技列表   
    REQ_SPORTS_CREATE                   = 1803,                             --发起比赛
    RET_SPORTS_CREATE                   = 18003,                            --发起比赛结果  
    REQ_SPORTS_CONFIG_LIST              = 1804,                             --请求比赛配置
    RET_SPORTS_CONFIG_LIST              = 18004,                            --返回比赛配置
    REQ_SPORTS_STATE              		= 1805,                             --请求比赛状态
    RET_SPORTS_STATE              		= 18005,                            --返回比赛状态  
    REQ_SPORTS_USER_LIST                = 1806,                             --请求竞技场用户胜次
    RET_SPORTS_USER_LIST                = 18006,                            --返回竞技场用户胜次
    REQ_SPORTS_REWARD_SELF_WINNING      = 1807,                             --请求用户比赛结束并且胜利的竞技场
    RET_SPORTS_REWARD_SELF_WINNING      = 18007,                            --返回用户比赛结束并且胜利的竞技场  
    REQ_SPORTS_REWARD_SELF_JOIN         = 1808,                             --请求用户比赛结束并且参与的竞技场
    RET_SPORTS_REWARD_SELF_JOIN         = 18008,                            --请求用户比赛结束并且参与的竞技场  
    REQ_SPORTS_REWARD_ALL               = 1809,                             --请求比赛结束并的竞技场
    RET_SPORTS_REWARD_ALL               = 18009,                            --返回比赛结束并的竞技场
    --游戏服登陆消息
    MDM_GR_LOGON = 1,                           --游戏登陆主消息
    REQ_GR_LOGON_USERID = 1,                    --游戏服登陆
    SUB_GR_LOGON_SUCCESS = 100,                  --游戏服登陆成功
    SUB_GR_LOGON_ERROR = 101,                   --游戏服登陆错误
    
    --游戏服用户消息
    MDM_GR_USER = 2,                    --游戏服用户主消息
    REQ_GR_USER_LEFT_GAME_REQ = 1,      --请求离开游戏
    REQ_GR_USER_CONTINUE_GAME = 2,      --请求继续游戏
    REQ_GR_USER_CONTINUE_REDENVELOPE = 9, --请求继续游戏
    REQ_GR_USER_GET_GAMEINFO = 3,       --请求玩家信息
    REQ_GR_USER_SEND_CHAT = 4,          --请求聊天
    REQ_GR_USER_SET_POSITION = 5,       --玩家位置
	RET_GR_USER_SET_POSITION = 38,  	--刷新定位
    SUB_GR_GAME_START = 100,            --游戏开始
    SUB_GR_USER_STATUS = 101,           --用户状态
    SUB_GR_USER_GOLD = 102,             --用户金币
    SUB_GR_SIT_FAILED = 103,            --坐下失败
    SUB_GR_PLAYER_INFO = 104,           --玩家信息
    SUB_GR_MATCH_TABLE_ING = 134,       --正在匹配
    SUB_GR_MATCH_TABLE_FAILED = 135,    --匹配桌子失败
    REQ_GR_USER_CONTINUE_GAME_BY_SPORTS = 7,    --竞技场继续游戏
    REQ_GR_USER_CONTINUE_CLUB = 8,                                   --请求继续游戏，亲友圈
    REQ_GR_USER_CONTINUE_CLUB_FAILD = 137,                                 --请求亲友圈继续游戏失败
    
    REQ_GET_REDENVELOPE_REWARD	= 41 ,								--发送领取红包券奖励 BYTE类型 0金币 1红包券
    
    RET_GET_REDENVELOPE_REWARD	= 141 ,								--接收领取红包券奖励

    --游戏服逻辑消息
    REQ_GR_MATCH_GOLD_TABLE = 30,   --金币场匹配
    REQ_MATCH_REDENVELOPE_TABLE = 40,--红包场匹配
    REQ_GR_MATCH_SPORTS_TABLE = 31, --竞技场匹配
    MDM_GF_GAME = 100,   --游戏消息
    MDM_GF_FRAME = 101,  --框架消息
    SUB_GF_CONFIG = 102, --双王扯胡子跟省
    SUB_GF_SCENE = 101,     --断线重连
    SUB_GR_LOGON_USERID = 2,        --I D 登录
    SUB_GR_USER_COME = 100,         --用户进入
    REQ_GR_CREATE_TABLE             = 32,                                  --请求创建桌子
    SUB_C_GAME_CONFIG = 100,    --是否翻省（永州扯胡子）
    REQ_CS_GAME_CONFIG  = 100,                                              --请求游戏配置
    RET_SC_GAME_CONFIG  = 1001,                                              --返回游戏配置
    SUB_GR_USER_READY = 130,   --服务器广播用户准备
    REQ_GR_USER_READY = 12,   --准备消息
    SUB_S_JUSHOUZUOSHENG			= 140,	--举手做声
    SUB_C_JUSHOUZUOSHENG            = 6 , --举手做声
    SUB_GR_CREATE_TABLE_FAILED = 124,   --创建桌子失败
    SUB_GR_USER_ENTER=120,   --桌子申请成功
    REQ_GR_JOIN_TABLE=33,       --加入桌子
    REQ_CL_GAME_SERVER_BY_ID = 1104,    --请求游戏房间，加入时用的
    SUB_GR_JOIN_TABLE_FAILED = 125, --加入桌子失败
    REQ_GR_DISMISS_TABLE=22,       --解散桌子
    SUB_GR_DISMISS_TABLE_SUCCESS=128,  --解散桌子
    SUB_GR_DISMISS_TABLE=126,     --别人发起解散桌子
    SUB_GR_DISMISS_TABLE_STATE = 133,--解散
    REQ_GR_DISMISS_TABLE_REPLY=23,        --请求解散返回
    REQ_GR_DISMISS_TABLE_BY_OWNER = 26,     --房主请求解散房间
    REQ_GR_LEAVE_TABLE_USER       = 27,       --请求离开
    SUB_GR_DISMISS_TABLE_REPLY=127,                --拒绝解散
    SUB_GR_DISMISS_TABLE_STATE = 133,           --请求解散桌子
    SUB_GR_USER_LEAVE   =121,         --用户离开
    SUB_GR_USER_OFFLINE =122,           --用户离线  
    SUB_GR_USER_CONNECT=123,        --用户连接
    SUB_GR_TABLE_STATUS = 131,   --好友房开始信息
    SUB_S_OPERATE_SCORE = 116,      --动作加分
    SUB_GR_USER_KICK_TABLE= 10,             --房主踢人
    SUB_GR_USER_START_TABLE=    11,             --房主开始游戏
    REQ_GR_USER_READY=25  ,               --游戏准备
    SUB_GR_USER_STATISTICS=132,                 --用户统计
    SUB_GR_GAME_STATISTICS = 136,            --游戏统计
    SUB_GR_LOGON_FINISH = 102,      --登陆完成
    SUB_GR_USER_LEFT_GAME_REQ = 4,  --离开游戏
    SUB_GR_USER_CONTINUE_GAME = 2,  --重新排队
    REQ_GR_USER_NEXT_GAME = 6,      --下一局    
    REQ_GR_USER_PLAYER_INFO=4,     --获取玩家信息
    SUB_GF_USER_EXPRESSION = 500,   --用户表情
    SUB_GF_USER_EFFECTS		=		503, -- //用户特效
    SUB_GF_USER_VOICE = 501,       --语音

    SUB_GF_USER_VOICE_YAYA	= 504, --//丫丫用户语音

    REQ_GR_USER_PLAYER_INFO = 3,  --用户聊天接收
    SUB_GR_SEND_CHAT = 105,  --用户聊天转发
    SUB_S_SELECT_PIAOFEN = 160,
    SUB_C_SELECT_PIAOFEN = 8,
    SUB_S_GAME_START = 100,         --游戏开始
    SUB_S_USER_TI_CARD = 101,       --用户提牌
    SUB_S_USER_PAO_CARD = 102,      --用户跑牌
    SUB_S_USER_WEI_CARD = 103,      --用户偎牌
    SUB_S_USER_PENG_CARD = 104,     --用户碰牌
    SUB_S_USER_CHI_CARD = 105,      --用户吃牌
    SUB_S_OPERATE_NOTIFY = 106,     --操作提示
    SUB_S_OUT_CARD_NOTIFY = 107,    --出牌提示
    SUB_S_OUT_CARD = 108,       --用户出牌
    SUB_S_SEND_CARD = 109,      --发牌命令
    SUB_S_GAME_END = 110,       --游戏结束
    SUB_S_WD = 111,         --王钓表现
    SUB_S_WC = 112,         --王闯表现       
    SUB_S_SISHOU = 113,         --死守表现
    SUB_S_3WC = 114,        --三王闯表现
    SUB_S_CLIENTERROR = 120,    --打牌错误
    SUB_S_GAME_START_REPLAY = 130,  --游戏开始_回放
    SUB_S_SITFAILED = 230,          --坐下失败
    SUB_C_OUT_CARD = 1,             --出牌命令
    SUB_C_OPERATE_CARD = 2,         --操作扑克
    SUB_C_CONTINUE_CARD = 3,        --继续命令
    SUB_S_ADD_BASE  =   114,                                    --游戏加倍
    SUB_S_ADD_BASE_VIEW =115,                           --  游戏加倍表现
    SUB_S_GAME_END_TIPS =116,                           --游戏轮数结算
    SUB_S_GAME_END_END  =117,                           --游戏结束
    SUB_S_GAME_GOON =118,                               --游戏新一轮
    SUB_C_ADD_BASE= 4,                                          --加倍命令
    SUB_C_TRUSTEESHIT=10,                                  --托管
    SUB_C_TRUSTEESHIT_NO=11,                            --取消托管
    SUB_S_GAME_START_PDK = 102,             --游戏开始
    SUB_S_USER_PASS_CARD_PDK = 104,         --放弃出牌
    SUB_S_USER_EXPRESSION_PDK = 500,        --用户表情
    SUB_S_WARN_INFO_PDK = 111,              --报警消息
    SUB_S_BOMB_PDK = 112,                   --炸弹消息
    SUB_S_OUT_CARD_PDK = 103,               --出牌消息
    SUB_S_GAME_END_PDK = 175,               --游戏结束消息
    SUB_S_TASK_PDK = 220,                   --任务消息
    SUB_S_RESEDCARD_PDK = 153,              --刷新自己的牌
    SUB_C_TRUSTEESHIT_PDK = 4,              --托管
    SUB_C_OUT_CARD_PDK = 2,                 --出牌命令
    REC_SUB_S_SHOW_CARD_PDK = 110,          --跑得快防作弊发牌

    REC_SUB_S_TIMECOUNT = 157,              --倍数显示
    SUB_PROXY_TABLE_DESC = 502,                             --代开房间描述
    SUB_C_SISHOU = 4,
    SUB_S_GIVE_UP = 139,
    SUB_C_CHONG_FEN = 5,                  --冲分
    SUB_S_CHONG_FEN = 119,                --冲分
    SUB_C_PiaoFen = 8,
    SUB_S_TING_CARD_NOTIFY = 150,       --听牌提示
    SUB_S_TING_CARD_CHANGE_NOTIFY = 151,--听牌提示
    SUB_C_OUT_CARD_TING_CARD = 5,
    
    
    --扑克
    --跑得快飘分
    REC_SUB_S_JIAPIAO	= 155,									--接受漂分
    REC_SUB_C_JIAPIAO	= 17,									--用户加漂 客户端发送

    REC_SUB_S_SHOUT_BANKER	= 156,                              --叫地主
    REC_SUB_S_BANKER_INFO	= 158,                              --地主信息

    REC_SUB_C_PASS_CARD	=3,                                     --放弃出牌
    REC_SUB_C_SHOUT_BANKER	= 17,								--抢地主

    --明牌操作
    SUB_C_MingPaiAction	= 14,
    SUB_S_MINGPAI_RESULT = 155,

    --加票
    SUB_C_JiaPiao				=14,
    SUB_S_JIA_PIAO = 153,
    SUB_S_JIA_PIAO_80 = 154 ,
    --聊天
    REQ_ADD_CLUB_CHAT_REFRESH_MEMBER = 1688, -- //添加聊天及时刷新列表

    REQ_DEL_CLUB_CHAT_REFRESH_MEMBER = 1689, -- //删除聊天及时刷新列表

    REQ_CLUB_CHAT_RECORD = 1680, -- //请求聊天记录

    RET_CLUB_CHAT_RECORD   = 16080,--返回聊天记录

    RET_CLUB_CHAT_RECORD_FINISH = 16081, --返回聊天记录结束

    REQ_CLUB_CHAT_MSG   = 1682,--请求聊天

    RET_CLUB_CHAT_MSG = 16082, --返回聊天
    REQ_CLUB_CHAT_HAVE_READ_MSG = 1683,							--请求标记已读

    RET_CLUB_CHAT_GET_UNREAD_MSG = 16085,							--返回未读消息
    REQ_CLUB_CHAT_GET_UNREAD_MSG = 1685,							--获取未读消息
    RET_CLUB_CHAT_GET_UNREAD_MSG_FAIL =	16086,						--返回未读消息失败

    REQ_CLUB_CHAT_SET_READ_MSG_TIME = 1687,							--设置读取消息的时间

    REQ_GET_CHAT_CONFIG = 1696, -- 获取聊天室配置

    RET_GET_CHAT_CONFIG = 16096, -- 返回聊天室配置


    --麻将
    SUB_S_GAME_SelectZhuang = 100,  --选庄家
    SUB_S_GAME_START_MAJIANG = 101,         --游戏开始
    SUB_S_SpecialCard = 102,        --特殊牌型
    SUB_S_SpecialCard_RESULT = 103, --特殊牌型结果
    SUB_S_OUT_CARD_NOTIFY_MAJIANG = 104,    --出牌提示
    SUB_S_OUT_CARD_RESULT = 105,    --出牌命令
    SUB_S_SEND_CARD_MAJIANG = 106,          --发送麻将
    SUB_S_OPERATE_NOTIFY_MAJIANG = 107,     --操作提示
    SUB_S_OPERATE_RESULT = 108,     --操作命令
    SUB_S_CASTDICE_NOTIFY = 109,    --掷骰操作
    SUB_S_CASTDICE_RESULT = 110,    --掷骰操作
    SUB_S_GAME_END_MAJIANG = 111,           --游戏结束
    SUB_S_OPERATE_HAIDI = 113,      --海底操作
    SUB_S_GAME_END_TIPS_MAJIANG = 115,      --游戏胡牌提示
    SUB_S_GAME_END_GANGSCORE = 116, --杠牌统计
    SUB_S_GAME_SELECT_CF  = 117,    --冲分 
    SUB_S_GAME_SELECT_CFDATA = 118 , --冲分数据
    SUB_S_OPERATE_XIAPAO  = 118 ,   --带下跑(飘分数据)
    SUB_S_SEND_HUN_CARD = 119,      --发送混牌 （王牌）
    SUB_S_SEND_BAOTING_CARD =   120,--发送报听操作
    SUB_S_SEND_BAOTING_ERROR = 121 ,-- 出牌不符合规则
    SUB_S_GAME_GUCHOU = 119,        --箍丑数据 
    SUB_C_OPERATE_HAIDI = 3,        --海底操作
    SUB_C_CASTDICE = 5,             --掷骰操作
    SUB_C_Xihu = 6,                 --小胡操作
    SUB_C_ZhuangStart = 7,          --庄家开始
    SUB_C_SelectCF = 8 ,            --冲分操作
    SUB_C_GuChou = 9 ,              --箍臭操作
    SUB_C_BaoTing = 9 ,             --报听请求玩家
    SUB_C_GAME_CONFIG_HZMJ = 100,   --扎鸟	    
    SUB_S_SEND_HAIDICARD = 117,     --海底
    SUB_S_SEND_PIAO_RESULT  =   119,--长沙麻将飘分结果
    SUB_S_OPERATE_MAIFEN = 118,     --接受买飘数据（宜春麻将） 
    SUB_C_MaiFen = 8 ,              --发送买飘数据（宜春麻将）

    SUB_S_SHANG_LOU = 157, --上楼
        
    SUB_S_BAOTINGOUTCARD = 150 ,    --报听可删牌数据
    SUB_S_ALONE_BAOTINGCARD = 151 , --报听可胡哪些牌数据
    SUB_C_AloneBaoTing  = 12,       --客户端要删牌数据
    
    
    SUB_C_ActionBaoTing  = 13 ,     --客户端监测是否听牌
    SUB_S_ACTION_BAOTINGCARD = 152,  --返回客户端监测听牌数据 

    SUB_S_WCWD	= 153 ,             --通知客户端进行王闯王钓操作   
    SUB_C_WDWC	= 14 ,			    --王钓王闯客户端操作


    --起手胡
    SUB_S_Start_HU = 154,                   --通知客户端必胡操作
    SUB_C_StartHu = 15,                     --客户端进行必胡操作

    SUB_S_GANG_CARD_DATA = 153,		--返回客户端相关牌数据   70专用

    CMD_S_WCWDSendCard = 154 ,      --王闯王钓拿牌
    
        --游戏记录命令码

        MDM_CL_RECORD = 170,                                        --战绩消息

        REQ_CL_MAIN_RECORD = 1700,                                  --请求战绩(大局)
        REQ_CL_SUB_RECORD = 1701,                                   --请求战绩(小局)
        REQ_CL_SUB_REPLAY = 1702,                                   --请求回放(小局)
        REQ_CL_SUB_SHARE_REPLAY = 1703,                             --请求回放(分享)
        REQ_CL_SUB_GET_REPLAY_SHAREID = 1704,                       --请求回放分享ID
        SUB_CL_SUB_GET_REPLAY_BY_SHAREID = 1705,                    --用分享ID请求回放
        REQ_CL_MAIN_RECORD_BY_TYPE = 1715,                          --请求战绩(大局)
        RET_CL_MAIN_RECORD_BY_TYPE0 = 17015,                        --个人普通房战绩(大局)
        RET_CL_MAIN_RECORD_BY_TYPE1 = 17016,                        --个人或群主亲友圈战绩(大局)
        RET_CL_MAIN_RECORD_BY_TYPE2 = 17017,                        --个人所在亲友圈战绩(大局)
        RET_CL_MAIN_RECORD_BY_TYPE3 = 17018,                        --亲友圈战绩(大局)
        RET_CL_MAIN_RECORD_TOTAL_SCORE = 17020,                     --总积分
        
        SUB_CL_MAIN_RECORD = 17000,                                 --战绩(大局)
        SUB_CL_MAIN_RECORD_FINISH = 17001,                          --战绩(大局)结束
        SUB_CL_SUB_RECORD = 17002,                                  --战绩(小局)
        SUB_CL_SUB_RECORD_FINISH = 17003,                           --战绩(小局)结束
        SUB_CL_SUB_REPLAY = 17004,                                  --回放(小局)
        SUB_CL_SUB_REPLAY_NOTFOUNT = 17005,                         --回放(小局)未找到
        SUB_CL_SUB_SHARE_REPLAY_BASE = 17006,                       --回放桌子信息(分享)       
        SUB_CL_SUB_SHARE_REPLAY_DATA = 17007,                       --回放游戏信息(分享)
        SUB_CL_SUB_SHARE_REPLAY_NOTFOUNT = 17008,                   --回放(分享)未找到    
        SUB_CL_SUB_REPLAY_SHAREID = 17009,                          --回放分享ID
        SUB_CL_SUB_REPLAY_SHAREID_ERROR = 17010,                    --回放分享ID分配失败


        REQ_GET_GAME_RECORD	= 1721,					                --新*请求战绩(大局)
        RET_GET_GAME_RECORD	= 17021,					            --返回战绩
        RET_GET_GAME_RECORD_FINISH = 17022,					        --/返回战绩结束
        REQ_LIKE_GAME_RECORD = 1723,				                --点赞战绩
        RET_LIKE_GAME_RECORD = 17023,					            --返回点赞战绩
        REQ_GET_3DAYS_GAME_RECORD =	1724,					        --请求个人三天的战绩总和
        RET_GET_3DAYS_GAME_RECORD =	17024,					        --返回个人三天的战绩总和 
        --双十
        --客户端命令结构
        REC_SUB_C_START_GAME            = 1111,                                    --请求开始游戏
        REC_SUB_C_BETTING               = 1005,                                    --请求押注
        REC_SUB_C_GRAB_BANKER           = 1007,                                    --请求抢庄
        REC_SUB_C_SHOW                  = 1009,                                    --请求亮牌

        --服务器命令结构
        REC_SUB_S_LAND_SCORE            = 101,                             --叫分命令
        REC_SUB_S_GAME_START            = 102,                             --游戏开始
        REC_SUB_S_SEND_CARD             = 103,                             --发牌
        REC_SUB_S_GRAB_BANKER_SEND_CARD = 104,                             --抢庄发牌
        REC_SUB_S_BETTING               = 105,                             --押注
        REC_SUB_S_BETTING_RESULT        = 106,                             --押注结果
        REC_SUB_S_GRAB_BANKER           = 107,                             --抢庄
        REC_SUB_S_GRAB_BANKER_RESULT    = 108,                             --抢庄结果
        REC_SUB_S_SHOW_TIPS             = 109,                             --亮牌提示
        REC_SUB_S_SHOW_RESULT           = 110,                             --亮牌
        REC_SUB_S_GAME_END              = 111,                             --游戏结束
        REC_SUB_S_UPDATE_BANKER         = 112,                             --更新庄家

        RET_GAMES_USER_POSITION         = 999,                             --更新距离
        RET_NOTICE_GAME_START           = 108,                             --通知游戏已开局

        --三打哈
        SDH_SUB_S_GAME_START            = 100,                             --发牌
        SDH_SUB_S_LAND_SCORE            = 101,                             --叫分
        SDH_SUB_S_SEND_CONCEAL          = 102,                             --底牌
        SDH_SUB_S_BACK_CARD             = 103,                             --埋底
        SDH_SUB_S_GAME_PLAY             = 104,                             --定主
        SDH_SUB_S_OUT_CARD              = 105,                             --出牌
        SDH_SUB_S_TURN_BALANCE          = 106,                             --一轮得分统计
        SDH_SUB_S_LOOK_RECARD_CARD      = 107,                             --历史出牌
        SDH_SUB_S_USER_SURRENDER        = 108,                             --投降

        SDH_SUB_C_LAND_SCORE            = 1,                               --叫分
        SDH_SUB_C_BACK_CARD             = 2,                               --埋底
        SDH_SUB_C_CALL_CARD             = 3,                               --叫主
        SDH_SUB_C_OUT_CARD              = 4,                               --出牌
        SDH_SUB_C_GIVEUP_GAME           = 5,                               --投降
        SDH_SUB_C_LOOK_RECORD_CARD      = 6,                               --历史出牌
        
}

return NetMsgId
