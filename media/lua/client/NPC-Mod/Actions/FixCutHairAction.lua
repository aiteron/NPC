local tmpFunc = ISCutHair.start
function ISCutHair:start()
    self:setActionAnim(CharacterActionAnims.Bandage);
    self:setAnimVariable("BandageType", "Head");
    tmpFunc(self)    
end