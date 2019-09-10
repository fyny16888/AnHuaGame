local Bit = require("common.Bit")

local GameConfig = {}

--解析参数
function GameConfig:getParameter(wKindID,luaFunc)
    local data = {}
    local haveReadByte = 0
    if wKindID == 15 then
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3    
        haveReadByte = 1    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节

    elseif wKindID == 16 then    
        data.bPlayerCount = luaFunc:readRecvByte()                    --参与游戏的人数 3+1模式为3
        data.bSuccessive = luaFunc:readRecvByte()                     --连庄选项 0：二连、1：无限连庄
        data.bQiangHuPai = luaFunc:readRecvByte()                     --制胡牌 0：不强胡、1：强胡
        data.bLianZhuangSocre = luaFunc:readRecvByte()                --连庄计分 0：加一倍、1：翻倍*2  
        haveReadByte = 4    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 21 then
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3    
        haveReadByte = 2    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 22 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些  
        haveReadByte = 20    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 23 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些   
        haveReadByte = 20    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 24 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0:自摸 1:能胡必胡 2:放炮必胡
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些      
        data.bPiaoHu = luaFunc:readRecvByte()
        data.bHongHu = luaFunc:readRecvByte()   
        data.bDelShowCardHu = luaFunc:readRecvByte()
        data.bDeathCard = luaFunc:readRecvByte()                    --亡牌
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        data.bStopCardGo = luaFunc:readRecvByte()                    --随机庄
        haveReadByte = 26    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 33 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件 
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 27 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        haveReadByte = 20    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 34 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bDouble = luaFunc:readRecvByte()                       --单双省
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 35 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 16 then    
        data.bPlayerCount = luaFunc:readRecvByte()                    --参与游戏的人数 3+1模式为3
        data.bSuccessive = luaFunc:readRecvByte()                     --连庄选项 0：二连、1：无限连庄
        data.bQiangHuPai = luaFunc:readRecvByte()                     --制胡牌 0：不强胡、1：强胡
        data.bLianZhuangSocre = luaFunc:readRecvByte()                --连庄计分 0：加一倍、1：翻倍*2  
        haveReadByte = 4    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
         
    elseif wKindID == 20 or wKindID == 19  or wKindID == 18 or wKindID == 17  then       
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3     
        data.bTotalHuXi = luaFunc:readRecvByte() 
        data.bMaxLost = luaFunc:readRecvWORD()
        haveReadByte = 5    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 25 or wKindID == 26 or wKindID == 76 or wKindID == 77 then 
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数   
        data.bStartCard = luaFunc:readRecvByte()            --首局出牌要求        0无要求  其他的对应的其他的牌
        data.bBombSeparation = luaFunc:readRecvByte()       --炸弹是否可拆      0不可拆  1可拆
        data.bRed10 = luaFunc:readRecvByte()                --红桃十可扎鸟      0无      1有
        data.b4Add3 = luaFunc:readRecvByte()                --是否可4带3        0无      1有
        data.bShowCardCount = luaFunc:readRecvByte()        --是否显示牌数量    0无      1有
        data.bSpringMinCount = luaFunc:readRecvByte()       --春天的最小数量    默认最多  否则其他值
        data.bAbandon = luaFunc:readRecvByte()              --放跑包赔           0无       1有     
        data.bCheating = luaFunc:readRecvByte()         --防作弊           0无       1有     
        data.bFalseSpring = luaFunc:readRecvByte()         --假春天            0无      1有   
        data.bAutoOutCard = luaFunc:readRecvByte()         --是否15s自动出牌   0无      1有
        haveReadByte = 11    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
    elseif wKindID == 83 then 
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数   
        data.bStartCard = luaFunc:readRecvByte()            --首局出牌要求        0无要求  其他的对应的其他的牌
        data.bBombSeparation = luaFunc:readRecvByte()       --炸弹是否可拆      0不可拆  1可拆
        data.bRed10 = luaFunc:readRecvByte()                --红桃十可扎鸟      0无      1有 2三分 3五分 4十分
        data.b4Add3 = luaFunc:readRecvByte()                --是否可4带3        0无      1有
        data.bShowCardCount = luaFunc:readRecvByte()        --是否显示牌数量    0无      1有
        data.bSpringMinCount = luaFunc:readRecvByte()       --春天的最小数量    默认最多  否则其他值
        data.bAbandon = luaFunc:readRecvByte()              --放跑包赔           0无       1有     
        data.bCheating = luaFunc:readRecvByte()         --防作弊           0无       1有     
        data.bFalseSpring = luaFunc:readRecvByte()         --假春天            0无      1有   
        data.bAutoOutCard = luaFunc:readRecvByte()         --是否15s自动出牌 自动出牌时间   0无      1有  >0 <256 s
        data.bThreeBomb = luaFunc:readRecvByte()           --AAA或KKK炸弹      0否      1是
        data.b15Or16 = luaFunc:readRecvByte()              --15张或16张        015张    116张
        data.bMustOutCard = luaFunc:readRecvByte()         --是否必出          0必出    1不必出
        data.bMustNextWarn = luaFunc:readRecvByte()        --下家报单是否必出  0必出    1不必出
        data.bJiaPiao = luaFunc:readRecvByte()             --0不漂分 1漂123 2漂235 3漂258
        data.bThreeEx = luaFunc:readRecvByte()             --0 三带两张  1 三带1张、2张、不带
        haveReadByte = 17    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
    elseif wKindID == 84 then 
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数   
        data.bShowCardCount = luaFunc:readRecvByte()          --是否显示牌数量    0无      1有
        data.bCheating = luaFunc:readRecvByte()          --防止坐标			0无		 1有
        data.bPlayWayType = luaFunc:readRecvByte()          --玩法类型 0 金典斗地主 1 欢乐斗地主 3 癞子斗地主 4 湘西斗地主 
        data.bShoutBankerType = luaFunc:readRecvByte()          --叫地主类型 0 随机 1 先出完先叫
        data.bBombMaxNum = luaFunc:readRecvByte()          --炸弹上限  0无限制  3、4、5炸
        data.bBankerWayType = luaFunc:readRecvByte()          --0叫分 1,2,3分  1 叫地主
    elseif wKindID == 36 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 37 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 31 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        data.bDeathCard = luaFunc:readRecvByte()
        haveReadByte = 22    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 32 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bLimit = luaFunc:readRecvByte()                        --限制条件
        haveReadByte = 21    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
		
    elseif wKindID == 44 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bPaoTips = luaFunc:readRecvByte()
        data.bStartBanker = luaFunc:readRecvByte()
        data.bDeathCard = luaFunc:readRecvByte()
        haveReadByte = 24    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 50 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bNiaoAdd = luaFunc:readRecvByte()
        data.mNiaoCount = luaFunc:readRecvByte()
        data.bLLSFlag = luaFunc:readRecvByte()
        data.bQYSFlag = luaFunc:readRecvByte()
        data.bWJHFlag = luaFunc:readRecvByte()
        data.bDSXFlag = luaFunc:readRecvByte()
        data.bBBGFlag = luaFunc:readRecvByte()
        data.bSTFlag = luaFunc:readRecvByte()
        data.bYZHFlag = luaFunc:readRecvByte()
        data.bMQFlag = luaFunc:readRecvByte()
        data.mZXFlag = luaFunc:readRecvByte()
        data.mPFFlag = luaFunc:readRecvByte()
        data.mZTSXlag = luaFunc:readRecvByte()
        data.bJJHFlag = luaFunc:readRecvByte()
        data.bWuTong = luaFunc:readRecvByte()
        data.mMaOne = luaFunc:readRecvByte()
        haveReadByte = 17    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 70 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bNiaoAdd = luaFunc:readRecvByte()
        data.mNiaoCount = luaFunc:readRecvByte()
        data.bLLSFlag = luaFunc:readRecvByte()
        data.bQYSFlag = luaFunc:readRecvByte()
        data.bWJHFlag = luaFunc:readRecvByte()
        data.bDSXFlag = luaFunc:readRecvByte()
        data.bBBGFlag = luaFunc:readRecvByte()
        data.bSTFlag = luaFunc:readRecvByte()
        data.bYZHFlag = luaFunc:readRecvByte()
        data.bMQFlag = luaFunc:readRecvByte()
        data.mZXFlag = luaFunc:readRecvByte()
        data.mPFFlag = luaFunc:readRecvByte()
        data.mZTSXlag = luaFunc:readRecvByte()
        data.bJJHFlag = luaFunc:readRecvByte()
        data.bWuTong = luaFunc:readRecvByte()
        data.mMaOne  = luaFunc:readRecvByte()
        data.mZTLLSFlag  = luaFunc:readRecvByte()       
        data.mKGNPFlag  = luaFunc:readRecvByte()     
        haveReadByte = 19    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
           
    elseif wKindID == 51 or wKindID == 55 or wKindID == 56 or wKindID == 57 or wKindID == 58 or wKindID == 59 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bBankerType = luaFunc:readRecvByte()
        data.bMultiple = luaFunc:readRecvByte()
        data.bBettingType = luaFunc:readRecvByte() 
        data.bSettlementType = luaFunc:readRecvByte() 
        data.bPush = luaFunc:readRecvByte()
        data.bNoFlower = luaFunc:readRecvByte()
        data.bCanPlayingJoin = luaFunc:readRecvByte()
        data.bNiuType_Flush = luaFunc:readRecvByte()
        data.bNiuType_Gourd = luaFunc:readRecvByte()
        data.bNiuType_SameColor = luaFunc:readRecvByte()
        data.bNiuType_Straight = luaFunc:readRecvByte()
        haveReadByte = 12    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 38 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0:自摸 1:能胡必胡 2:放炮必胡
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD() 
        data.bFangPaoPay = luaFunc:readRecvByte()                   --放炮赔钱方式 0通赔  放炮赔两家钱
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        haveReadByte = 22    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 39 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD() 
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        data.bCanSiShou = luaFunc:readRecvByte()                    --能否弃牌
        data.bCanJuShouZuoSheng = luaFunc:readRecvByte()            --举手
        haveReadByte = 23    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节

    elseif wKindID == 40 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型   0:自摸 1:能胡必胡 2:放炮必胡
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD() 
        data.bCardCount21 = luaFunc:readRecvByte()  
        data.bMinLostCell = luaFunc:readRecvByte()                 --//最小分 加番倍
        data.bMinLost = luaFunc:readRecvByte()  				    --//最小分
        data.bDeathCard = luaFunc:readRecvByte()  
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        data.bDelShowCardHu = luaFunc:readRecvByte()                    --随机庄
        data.bPiaoHu = luaFunc:readRecvByte()                    --飘胡
        data.bStopCardGo = luaFunc:readRecvByte()                    --冲招

        haveReadByte = 28    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 42 then
        data.numpep=luaFunc:readRecvByte() --    -- 代表4人玩 （ 写死）
        data.bPlayerCount = data.numpep
        data.mailiao=luaFunc:readRecvWORD()--    --买鸟数
        data.fanbei=luaFunc:readRecvByte() --    --1、2、4 翻倍底分、
        data.jiabei=luaFunc:readRecvByte() --    --庄家输赢做加减一倍底分、0无、1有
        data.zimo=luaFunc:readRecvByte()   --    --只准自摸胡牌  1.有  0.无            
        data.piaohua=luaFunc:readRecvByte()--    --1.有飘花、0.无飘花
        haveReadByte = 7    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 43 then
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bChongFen = luaFunc:readRecvByte()
        data.bFanBei = luaFunc:readRecvByte()
        haveReadByte = 4    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 68 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        data.bNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.bQiDui = luaFunc:readRecvByte()
        data.bWuTong = luaFunc:readRecvByte()
        haveReadByte = 11    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 46 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        data.bQiDui = luaFunc:readRecvByte()
        data.bWuTong = luaFunc:readRecvByte()
        haveReadByte = 10    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 61 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        haveReadByte = 8    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 47 then
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bDeathCard =luaFunc:readRecvByte()                     --亡牌
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        haveReadByte = 23    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 89 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                 --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()               --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省(无用)
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bPaoTips = luaFunc:readRecvByte()
        data.bStartBanker = luaFunc:readRecvByte()
        data.bDeathCard = luaFunc:readRecvByte()                    --0 不抽低  1 抽牌20张 
        data.bMingType = luaFunc:readRecvByte()
        data.bMingWei = luaFunc:readRecvByte()
        data.b3Long5Kan = luaFunc:readRecvByte()
        haveReadByte = 27    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节

    elseif wKindID == 88 then 
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bDeathCard = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bZhuangFen = luaFunc:readRecvByte()                      --最大输
        data.bChongFen = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.dwMingTang = luaFunc:readRecvDWORD()                     --是否亮牌
        data.bChiNoPeng = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        haveReadByte = 9   --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 49 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bDeathCard =luaFunc:readRecvByte()                     --亡牌
        data.bStartBanker = luaFunc:readRecvByte()                    --随机庄
        data.bHuangFanAddUp = luaFunc:readRecvByte()                    --黄番
        data.STWK = luaFunc:readRecvByte()                    --三五
        haveReadByte = 25    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 52 then
        data.bPlayerCount = luaFunc:readRecvByte()--参与游戏的人数           
        data.bQGHu = luaFunc:readRecvByte()--是否抢杠胡  0.不抢杠胡 1.抢杠胡
        data.bHuangZhuangHG = luaFunc:readRecvByte()--是否黄庄黄杠  0.不 1.是
        data.bJiePao = luaFunc:readRecvByte()--是否接炮   0.不接炮 1.接炮
        data.bHuQD = luaFunc:readRecvByte()--可胡七对  0.不  1.是
        data.bMaCount = luaFunc:readRecvByte()--马数 2、4、6 0 
        haveReadByte = 6    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 53 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bBankerType = luaFunc:readRecvByte()
        data.bMultiple = luaFunc:readRecvByte()
        data.bBettingType = luaFunc:readRecvByte() 
        data.bPush = luaFunc:readRecvByte()
        data.bCanPlayingJoin = luaFunc:readRecvByte()
        data.bExtreme = luaFunc:readRecvByte()
        haveReadByte = 7    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 54 then   
        data.bPlayerCount = luaFunc:readRecvByte()  --参与游戏的人数
        data.bHuType = luaFunc:readRecvByte()       --胡牌类型--0.自摸胡<只能自摸胡牌> 1.点炮胡<可自摸、可点炮>
        data.bDHPlayFlag = luaFunc:readRecvByte()   --是否带混玩法-- 0.不带混 1.带混
        data.bDFFlag = luaFunc:readRecvByte()       --是否带风  0.不带风  1.带风
        data.bDXPFlag = luaFunc:readRecvByte()      --是否带下跑 0.不带下跑 1.带下跑<飘分>
        data.bBTHu = luaFunc:readRecvByte()         --是否报听胡  0.不报听胡 1.报听胡
        data.bQYMFlag = luaFunc:readRecvByte()      --是否缺一门 0.不需要缺一门 1.缺一门
        data.bQDJFFlag = luaFunc:readRecvByte()     --七对加分 0. 七对翻倍 1.
        data.bLLFlag = luaFunc:readRecvByte()       --是否连六  0.不连六 1.连六 
        data.bQYSFlag = luaFunc:readRecvByte()      --是否清一色 0.不清一色 1.清一色
        data.bZJJD = luaFunc:readRecvByte()         --是否庄家加底 0.不加 1.加
        data.bGSKHJB = luaFunc:readRecvByte()       --杠上花加倍 0.不杠上开花加倍 1.杠上开花加倍
        data.bQDFlag = luaFunc:readRecvByte()       --是否七对   0/1.
        haveReadByte = 13    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 60 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                        --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                       --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()                      --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bStartBanker = luaFunc:readRecvByte()
        data.bDeathCard = luaFunc:readRecvByte()                    --0 不抽低  1 抽牌20张 
        haveReadByte = 22    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 63 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        data.bNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        haveReadByte = 9    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 65 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaiPiaoCount = luaFunc:readRecvByte()
        data.bDiCount = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        haveReadByte = 4    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
        
    elseif wKindID == 67 then
        data.bPlayerCount = luaFunc:readRecvByte()
        data.bMaType = luaFunc:readRecvByte()
        data.bMaCount = luaFunc:readRecvByte()
        data.bQGHu = luaFunc:readRecvByte()
        data.bQGHuJM = luaFunc:readRecvByte()
        data.bHuangZhuangHG = luaFunc:readRecvByte()
        data.bQingSH = luaFunc:readRecvByte()
        data.bJiePao = luaFunc:readRecvByte()
        data.bNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.bQingYiSe = luaFunc:readRecvByte()
        data.bQiXiaoDui = luaFunc:readRecvByte()
        data.bPPHu = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.bWuTong = luaFunc:readRecvByte()  
        data.mPFFlag = luaFunc:readRecvByte()  
		haveReadByte = 14    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
		
	elseif wKindID == 69 then 
        data.FanXing = {}
        data.FanXing.bType = luaFunc:readRecvByte()                 --翻省    0默认没有反省  1上省  2下省  3跟省
        data.FanXing.bCount = luaFunc:readRecvByte()                --翻省的次数
        data.FanXing.bAddTun = luaFunc:readRecvByte()               --省算法, 一省三囤  单省    
        data.bPlayerCountType = luaFunc:readRecvByte()              --用户人数模式 0：默认3人   1：4人玩法  2：3人参与另外一人省(无用)
        data.bPlayerCount = luaFunc:readRecvByte()                  --参与游戏的人数 3+1模式为3
        data.bLaiZiCount = luaFunc:readRecvByte()                   --癞子数量 0 ~ 4个
        data.bMaxLost = luaFunc:readRecvWORD()                      --最大输
        data.bYiWuShi = luaFunc:readRecvByte()                      --是否有一五十吃法
        data.bLiangPai = luaFunc:readRecvByte()                     --是否亮牌
        data.bCanHuXi = luaFunc:readRecvByte()                      --起胡数  0 3 6 10 15  
        data.bHuType = luaFunc:readRecvByte()                       --胡牌类型  0自摸翻倍  1接炮
        data.bFangPao = luaFunc:readRecvByte()                      --是否有放跑功能
        data.bSettlement = luaFunc:readRecvByte()                   --结算是否按三胡一囤，否则一胡一囤
        data.bStartTun = luaFunc:readRecvByte()                     --囤数起始算法  0起始胡息一囤  1起始胡息二囤 210胡息三囤<=15胡息每多1胡息+1囤    
        data.bSocreType = luaFunc:readRecvByte()                    --0低分*囤数总和*名堂番数总和  1低分*囤数总和*名堂番数乘积
        data.dwMingTang = luaFunc:readRecvDWORD()                   --包含的名堂有哪些             
        data.bTurn = luaFunc:readRecvByte()
        data.bPaoTips = luaFunc:readRecvByte()
        data.bStartBanker = luaFunc:readRecvByte()
        data.bSiQiHong = luaFunc:readRecvByte()
        data.bDelShuaHou = luaFunc:readRecvByte()
        data.bHuangFanAddUp = luaFunc:readRecvByte()
        data.bTingHuAll = luaFunc:readRecvByte()
		data.bDeathCard = luaFunc:readRecvByte()                    --0 不抽低  1 抽牌20张 
		data.bPaPo = luaFunc:readRecvByte()
        haveReadByte = 29    --已读长度，每次增加或者减少都要修改该值，Byte1个字节 WORD2个字节 DWORD4个字节
   
    elseif wKindID == 78 then
        data.bPlayerCount = luaFunc:readRecvByte()          -- //参与游戏的人数
        data.mLaiZiCount = luaFunc:readRecvByte()           -- //0.无红中  1.四红中   2.八红中  （默认四红中）
        data.bJiePao = luaFunc:readRecvByte()               -- //是否接炮(点炮胡)  0.不接炮 1.接炮
        data.bQiDui = luaFunc:readRecvByte()                -- //七对玩法  0.不  1.是
        data.bQGHu = luaFunc:readRecvByte()                 -- //是否抢杠胡  0.不抢杠胡 1.抢杠胡
        data.bQGHuBaoPei = luaFunc:readRecvByte()           -- //是否抢杠胡包赔  0.不包赔（勾选）  1.包赔（不勾选）  默认包赔
        data.bJiaPiao = luaFunc:readRecvByte()              -- //充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
        data.bMaType = luaFunc:readRecvByte()               -- //1.一五九、2.抓鸟、3.一马全中、4.不奖马 5.摸几奖几、6.翻几奖几
        data.bMaCount = luaFunc:readRecvByte()              --//马数 2、4、6
        data.mNiaoType = luaFunc:readRecvByte()             --//1.一鸟一分、2.一鸟两分
        data.mHongNiao = luaFunc:readRecvByte()             --//1.无红中加一码、0.无	
        data.bWuTong = luaFunc:readRecvByte()               --//1.有筒  0.无筒 (默认有筒)
        haveReadByte = 12 
    elseif wKindID == 79 then 
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数
        data.mLaiZiCount = luaFunc:readRecvByte()           --0.无红中  1.四红中   （默认无红中）
        data.bJiePao = luaFunc:readRecvByte()               --是否接炮(点炮胡--抢杠胡)	 0.不接炮 1.接炮
        data.bQiDui = luaFunc:readRecvByte()                --七对玩法  0.不  1.是
        data.bQGHuBaoPei = luaFunc:readRecvByte()           --是否抢杠胡包赔  0.不包赔（勾选）  1.包赔（不勾选）  默认包赔
        data.bJiaPiao = luaFunc:readRecvByte()              --充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
        data.bMaType = luaFunc:readRecvByte()               --1.一五九、2.抓鸟、3.一马全中、4.不奖马 5.摸几奖几、6.翻几奖几
        data.bMaCount = luaFunc:readRecvByte()              --马数 2、4、6
        data.mNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.mHongNiao = luaFunc:readRecvByte()             --1.无红中加一码、0.无
        data.bZhuangXian = luaFunc:readRecvByte()           --庄闲：0.不算   1.算   （默认不算）
        data.bWuTong = luaFunc:readRecvByte()               --1.有筒  0.无筒 (默认有筒)
        haveReadByte = 12
        
    elseif wKindID == 80 then  
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数
        --玩法
        data.mZXFlag = luaFunc:readRecvByte()               --庄闲(算分) 默认1 是
        data.bBBGFlag = luaFunc:readRecvByte()              --步步高     默认0 否
        data.bSTFlag = luaFunc:readRecvByte()               --三同     默认0 否
        data.bXHBJPFlag = luaFunc:readRecvByte()            --小胡不接炮  默认1 （开启）
        data.bYZHFlag = luaFunc:readRecvByte()              --一枝花   默认0  否
        data.mZTSXlag = luaFunc:readRecvByte()              --中途四喜 默认0  否
        data.mJTYNFlag = luaFunc:readRecvByte()             --金童玉女 默认0  否
        data.mZTLLSFlag = luaFunc:readRecvByte()            --中途六六顺 默认0  否
        data.bMQFlag = luaFunc:readRecvByte()               --门清     默认0 否
        data.bJJHFlag = luaFunc:readRecvByte()              --假将胡   默认1.是
        --以下默认有
        data.bLLSFlag = luaFunc:readRecvByte()              --六六顺   默认1.是
        data.bQYSFlag = luaFunc:readRecvByte()              --缺一色   默认1.是
        data.bWJHFlag = luaFunc:readRecvByte()              --无将胡   默认1.是
        data.bDSXFlag = luaFunc:readRecvByte()              --大四喜   默认1.是
        --冲分
        data.bJiaPiao = luaFunc:readRecvByte()              --充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
        --扎鸟
        data.bMaType = luaFunc:readRecvByte()               --1.一五九、2.抓鸟、3.中鸟翻倍、4.不奖马
        data.bMaCount = luaFunc:readRecvByte()              --马数 1、2、4、6
        data.mNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        --开杠数量
        data.mKGNPFlag = luaFunc:readRecvByte()             --开杠拿牌 默认2，可选2、4、6
        --有无筒
        data.bWuTong = luaFunc:readRecvByte()               --1.有筒  0.无筒 (默认有筒)

        haveReadByte = 21

    elseif wKindID == 81 then 
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数
        data.mLaiZiCount = luaFunc:readRecvByte()           --0.无红中  1.四红中   （默认无红中）
        data.bJiePao = luaFunc:readRecvByte()               --是否接炮(点炮胡--抢杠胡)	 0.不接炮 1.接炮
        data.bQiDui = luaFunc:readRecvByte()                --七对玩法  0.不  1.是
        data.bQGHuBaoPei = luaFunc:readRecvByte()           --是否抢杠胡包赔  0.不包赔（勾选）  1.包赔（不勾选）  默认包赔
        data.bJiaPiao = luaFunc:readRecvByte()              --充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>
        data.bMaType = luaFunc:readRecvByte()               --1.一五九、2.抓鸟、3.一马全中、4.不奖马 5.摸几奖几、6.翻几奖几
        data.bMaCount = luaFunc:readRecvByte()              --马数 2、4、6
        data.mNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.mHongNiao = luaFunc:readRecvByte()             --1.无红中加一码、0.无
        data.bZhuangXian = luaFunc:readRecvByte()           --庄闲：0.不算   1.算   （默认不算）
        data.bWuTong = luaFunc:readRecvByte()               --1.有筒  0.无筒 (默认有筒)
        haveReadByte = 12
    elseif wKindID == 82 then  
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数
        --玩法
        data.mBanBanHu = luaFunc:readRecvByte()             --板板胡 0.无(默认) 1.有              ----起手
        data.mJiangJiangHu = luaFunc:readRecvByte()         --将将胡 0.无(默认) 1.有
        data.bQiDui = luaFunc:readRecvByte()                --七对玩法  0.不(默认)  1.是
        data.bHaoHuaQiDui = luaFunc:readRecvByte()          --豪华七对玩法  0.不(默认)  1.是

        data.bGangShangPao = luaFunc:readRecvByte()         --杠上炮  0.不(默认)  1.是			  --OK
        data.bGangShangHua = luaFunc:readRecvByte()         --杠上花  0.不(默认)  1.是			  --OK
        data.bQingYiSe = luaFunc:readRecvByte()             --清一色  0.不(默认)  1.是
        data.bPPHu = luaFunc:readRecvByte()                 --碰碰胡  0.不(默认)  1.是
        
        data.bHuangZhuangHG = luaFunc:readRecvByte()               --荒庄荒杠 0.不(默认)  1.是			  --OK
        data.bSiHZHu = luaFunc:readRecvByte()              --四红中胡牌  0.不(默认)  1.是        ----起手
        data.bQGHu = luaFunc:readRecvByte()              --是否抢杠胡  0.不抢杠胡 1.抢杠胡	  --OK
        data.bJiePao = luaFunc:readRecvByte()              --是否接炮(点炮胡)	 0.不接炮 1.接炮  --OK

        data.mLaiZiCount = luaFunc:readRecvByte()              --是否有红中癞子牌 0.无红中  1.四红中 --OK

        data.bJiaPiao = luaFunc:readRecvByte()              --充分    0.不飘     1.飘一   2.飘二   3.选一次漂    4.每小局选漂<发牌前飘分>  --OK

        --扎鸟
        data.bMaType = luaFunc:readRecvByte()               --1.一五九、2.抓鸟加分、3.一马全中 0.不奖马    7.抓鸟翻倍
        data.bMaCount = luaFunc:readRecvByte()              --马数 1、2、4、6
        data.mNiaoType = luaFunc:readRecvByte()             --1.一鸟一分、2.一鸟两分
        data.mHongNiao = luaFunc:readRecvByte()             --1.无红中加一码、0.无	        
        --有无筒
        data.bWuTong = luaFunc:readRecvByte()               --1.有筒  0.无筒 (默认有筒)

        haveReadByte = 20

    elseif wKindID == 85 then
        data.bPlayerCount = luaFunc:readRecvByte()          --参与游戏的人数
        data.bShowCardCount = luaFunc:readRecvByte()        --是否显示牌数量    0无      1有
        data.bCheating = luaFunc:readRecvByte()             --防止坐标          0无       1有
        data.bPlayWayType = luaFunc:readRecvByte()
        data.bSettleType = luaFunc:readRecvByte()
        data.bSurrenderStage = luaFunc:readRecvByte()
        data.bRemoveKingCard = luaFunc:readRecvBool()
        data.bRemoveSixCard = luaFunc:readRecvBool()
        data.bPaiFei = luaFunc:readRecvBool()
        data.bDaDaoEnd = luaFunc:readRecvBool()

        data.bNoTXPlease = luaFunc:readRecvBool()
        data.bNoLookCard = luaFunc:readRecvBool()
        data.b35Down = luaFunc:readRecvBool()
        haveReadByte = 13

    else
    
    end
    
    return data, haveReadByte
end

return GameConfig