local Serialize = {}

function Serialize:create(data, size)
    self.obj = cus.Serialize:create(data, size)
	return self
end

function Serialize:readRecvByte(len)
    return self.obj:readByte(0)
end

function Serialize:readRecvShort(len)
    return self.obj:readShort(0)
end

function Serialize:readRecvInt(len)
    return self.obj:readInt(0)
end

function Serialize:readRecvUint32(len)
    return self.obj:readUint32(0)
end

function Serialize:readRecvDouble(len)
    return self.obj:readDouble(0)
end

function Serialize:readRecvBool(len)
    return self.obj:readBool(0)
end

function Serialize:readRecvLong(len)
    return self.obj:readLong(0)
end

function Serialize:readRecvWORD(len)
    return self.obj:readWORD(0)
end

function Serialize:readRecvDWORD(len)
    return self.obj:readDWORD(0)
end

function Serialize:readRecvString(len)
    return self.obj:readString(len)
end

function Serialize:writeSendBuffer(data, size)
    self.obj:writeBuffer(data, size)
end
return Serialize