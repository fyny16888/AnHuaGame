local Bit = require("common.Bit")

local GameDesc = {}

function GameDesc:getGameDesc(wKindID,data,tableConfig)
    if not (wKindID and data) then
        return ""
    end

    local desc = ""
    if wKindID == 24 then      
       if data.bPlayerCount == 3 then
           desc = desc.."3人房"
       else
           desc = desc.."2人房"
       end    
       if data.bPlayerCount == 2 then
        if data.bDeathCard == 1 then
            desc = desc.."/抽牌20张"
        else
            desc = desc.."/不抽底牌"
        end
      end    
       if data.FanXing.bType == 1 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 2 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 3 then
           desc = desc.."/随醒"
       else
           desc = desc.."/不带醒"
       end      
       if data.bStartTun == 1 then
           desc = desc.."/带底2分"
       end
       if data.bYiWuShi == 1 then
           desc = desc.."/有一五十"
       end          
       if Bit:_and(data.dwMingTang,0x02) ~= 0 then
           desc = desc.."/红黑点"
       end
       if Bit:_and(data.dwMingTang,0x01) ~= 0 then
           desc = desc.."/自摸翻倍"
       end

       desc = desc.."\n"
       if data.bHuType == 1 then
           desc = desc.."/有胡必胡"
       elseif data.bHuType == 2 then
           desc = desc.."/点炮必胡"
       end
       if data.bPiaoHu == 1 then
           desc = desc.."/飘胡"
       end
       if data.bStopCardGo == 1 then
           desc = desc.."/冲招" 
       end    
       if Bit:_and(data.dwMingTang,0x0D00) ~= 0 then
           desc = desc.."/天地海底胡"
       end        
       if data.bDelShowCardHu == 1 then
           desc = desc.."/可胡示众牌"
       end
       if data.bStartBanker == 1 then
           desc = desc.."/首局房主坐庄"
       else
           desc = desc.."/首局随机坐庄"
       end                
    elseif wKindID == 27 then 
        if data.bLaiZiCount == 0 then
            desc = "无王"
        elseif data.bLaiZiCount == 1 then
            desc = "单王"
        elseif data.bLaiZiCount == 2 then
            desc = "双王"
        else
        end           
        if data.bPlayerCount == 2 then
            desc = desc.."/两人场"
        elseif data.bPlayerCount == 3 then
            desc = desc.."/三人场"
        elseif data.bPlayerCount == 4 then
            desc = desc.."/四人场"
        end
        if data.FanXing.bType == 1 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/跟醒"
        else
            desc = desc.."/不翻醒"
        end
        desc = desc.."/6胡起胡，一胡一分，无王必胡"  
        if data.bMaxLost == 300 then
            desc = desc.."/300封顶"
        elseif data.bMaxLost == 600 then
            desc = desc.."/600封顶"
        end
        
    elseif wKindID == 34 then 
        if data.bLaiZiCount == 0 then
            desc = "无王"
        elseif data.bLaiZiCount == 1 then
            desc = "单王"
        elseif data.bLaiZiCount == 2 then
            desc = "双王"
        else
        end             
        if data.bPlayerCount == 3 then
            desc = desc.."/三人场"
        elseif data.bPlayerCount == 2 then
            desc = desc.."/二人场"
        else
            desc = desc.."/四人场"
        end
        if data.FanXing.bType == 1 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/跟醒"
        else
            desc = desc.."/不翻醒"
        end   
        if data.bMaxLost == 300 then
            desc = desc.."/300封顶"
        elseif data.bMaxLost == 600 then
            desc = desc.."/600封顶"
        end
        if data.FanXing.bAddTun ==3 then 
            desc = desc.."/一醒三囤"
        end
    elseif  wKindID == 36 then       
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人(坐醒)"
--        elseif data.bPlayerCount == 2 then
--            desc = desc.."双人竞技"
        end
        desc = desc..string.format("/%d胡起胡",data.bCanHuXi) 
        if data.FanXing.bType == 1 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/跟醒"
        else
            desc = desc.."/不翻醒"
        end
        if data.FanXing.bAddTun == 3 then
            desc = desc.."/一醒三囤"
        elseif data.FanXing.bAddTun == 2 then
            desc = desc.."/双醒"
        elseif data.FanXing.bAddTun == 1 then
            desc = desc.."/单醒"
        else                
        end  
--        if data.bLaiZiCount == 4 then 
--            if data.bLimit == 1 then
--                desc = desc.."/按番限胡"
--            elseif data.bLimit == 2 then
--                desc = desc.."/按王限胡"
--            end
--        end
--        if Bit:_and(data.dwMingTang,0x8) ~= 0 then
--            desc = desc.."/红转点"
--        end
        if Bit:_and(data.dwMingTang,0x10) ~= 0 then
            desc = desc.."/红转朱黑"
        end
        if Bit:_and(data.dwMingTang,0x01) ~= 0 then
            desc = desc.."/带底"
        end
        if data.bMaxLost == 300 then
            desc = desc.."/300封顶"
--        elseif data.bMaxLost == 600 then
--            desc = desc.."/600封顶"
        end
        
    elseif wKindID == 31 then  
           if data.bLaiZiCount == 0 then
           desc = desc.."无王"
       elseif data.bLaiZiCount == 1 then
           desc = desc.."单王"
       elseif data.bLaiZiCount == 2 then
           desc = desc.."双王"
       elseif data.bLaiZiCount == 3 then
           desc = desc.."三王"
       elseif data.bLaiZiCount == 4 then
           desc = desc.."四王"
       end    
       if data.bPlayerCount == 3 then
           desc = desc.."/三人激情"
       elseif data.bPlayerCount == 4 then
           desc = desc.."/四人(坐醒)"
       elseif data.bPlayerCount == 2 then
           desc = desc.."/两人PK"
       end
       if data.bCanHuXi == 15 then
           desc = desc.."/15胡息"
       elseif data.bCanHuXi == 21 then
           desc = desc.."/21胡息"
       else                
       end 
       if data.FanXing.bType == 1 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 2 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 3 then
           desc = desc.."/跟醒"
       else
           desc = desc.."/不翻醒"
       end
       if data.bDeathCard == 1 then
            desc = desc.."/亡牌"            
       end 
       if data.FanXing.bAddTun == 3 then
           desc = desc.."/一醒三囤"
       elseif data.FanXing.bAddTun == 2 then
           desc = desc.."/双醒"
       elseif data.FanXing.bAddTun == 1 then
           desc = desc.."/单醒"
       else                
       end  
       if data.bLaiZiCount == 4 then 
           if data.bLimit == 1 then
               desc = desc.."/按番限胡"
           elseif data.bLimit == 2 then
               desc = desc.."/按王限胡"
           end
       else
           desc = desc.."/有王必须自摸"
       end
       if Bit:_and(data.dwMingTang,0x8) ~= 0 then
           desc = desc.."/红转朱黑"
       end
       -- if Bit:_and(data.dwMingTang,0x01) ~= 0 then
       --     desc = desc.."/带底"
       -- end
       if data.bMaxLost == 300 then
           desc = desc.."/300封顶"
       elseif data.bMaxLost == 600 then
           desc = desc.."/600封顶"
       end
    
    elseif wKindID == 38 then        
       if data.bPlayerCount == 3 then
           desc = desc.."3人房"
       else
           desc = desc.."4人房"
       end
       if data.bCanHuXi == 15 then
           desc = desc.."/15胡息起胡"
       end

       if data.bSettlement == 1 then
           desc = desc.."/三息一囤"
       else            
           desc = desc.."/一息一囤"
       end 
       if data.FanXing.bType == 1 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 2 then
           desc = desc.."/翻醒"
       elseif data.FanXing.bType == 3 then
           desc = desc.."/随醒"
       else
           desc = desc.."/不翻醒"
       end        
       if Bit:_and(data.dwMingTang,0x01) ~= 0 then
           desc = desc.."/自摸翻倍"
       end
       if data.bStartTun == 2 then
           desc = desc.."/底分2分"
       end
       if Bit:_and(data.dwMingTang,0x02) ~= 0 then
           desc = desc.."/红黑点"
       end
       if data.bHuType == 1 then
           desc = desc.."/有胡必胡"
       elseif data.bHuType == 2 then
           desc = desc.."/放炮必胡"
       end

       if data.bStartBanker == 1 then
           desc = desc.."/首局房主坐庄"
       else
           desc = desc.."/首局随机坐庄"
       end
        
    elseif wKindID == 40 then         
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."2人房"
        else
            desc = desc.."4人房"
        end
        if data.bYiWuShi == 1 then
            desc = desc.."/有一五十"
        end  
        if data.bFangPao == 1 then
            desc = desc.."/明偎" 
        else            
            desc = desc.."/暗偎"
        end 
        if data.bDelShowCardHu == 0 then
            desc = desc.."/可胡示众牌" 
        end
        if data.bStartTun == 2 then
            desc = desc.."/底分2分"
        end
        if data.bSettlement == 1 then
            desc = desc.."/三息一囤"
        else            
            desc = desc.."/一息一囤"
        end 
        if data.bCanHuXi == 6 then
            desc = desc.."/6息起胡"
        elseif data.bCanHuXi == 9 then
            desc = desc.."/9息起胡"
        elseif data.bCanHuXi == 15 then
            desc = desc.."/15息起胡"
        end   
        if data.FanXing.bType == 1 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 2 then
            desc = desc.."/翻醒"
        elseif data.FanXing.bType == 3 then
            desc = desc.."/随醒"
        else
            desc = desc.."/不带醒"
        end
        if data.FanXing.bAddTun == 3 then
            desc = desc.."/一垛三囤"   
        elseif data.FanXing.bAddTun == 1 then
            desc = desc.."/一垛一囤"
        else
        end

        desc = desc.."\n"

        if data.bPlayerCount == 2 then
            if data.bDeathCard == 1 then
                desc = desc.."/抽牌20张"
            else
                desc = desc.."/不抽底牌"
            end 
        end
        if data.bPiaoHu == 1 then
            desc = desc.."/飘胡"
        end 
        if data.bStopCardGo == 1 then
            desc = desc.."/冲招"
        end 
        if Bit:_and(data.dwMingTang,0x01) ~= 0 then
            desc = desc.."/自摸翻倍"
        end
        if Bit:_and(data.dwMingTang,0x02) ~= 0 then
            desc = desc.."/红黑点胡"
        end
        if Bit:_and(data.dwMingTang,0x20) ~= 0 then
            desc = desc.."/碰碰胡"
        end
        if Bit:_and(data.dwMingTang,0x40) ~= 0 then
            desc = desc.."/大小字胡"
        end
        if Bit:_and(data.dwMingTang,0x0D00) ~= 0 then
            desc = desc.."/天地海底胡"
        end
        if data.bHuType == 1 then
            desc = desc.."/有胡必胡"
        elseif data.bHuType == 2 then
            desc = desc.."/点炮必胡"
        end
        if data.bCardCount21 == 1 then
            desc = desc.."/21张"
        end 
        if data.bMinLostCell ~= 1   then  
            if data.bMinLost == 0 then 
                desc = desc.."/不限分加倍" 
            elseif data.bMinLost == 10 then   
                desc = desc.."/低于10分加倍" 
            elseif data.bMinLost == 20 then   
                desc = desc.."/低于20分加倍" 
            elseif data.bMinLost == 30 then   
                desc = desc.."/低于30分加倍" 
            end           
        end 

        if data.bMinLostCell == 1   then  
        elseif data.bMinLostCell == 2   then 
            desc = desc.."/翻2倍" 
        elseif data.bMinLostCell == 3   then   
            desc = desc.."/翻3倍"
        elseif data.bMinLostCell == 4   then   
            desc = desc.."/翻4倍"
        end  

        if data.bStartBanker == 1 then
            desc = desc.."/首局房主坐庄"
        else
            desc = desc.."/首局随机坐庄"
        end
    elseif wKindID == 44 then  
       if data.bPlayerCount == 3 then
           desc = desc.."/三人房"
       elseif data.bPlayerCount == 2 then
           desc = desc.."/2人PK"
       else
           desc = desc.."/4人(坐醒)"
       end
       if data.bDeathCard == 1 then
            desc = desc.."/亡牌"
        end
       if data.bCanHuXi == 15 then
           desc = desc.."/15胡息起胡" 
       elseif data.bCanHuXi == 18 then
           desc = desc.."/18胡息起胡"
       elseif data.bCanHuXi == 21 then
           desc = desc.."/21胡息起胡"
       end
       if Bit:_and(data.dwMingTang,0x01) ~= 0 then
           desc = desc.."/15胡带名堂可胡"
       end
       if data.bDeathCard == 1 then
            desc = desc.."/去牌"
       end 
       if data.bMaxLost == 200 then
           desc = desc.."/200封顶"
       elseif data.bMaxLost == 600 then
           desc = desc.."/600封顶"
       end

        
     elseif wKindID == 39 then       
       if data.bPlayerCount == 3 then
           desc = desc.."3人房"
       else
           desc = desc.."2人PK"
       end
        -- if data.FanXing.bType == 3 then
        --     desc = desc.."/跟垛"
        -- else
        --     desc = desc.."/无垛"
        -- end
        if Bit:_and(data.dwMingTang,0x08) ~= 0 then
            desc = desc.."/一点红"
        else
            desc = desc.."/不带一点红"
        end
    --    if data.bFangPao == 1 then
    --        desc = desc.."/有冲招"
    --    else
    --        desc = desc.."/无冲招"
    --    end
       if data.bHuType == 2 then
           desc = desc.."/点炮必胡"
       end
       if data.bCanHuXi == 0 then
           desc = desc.."/无胡"
       else
           desc = desc.."/不带无胡"
       end
       
       if data.bCanJuShouZuoSheng == 1 then
        desc = desc.."/举手做声"
       end
       
       if data.bCanSiShou == 1 then
           desc = desc.."/允许弃牌"
       end

       if data.bStartBanker == 1 then
            desc = desc.."/首局房主坐庄"
        else
            desc = desc.."/首局随机坐庄"
        end
        
    elseif wKindID == 47 then       
        if data.bPlayerCount == 3 then
            desc = desc.."三人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        end
		if data.bPlayerCount == 2 then
        if data.bDeathCard == 1 then
            desc = desc.."/抽牌20张"
        else
            desc = desc.."/不抽底牌"
        end
      end
        -- if data.bCanHuXi == 15 then
        --     desc = desc.."/15胡息起胡"
        -- elseif data.bCanHuXi == 18 then
        --     desc = desc.."/18胡息起胡"
        -- elseif data.bCanHuXi == 21 then
        --     desc = desc.."/21胡息起胡"
        -- end
        if data.bStartTun == 1 then
            desc = desc.."/底分2分"
        elseif data.bStartTun == 2 then
            desc = desc.."/底分3分"
        elseif data.bStartTun == 3 then
            desc = desc.."/底分4分"
        elseif data.bStartTun == 4 then
            desc = desc.."/底分5分"
        else
            desc = desc.."/底分1分"
        end
        if data.bMaxLost == 100 then
            desc = desc.."/100封顶"
        elseif data.bMaxLost == 200  then
            desc = desc.."/200封顶"
        elseif data.bMaxLost == 300  then
            desc = desc.."/300封顶"
        elseif data.bMaxLost == 0  then
            desc = desc.."/不封顶"
        end
        if Bit:_and(data.dwMingTang,0x2000) ~= 0 then
            desc = desc.."/对对胡"
        end
        if data.bStartBanker == 1 then
            desc = desc.."/首局房主坐庄"
        else
            desc = desc.."/首局随机坐庄"
        end
        
    elseif wKindID == 89 then        
      if data.bPlayerCount == 3 then
          desc = desc.."三人"
      elseif data.bPlayerCount == 2 then
          desc = desc.."二人"
      end

      if data.bPlayerCount == 2 then
        if data.bDeathCard == 1 then
            desc = desc.."/抽牌20张"
        else
            desc = desc.."/不抽底牌"
        end
      end
      
        if data.bMaxLost == 0 then
            desc = desc.."/不封顶"
        else
            desc = desc..string.format("/%d封顶",data.bMaxLost)
        end
        
        if data.bStartTun == 1 then
            desc = desc.."/冲1囤"
        elseif data.bStartTun == 2 then
            desc = desc.."/冲2囤"
        elseif data.bStartTun == 3 then
            desc = desc.."/冲3囤"
        else
            desc = desc.."/不冲囤"
        end
        
        if data.bYiWuShi == 1 then
            desc = desc.."/一五十"
        end
        if data.bMingWei == 1 then
            desc = desc.."/明偎"
        end
        if data.b3Long5Kan == 1 then
            desc = desc.."/三垄五坎"
        end
      
        if data.bMingType == 2 then
            desc = desc.."/八十番"
        elseif data.bMingType == 1 then
            desc = desc.."/六八番"
        else
            desc = desc.."/红点黑"
        end
        
        local MingTang_Null                   =0x00000000
        local MingTang_ZiMo                   =0x00000001
        local MingTang_47Hong                 =0x00000002
        local MingTang_HongHu                 =0x00000004
        local MingTang_HongWu                 =0x00000008
        local MingTang_HeiHu                  =0x00000010
        local MingTang_DianHu                 =0x00000020
        local MingTang_TingHu                 =0x00000040
        local MingTang_TianHu                 =0x00000080
        local MingTang_DiHu                   =0x00000100
        local MingTang_HaiDiHu                =0x00000200
        local MingTang_DuiDuiHu               =0x00000400
        local MingTang_DaZiHu                 =0x00000800
        local MingTang_XiaoZiHu               =0x00001000
        local MingTang_ZhenHangHangXing       =0x00002000
        local MingTang_JiaHangHangXing        =0x00004000
        local MingTang_TuanYuanDieJia         =0x00008000
        local MingTang_TuanYuan               =0x00010000
        local MingTang_DanPiao                =0x00020000
        local MingTang_ShuangPiao             =0x00040000
        local MingTang_Yin                    =0x00080000
        local MingTang_Gai                    =0x00100000
        local MingTang_Bei                    =0x00200000
        local MingTang_Shun                   =0x00400000
        local MingTang_ShuaHou                =0x00800000
        local MingTang_ZhuoXiaoSan            =0x01000000
        local MingTang_Max                    =0x80000000
        if Bit:_and(data.dwMingTang,MingTang_Yin) ~= 0 then
            desc = desc.."/印"
        end
        if Bit:_and(data.dwMingTang,MingTang_ZhenHangHangXing) ~= 0 then
            desc = desc.."/行行息"
        end
        if Bit:_and(data.dwMingTang,MingTang_TuanYuan) ~= 0 then
            desc = desc.."/大团圆"
        end
        if Bit:_and(data.dwMingTang,MingTang_47Hong) ~= 0 then
            desc = desc.."/四七红"
        end
        if Bit:_and(data.dwMingTang,MingTang_Shun) ~= 0 then
            desc = desc.."/顺"
        end
        if Bit:_and(data.dwMingTang,MingTang_DanPiao) ~= 0 then
            desc = desc.."/漂"
        end
        if Bit:_and(data.dwMingTang,MingTang_Bei) ~= 0 then
            desc = desc.."/背"
        end
        if Bit:_and(data.dwMingTang,MingTang_Gai) ~= 0 then
            desc = desc.."/盖盖胡"
        end

    elseif wKindID == 88 then        
        if data.bPlayerCount == 3 then
            desc = desc.."三人"
        elseif data.bPlayerCount == 2 then
            desc = desc.."二人"
        end
        if data.bDeathCard == 1 then
            desc = desc.."/亡牌"
        end
        if data.bZhuangFen ~= 1 then
            desc = desc..string.format("/庄分%d",data.bZhuangFen)
        end
        if data.bChongFen == 1 then
            desc = desc.."/充分"
        end
        if Bit:_and(data.dwMingTang,0x00000001) ~= 0 then
            desc = desc.."/自摸加1分"
        end
        if data.bChiNoPeng == 1 then
            desc = desc.."/吃过的牌之后不能碰"
        end

    elseif wKindID == 49 then        
       if data.bPlayerCount == 3 then
           desc = desc.."三人房"
       elseif data.bPlayerCount == 2 then
           desc = desc.."双人竞技"
       end
	   if data.bPlayerCount == 2 then
        if data.bDeathCard == 1 then
            desc = desc.."/抽牌20张"
        else
            desc = desc.."/不抽底牌"
        end
      end
       if data.bStartTun == 1 then
           desc = desc.."/底分2分"
       elseif data.bStartTun == 2 then
           desc = desc.."/底分3分"
       elseif data.bStartTun == 3 then
           desc = desc.."/底分4分"
       elseif data.bStartTun == 4 then
           desc = desc.."/底分5分"
       else
           desc = desc.."/底分1分"
       end
       if data.bMaxLost == 100 then
           desc = desc.."/100封顶"
       elseif data.bMaxLost == 200  then
           desc = desc.."/200封顶"
       elseif data.bMaxLost == 300  then
           desc = desc.."/300封顶"
       elseif data.bMaxLost == 0  then
           desc = desc.."/不封顶"
       end
       if data.bStartBanker == 1 then
           desc = desc.."/首局房主坐庄"
       else
           desc = desc.."/首局随机坐庄"
       end
    elseif wKindID == 68 then         
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end
        if data.bMaType == 1 then
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/窝窝鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一马全中"
        elseif data.bMaType == 6 then
            desc = desc.."/翻几奖几"
        else
            desc = desc.."/摸几奖几"
        end
        if data.bMaCount == 2 then
            desc = desc.."/2个马"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个马"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个马"
        else

        end
        if data.bNiaoType == 1 then
            desc = desc.."/一马一分"
        elseif data.bNiaoType == 2 then
            desc = desc.."/一马两分"
        end
        if data.bQGHu == 1 then
            desc = desc.."/抢杠胡"
        else
            desc = desc.."/无抢杠胡"
        end
        if data.bQGHuJM == 1 then
            desc = desc.."/抢杠胡奖马"
        end
        if data.bHuangZhuangHG == 1 then
            desc = desc.."/黄庄荒杠"
        end
        if data.bJiePao == 1 then
            desc = desc.."/可接炮"
        end
        if data.bQingSH == 1 then
            desc = desc.."/清水胡"
        end
        if data.bQiDui == 1 then
            desc = desc.."/七对"
        end
    elseif wKindID == 25 or wKindID == 76 then        
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        else
            desc = desc.."2人(PK)"
        end
        if data.bStartCard ~= 0 then
            desc = desc.."/首局红桃3必出"
        else
            desc = desc.."/首局红桃3不必出"
        end  
        if data.bBombSeparation == 1 then
            desc = desc.."/炸弹可拆"
        end
        if data.bRed10 == 1 then
            desc = desc.."/红桃10扎鸟"
        end
        if data.b4Add3 == 1 then
            desc = desc.."/可4带3"
        end
        if data.bShowCardCount == 1 then
            desc = desc.."/显示牌数"
        end
        if data.bAbandon == 1 then
            desc = desc.."/放走包赔"
        end
        if data.bCheating == 1 then
            desc = desc.."/防作弊"
        end
        if data.bFalseSpring == 1 then
            desc = desc.."/假春天"
        end
        if data.bAutoOutCard == 1 then
            desc = desc.."/15秒场"
        end
        desc = desc..string.format("/%d张全关",data.bSpringMinCount)
                
    elseif wKindID == 26 or wKindID == 77 then         
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        else
            desc = desc.."2人(PK)"
        end
        if data.bStartCard ~= 0 then
            desc = desc.."/首局红桃3必出"
        else
            desc = desc.."/首局红桃3不必出"
        end  
        if data.bBombSeparation == 1 then
            desc = desc.."/炸弹可拆"
        end
        if data.bRed10 == 1 then
            desc = desc.."/红桃10扎鸟"
        end
        if data.b4Add3 == 1 then
            desc = desc.."/可4带3"
        end
        if data.bShowCardCount == 1 then
            desc = desc.."/显示牌数"
        end
        if data.bAbandon == 1 then
            desc = desc.."/放走包赔"
        end
        if data.bFalseSpring == 1 then
            desc = desc.."/假春天"
        end
        if data.bAutoOutCard == 1 then
            desc = desc.."/15秒场"
        end
        desc = desc..string.format("/%d张全关",data.bSpringMinCount)

    elseif wKindID == 83 then         
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        else
            desc = desc.."2人(PK)"
        end
        if data.bStartCard ~= 0 then
            desc = desc.."/首局黑桃3必出"
        else
            desc = desc.."/首局黑桃3不必出"
        end  
        if data.bBombSeparation == 1 then
            desc = desc.."/炸弹可拆"
        end
        if data.bRed10 == 1 then
            desc = desc.."/红桃10扎鸟"
        elseif data.bRed10 == 2 then
            desc = desc.."/红桃10三分"
        elseif data.bRed10 == 3 then
            desc = desc.."/红桃10五分"
        elseif data.bRed10 == 4 then
            desc = desc.."/红桃10十分"
        end
        if data.b4Add3 == 1 then
            desc = desc.."/可4带3"
        end
        if data.bShowCardCount == 1 then
            desc = desc.."/显示牌数"
        end
        if data.bAbandon == 1 then
            desc = desc.."/放走包赔"
        end
        if data.bFalseSpring == 1 then
            desc = desc.."/假春天"
        end
        if data.bAutoOutCard == 1 then
            desc = desc.."/15秒场"
        end

        if data.b15Or16 == 1 then
            desc = desc.."/16张"
            if data.bThreeBomb == 1 then
                desc = desc.."/三A炸弹"
            end
        elseif data.b15Or16 == 0 then
            desc = desc.."/15张"
            if data.bThreeBomb == 1 then
                desc = desc.."/三K炸弹"
            end
        end
        if data.bMustOutCard == 1 then
            desc = desc.."/不必压"
            if data.bMustNextWarn == 1 then
                desc = desc.."/上家报单不必压"
            end
        end
        if data.bJiaPiao == 0 then
            desc = desc.."/不飘分"
        elseif data.bJiaPiao == 1 then
            desc = desc.."/飘123"
        elseif data.bJiaPiao == 2 then
            desc = desc.."/飘235"
        elseif data.bJiaPiao == 3 then
            desc = desc.."/飘258"
        end

        if data.bThreeEx == 1 then
            desc = desc.."/三带一"
        end
        if data.bSpringMinCount ~= 0 then
            desc = desc..string.format("/%d张全关",data.bSpringMinCount)
        end    
    elseif wKindID == 84 then  
        if data.bPlayWayType == 0 then
            desc = desc.."经典斗地主"
            if data.bBankerWayType == 0 then
                desc = desc.."/1，2，3分"
            else
                desc = desc.."/叫地主"
            end
        elseif data.bPlayWayType == 1 then
            desc = desc.."欢乐斗地主"
        elseif data.bPlayWayType == 2 then
            desc = desc.."癞子斗地主"
        elseif data.bPlayWayType == 3 then
            desc = desc.."湘西斗地主"
        end

        if data.bShoutBankerType == 0 then
            desc = desc.."/随机叫地主"
        else
            desc = desc.."/先出完先叫"
        end

        if data.bBombMaxNum == 3 then
            desc = desc.."/3炸"
        elseif data.bBombMaxNum == 4 then
                desc = desc.."/4炸"
        elseif data.bBombMaxNum == 5 then
                desc = desc.."/5炸"
        end
        if data.bShowCardCount == 1 then
            desc = desc.."/显示牌数"
        end 

    elseif wKindID == 46 then
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end
        if data.bMaType == 1 then
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/窝窝鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一马全中"
        else
            desc = desc.."/摸几奖几"
        end
        if data.bMaCount == 2 then
            desc = desc.."/2个马"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个马"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个马"
        else

        end
        if data.bQGHu == 1 then
            desc = desc.."/抢杠胡"
        else
            desc = desc.."/无抢杠胡"
        end
        if data.bQGHuJM == 1 then
            desc = desc.."/抢杠胡奖马"
        end
        if data.bHuangZhuangHG == 1 then
            desc = desc.."/黄庄荒杠"
        end
        if data.bJiePao == 1 then
            desc = desc.."/可接炮"
        end
        if data.bQingSH == 1 then
            desc = desc.."/清水胡"
        end
        if data.bQiDui == 1 then
            desc = desc.."/七对"
        end
    elseif wKindID == 50 then         
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end

        if data.bNiaoAdd == 1 then
            desc = desc.."/中鸟加分"
        elseif data.bNiaoAdd == 2 then
            desc = desc.."/中鸟翻倍"
        else
        end
        if data.mNiaoCount == 1 then
            desc = desc.."/1个鸟"
        elseif data.mNiaoCount == 2 then
            desc = desc.."/2个鸟"
        elseif data.mNiaoCount == 4 then
            desc = desc.."/4个鸟"
        elseif data.mNiaoCount == 6 then
            desc = desc.."/6个鸟"
        else
        end
        if data.bMQFlag == 1 then
            desc = desc.."/门清"
        end
        if data.mZXFlag == 1 then
            desc = desc.."/庄闲(算分)"
        end
        if data.bJJHFlag == 1 then
            desc = desc.."/假将胡"
        end
        if data.mPFFlag == 1 then
            desc = desc.."/漂分"
        end
    
        if data.bLLSFlag == 1 then
            desc = desc.."/六六顺"
        end
        if data.bQYSFlag == 1 then
            desc = desc.."/缺一色"
        end    
        desc = desc.."\n"
        if data.bWJHFlag == 1 then
            desc = desc.."/无将胡"
        end
        if data.bDSXFlag == 1 then
            desc = desc.."/大四喜"
        end
        if data.mZTSXlag == 1 then
            desc = desc.."/中途四喜"
        end
        if data.bBBGFlag == 1 then
            desc = desc.."/步步高"
        end
        if data.bSTFlag == 1 then
            desc = desc.."/三同"
        end
        if data.bYZHFlag == 1 then
            desc = desc.."/一枝花"
        end

        if data.bWuTong == 0 then
            desc = desc.."/去掉筒子"
        end

    elseif wKindID == 70 then         
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end

        if data.bNiaoAdd == 1 then
            desc = desc.."/中鸟加分"
        elseif data.bNiaoAdd == 2 then
            desc = desc.."/中鸟翻倍"
        else
        end
        if data.mNiaoCount == 1 then
            desc = desc.."/1个鸟"
        elseif data.mNiaoCount == 2 then
            desc = desc.."/2个鸟"
        elseif data.mNiaoCount == 4 then
            desc = desc.."/4个鸟"
        elseif data.mNiaoCount == 6 then
            desc = desc.."/6个鸟"
        else
        end
        if data.mKGNPFlag == 2 then
            desc = desc.."/开杠两张牌"
        elseif data.mKGNPFlag == 4 then
            desc = desc.."/开杠四张牌"
        elseif data.mKGNPFlag == 6 then
            desc = desc.."/开杠六张牌"
        else
        end
        if data.mMaOne == 1 then
            desc = desc.."/一鸟一分"
        elseif data.mMaOne == 2 then
            desc = desc.."/一鸟两分"
        end
        if data.bMQFlag == 1 then
            desc = desc.."/门清"
        end
        if data.mZXFlag == 1 then
            desc = desc.."/庄闲(算分)"
        end
        if data.bJJHFlag == 1 then
            desc = desc.."/假将胡"
        end
        if data.mPFFlag == 1 then
            desc = desc.."/漂分"
        end
        -- desc = desc.."\n"
        if data.bLLSFlag == 1 then
            desc = desc.."/六六顺"
        end
        if data.mZTLLSFlag == 1 then
            desc = desc.."/中途六六顺"
        end
        if data.bQYSFlag == 1 then
            desc = desc.."/缺一色"
        end
        if data.bWJHFlag == 1 then
            desc = desc.."/无将胡"
        end
        if data.bDSXFlag == 1 then
            desc = desc.."/大四喜"
        end
        if data.mZTSXlag == 1 then
            desc = desc.."/中途四喜"
        end
        if data.bBBGFlag == 1 then
            desc = desc.."/步步高"
        end
        if data.bSTFlag == 1 then
            desc = desc.."/三同"
        end
        if data.bYZHFlag == 1 then
            desc = desc.."/一枝花"
        end

        if data.bWuTong == 0 then
            desc = desc.."/去掉筒子"
        end
        
    elseif wKindID == 16 then    
        if data.bPlayerCount == 2 then
            desc = desc.."2人房"       
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人房"
        else
            desc = desc.."4人房"
        end
        desc = desc.."\n"
        if data.bSuccessive == 0 then
            desc = desc.."中庄"
        elseif data.bSuccessive == 1 then 
            desc = desc.."无限连庄"
        end
        if data.bQiangHuPai == 1 then
            desc = desc.."/必胡"
        end
        if data.bLianZhuangSocre == 0 then
            desc = desc.."/中庄相加"
        elseif data.bLianZhuangSocre == 1 then 
            desc = desc.."/中庄乘二"
        end
        
    elseif wKindID == 60 then        
        if data.bPlayerCount == 3 then
            desc = desc.."3人房"
        elseif data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人坐省"
        end
        if data.bDeathCard == 1 then
            desc = desc.."/亡牌"
        end
        if data.bCanHuXi == 15 then
            desc = desc.."/15胡息起胡"
        elseif data.bCanHuXi == 18 then
            desc = desc.."/18胡息起胡"
        elseif data.bCanHuXi == 21 then
            desc = desc.."/21胡息起胡"
        end
        if data.bStartTun == 1 then
            desc = desc.."/倒一"
        elseif data.bStartTun == 3 then
            desc = desc.."/倒三"
        elseif data.bStartTun == 5 then
            desc = desc.."/倒五"
        elseif data.bStartTun == 8 then
            desc = desc.."/倒八"
        end

    elseif wKindID == 67 then         
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        else
            desc = desc.."4人"
        end
        if data.bWuTong == 0 then
            desc = desc.."/没有筒子"
        end 
        if data.bMaType == 1 then
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/窝窝鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一马全中"
        else
            desc = desc.."/摸几奖几"
        end
        if data.bMaCount == 2 then
            desc = desc.."/2个马"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个马"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个马"
        else

        end
        if data.bNiaoType == 1 then
            desc = desc.."/一马一分"
        elseif data.bNiaoType == 2 then
            desc = desc.."/一马两分"
        end
        if data.bQGHu == 1 then
            desc = desc.."/抢杠胡"
        else
            desc = desc.."/无抢杠胡"
        end
        if data.bQGHuJM == 1 then
            desc = desc.."/抢杠胡奖马"
        end
        if data.bHuangZhuangHG == 1 then
            desc = desc.."/黄庄荒杠"
        end
        if data.bJiePao == 1 then
            desc = desc.."/可接炮"
        end
        if data.bQingSH == 1 then
            desc = desc.."/两片"
        end  
        if data.bQingYiSe == 1 then
            desc = desc.."/清一色"
        end 
        if data.bQiXiaoDui == 1 then
            desc = desc.."/七对"
        end 
        if data.bPPHu == 1 then
            desc = desc.."/碰碰胡"
        end 
        if data.mJFCount == 100 then
            desc = desc.."/100封顶"
        elseif data.mJFCount == 200  then
            desc = desc.."/200封顶"
        elseif data.mJFCount == 300  then
            desc = desc.."/300封顶"
        elseif data.mJFCount == 0  then
            desc = desc.."/不封顶"
        end

    elseif wKindID == 69 then
      if data.bPaPo == 0 then
        desc = desc.."不爬坡"
      elseif data.bPaPo == 1 then
        desc = desc.."爬坡"
      elseif data.bPaPo == 2 then
        desc = desc.."持续爬坡"
      end

      if data.bStartTun == 1 then
         desc = desc.."/加一囤"
      end
      
      desc = desc..string.format("/%d胡起胡",data.bCanHuXi) 
    elseif wKindID == 78 then
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
            if data.bWuTong == 0 then                       --//1.有筒  0.无筒 (默认有筒)
                desc = desc.."/无筒"
            elseif data.bWuTong == 1 then
                desc = desc.."/有筒"
            end
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人"
        end

        if data.mLaiZiCount == 1 then
            desc = desc.."/四红中"
        elseif data.mLaiZiCount == 2 then
            desc = desc.."/八红中"
        else
            desc = desc.."/无红中"
        end
        if data.bJiePao == 0 then
            desc = desc.."/不接炮"
        elseif data.bJiePao == 1 then
            desc = desc.."/接炮"
        end
        if data.bQiDui == 1 then
            desc = desc.."/七对"
        end
        if data.bQGHu == 0 then             -- //是否抢杠胡  0.不抢杠胡 1.抢杠胡
            desc = desc.."/不抢杠胡"
        elseif data.bQGHu == 1 then
            desc = desc.."/抢杠胡"
        end        
        if data.bQGHuBaoPei == 1 then       -- //是否抢杠胡包赔  1.不包赔（勾选）  0.包赔（不勾选）  默认包赔
            desc = desc.."/不包赔"
        elseif data.bQGHuBaoPei == 0 then
            desc = desc.."/抢杠胡包赔"
        end
        if data.bJiaPiao == 0 then          -- //充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
            desc = desc.."/不充"
        elseif data.bJiaPiao == 1 then
            desc = desc.."/充一"
        elseif data.bJiaPiao == 2 then
            desc = desc.."/充二"
        elseif data.bJiaPiao == 3 then
            desc = desc.."/选一次充"
        elseif data.bJiaPiao == 4 then
            desc = desc.."/每小局充分"
        end
        if data.bMaType == 1 then           -- //1.一五九、2.抓鸟、3.一码全中、4.不奖码 5.摸几奖几、6.翻几奖几
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/抓鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一码全中"
        elseif data.bMaType == 4 then
            desc = desc.."/不奖码"
        elseif data.bMaType == 5 then
            desc = desc.."摸几奖几"        
        elseif data.bMaType == 6 then
            desc = desc.."/翻几奖几"
        end
        if data.bMaCount == 2 then                    --//马数 2、4、6
            desc = desc.."/2个码"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个码"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个码"
        end
        if data.mNiaoType == 1 then                  --//1.一鸟一分、2.一鸟两分
            desc = desc.."/一鸟一分"
        elseif data.mNiaoType == 2 then
            desc = desc.."/一鸟两分"
        end
        if data.mHongNiao == 0 then                        --//1.无红中加一码、0.无	
            --desc = desc.."/不接炮"
        elseif data.mHongNiao == 1 then
            desc = desc.."/红中加一码"
        end

    elseif wKindID == 79 then
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
            if data.bWuTong == 0 then                       --//1.有筒  0.无筒 (默认有筒)
                desc = desc.."/无筒"
            elseif data.bWuTong == 1 then
                desc = desc.."/有筒"
            end 
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人"
        end

        if data.mLaiZiCount == 1 then
            desc = desc.."/有红中"
        elseif data.mLaiZiCount == 2 then
            desc = desc.."/八红中"
        else
            desc = desc.."/无红中"
        end
        if data.bJiePao == 0 then
            desc = desc.."/不接炮"
        elseif data.bJiePao == 1 then
            desc = desc.."/接炮"
        end
        if data.bQiDui == 1 then
            desc = desc.."/七对"
        end
        -- if data.bQGHu == 0 then             -- //是否抢杠胡  0.不抢杠胡 1.抢杠胡
        --     desc = desc.."不抢杠胡"
        -- elseif data.bQGHu == 1 then
        --     desc = desc.."抢杠胡"
        -- end        
        -- if data.bQGHuBaoPei == 0 then       -- //是否抢杠胡包赔  1.不包赔（勾选）  0.包赔（不勾选）  默认包赔
        --     desc = desc.."抢杠胡包赔"
        -- elseif data.bQGHuBaoPei == 1 then
        --     desc = desc.."不包赔"
        -- end
        if data.bJiaPiao == 0 then          -- //充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
            desc = desc.."/不充"
        elseif data.bJiaPiao == 1 then
            desc = desc.."/充一"
        elseif data.bJiaPiao == 2 then
            desc = desc.."/充二"
        elseif data.bJiaPiao == 3 then
            desc = desc.."/选一次充"
        elseif data.bJiaPiao == 4 then
            desc = desc.."/每小局充分"
        end
        if data.bMaType == 1 then           -- //1.一五九、2.抓鸟、3.一码全中、4.不奖码 5.摸几奖几、6.翻几奖几
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/抓鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一码全中"
        elseif data.bMaType == 4 then
            desc = desc.."/不奖码"
        elseif data.bMaType == 5 then
            desc = desc.."/摸几奖几"        
        elseif data.bMaType == 6 then
            desc = desc.."/翻几奖几"
        end
        if data.bMaCount == 2 then                    --//马数 2、4、6
            desc = desc.."/2个码"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个码"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个码"
        end
        if data.mNiaoType == 1 then                  --//1.一鸟一分、2.一鸟两分
            desc = desc.."/一鸟一分"
        elseif data.mNiaoType == 2 then
            desc = desc.."/一鸟两分"
        end
        if data.mHongNiao == 0 then                        --//1.无红中加一码、0.无	
            --desc = desc.."/不接炮"
        elseif data.mHongNiao == 1 then
            desc = desc.."/红中加一码"
        end
        if data.bZhuangXian == 0 then                        --//1.无红中加一码、0.无	
            --desc = desc.."/不接炮"
        elseif data.bZhuangXian == 1 then
            desc = desc.."/庄闲"
        end

    elseif wKindID == 80 then
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
            if data.bWuTong == 0 then                       --//1.有筒  0.无筒 (默认有筒)
                desc = desc.."/无筒"
            elseif data.bWuTong == 1 then
                desc = desc.."/有筒"
            end  
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人"
        end

        if data.mZXFlag == 1 then
            desc = desc.."/庄闲算分"
        end
        if data.bBBGFlag == 1 then
            desc = desc.."/步步高"
        end
        if data.bSTFlag == 1 then
            desc = desc.."/三同"
        end
        if data.bXHBJPFlag == 1 then
            desc = desc.."/小胡不接炮"
        end

        if data.bYZHFlag == 1 then
            desc = desc.."/一枝花"
        end
        if data.mZTSXlag == 1 then
            desc = desc.."/中途四喜"
        end
        if data.mJTYNFlag == 1 then
            desc = desc.."/金童玉女"
        end
        if data.mZTLLSFlag == 1 then
            desc = desc.."/中途六六顺"
        end

        if data.bMQFlag == 1 then
            desc = desc.."/门清"
        end
        if data.bJJHFlag == 1 then
            desc = desc.."/假将胡"
        end    
   
        if data.bJiaPiao == 0 then          -- //充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
            desc = desc.."/不飘"
        elseif data.bJiaPiao == 1 then
            desc = desc.."/飘一分"
        elseif data.bJiaPiao == 2 then
            desc = desc.."/飘二分"
        elseif data.bJiaPiao == 3 then
            desc = desc.."/选一次飘"
        elseif data.bJiaPiao == 4 then
            desc = desc.."/每小局飘分"
        end
        if data.bMaType == 1 then           -- //1.一五九、2.抓鸟、3.中鸟翻倍、4.不奖码 5.摸几奖几、6.翻几奖几
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/抓鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/中鸟翻倍"
        elseif data.bMaType == 4 then
            desc = desc.."/不奖码"
        elseif data.bMaType == 5 then
            desc = desc.."/摸几奖几"        
        elseif data.bMaType == 6 then
            desc = desc.."/翻几奖几"
        end
        if data.bMaCount == 2 then                    --//马数 2、4、6
            desc = desc.."/2个码"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个码"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个码"
        end
        if data.mNiaoType == 1 then                  --//1.一鸟一分、2.一鸟两分
            desc = desc.."/一鸟一分"
        elseif data.mNiaoType == 2 then
            desc = desc.."/一鸟两分"
        end

        if data.mKGNPFlag == 2 then                        --//1.无红中加一码、0.无	
            desc = desc.."/开2杠"
        elseif data.mKGNPFlag == 4 then
            desc = desc.."/开4杠"
        elseif data.mKGNPFlag == 6 then
            desc = desc.."/开6杠"
        end

    elseif wKindID == 81 then
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
            if data.bWuTong == 0 then                       --//1.有筒  0.无筒 (默认有筒)
                desc = desc.."/无筒"
            elseif data.bWuTong == 1 then
                desc = desc.."/有筒"
            end 
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人"
        end

        -- if data.mLaiZiCount == 1 then
        --     desc = desc.."/有红中"
        -- elseif data.mLaiZiCount == 2 then
        --     desc = desc.."/八红中"
        -- else
        --     desc = desc.."/无红中"
        -- end
        if data.bJiePao == 0 then
            desc = desc.."/不接炮"
        elseif data.bJiePao == 1 then
            desc = desc.."/接炮"
        end
        if data.bQiDui == 1 then
            desc = desc.."/七对"
        end
        if data.bJiaPiao == 0 then          -- //充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
            desc = desc.."/不充"
        elseif data.bJiaPiao == 1 then
            desc = desc.."/充一"
        elseif data.bJiaPiao == 2 then
            desc = desc.."/充二"
        elseif data.bJiaPiao == 3 then
            desc = desc.."/选一次充"
        elseif data.bJiaPiao == 4 then
            desc = desc.."/每小局充分"
        end
        if data.bMaType == 1 then           -- //1.一五九、2.抓鸟、3.一码全中、4.不奖码 5.摸几奖几、6.翻几奖几
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/抓鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一码全中"
        elseif data.bMaType == 4 then
            desc = desc.."/不奖码"
        elseif data.bMaType == 5 then
            desc = desc.."/摸几奖几"        
        elseif data.bMaType == 6 then
            desc = desc.."/翻几奖几"
        end
        if data.bMaCount == 2 then                    --//马数 2、4、6
            desc = desc.."/2个码"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个码"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个码"
        end
        -- if data.mNiaoType == 1 then                  --//1.一鸟一分、2.一鸟两分
        --     desc = desc.."/一鸟一分"
        -- elseif data.mNiaoType == 2 then
        --     desc = desc.."/一鸟两分"
        -- end
        -- if data.mHongNiao == 0 then                        --//1.无红中加一码、0.无	
        --     desc = desc.."/不接炮"
        -- elseif data.mHongNiao == 1 then
        --     desc = desc.."/红中加一码"
        -- end
        if data.bZhuangXian == 0 then                        --//1.无红中加一码、0.无	
            --desc = desc.."/不接炮"
        elseif data.bZhuangXian == 1 then
            desc = desc.."/庄闲"
        end

    elseif wKindID == 82 then
        if data.bPlayerCount == 2 then
            desc = desc.."双人竞技"
            if data.bWuTong == 0 then                       --//1.有筒  0.无筒 (默认有筒)
                desc = desc.."/无筒"
            elseif data.bWuTong == 1 then
                desc = desc.."/有筒"
            end  
        elseif data.bPlayerCount == 3 then
            desc = desc.."3人"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人"
        end

        if data.mBanBanHu == 1 then
            desc = desc.."/板板胡"
        end
        if data.mJiangJiangHu == 1 then
            desc = desc.."/将将胡"
        end
        if data.bQiDui == 1 then
            desc = desc.."/七对"
        end
        if data.bHaoHuaQiDui == 1 then
            desc = desc.."/豪华七对玩法"
        end

        if data.bGangShangPao == 1 then
            desc = desc.."/杠上炮"
        end
        if data.bGangShangHua == 1 then
            desc = desc.."/杠上花"
        end
        if data.bQingYiSe == 1 then
            desc = desc.."/清一色"
        end
        if data.bPPHu == 1 then
            desc = desc.."/碰碰胡"
        end

        if data.bHuangZhuangHG == 1 then
            desc = desc.."/荒庄荒杠"
        end
        if data.bSiHZHu == 1 then
            desc = desc.."/四红中胡牌"
        end  
        if data.bQGHu == 1 then
            desc = desc.."/抢杠胡"
        end    
        if data.bJiePao == 1 then
            desc = desc.."/点炮胡"
        end      

        if data.mLaiZiCount == 1 then
            desc = desc.."/红中癞子"
        end 

        if data.bJiaPiao == 0 then          -- //充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
            desc = desc.."/不充"
        elseif data.bJiaPiao == 1 then
            desc = desc.."/充一分"
        elseif data.bJiaPiao == 2 then
            desc = desc.."/充二分"
        elseif data.bJiaPiao == 3 then
            desc = desc.."/选一次充"
        elseif data.bJiaPiao == 4 then
            desc = desc.."/每小局充分"
        end
        if data.bMaType == 1 then           -- 1.一五九、2.抓鸟加分、3.一马全中、4.抓鸟翻倍 0.不奖马   
            desc = desc.."/一五九"
        elseif data.bMaType == 2 then
            desc = desc.."/抓鸟"
        elseif data.bMaType == 3 then
            desc = desc.."/一码全中"
        elseif data.bMaType == 7 then
            desc = desc.."/抓鸟翻倍"
        elseif data.bMaType == 0 then
            desc = desc.."/不奖马"        
        elseif data.bMaType == 6 then
            desc = desc.."/翻几奖几"
        end
        if data.bMaCount == 1 then  
            desc = desc.."/1个码"      
        elseif data.bMaCount == 2 then                    --//马数 2、4、6
            desc = desc.."/2个码"
        elseif data.bMaCount == 4 then
            desc = desc.."/4个码"
        elseif data.bMaCount == 6 then
            desc = desc.."/6个码"
        end
        if data.mNiaoType == 1 then                  --//1.一鸟一分、2.一鸟两分
            desc = desc.."/一鸟一分"
        elseif data.mNiaoType == 2 then
            desc = desc.."/一鸟两分"
        end

        if data.mHongNiao == 1 then                        --//1.无红中加一码、0.无	
            desc = desc.."/无红中加一码"
        end

    elseif wKindID == 85 then
        if data.bPlayerCount == 3 then
            desc = desc.."3人"
        elseif data.bPlayerCount == 4 then
            desc = desc.."4人"
        end

        if data.bPlayWayType == 0 then
            desc = desc.."/经典玩法"
        elseif data.bPlayWayType == 1 then
            desc = desc.."/双进单出"
        end

        if data.bSettleType == 0 then
            desc = desc.."/默认结算"
        elseif data.bSettleType == 1 then
            desc = desc.."/等级结算"
        end

        if data.bSurrenderStage == 2 then
            desc = desc.."/投降2档"
        elseif data.bSurrenderStage == 3 then
            desc = desc.."/投降3档"
        elseif data.bSurrenderStage == 4 then
            desc = desc.."/投降4档"
        end

        if data.bNoLookCard then
            desc = desc .. "/不允许查牌"
        else
            desc = desc .. "/允许查牌"
        end

        if data.bRemoveKingCard then
            desc = desc.."/去掉大小王"
        end

        if data.bRemoveSixCard then
            desc = desc.."/去掉6"
        end

        if data.b35Down then
            desc = desc.."/35分以下不能投降"
        end

        if data.bDaDaoEnd then
            desc = desc.."/大倒结束"
        end
    end
    
    if tableConfig ~= nil and tableConfig.nTableType ~= nil and tableConfig.nTableType == TableType_ClubRoom and tableConfig.dwClubID ~= 0 then
        if wKindID == 69 then
          desc = string.format("(亲友圈[%d])\n",tableConfig.dwClubID)..desc
        else
          desc = string.format("(亲友圈[%d])",tableConfig.dwClubID)..desc
        end
    end
    return desc
end

return GameDesc