local composer=require("composer");

local scene=composer.newScene();

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
--serve per utilizzare poi codifica e decodifica del file 
local json=require("json");

local scoreTable={};

local filePath=system.pathForFile("score.json", system.DocumentsDirectory);

local backgroundTrack;

local function loadScore()
	local file=io.open(filePath, "r"); --read only
	
	if(file) then
		local content=file:read("*a");
		io.close(file);
		scoreTable=json.decode(content);
	end
	
	--se è la prima volta allora riempio la tabella con questi risultati
	if(scoreTable==nill or #scoreTable==0) then
		scoreTable={10000, 9000, 8000, 7000, 6000, 5000, 4000, 3000, 2000, 1000};
	end
end

local function saveScore()
	--mi accerto di avere solo 10 score dentro scoreTable
	for i=11, #scoreTable, 1 do
		table.remove(scoreTable, i);
	end
	
	local file=io.open(filePath, "w"); --write only
	
	if(file) then
		file:write(json.encode(scoreTable));
		io.close(file);
	end
end

local function enterMenu()
	composer.gotoScene("menu", 
		{
			time=800;
			effect="crossFade";
		}
	);
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)

	local sceneGroup=self.view;
	-- Code here runs when the scene is first created but has not yet appeared on screen
	loadScore();
	
	table.insert(scoreTable, composer.getVariable("score"));
	composer.setVariable("score", 0);

	local function compare(a, b)
		return a>b;
	end
	
	table.sort(scoreTable, compare);
	
	saveScore();
	
	local background=display.newImageRect(sceneGroup, "background.jpg", 800, 1400);
	background.x=display.contentCenterX;
	background.y=display.contentCenterY;
	background.alpha=0.4; --opacity
	
	local title=display.newText(sceneGroup, "Punteggi Migliori", display.contentCenterX, 100, native.SystemFont, 50);
	title:setFillColor(0.82, 0.78, 1);
	
	for i=1, 10 do
		if(scoreTable[i]) then
			local yPos=150+(i*56);
			
			local rankNum=display.newText(sceneGroup, i .. ".", display.contentCenterX-50, yPos, native.SystemFont, 36);
			rankNum:setFillColor(0.82, 0.78, 1);
			--per allineare i diversi oggetti
			rankNum.anchorX=1; --allineo a dx
			
			local thisScore=display.newText(sceneGroup, scoreTable[i], display.contentCenterX-30, yPos, native.SystemFont, 36);
			thisScore:setFillColor(0.82, 0.78, 1);
			thisScore.anchorX=0; --allineo a sx
		end
	end
	
	backgroundTrack=audio.loadStream("audio/backgroundLoopWarsDarth.mp3")
	
	local menuBotton=display.newText(sceneGroup, "Menu", display.contentCenterX, 810, native.SystemFont, 50);
	menuBotton:setFillColor(0.82, 0.78, 1);
	menuBotton:addEventListener("tap", enterMenu);
end


-- show()
function scene:show(event)

	local sceneGroup=self.view;
	local phase=event.phase;

	if (phase=="will") then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif (phase=="did") then
		-- Code here runs when the scene is entirely on screen
		audio.play(backgroundTrack, {channel=2, loops=-1});
	end
end


-- hide()
function scene:hide(event)

	local sceneGroup=self.view;
	local phase=event.phase;

	if (phase=="will") then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif (phase=="did") then
		-- Code here runs immediately after the scene goes entirely off screen
		composer.removeScene("highscores");
		audio.stop(2);
	end
end


-- destroy()
function scene:destroy(event)

	local sceneGroup=self.view;
	-- Code here runs prior to the removal of scene's view
	audio.dispose(backgroundTrack);
end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener("create", scene);
scene:addEventListener("show", scene);
scene:addEventListener("hide", scene);
scene:addEventListener("destroy", scene);
-- -----------------------------------------------------------------------------------

return scene;
