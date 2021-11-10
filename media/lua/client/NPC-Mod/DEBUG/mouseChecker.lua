local containderRender = {}

containderRender.text = TextDrawObject.new()
containderRender.text:setAllowAnyImage(true);
containderRender.text:setDefaultFont(UIFont.Small);
containderRender.text:setDefaultColors(1, 1, 1, 1);

local function testFunc()
    local picked = IsoObjectPicker.Instance:ContextPick(getMouseX(), getMouseY()) 

    if picked ~= nil then
        local objField = getClassField(picked, 2)
        local obj = objField:get(picked)
        if obj ~= nil and obj:getContainer() ~= nil then
            print(obj:getContainer():getType())    
            containderRender.text:ReadString(obj:getContainer():getType())
            containderRender.text:AddBatchedDraw(getMouseX() + containderRender.text:getWidth() + 14, getMouseY() + 20, true)
        end
    end
end


--Events.OnTick.Add(testFunc)