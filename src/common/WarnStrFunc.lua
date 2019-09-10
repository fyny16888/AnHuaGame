--敏感词库
local StaticData = require("app.static.StaticData")

local WarnStrFunc = {}--class('WarnStrFunc')

function WarnStrFunc:ctor()
    self:createTree()
end

--树节点创建
function WarnStrFunc:createNode(c,flag,nodes)
    local node = {}
    node.c = c or nil           --字符
    node.flag = flag or 0       --是否结束标志，0：继续，1：结尾
    node.nodes = nodes or {}    --保存子节点
    return node
end

--初始化树结构
function WarnStrFunc:createTree()
    self.rootNode = self:createNode('R')  --根节点  
    for i,v in ipairs(StaticData.Warning) do
        local chars = self:getCharArray(v.word)
        if #chars > 0 then
            self:insertNode(self.rootNode,chars,1)
        end
    end
end

--插入节点
function WarnStrFunc:insertNode(node,cs,index)
    local n = self:findNode(node,cs[index])
    if n == nil then
        n = self:createNode(cs[index])
        table.insert(node.nodes,n)
    end

    if index == #cs then
        n.flag = 1
    end

    index = index + 1
    if index <= #cs then
        self:insertNode(n,cs,index)
    end
end

--节点中查找子节点
function WarnStrFunc:findNode(node,c)
    local nodes = node.nodes
    local rn = nil
    for i,v in ipairs(nodes) do
        if v.c == c then
            rn = v
            break
        end
    end
    return rn
end

--字符串转换为字符数组
function WarnStrFunc:getCharArray(str)
    local array = {}
    local len = string.len(str)
    while str do
        local fontUTF = string.byte(str,1)

        if fontUTF == nil then
            break
        end

        --lua中字符占1byte,中文占3byte
        if fontUTF > 127 then 
            local tmp = string.sub(str,1,3)
            table.insert(array,tmp)
            str = string.sub(str,4,len)
        else
            local tmp = string.sub(str,1,1)
            table.insert(array,tmp)
            str = string.sub(str,2,len)
        end
    end
    return array
end

--将字符串中敏感字用*替换返回
function WarnStrFunc:warningStrGsub(inputStr)
    local chars = self:getCharArray(inputStr)
    local index = 1
    local node = self.rootNode
    local word = {}

    while #chars >= index do
        --遇空格节点树停止本次遍历[习 近  平 -> ******]
        if chars[index] ~= ' ' then
            node = self:findNode(node,chars[index])
        end

        if node == nil then
            index = index - #word 
            node = self.rootNode
            word = {}
        elseif node.flag == 1 then
            table.insert(word,index)
            for i,v in ipairs(word) do
                chars[v] = '*'
            end
            node = self.rootNode
            word = {}
        else
            table.insert(word,index)
        end
        index = index + 1
    end

    local str = ''
    for i,v in ipairs(chars) do
        str = str .. v
    end

    return str
end

--字符串中是否含有敏感字
function WarnStrFunc:isWarningInPutStr(inputStr)
    local chars = self:getCharArray(inputStr)
    local index = 1
    local node = self.rootNode
    local word = {}

    while #chars >= index do
        if chars[index] ~= ' ' then
            node = self:findNode(node,chars[index])
        end

        if node == nil then
            index = index - #word 
            node = self.rootNode
            word = {}
        elseif node.flag == 1 then
            return true
        else
            table.insert(word,index)
        end
        index = index + 1
    end

    return false
end

WarnStrFunc:createTree()

return WarnStrFunc