--    // lua 调用 C++
--    int GetMainCmdID();
--    int GetSubCmdID();
--    int GetAlignmentValue();
--    void SetAlignmentValue(int alignmentValue);
--    
--    unsigned char readRecvByte();
--    short readRecvShort();
--    int readRecvInt();
--    unsigned int readRecvUint32();
--    double readRecvDouble();
--    std::string readRecvString(unsigned int nLen);
--    void readRecvBuffer(char *buf, unsigned int nLen);
--    bool readRecvBool();
--    int readRecvLong();
--    unsigned short readRecvWORD();
--    unsigned int readRecvDWORD();
--    unsigned long long readRecvUnsignedLongLong();
--    
--    unsigned char readRecvByte(unsigned int len);
--    short readRecvShort(unsigned int len);
--    int readRecvInt(unsigned int len);
--    unsigned int readRecvUint32(unsigned int len);
--    double readRecvDouble(unsigned int len);
--    bool readRecvBool(unsigned int len);
--    int readRecvLong(unsigned int len);
--    unsigned short readRecvWORD(unsigned int len);
--    unsigned int readRecvDWORD(unsigned int len);
--    unsigned long long readRecvUnsignedLongLong(unsigned int len);
--    
--    bool writeSendByte(unsigned char byValue,int len);
--    bool writeSendShort(short shtValue,int len);
--    bool writeSendInt(int nValue,int len);
--    bool writeSendUint32(unsigned int unValue,int len);
--    bool writeSendDouble(double dblValue,int len);
--    bool writeSendString(std::string strValue,int len);
--    bool writeSendBuffer(const char* szBuf,int len);
--    bool writeSendBool(bool value,int len);
--    bool writeSendLong(int value,int len);
--    bool writeSendWORD(unsigned short value,int len);
--    bool writeSendDWORD(unsigned int value,int len);
--    bool writeSendUnsignedLongLong(unsigned long long value, int len);
--    //void beginSendBuf(unsigned int unUserId,unsigned int unMsgId);
--    void beginSendBuf(int nMainCmdID, int nSubCmdID);
--    void endSendBuf();
--    bool connectSvr(const char* szFarAddr,unsigned short uPort);
--    int sendSvrBuf();
--    
--    void closeConnect();
--    std::string int2ip(unsigned int nIp);
--    unsigned int getSockID();

local Net = {
    id = 0,                         --socketID
    cppFunc = nil,
    connected = false,              -- 是否已经连接上服务器
    serverAddr = "",                -- 地址
    serverPort = 0,                 -- 端口
    isActiveNetwork = false,        -- 是否主动断网
}

function Net:sendMsgToSvr(mainCmdId,subCmdId,strCmd,...)
    if self.connected == false then
        printInfo(string.format("网络已中断：mainCmdId = %d, subCmdId=%d,strCmd=%s",mainCmdId,subCmdId,strCmd))
        return false
    end
    local arg = {...}
    local nStrLen = string.len(strCmd)
    self.cppFunc:beginSendBuf(mainCmdId,subCmdId)
    local padded = 0
    for i = 1,nStrLen,1 do
        local sTemp = string.sub(strCmd,i,i)
        if sTemp == "b" then
            self.cppFunc:writeSendByte(arg[i],padded)
        elseif sTemp == "i" then
            self.cppFunc:writeSendInt(arg[i],padded)
        elseif sTemp == "h" then
            self.cppFunc:writeSendShort(arg[i],padded)
        elseif sTemp == "u" then
            self.cppFunc:writeSendUint32(arg[i],padded)
        elseif sTemp == "g" then
            self.cppFunc:writeSendDouble(arg[i],padded)
        elseif sTemp == "s" then
            self.cppFunc:writeSendString(arg[i],padded)
        elseif sTemp == "f" then
            self.cppFunc:writeSendBuffer(arg[i],padded)
        elseif sTemp == "w" then
            self.cppFunc:writeSendWORD(arg[i],padded)
        elseif sTemp == "d" then
            self.cppFunc:writeSendDWORD(arg[i],padded)
        elseif sTemp == "l" then
            self.cppFunc:writeSendLong(arg[i],padded)
        elseif sTemp == "o" then
            self.cppFunc:writeSendBool(arg[i],padded)
        elseif sTemp == "a" then
            self.cppFunc:writeSendDouble(arg[i],padded)
        elseif sTemp == "k" then
            self.cppFunc:writeSendUnsignedLongLong(arg[i],padded)
        elseif sTemp == "n" then
            padded = arg[i]
        end

        if sTemp ~= "n" then
            padded = 0
        end
    end
    self.cppFunc:endSendBuf()
    local ret = self.cppFunc:sendSvrBuf()
    if ret == -1 then
        return false
    else
        return true
    end
end

function Net:onDisConnect()
    self.connected = false
end

function Net:connectGameSvr(addr,port)
    if not (addr and port) then
        return
    end

    self.isActiveNetwork = true
    self.serverAddr = addr
    self.serverPort = port
    self.connected = self.cppFunc:connectSvr(addr,port)
    self.isActiveNetwork = false
    return self.connected 
end

function Net:closeConnect()
    self.isActiveNetwork = true
    self.cppFunc:closeConnect()
    self.isActiveNetwork = false
end

function Net:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function Net:destroyNetworkDelay()
    if self.node ~= nil then
        self.node:removeFromParent()
    end
    self.node = nil
    self.networkDelay = 0
end

return Net
