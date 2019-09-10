local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Default = require("common.Default")
local Common = require("common.Common")
local PerfectInfoLayer = class("PerfectInfoLayer", function()
    return ccui.Layout:create()
end)

local PerfectInfoLayer = class("PerfectInfoLayer", cc.load("mvc").ViewBase)

function PerfectInfoLayer:onEnter()
    EventMgr:registListener(EventType.INFO_SET_USER_DETAIL,self,self.INFO_SET_USER_DETAIL)
    EventMgr:registListener(EventType.UPDATE_SELF_USER_DETAIL,self,self.UPDATE_SELF_USER_DETAIL)
    EventMgr:registListener(EventType.SUB_CL_TASK_REWARD,self,self.SUB_CL_TASK_REWARD)  -- 获取验证马
end

function PerfectInfoLayer:onExit()
    EventMgr:unregistListener(EventType.INFO_SET_USER_DETAIL,self,self.INFO_SET_USER_DETAIL)
    EventMgr:unregistListener(EventType.UPDATE_SELF_USER_DETAIL,self,self.UPDATE_SELF_USER_DETAIL)
    EventMgr:unregistListener(EventType.SUB_CL_TASK_REWARD,self,self.SUB_CL_TASK_REWARD)
end

function PerfectInfoLayer:onCleanup()

end

function PerfectInfoLayer:onCreate(expressCallback, quickCallback)    
    self:initUI()
end

------------------------------------------------------------------UI--------------------------------------------------------------

function PerfectInfoLayer:initUI()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("PerfectInfoLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    
    self.uiPanel_iocertification = ccui.Helper:seekWidgetByName(self.root,"Panel_iocertification")
    self.uiPanel_information = ccui.Helper:seekWidgetByName(self.root,"Panel_information")
    self.Realname = false
    if  self.Realname == false then 
        self.uiPanel_iocertification:setVisible(true)
        self.uiPanel_information:setVisible(false)
    else
        self.uiPanel_iocertification:setVisible(false)
        self.uiPanel_information:setVisible(true)
    end

    -- local bgNode = ccui.Helper:seekWidgetByName(self.root,"Panel_nameInfo")
    -- Common:playPopupAnim(bgNode)

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        -- local callback = function()
        --     require("common.SceneMgr"):switchOperation()
        -- end
        -- Common:playExitAnim(bgNode, callback)
        self:removeFromParent()
    end)

    -- Common:addTouchEventListener(self.root,function() 
    --    -- require("common.SceneMgr"):switchOperation()
    --     self:removeFromParent()
    -- end,true)
    
    --确定
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_tijiao"),function() 
        self:OkInfo() 
    end)


    --姓名
    local uiTextField_name = ccui.Helper:seekWidgetByName(self.root,"TextField_name")

    --身份证
    local uiTextField_number = ccui.Helper:seekWidgetByName(self.root,"TextField_number")



    print("玩家姓名",UserData.User.szRealName,UserData.User.zIDNumber,UserData.User.szPhone)
    if  UserData.User.szRealName ~= "" and UserData.User.zIDNumber ~= ""  then       -- ~=and UserData.User.szEMail ~= "" ""
        self:Showdata()
        self.uiPanel_iocertification:setVisible(false)
        self.uiPanel_information:setVisible(true)
    end
end

function PerfectInfoLayer:Oktime()
  --充值   
        self.text_s:setVisible(true)
        self.time = 60  
        print("玩家姓名3333",UserData.User.szRealName)
        local function onEventRefreshTime(sender,event)
            local date = os.date("*t",os.time())
            self.time = self.time - 1
            self.text_s:setString(string.format("%d秒",self.time))
            self.text_s:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventRefreshTime)))
            if self.time == 0 then  
            self.time = 60 
            self.uiButton_Verification1:setVisible(true)            
            end
        end
        onEventRefreshTime()
end

function PerfectInfoLayer:OkInfo()
    --获取所有输入信息
    self:GetAllInfo()
    if self.Infoname == ""  then
        require("common.MsgBoxLayer"):create(0,nil,"请输入姓名")
        return
    end     
    local is_shenfenz =  self:TestShenfz(self.Infoshenfenzheng)
    print("身份证输入正确",self.Infoshenfenzheng)
    if is_shenfenz == false then
        return
    elseif is_shenfenz == true then
        print("身份证输入正确")
    end 

    self.Infodianhua = 0
    self.Infomailbox = 0
    --require("app.views.MsgBoxLayer"):create(3,"完善成功")
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_USER, NetMsgId.REQ_CL_SET_USER_DETAIL,"wdnsnsnsns",1000,
        UserData.User.userID,16,self.Infoname,20,self.Infoshenfenzheng,32,self.Infomailbox,16,self.Infodianhua)
end

function PerfectInfoLayer:Showdata()
    print("完善资料结果3",UserData.User.szRealName,UserData.User.zIDNumber,UserData.User.szPhone) 
    local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")
    uiText_name:setString(string.format("姓名:%s",UserData.User.szRealName))

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_OK"),function() 
        self:removeFromParent()
     end)

end

function PerfectInfoLayer:INFO_SET_USER_DETAIL(event)--INFO_SET_USER_DETAIL
    local data = event._usedata
    print("完善资料：",UserData.User.szRealName, UserData.User.zIDNumber,UserData.User.szPhone)
    if  UserData.User.szRealName ~= "" and UserData.User.zIDNumber ~= ""  then       --and UserData.User.szPhone ~= ""  ~= ""  and UserData.User.szEMail ~= "" 
        require("common.MsgBoxLayer"):create(0,nil,"完善成功")        
        self:Showdata()
        self.uiPanel_iocertification:setVisible(false)
        self.uiPanel_information:setVisible(true)
    else
        self:Showdata()
        require("common.MsgBoxLayer"):create(0,nil,"完善失败")
    end
      
end

function PerfectInfoLayer:UPDATE_SELF_USER_DETAIL(event)--INFO_SET_USER_DETAIL
    local data = event._usedata
end

function PerfectInfoLayer:SUB_CL_TASK_REWARD( event )
    local data = event._usedata
    if  data  then       -- ~= ""
      if data["ret"] == 0  then 
            print("123454566",data)          
            UserData.User.szPhone = data["Telephone"]
            UserData.User.VerificaCode = data["VerificaCode"]
            self.TimeCode = data["TimeCode"]  
            print("12345",self.Telephone,self.VerificaCode,self.TimeCode)     
            return
      else            
            require("common.MsgBoxLayer"):create(0,nil,"发送手机号失败") 
            return
      end
    else
        require("common.MsgBoxLayer"):create(0,nil,"发送手机号失败")
        return 
    end
--{"ret":-1,"Telephone":"11111111111","VerificaCode":"","TimeCode":""}
end


function PerfectInfoLayer:GetAllInfo()
    --姓名
    local uiTextField_name = ccui.Helper:seekWidgetByName(self.root,"TextField_name")
    self.Infoname = uiTextField_name:getString()

    --身份证
    local uiTextField_number = ccui.Helper:seekWidgetByName(self.root,"TextField_number")
    self.Infoshenfenzheng = uiTextField_number:getString()
end
function PerfectInfoLayer:TestShenfz(shenfz)   
    --检验身份证  
    local num1 = string.len(shenfz);      
    local shenfzLast = string.sub(shenfz,num1,-1);              --[[拿到身份证最后面一位]] 
    local idNumber1 = 0;
    local tableNum = {7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2};  
    print("身份证权和",num1,"取模",shenfz)  
    if num1 == 18 then            
        local id1 = string.sub(shenfz,1,num1-1);                --拿到身份证前17位
        for i=1,#id1 do                                         --获得身份证每位的值      
            local idNumber = string.sub(id1,i,i);                   --将身份证每位的值转换成数字进行计算
            local idNumber2 = tonumber(idNumber);                   --判断前17位是否为数字    
            if idNumber2 then                     
                idNumber1 = idNumber1+(tableNum[i]*idNumber2);  --[[tableNum[i]是获取列表tableNum中设置的系数值,将这17位数字和系数相乘的结果相加]]  
            else
                require("common.MsgBoxLayer"):create(0,nil,"身份证前17位只能为数字")
                return false
            end
        end  
        local tableyu = {["0"]="1",["1"]="0",["2"]="X",["3"]="9",["4"]="8",["5"]="7",["6"]="6",["7"]="5",["8"]="4",["9"]="3",["10"]="2"}; 
        local yushu = idNumber1 % 11;        
        local relaut = tableyu[tostring(yushu)];    
        print("身份证权和",idNumber1,"取模",yushu,"最后一位应为",relaut,"身份证:",shenfz)                
        if relaut == shenfzLast then        --判断身份证最后一位
            return true;        
        else       
            require("common.MsgBoxLayer"):create(0,nil,"身份证输入错误！")
            return false;       
        end;   
    else      
        require("common.MsgBoxLayer"):create(0,nil,"身份证位数应为18位！")
        return false;
    end
end


function PerfectInfoLayer:isRightdianhua(str)
    if  UserData.User.VerificaCode == str  then 
        print("验证码正确")
  else
        require("common.MsgBoxLayer"):create(0,nil,"验证码输入错误！")
     return false
  end 
  return true
end
function PerfectInfoLayer:SUB_CL_SET_USER_DETAIL( event )
    local data = event._usedata
    if data.dwCode == 1000 then
        if  data.dwTaskID == 1004  then
            StaticData.Task[1004].dwModifyDate =2            --标记完成任务状态
            StaticData.Task[1004].isOpen =false
            --            require("app.views.GetPropLayer"):create(0,"福利" ,"string" ,StaticData.Task[1004].reward,"试试看")
            --            print("走了加奖励333")
        end
    end
end

return PerfectInfoLayer  