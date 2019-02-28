-- gui library 
local gui = {}
gui.uid = 0

-- unique identifier for each node
function gui.getUID()
    gui.uid = gui.uid + 1
    return gui.uid
end

-- root element for all gui
function gui.newNode(pX, pY)
    local myNode = {}

    -- unique identifier
    myNode.uid = gui.getUID()

    -- relative position to the tree
    myNode.relativeX = pX
    myNode.relativeY = pY

    -- absolute position
    myNode.absoluteX = pX
    myNode.absoluteY = pY
    
    -- each node is a tree
    myNode.lstChildren = {}

    -- visible group
    myNode.visible = true

    -- events
    myNode.lstEvents = {}

    -- append a new gui element
    -- register as its new parent
    function myNode:appendChild(pChildNode)
        table.insert(self.lstChildren, pChildNode)
        pChildNode:setParent(self)
    end

    -- remove gui element
    function myNode:removeChild(pChildNode)
        for i = #self.lstChildren, 1, -1 do
            if self.lstChildren[i].uid == pChildNode.uid then
                table.remove(self.lstChildren, i)
                return
            end
        end
    end

    -- add a parent
    -- removes old parent
    function myNode:setParent(pParentNode)
        if self.parent ~= nil then
            self:removeParent()
        end
        self.parent = pParentNode
        self:refreshPosition()
    end

    -- removes parent
    function myNode:removeParent()
        self.parent:removeChild(self)
        self.parent = nil

        -- reset position
        myNode.absoluteX = relativeX
        myNode.absoluteY = relativeY
    end

    -- refresh absolute position
    function myNode:refreshPosition()
        if self.parent then
            self.absoluteX = self.relativeX + self.parent.absoluteX
            self.absoluteY = self.relativeY + self.parent.absoluteY
        end
        for n, v in pairs(self.lstChildren) do
            v:refreshPosition()
        end
    end

    -- show / hide every elts in the group
    function myNode:setVisible(pVisible)
        self.visible = pVisible
        for n, v in pairs(self.lstChildren) do
            v:setVisible(pVisible)
        end
    end

    -- update all elements
    function myNode:updateChildren(dt)
        for n, v in pairs(self.lstChildren) do
            v:update(dt)
        end
    end

    -- update function
    function myNode:update(dt)
        self:updateChildren(dt)
    end

    -- draw all elements
    function myNode:drawChildren()
        -- allows temporary trasformations and color modification
        love.graphics.push('all')
        for n, v in pairs(self.lstChildren) do
            v:draw()
        end
        -- close temporary transformations and color modification
        love.graphics.pop()
    end

    -- draw all elements
    function myNode:draw()
        self:drawChildren()
    end
    
    -- add new event listener
    function myNode:setEvent(pEventType, pFunction, pCaller)
        self.caller = pCaller
        self.lstEvents[pEventType] = pFunction
    end

    return myNode
end

function gui.newPanel(pX, pY, pW, pH)
    local myPanel = gui.newNode(pX, pY)
    myPanel.w = pW
    myPanel.h = pH
    myPanel.image = nil
    myPanel.circular = false
    myPanel.radius = 0
    myPanel.isHover = false
    myPanel.lstEvents = {}
    myPanel.isPressed = false
    myPanel.oldButtonState = false
    myPanel.color = {1,1,1}
    -- dragging
    myPanel.draggable = false
    myPanel.dragConstraint = "none"
    myPanel.isDragged = false
    myPanel.oldMouseDownX = 0
    myPanel.oldMouseDownY = 0
    
    -- allows / disable dragging
    function myPanel:setDraggable(pDraggable, pDragConstraint)
        self.draggable = pDraggable
        self.dragConstraint = pDragConstraint
    end

    function myPanel:updatePanel(dt)
        local mx, my = love.mouse.getPosition()
        
        local left = self.absoluteX - self.w / 2
        local top = self.absoluteY - self.h / 2
        local right = self.absoluteX + self.w / 2
        local bottom = self.absoluteY + self.h / 2
        
        -- is the panel hovered by the mouse
        if mx > left and mx < right and
           my > top and my < bottom 
        then
            if not self.isHover then
                self.isHover = true
                if self.lstEvents["hover"] ~= nil then
                    self.lstEvents["hover"](self.caller, "begin")
                end
            end
        else
            if self.isHover then
                self.isHover = false
                if self.lstEvents["hover"] ~= nil then
                    self.lstEvents["hover"](self.caller, "begin")
                end
            end
        end

        -- is the panel pressed by the mouse
        local mouseDown = love.mouse.isDown(1)
        if self.isHover and  mouseDown and not self.isPressed and not self.oldButtonState then
            self.isPressed = true
            -- set dragged
            if self.draggable then
                self.isDragged = true
                self.oldMouseDownX = mx
                self.oldMouseDownY = my
            end
            -- use begin event
            if self.lstEvents["pressed"] ~= nil then
                self.lstEvents["pressed"](self.caller, "begin")
            end
        else
            if self.isPressed and not mouseDown then
                self.isPressed = false
                -- unset dragged
                self.isDragged = false
                -- use end event
                if self.lstEvents["pressed"] ~= nil then
                    self.lstEvents["pressed"](self.caller, "end")
                end
            end 
        end

        self.oldButtonState = mouseDown

        -- dragging behaviour
        if self.isDragged then
            -- compute relative change of position
            local dx = mx - self.oldMouseDownX
            local dy = my - self.oldMouseDownY
            -- update position
            if self.dragConstraint ~= "vertical" then
                self.relativeX = self.relativeX + dx
            end
            if self.dragConstraint ~= "horizontal" then
                self.relativeY = self.relativeY + dy
            end
            -- update children position too
            self:refreshPosition(self)
            -- refresh mouse old position
            self.oldMouseDownX = mx
            self.oldMouseDownY = my
        end
    end

    function myPanel:update(dt)
        self:updatePanel(dt)
        self:updateChildren(dt)
    end

    function myPanel:setCircular(pRadius)
        self.radius = pRadius
        self.circular = true
    end

    function myPanel:setRectangular(pW, pH)
        self.circular = false
        self.w = pW
        self.h = pH
    end

    function myPanel:setImage(pImage)
        self.image = pImage
        self.w = pImage:getWidth()
        self.h = pImage:getHeight()
    end

    function myPanel:drawPanel()
        love.graphics.setColor(self.color)
        if self.image == nil then
            if self.circular then
                love.graphics.circle("line", self.absoluteX, self.absoluteY, self.radius)
            else
                local left = self.absoluteX - self.w / 2
                local top = self.absoluteY - self.h / 2
                love.graphics.rectangle("line", left, top, self.w, self.h)
            end
        else
            love.graphics.draw(self.image, self.x, self.y)
        end
    end

    function myPanel:draw()
        if not self.visible then 
            return 
        end
        self:drawPanel()
        self:drawChildren()
    end

    function myPanel:setColor(pColor)
        self.color = pColor
    end

    return myPanel
end

function gui.newText(pX, pY, pW, pH, pText, pFont, pHAlign, pVAlign, pColor)
    local myText = gui.newPanel(pX, pY, pW, pH)
    myText.text = pText
    myText.font = pFont
    myText.hAlign = pHAlign
    myText.vAlign = pVAlign
    myText.textW = pFont:getWidth(pText)
    myText.textH = pFont:getHeight(pText)
    myText.color = pColor

    function myText:drawText()
        love.graphics.setColor(pColor)
        love.graphics.setFont(self.font)
        local x = self.absoluteX
        local y = self.absoluteY
        if self.hAlign then
            x = x - self.textW / 2
        end
        if self.vAlign then
            y = y - self.textH / 2
        end
        love.graphics.print(self.text, x, y)
    end

    function myText:draw()
        if not self.visible then
            return
        end
        self:drawText()
        self:drawChildren()
    end

    return myText
end

function gui.newButton(pX, pY, pW, pH, pText, pFont, pColor)
    local myButton = gui.newPanel(pX, pY, pW, pH)
    myButton:setColor(pColor)
    myButton.text = pText
    myButton.font = pFont
    myButton:appendChild(gui.newText(0, 0, pW, pH, pText, pFont, true, true, pColor))

    function myButton:updateButton(dt)
    end

    function myButton:update(dt)
        self:updateChildren(dt)
        self:updatePanel(dt)
        self:updateButton(dt)
    end

    function myButton:drawButton()
        local left = self.absoluteX - self.w / 2
        local top = self.absoluteY - self.h / 2

        if self.isPressed then
            self:drawPanel()
            love.graphics.setColor(1, 1, 1, 0.5)
            if (self.circular) then
                love.graphics.circle("fill", self.absoluteX, self.absoluteY, self.radius)
            else
                love.graphics.rectangle("fill", left, top, self.w, self.h)
            end
            
        elseif self.isHover then
            self:drawPanel()
            love.graphics.setColor(1, 1, 1, 0.2)
            if (self.circular) then
                love.graphics.circle("fill", self.absoluteX, self.absoluteY, self.radius - 2)
            else
                love.graphics.rectangle("fill", left + 2, top + 2, self.w - 4, self.h - 4)
            end
        else
            self:drawPanel()
        end
    end

    function myButton:draw()
        if not self.visible then
            return
        end
        self:drawButton()
        self:drawChildren()
    end

    return myButton
end


return gui