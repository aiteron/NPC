NPCTutorial = {}

local text = "<H1> Hi! Thanks for choosing NPC mod <BR> <TEXT> <IMAGECENTRE:media/ui/AiteronLogo.png> <LINE><LINE> " ..
"<CENTRE> <SIZE:large> This is a alpha build <LINE><LINE> " ..
"<CENTRE> It took hundreds of hours of development to create the mod and thousands of lines of code were written. <LINE><LINE> " ..
"<CENTRE> Enjoy! If you want to support me - below links to my patreon and ko-fi. <LINE><LINE> " ..
"<CENTRE> YouTube:  shorturl.at/xyBQY <LINE>" ..
"<CENTRE> Patreon: patreon.com/aiteron <LINE>" ..
"<CENTRE> Ko-fi: ko-fi.com/aiteron <LINE><LINE>" ..
"<CENTRE> Tutorial: <LINE> " ..
"<CENTRE> Radial menu - Tab key <LINE> " ..
"<CENTRE> NPC settings - in global settings <LINE> " ..
"<CENTRE> Video tutorial: TODO <LINE><LINE> "

function NPCTutorial.onGameBoot()
    local animPopup = ISModalRichText:new(getCore():getScreenWidth()/2-350,getCore():getScreenHeight()/2-300,700,600, text);
    animPopup:initialise();
    animPopup.backgroundColor = {r=0, g=0, b=0, a=0.9};
    animPopup.alwaysOnTop = true;
    animPopup.chatText:paginate();
    animPopup:setY(getCore():getScreenHeight()/2-(animPopup:getHeight()/2));
    animPopup:setVisible(true);
    animPopup:addToUIManager();
end


Events.OnGameBoot.Add(NPCTutorial.onGameBoot)