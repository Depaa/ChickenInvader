local composer = require("composer");

local scene = composer.newScene();

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
--rimuovo la barra di stato dei cellulari
display.setStatusBar(display.HiddenStatusBar);
--NB UNA DI QUESTE DOVREBBE ESSERE LA BOTTOM BAR
--display.HiddenStatusBar
--display.DefaultStatusBar
--display.TranslucentStatusBar
--display.DarkStatusBar
--display.LightTransparentStatusBar
--display.DarkTransparentStatusBar

display.setStatusBar(display.DefaultStatusBar);
math.randomseed(os.time());
--audio per il loop
audio.reserveChannels(2);
audio.setVolume(0.1, {channel=1});
audio.setVolume(0.1, {channel=2});
local backgroundTrack;

local function enterGame()
	composer.gotoScene("game", 
		{
			time=800;
			effect="crossFade";
		}
	);
end

local function enterHighscore()
	composer.gotoScene("highscores",
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

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
	
	local background = display.newImageRect(sceneGroup, "background.jpg", 800, 1400);
	background.x=display.contentCenterX;
	background.y=display.contentCenterY;
	background.alpha=0.4; --opacity
	
	local title=display.newText(sceneGroup, "Chicken Invader", display.contentCenterX, 200, native.systemFont, 70)
	title:setFillColor(0.82, 0.78, 1);
	
	local playButton=display.newText(sceneGroup, "Gioca", display.contentCenterX, 700, native.systemFont, 44);
	playButton:setFillColor(0.82, 0.78, 1);
	
	local highscores=display.newText(sceneGroup, "Punteggi Migliori", display.contentCenterX, 810, native.systemFont, 44)
	highscores:setFillColor(0.82, 0.78, 1);
	
	backgroundTrack=audio.loadStream("audio/backgroundLoopWarsDarth.mp3")
	
	playButton:addEventListener("tap", enterGame);
	highscores:addEventListener("tap", enterHighscore);
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		audio.play(backgroundTrack, {channel=2, loops=-1});
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		audio.stop(2);
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view
	audio.dispose(backgroundTrack);
end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene