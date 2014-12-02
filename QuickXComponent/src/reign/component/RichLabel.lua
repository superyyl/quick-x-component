---
--
-- 下午2:36:09,2014年12月2日
-- @author superyyl
--
local RichLabel = class("RichLabel",function()
    return display.newNode()
end)

local LABEL_DIV_BEGIN = "<div>"
local LABEL_DIV_END = "</div>"

-- 共享解析器列表
local shared_parserlist = {}
-- 播放动画默认速度
local ANIM_WORD_PER_SEC = 15
local DEBUG_MARK = "richlabel.debug.drawnodes"

function RichLabel:ctor(params)
    params = params or {}
    local fontName       = params.font or display.DEFAULT_TTF_FONT
    local fontSize       = params.size or display.DEFAULT_TTF_FONT_SIZE
    local fontColor      = params.color or display.COLOR_WHITE
    local maxWidth   = params.maxWidth or 0
    local linespace  = params.lineSpace or 0 -- 行间距
    local charspace  = params.charSpace or 0 -- 字符距
    
    self._maxWidth = maxWidth
    self._animationCounter = 0
    
    self._default = {}
    self._default.fontName = fontName
    self._default.fontSize = fontSize
    self._default.fontColor = fontColor
    self._default.lineSpace = linespace
    self._default.charSpace = charspace
    
    -- 标签内容向右向下增长
    self:setAnchorPoint(cc.p(0, 1))
    -- 允许setColor和setOpacity生效
    self:setCascadeOpacityEnabled(true)
    self:setCascadeColorEnabled(true)
end

function RichLabel:setString(text)
    text = text or ""
    -- 字符串相同的直接返回
    if self._currentText == text then return
    end
    
    -- 若之前存在字符串，要先清空
    if self._currentText then
        self._allnodelist = nil
        self._parsedtable = nil
        self._alllines = nil
        self:removeAllChildren()
    end
    
    self._currentText = text
    
    -- 解析字符串，解析成为一种内定格式(表结构)，便于创建精灵使用
    local parsedtable = self:parse(text)
    self._parsedtable = parsedtable
    if parsedtable == nil then
        return self:printf("parser text error")
    end
    -- 将解析的字符串转化为精灵或者Label
    local containerNode = self
    local allnodelist = self:charsToNodes_(parsedtable, containerNode)
    if not allnodelist then return
    end
    self._allnodelist = allnodelist

    -- 将精灵排版布局
    self:layout()
end

function RichLabel:getString()
    return self._currentText
end

function RichLabel:setMaxWidth(maxwidth)
    self._maxWidth = maxwidth
    self:layout()
end

function RichLabel:setAnchorPoint(anchor, anchor_y)
    if type(anchor) == "number" then
        anchor = cc.p(anchor, anchor_y)
    end
    local super_setAnchorPoint = getmetatable(self).setAnchorPoint
    super_setAnchorPoint(self, anchor)
    if self._currentText then self:layout()
    end
end

function RichLabel:getSize()
    return cc.size(self._currentWidth, self._currentHeight)
end

function RichLabel:getLineHeight(rowindex)
    local line = self._alllines[rowindex]
    if not line then return 0
    end

    local maxheight = 0
    for _, node in pairs(line) do
        local box = node:getBoundingBox()
        if box.height > maxheight then
            maxheight = box.height
        end
    end
    return maxheight
end

function RichLabel:getElementWithIndex(index)
    return self._allnodelist[index]
end

function RichLabel:getElementWithRowCol(rowindex, colindex)
    local line = self._alllines[rowindex]
    if line then return line[colindex]
    end
end

function RichLabel:getElementsWithLetter(letter)
    local nodelist = {}
    for _, node in pairs(self._allnodelist) do
        -- 若为Label则存在此方法
        if node.getString then
            local str = node:getString()
            -- 若存在换行符，则换行
            if str==letter then 
                table.insert(nodelist, node)
            end
        end
    end
    return nodelist
end

function RichLabel:getElementsWithGroup(groupIndex)
    return self._parsedtable[groupIndex].nodelist
end

function RichLabel:walkElements(callback)
    assert(callback)
    for index, node in pairs(self._allnodelist) do
        if callback(node, index) ~= nil then return 
        end
    end
end

function RichLabel:walkLineElements(callback)
    assert(callback)
    for rowindex, line in pairs(self._alllines) do
        for colindex, node in pairs(line) do
            if callback(node, rowindex, colindex) ~= nil then return 
            end
        end
    end
end

function RichLabel:playAnimation(wordpersec, callback)
    wordpersec = wordpersec or ANIM_WORD_PER_SEC
    if self:isAnimationPlaying() then return
    end
    local counter = 0
    local animationCreator = function(node, rowindex, colindex)
        counter = counter + 1
        return cc.Sequence:create(
            cc.DelayTime:create(counter/wordpersec),
            cc.CallFunc:create(function() 
                if callback then callback(node, rowindex, colindex) end 
            end),
            cc.FadeIn:create(0.2),
            cc.CallFunc:create(function()
                self._animationCounter = self._animationCounter - 1
            end)
        )
    end

    self:walkLineElements(function(node, rowindex, colindex)
        self._animationCounter = self._animationCounter + 1
        node:setOpacity(0)
        node:runAction(animationCreator(node, rowindex, colindex))
    end)
end

function RichLabel:isAnimationPlaying()
    return self._animationCounter > 0
end

function RichLabel:stopAnimation()
    self._animationCounter = 0 
    self:walkElements(function(node, index)
        node:setOpacity(255)
        node:stopAllActions()
    end)
end

-- 一般情况下无需手动调用，设置setMaxWidth, setString, setAnchorPoint时自动调用
-- 自动布局文本，若设置了最大宽度，将自动判断换行
-- 否则一句文本中得内容'\n'换行
function RichLabel:layout()
    local parsedtable = self._parsedtable
    local basepos = cc.p(0, 0)
    local col_idx = 0
    local row_idx = 0

    local containerNode = self
    local allnodelist = self._allnodelist
    local linespace = self._default.lineSpace
    local charspace = self._default.charSpace
    local maxwidth = 0
    local maxheight = 0
    -- 处理所有的换行，返回换行后的数组
    local alllines = self:adjustLineBreak_(allnodelist, charspace)
    self._alllines = alllines
    for index, line in pairs(alllines) do
        local linewidth, lineheight = self:layoutLine_(basepos, line, 1, charspace)
        local offset = lineheight + linespace
        basepos.y = basepos.y - offset
        maxheight = maxheight + offset
        if maxwidth < linewidth then maxwidth = linewidth
        end
    end
    -- 减去最后多余的一个行间距
    maxheight = maxheight - linespace
    self._currentWidth = maxwidth
    self._currentHeight = maxheight

    -- 根据锚点重新定位
    local anchor = self:getAnchorPoint()
    local origin_x, origin_y = 0, maxheight
    local result_x = origin_x - anchor.x * maxwidth
    local result_y = origin_y - anchor.y * maxheight
    containerNode:setPosition(result_x, result_y)
end

--
-- Debug
--

--[[--
-   debugDraw: 绘制边框
@param: level - 绘制级别，level<=2 只绘制整体label, level>2 绘制整体label和单个字符的范围
]]
function RichLabel:debugDraw(level)
    level = level or 2
    local containerNode = self
    local debugdrawnodes1 = cc.utils:findChildren(containerNode, DEBUG_MARK)
    local debugdrawnodes2 = cc.utils:findChildren(self, DEBUG_MARK)
    function table_insertto(dest, src, begin)
        if begin <= 0 then
            begin = #dest + 1
        end
        local len = #src
        for i = 0, len - 1 do
            dest[i + begin] = src[i + 1]
        end
    end
    table_insertto(debugdrawnodes1, debugdrawnodes2, #debugdrawnodes1+1)
    for k,v in pairs(debugdrawnodes1) do
        v:removeFromParent()
    end

    local labelSize = self:getSize()
    local anchorpoint = self:getAnchorPoint()
    local pos_x, pos_y = 0, 0
    local origin_x = pos_x-labelSize.width*anchorpoint.x
    local origin_y = pos_y-labelSize.height*anchorpoint.y
    local frame = cc.rect(origin_x, origin_y, labelSize.width, labelSize.height)
    -- 绘制整个label的边框
    self:drawrect(self, frame, 1):setName(DEBUG_MARK)
    -- 绘制label的锚点
    self:drawdot(self, cc.p(0, 0), 5):setName(DEBUG_MARK)

    -- 绘制每个单独的字符
    if level > 1 then
        local allnodelist = self._allnodelist
        local drawcolor = cc.c4f(0,0,1,0.5)
        for _, node in pairs(allnodelist) do
            local box = node:getBoundingBox()
            local pos = cc.p(node:getPositionX(), node:getPositionY())
            self:drawrect(containerNode, box, 1, drawcolor):setName(DEBUG_MARK)
            self:drawdot(containerNode, pos, 2, drawcolor):setName(DEBUG_MARK)
        end
    end
end

--
-- Internal Method
--

-- 加载标签解析器，在labels文件夹下查找
function RichLabel:loadLabelParser_(label)
    local labelparserlist = shared_parserlist
    local parser = labelparserlist[label]
    if parser then return parser
    end
    --    local parserpath = string.format("%s.labels.label_%s", currentpath, label)
    -- 检测是否存在解析器
    --    local parser = require(parserpath)
    local parser = nil
    if label == "img" then
        parser = function (self, params, default)
            if not params.src then return 
            end
            -- 创建精灵，自动在帧缓存中查找，屏蔽了图集中加载和直接加载的区别
            local sprite = self:getSprite(params.src)
            if not sprite then
                self:printf("<img> - create sprite failde")
                return
            end
            if params.scale then
                sprite:setScale(params.scale)
            end
            if params.rotate then
                sprite:setRotation(params.rotate)
            end
            if params.visible ~= nil then
                sprite:setVisible(params.visible)
            end
            return {sprite}
        end
    elseif label == "div" then
        local function div_createlabel(self, word, fontname, fontsize, fontcolor)
            if word == "" then return
            end
            local label = display.newTTFLabel({
                text = word,font=fontname,size=fontsize
            })--cc.Label:createWithTTF(word, fontname, fontsize)
            if not label then 
                self:printf("<div> - create label failed")
                return
            end
            label:setColor(fontcolor)
            return label
        end

        local function div_parseshadow(self, shadow)
            if not shadow then return
            end
            -- 标准的格式：shadow=10,10,10,#ff0099
            -- (offset_x, offset_y, blur_radius, shadow_color)
            local params = self:split(shadow, ",")
            if #params~=4 then
                self:printf("parser <div> property shadow error")
                return nil
            end
            local offset_x = tonumber(params[1]) or 0
            local offset_y = tonumber(params[2]) or 0
            params.offset = cc.size(offset_x, offset_y)
            params.blurradius = tonumber(params[3]) or 0
            params.color = self:convertColor(params[4]) or cc.c4b(255,255,255,255)
            return params
        end

        local function div_parseoutline(self, outline)
            if not outline then return
            end
            -- 标准格式: outline=1,#ff0099
            -- (outline_size, outline_color)
            local params = self:split(outline, ",")
            if #params~=2 then
                self:printf("parser <div> property outline error")
                return nil
            end
            params.size = tonumber(params[1]) or 0
            params.color = self:convertColor(params[2]) or cc.c4b(255,255,255,255)
            return params
        end 

        local function div_parseglow(self, glow)
            if not glow then return
            end
            -- 标准格式: glow=#ff0099   
            -- (glow_color)
            local color = self:convertColor(glow) or cc.c4b(255,255,255,255)
            return {["color"]=color}
        end
        parser = function (self, params, default)
            -- 将字符串拆分成一个个字符
            local content = params.content
            if content then
                params.charlist = self:stringToChars(content)
            end
            -- 必须返回表，表中包含要显示的精灵
            local charlist = params.charlist
            local labellist = {}
            if not charlist then return labellist
            end

            -- 获得要设置的属性
            local fontname = params.fontname or default.fontName
            local fontsize = params.fontsize or default.fontSize
            local fontcolor = self:convertColor(params.fontcolor) or default.fontColor
            -- label effect
            local shadow = params.shadow
            local shadow_params = div_parseshadow(self, shadow)
            local outline = params.outline
            local outline_params = div_parseoutline(self, outline)
            local glow = params.glow
            local glow_params = div_parseglow(self, glow)

            for index, char in pairs(charlist) do
                local label = div_createlabel(self, char, fontname, fontsize, fontcolor)
                if label then
                    if shadow then 
                        label:enableShadow(shadow_params.color, shadow_params.offset, shadow_params.blurradius)
                    end
                    if outline then
                        label:enableOutline(outline_params.color, outline_params.size)
                    end
                    if glow then
                        label:enableGlow(glow_params.color)
                    end
                    table.insert(labellist, label)
                end
            end
            return labellist
        end
    end
    if parser then
        labelparserlist[label] = parser
    end
    return parser
end

-- 将文本解析后属性转化为节点(Label, Sprite, ...)
function RichLabel:charsToNodes_(parsedtable, containerNode)
    local default = self._default
    local allnodelist = {}
    for index, params in pairs(parsedtable) do
        local labelname = params.labelname
        -- 检测是否存在解析器
        local parser = self:loadLabelParser_(labelname)
        if not parser then
            return self:printf("not support label %s", labelname)
        end
        -- 调用解析器
        local nodelist = parser(self, params, default)
        params.nodelist = nodelist
        -- 连接两个表格
        for _, node in pairs(nodelist) do
            table.insert(allnodelist, node)
            -- 将label添加到容器上，才能显示出来
            containerNode:addChild(node)
        end
    end
    return allnodelist
end

-- 布局单行中的节点的位置，并返回行宽和行高
function RichLabel:layoutLine_(basepos, line, anchorpy, charspace)
    anchorpy = anchorpy or 0.5
    local pos_x = basepos.x
    local pos_y = basepos.y
    local lineheight = 0
    local linewidth = 0
    for index, node in pairs(line) do
        local box = node:getBoundingBox()
        -- 设置位置
        node:setPosition((pos_x + linewidth + box.width/2), pos_y)
        -- 累加行宽度
        linewidth = linewidth + box.width + charspace
        -- 查找最高的元素，为行高
        if lineheight < box.height then lineheight = box.height
        end
    end
    -- 重新根据排列位置排列
    -- anchorpy代表文本上下对齐的位置，0.5代表中间对齐，1代表上部对齐
    if anchorpy ~= 0.5 then
        local offset = (anchorpy-0.5)*lineheight
        for index, node in pairs(line) do
            local yy = node:getPositionY()
            node:setPositionY(yy-offset)
        end
    end
    return linewidth - charspace, lineheight
end

-- 自动适应换行处理方法，内部会根据最大宽度设置和'\n'自动换行
-- 若无最大宽度设置则不会自动换行
function RichLabel:adjustLineBreak_(allnodelist, charspace)
    -- 如果maxwidth等于0则不自动换行
    local maxwidth = self._maxWidth
    if maxwidth <= 0 then maxwidth = 999999999999
    end
    -- 存放每一行的nodes
    local alllines = {{}, {}, {}}
    -- 当前行的累加的宽度
    local addwidth = 0
    local rowindex = 1
    local colindex = 0
    for _, node in pairs(allnodelist) do
        colindex = colindex + 1
        -- 为了防止存在缩放后的node
        local box = node:getBoundingBox()
        addwidth = addwidth + box.width
        local totalwidth = addwidth + (colindex - 1) * charspace
        local breakline = false
        -- 若累加宽度大于最大宽度
        -- 则当前元素为下一行第一个元素
        if totalwidth > maxwidth then
            rowindex = rowindex + 1
            addwidth = box.width -- 累加数值置当前node宽度(为下一行第一个)
            colindex = 1
            breakline = true
        end

        -- 在当前行插入node
        local curline = alllines[rowindex] or {}
        alllines[rowindex] = curline
        table.insert(curline, node)

        -- 若还没有换行，并且换行符存在，则下一个node直接转为下一行
        if not breakline and self:adjustContentLinebreak_(node) then
            rowindex = rowindex + 1
            colindex = 0
            addwidth = 0 -- 累加数值置0
        end
    end
    return alllines
end

-- 判断是否为文本换行符
function RichLabel:adjustContentLinebreak_(node)
    -- 若为Label则有此方法
    if node.getString then
        local str = node:getString() 
        -- 查看是否为换行符
        if str == "\n" then
            return true
        end
    end
    return false
end

-- 
-- utils
--

-- 解析16进制颜色rgb值
function  RichLabel:convertColor(xstr)
    if not xstr then return 
    end
    local toTen = function (v)
        return tonumber("0x" .. v)
    end

    local b = string.sub(xstr, -2, -1) 
    local g = string.sub(xstr, -4, -3) 
    local r = string.sub(xstr, -6, -5)

    local red = toTen(r)
    local green = toTen(g)
    local blue = toTen(b)
    if red and green and blue then 
        return cc.c4b(red, green, blue, 255)
    end
end

-- 拆分出单个字符
function RichLabel:stringToChars(str)
    -- 主要用了Unicode(UTF-8)编码的原理分隔字符串
    -- 简单来说就是每个字符的第一位定义了该字符占据了多少字节
    -- UTF-8的编码：它是一种变长的编码方式
    -- 对于单字节的符号，字节的第一位设为0，后面7位为这个符号的unicode码。因此对于英语字母，UTF-8编码和ASCII码是相同的。
    -- 对于n字节的符号（n>1），第一个字节的前n位都设为1，第n+1位设为0，后面字节的前两位一律设为10。
    -- 剩下的没有提及的二进制位，全部为这个符号的unicode码。
    local list = {}
    local len = string.len(str)
    local i = 1 
    while i <= len do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
        elseif (c >= 240 and c <= 247) then
            shift = 4
        end
        local char = string.sub(str, i, i+shift-1)
        i = i + shift
        table.insert(list, char)
    end
    return list, len
end

function RichLabel:split(str, delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

function RichLabel:printf(fmt, ...)
    return print(string.format("RichLabel# "..fmt, ...))
end

-- drawdot(self, cc.p(200, 200))
function RichLabel:drawdot(canvas, pos, radius, color4f)
    radius = radius or 2
    color4f = color4f or cc.c4f(1,0,0,0.5)
    local drawnode = cc.DrawNode:create()
    drawnode:drawDot(pos, radius, color4f)
    canvas:addChild(drawnode)
    return drawnode
end

-- drawrect(self, cc.rect(200, 200, 300, 200))
function RichLabel:drawrect(canvas, rect, borderwidth, color4f, isfill)
    local bordercolor = color4f or cc.c4f(1,0,0,0.5)
    local fillcolor = isfill and bordercolor or cc.c4f(0,0,0,0)
    borderwidth = borderwidth or 2

    local posvec = {
        cc.p(rect.x, rect.y),
        cc.p(rect.x, rect.y + rect.height),
        cc.p(rect.x + rect.width, rect.y + rect.height),
        cc.p(rect.x + rect.width, rect.y)
    }
    local drawnode = cc.DrawNode:create()
    drawnode:drawPolygon(posvec, 4, fillcolor, borderwidth, bordercolor)
    canvas:addChild(drawnode)
    return drawnode
end

-- 创建精灵，现在帧缓存中找，没有则直接加载
-- 屏蔽了使用图集和直接使用碎图创建精灵的不同
function RichLabel:getSprite(filename)
    local spriteFrameCache = cc.SpriteFrameCache:getInstance()
    local spriteFrame = spriteFrameCache:getSpriteFrameByName(filename)

    if spriteFrame then
        return cc.Sprite:createWithSpriteFrame(spriteFrame)
    end
    return cc.Sprite:create(filename)
end

function RichLabel:parse(text)
    -- 用于存储解析结果
    local parsedtable = {}
    -- 检测开头和结尾是否为标签 <xxx>即为标签
    if not string.find(text, "^%b<>.+%b<>$") then
        -- 在最外层包装一个标签，便于解析时的统一处理，不用处理没有包装标签的情况
        text = table.concat({LABEL_DIV_BEGIN, text, LABEL_DIV_END})
    end
    -- 标签头栈，用于存储标签头(<div>是标签头，</div>是标签尾)
    -- 标签头存储了格式信息，碰到标签时可以直接使用当前栈顶的标签头格式信息，应用到标签之间的内容上
    local labelheadstack = {}
    -- 迭代所有格式为<xxx>的标签(包含了标签头和标签尾巴)
    local index = 0
    for beginindex, endindex in function() return string.find(text, "%b<>", index) end do
        local label = string.sub(text, beginindex, endindex)
        -- 检测字符串是否以"</"开头
        if string.find(label, "^</") then
            -- 标签尾
            self:disposeLabelTail(labelheadstack, parsedtable, text, label, beginindex, endindex)
        elseif string.find(label, "/>$") then -- 检测以'/>'结尾
            -- 自闭合标签
            self:disposeLabelSelfClosing(labelheadstack, parsedtable, text, label, beginindex, endindex)
        else-- 检测到标签头
            self:disposeLabelHead(labelheadstack, parsedtable, text, label, beginindex, endindex)
        end

        index = endindex + 1
    end
    
    return parsedtable
end

-- 处理标签头
function RichLabel:disposeLabelHead(labelheadstack, parsedtable, text, labelhead, beginindex, endindex)
    -- 取出当前栈顶位置的标签信息
    local labelinfo = self:peekstack(labelheadstack)
    if labelinfo then
        -- 获得当前标签头和上一个标签头之间内容(标签嵌套造成)
        local content = string.sub(text, labelinfo.endindex+1, beginindex-1)
        -- 解析两个标签头之间的内容
        local labelparams = self:parseLabelWithContent(labelinfo.labelhead, content)
        table.insert(parsedtable, labelparams)
    end
    -- 将当前标签头和位置信息，放入栈顶位置
    self:pushstack(labelheadstack, {["labelhead"]=labelhead, ["beginindex"]=beginindex, ["endindex"]=endindex})
end

-- 处理标签尾
function RichLabel:disposeLabelTail(labelheadstack, parsedtable, text, labeltail, beginindex, endindex, selfclosing)
    -- 检测到标签尾，可以解析当前标签范围内的串，标签头在栈顶位置
    -- 将与标签尾对应的标签头出栈(栈顶)
    local labelinfo = self:popstack(labelheadstack)
    -- 解析栈顶标签头和当前标签尾之间的内容
    if labelinfo then
        -- 检测标签是否匹配
        if not self:checkLabelMatch(labelinfo.labelhead, labeltail) then
            return print(string.format("labelparser # error: label can not match(%s, %s)", 
                labelinfo.labelhead, labeltail))
        end
        -- 获得当前标签尾和对应标签头之间内容
        local content = string.sub(text, labelinfo.endindex+1, beginindex-1)
        local labelparams = self:parseLabelWithContent(labelinfo.labelhead, content, selfclosing)
        table.insert(parsedtable, labelparams)
        -- 因为此前内容都解析过了，所以修改栈顶标签头信息，让其修饰范围改变为正确的
        -- 修改当前栈顶标签头位置到当前标签尾的范围
        local labelinfo_unused = self:peekstack(labelheadstack)
        if labelinfo_unused then
            labelinfo_unused.beginindex = beginindex
            labelinfo_unused.endindex = endindex
        end
    end
end

-- 处理自闭合标签
function RichLabel:disposeLabelSelfClosing(labelheadstack, parsedtable, text, label, beginindex, endindex)
    self:disposeLabelHead(labelheadstack, parsedtable, text, label, beginindex, endindex)
    self:disposeLabelTail(labelheadstack, parsedtable, text, label, beginindex, endindex, true)
end

-- 检测标签头和标签尾是否配对，即标签名是否相同
function RichLabel:checkLabelMatch(labelhead, labeltail)
    local labelheadname = self:parseLabelname(labelhead)
    local labeltailname = self:parseLabelname(labeltail)
    return labeltailname == labelheadname
end

-- 整合标签头属性和内容
function RichLabel:parseLabelWithContent(labelhead, content, selfclosing)
    -- 不是自闭和标签则，则检测内容，内容为空则直接返回
    if not selfclosing then
        if content == nil or content == "" then return
        end
    else
        -- 是自闭和标签
        content = nil
    end
    -- 获得标签名称
    local labelname = self:parseLabelname(labelhead)

    -- 解析标签属性
    local labelparams = self:parseLabelHead(labelhead)
    labelparams.labelname = labelname
    labelparams.content = content
    return labelparams
end

-- 从标签头或者标签尾解析出标签名称
function RichLabel:parseLabelname(label)
    -- 解析标签名
    local labelnameindex1, labelnameindex2 = string.find(label, "%w+")
    if not labelnameindex1 then
        return print ("labelparser # error: label name not found") and nil
    end
    -- 获得标签名称
    local labelname = string.sub(label, labelnameindex1, labelnameindex2)
    local labelname = string.lower(labelname)
    return labelname
end

-- 解析标签头属性
function RichLabel:parseLabelHead(labelhead)
    local labelparams = {}
    -- 匹配格式：property=value
    -- value要求非空白字符并且不含有‘>’
    for property in string.gmatch(labelhead, "[%w%_]+%=[^%s%>]+") do
        local equalmarkpos = string.find(property, "=")
        -- 分离属性名和属性值
        local propertyname = string.sub(property, 1, equalmarkpos-1)
        local propertyvalue = string.sub(property, equalmarkpos+1, string.len(property))
        -- 属性名转为小写
        propertyname = string.lower(propertyname)
        -- 属性值处理
        local continue = false
        -- 1.检测是否为字符串(单引号或者双引号括起来)
        local beginindex, endindex = string.find(propertyvalue, "['\"].+['\"]")
        if beginindex then
            propertyvalue = string.sub(propertyvalue, beginindex+1, endindex-1)
            continue = true
        end
        -- 2.检测是否为布尔值
        if not continue then
            local propertyvalue_lower = string.lower(propertyvalue)
            if propertyvalue_lower == BOOLEAN_TRUE then 
                propertyvalue = true 
                continue = true
            elseif propertyvalue_lower == BOOLEAN_FALSE then 
                propertyvalue = false 
                continue = true
            end
        end
        -- 3.检测是否为数字
        if not continue then
            local propertyvalue_number = tonumber(propertyvalue)
            if propertyvalue_number then 
                propertyvalue = propertyvalue_number 
                continue = true
            end
        end
        -- 若以上都不是，则默认直接为字符串
        labelparams[propertyname] = propertyvalue
    end
    return labelparams
end

function RichLabel:popstack(stacktable)
    local elem = stacktable[#stacktable]
    stacktable[#stacktable] = nil
    return elem
end

function RichLabel:pushstack(stacktable, elem)
    table.insert(stacktable, elem)
end

function RichLabel:peekstack(stacktable)
    return stacktable[#stacktable]
end

return RichLabel