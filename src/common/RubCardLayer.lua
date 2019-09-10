
-- 顶点着色器
local strVertSource = 
[[
attribute vec4 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;

uniform float ratio;  //牌初始状态到搓牌最终位置的完成度比例
uniform float radius; //搓牌类似于绕圆柱滚起，其圆柱的半径
uniform float width;
uniform float finish; //是否完成搓牌

uniform float offx;
uniform float offy;

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
	//注意OpenGL-ES中：1.attribute修饰的变量是常量。2.没有自动转类型float a = 1;或者5.0/3都是错误的
	//可以通过修改CPP代码，打印log来调试cocos2dx程序
	vec4 tmp_pos = a_position;

	//顺时针旋转90度
	tmp_pos = vec4(tmp_pos.y, -tmp_pos.x, tmp_pos.z, tmp_pos.w);

	if(finish > 0.5) {
		tmp_pos = vec4(tmp_pos.x, -width - tmp_pos.y, tmp_pos.z, tmp_pos.w);

	}else {
		//计算卡牌弯曲的位置，类似于卡牌绕圆柱卷起的原理
		float halfPeri = radius * 3.14159; //半周长
		float hr = halfPeri * ratio;
		if(tmp_pos.y < -width + hr) {
			float dy = -tmp_pos.y - (width - hr);
			float arc = dy/radius;
			tmp_pos.y = -width + hr - sin(arc)*radius;
			tmp_pos.z = radius * (1.0-cos(arc)); //注意之前这里是1，是错误的，opengles不自动类型转换
		}
	}
	
	tmp_pos += vec4(offx, offy, 0.0, 0.0);

	gl_Position = CC_MVPMatrix * tmp_pos;
	v_fragmentColor = a_color;
	v_texCoord = a_texCoord;
}
]]

-- 片段着色器
local strFragSource = 
[[
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
	//TODO, 这里可以做些片段着色特效

	gl_FragColor = texture2D(CC_Texture0, v_texCoord);
}
]]


local Bit = require("common.Bit")
local GameCommon = require("game.puke.PDKGameCommon")
local UserData = require("app.user.UserData")
local Default = require("common.Default")

-- 通过图片取得纹理id和该纹理坐标范围
local function getTextureAndRange(szImage)
	print('texture name = ', szImage)
	local textureCache = cc.Director:getInstance():getTextureCache()
	local texure = textureCache:addImage(szImage)
	local size = texure:getContentSize()
	local rect = cc.rect(0, 0, size.width, size.height)
	local id = texure:getName()
	local bigWide = texure:getPixelsWide()
	local bigHigh = texure:getPixelsHigh()

	-- 左右上下的纹理范围
	local ll, rr, tt, bb = rect.x/bigWide, (rect.x + rect.width)/bigWide, rect.y/bigHigh, (rect.y + rect.height)/bigHigh
	return id, {ll, rr, tt, bb}, {rect.width, rect.height}
end

-- 创建3D牌面，所需的顶点和纹理数据, size:宽高, texRange:纹理范围, bFront:是否正面
local function initCardVertex(size, texRange, bFront)
	local nDiv = 100 --将宽分成100份
	local verts = {} --位置坐标
	local texs = {}  --纹理坐标
	local dh = size.height
	local dw = size.width / nDiv
	
	--计算顶点位置
	for c = 1, nDiv do 
		local x, y = (c-1)*dw, 0
		local quad = {}
		if bFront then
			quad = {x, y, x+dw, y, x, y+dh, x+dw, y, x+dw, y+dh, x, y+dh}
		else
			quad = {x, y, x, y+dh, x+dw, y, x+dw, y, x, y+dh, x+dw, y+dh}
		end
		for _, v in ipairs(quad) do table.insert(verts, v) end
	end

	local bXTex = true --是否当前在计算横坐标纹理坐标
	for _, v in ipairs(verts) do 
		if bXTex then
			if bFront then
				table.insert(texs, v/size.width * (texRange[2] - texRange[1]) + texRange[1])
			else
				table.insert(texs, v/size.width * (texRange[1] - texRange[2]) + texRange[2])
			end
		else
			if bFront then
				table.insert(texs, (1-v/size.height) * (texRange[4] - texRange[3]) + texRange[3])
			else
				table.insert(texs, v/size.height * (texRange[3] - texRange[4]) + texRange[4])
			end
		end
		bXTex = not bXTex
	end

	local res = {}
	local tmp = {verts, texs}
	for _, v in ipairs(tmp) do 
		local buffid = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, buffid)
		gl.bufferData(gl.ARRAY_BUFFER, table.getn(v), v, gl.STATIC_DRAW)
		gl.bindBuffer(gl.ARRAY_BUFFER, 0)
		table.insert(res, buffid)
	end
	return res, #verts
end

--创建UI层
local function createRubCardUILayer(layer, handCardArr)
	local Director = cc.Director:getInstance()
	local WinSize = Director:getWinSize()
	local path = 'common/hall_return1.png'
	local closeBtn = ccui.Button:create(path, path, path)
	layer:addChild(closeBtn)
	closeBtn:setPosition(WinSize.width * 0.9, WinSize.height * 0.85)

	closeBtn:setPressedActionEnabled(true)
	closeBtn:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
           layer:removeFromParent()
        end
    end)

    local tipsImage = ccui.ImageView:create('puke/table/pukenew_17.png')
    layer:addChild(tipsImage)
    tipsImage:setPosition(WinSize.width * 0.8, WinSize.height * 0.3)
    tipsImage:setName('tipsImage')

	local step = 82
	local cardNum = #handCardArr - 1
	local startPos = (cardNum - 1) * step
    for i = 1, cardNum do
    	local data = handCardArr[i]
        local card = GameCommon:getCardNode(data)
        layer:addChild(card)
        -- card:setScale(0.5)
        local x = (WinSize.width * 0.5 - startPos) + (i - 1) * step * 2
        local y = WinSize.height * 0.5 + 120
        card:setPosition(x, y)
    end
end

--加载配置
local function loadTurnCardCnfInfo()
	local myRoleData = {}
	print('MyRole userid = ', UserData.User.userID)
	dump(GameCommon.player, 'PlayerInfo::')
	for i,v in pairs(GameCommon.player or {}) do
		if tonumber(v.dwUserID) == tonumber(UserData.User.userID) then
			myRoleData = v
			break
		end
	end

	local handCardArr = myRoleData.cbCardData
	if not handCardArr then
		printError('player card info no find')
		return
	end

	local data = handCardArr[#handCardArr]
	local value = Bit:_and(data,0x0F)
    local color = Bit:_rshift(Bit:_and(data,0xF0),4)
    local cardIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_PukeCardBg,0)
	local szBack = string.format('puke/table/puke_bg%d.png', cardIndex)
	local szFont = string.format("puke/card/card0/puke_%d_%d.png",color,value)
	return szBack, szFont, handCardArr
end

-- 创建搓牌效果层
local function createRubCardEffectLayer(scale)
	scale = scale or 1.0
	local szBack, szFont, handCardArr = loadTurnCardCnfInfo()
	if not (szBack and szFont and handCardArr) then
		return
	end

	-- 取得屏幕宽高
	local Director = cc.Director:getInstance()
	local WinSize = Director:getWinSize()

	-- 创建用于OpenGL绘制的节点
	gl.clear(gl.COLOR_BUFFER_BIT)
	gl.clear(gl.DEPTH_BUFFER_BIT)
	local glNode = gl.glNodeCreate()
	local glProgram = cc.GLProgram:createWithByteArrays(strVertSource, strFragSource)
	glProgram:retain()
	glProgram:updateUniforms()

	-- 创建搓牌图层
	local layer = cc.LayerColor:create(cc.c4b(0, 0, 0, 170))
	createRubCardUILayer(layer, handCardArr)
	layer:addChild(glNode)
	
	-- 退出时，释放glProgram程序
	local function onNodeEvent(event)
		if "exit" == event then
			glProgram:release()
		end
	end
	layer:registerScriptHandler(onNodeEvent)

	local posNow = cc.p(0, 0)
 	--创建触摸回调
	local function touchBegin(touch, event)
		posNow = touch:getLocation()
		printInfo("onTouchBegan: %0.2f, %0.2f", posNow.x, posNow.y)
		return true
	end
	local function touchMove(touch, event)
		local location = touch:getLocation()
		printInfo("onTouchMoved: %0.2f, %0.2f", location.x, location.y)
		--拉伸程度
		local dy = location.y - posNow.y
		layer.ratioVal = cc.clampf(layer.ratioVal + dy/100, 0.0, 0.98)
		posNow = location

		local tipsImage = layer:getChildByName('tipsImage')
		if tipsImage then
			tipsImage:removeFromParent()
		end
		return true
	end
	local function touchEnd(touch, event)
		local location = touch:getLocation()
		printInfo("onTouchEnded: %0.2f, %0.2f", location.x, location.y)
		layer.ratioVal = 0.0
		return true
	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:registerScriptHandler(touchBegin, cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(touchMove, cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(touchEnd, cc.Handler.EVENT_TOUCH_ENDED )
	listener:setSwallowTouches(true)
	local eventDispatcher = layer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)

	--创建牌的背面
	local id1, texRange1, sz1 = getTextureAndRange(szBack)
	local msh1, nVerts1 = initCardVertex(cc.size(sz1[1] * scale, sz1[2] * scale), texRange1, true)
	--创建牌的正面
	local id2, texRange2, sz2 = getTextureAndRange(szFont)
	local msh2, nVerts2 = initCardVertex(cc.size(sz2[1] * scale, sz2[2] * scale), texRange2, false)

	--搓牌的程度控制， 搓牌类似于通过一个圆柱滚动将牌粘着起来的效果。下面的参数就是滚动程度和圆柱半径
	layer.ratioVal = 0.0
	layer.radiusVal = sz1[1]*scale/math.pi;

	--牌的渲染信息
	local cardMesh = {{id1, msh1, nVerts1}, {id2, msh2, nVerts2}}
	-- OpenGL绘制函数
	local function draw(transform, transformUpdated)
		gl.enable(gl.CULL_FACE)
		glProgram:use()
		glProgram:setUniformsForBuiltins()

		for _, v in ipairs(cardMesh) do 
			gl.bindTexture(gl.TEXTURE_2D, v[1])

			-- 传入搓牌程度到着色器中，进行位置计算
			local ratio = gl.getUniformLocation(glProgram:getProgram(), "ratio")
			glProgram:setUniformLocationF32(ratio, layer.ratioVal)
			local radius = gl.getUniformLocation(glProgram:getProgram(), "radius")
			glProgram:setUniformLocationF32(radius, layer.radiusVal)

			-- 偏移牌，使得居中
			local offx = gl.getUniformLocation(glProgram:getProgram(), "offx")
			glProgram:setUniformLocationF32(offx, WinSize.width/2 - sz1[2]/2*scale)
			local offy = gl.getUniformLocation(glProgram:getProgram(), "offy")
			glProgram:setUniformLocationF32(offy, WinSize.height/2) -- + sz1[1]/2*scale)

			local width = gl.getUniformLocation(glProgram:getProgram(), "width")
			glProgram:setUniformLocationF32(width, sz1[1]*scale)

			gl.glEnableVertexAttribs(bit._or(cc.VERTEX_ATTRIB_FLAG_TEX_COORDS, cc.VERTEX_ATTRIB_FLAG_POSITION))
			gl.bindBuffer(gl.ARRAY_BUFFER, v[2][1])
			gl.vertexAttribPointer(cc.VERTEX_ATTRIB_POSITION,2,gl.FLOAT,false,0,0)
			gl.bindBuffer(gl.ARRAY_BUFFER, v[2][2])
			gl.vertexAttribPointer(cc.VERTEX_ATTRIB_TEX_COORD,2,gl.FLOAT,false,0,0)
			gl.drawArrays(gl.TRIANGLES, 0, v[3])
		end

        gl.bindTexture(gl.TEXTURE_2D, 0)
        gl.bindBuffer(gl.ARRAY_BUFFER, 0)
	end
	glNode:registerScriptDrawHandler(draw)

	return layer
end

return createRubCardEffectLayer