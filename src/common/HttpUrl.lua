local HttpUrl = {
    POST_URL_GameUserInfo =  "https://graph.qq.com/user/get_user_info?access_token=%s&oauth_consumer_key=%s&openid=%s",
    POST_URL_GameUserSns =  "https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s",                      
    POST_URL_GameUserAuth =  "https://api.weixin.qq.com/sns/auth?access_token=%s&openid=%s",                           
    POST_URL_GameUserToken = "https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s",                        
    POST_URL_GameUserOauth = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code", 
    POST_URL_GameUserLocation = "http://restapi.amap.com/v3/ip?output=JSON&key=ff5a4b284dcd748d8e57f3736dc42b16", --高德地图IP定位
    POST_URL_GameUserDetailLocation = 'https://restapi.amap.com/v3/geocode/regeo?output=JSON&location=%f,%f&key=ff5a4b284dcd748d8e57f3736dc42b16&radius=1000&extensions=base',
    
    POST_URL_GetGameIpAddr = "http://pv.sohu.com/cityjson?ie=utf-8",
    POST_URL_GameUserOrder = "http://pay.hy.qilaigame.com/Pay/CreateOrder.aspx",                                --支付订单
    POST_URL_StandbyServer = "http://download.hy.qilaigame.com/standbyservernew.json",                          --备用服务器列表
    POST_URL_phoneMsg = "http://pay.hy.qilaigame.com/api/Sociaty/GetPhoneVerifica?phoneNum=%s&channelID=%d",    --手机号码修改
    POST_URL_ClientStatistics = "http://management.qilaigame.com/index.php/api/ClientStatistics?Type=%d&ChannelID=%d&UserID=%d&Desc=%s",
    POST_URL_DownShareImg = "http://management.qilaigame.com/index.php/api/CombineImg?CT=%d&CID=%d&TID=%d&ShareImg=%s"
}

return HttpUrl

