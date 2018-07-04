local composer=require("composer");
local scene=composer.newScene();

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local physics=require("physics");
physics.start();
physics.setGravity(0, 0);

--audio variabili
local backgroundTrack;
local shootTrack;
local powerUPTrack;
local deadTrack;
local shakeTrack;
local shootRocketTrack;
local explosionTrack;

local lives=3;
local score=0;

local levels=1;
local rimosso=0;
local done=0;

local alreadyShaked=0;
local alreadyBlasted=0; 

local gameLoopTimerChicken;
local gameLoopTimerAsteroid;
local gameLoopTimerEggs;
local gameLoopTimerLaser;

local ship;
local died=false;
local chickenLives=2;

local chickenTable={};
local chickenPosTable={};
local asteroidsTable={};

local livesText;
local scoreText;

local backGroup;
local mainGroup;
local uiGroup;

local fireSpeed=4000; -- +speed = lento --4000 ok
local fireSpawn=700; -- +spawn = lento --700 ok

local numChicken=25; --non cambia, statico
local numAsteroid=20;

local presentUp;
local posPresentX=0;
local posPresentY=0;

local powerUP=0;

local function endGame(event)
	if(done==0) then
		done=1;
		composer.setVariable("score", score);
		composer.gotoScene("highscores",
			{
				time=800;
				effect="crossFade";
			}
		);
	end
end

local function positionChicken(position)
	chicken = {
		{x = 100, y = 170, life=chickenLives},
		{x = 210, y = 170, life=chickenLives},
		{x = 320, y = 170, life=chickenLives},
		{x = 430, y = 170, life=chickenLives},
		{x = 540, y = 170, life=chickenLives},
		
		{x = 100, y = 280, life=chickenLives},
		{x = 210, y = 280, life=chickenLives},
		{x = 320, y = 280, life=chickenLives},
		{x = 430, y = 280, life=chickenLives},
		{x = 540, y = 280, life=chickenLives},
		
		{x = 100, y = 390, life=chickenLives},
		{x = 210, y = 390, life=chickenLives},
		{x = 320, y = 390, life=chickenLives},
		{x = 430, y = 390, life=chickenLives},
		{x = 540, y = 390, life=chickenLives},
		
		{x = 100, y = 500, life=chickenLives},
		{x = 210, y = 500, life=chickenLives},
		{x = 320, y = 500, life=chickenLives},
		{x = 430, y = 500, life=chickenLives},
		{x = 540, y = 500, life=chickenLives},
		
		{x = 100, y = 610, life=chickenLives},
		{x = 210, y = 610, life=chickenLives},
		{x = 320, y = 610, life=chickenLives},
		{x = 430, y = 610, life=chickenLives},
		{x = 540, y = 610, life=chickenLives},
	}	
	return chicken[position];
end

--creo il pollo
local function createChicken()
	if(done==0) then
		local newChicken;
		if(levels==1) then
			newChicken=display.newImageRect(mainGroup, "chicken.png", 100, 100);
		elseif(levels>=2) then
			newChicken=display.newImageRect(mainGroup, "chickenBLU.png", 100, 100);
		end
		
		table.insert(chickenTable, newChicken);
		
		local position=positionChicken(#chickenTable); --passo il numero dei polli inseriti e quindi ritorno la posizione dell'ultimo pollo
		newChicken.x=position.x;
		newChicken.y=position.y; 
		newChicken.life=position.life;
		
		table.insert(chickenPosTable, position); --chickenPosTable[i]=chickenTable[i] solo che uno mantiene la posizione, l'altro il pollo
		
		physics.addBody(newChicken, 'static');
		newChicken.died=false;
		newChicken.myName="chicken";
	end
end

local function createDeadegg()
	local newDeadegg=display.newImageRect("deadEgg.png", 60, 60);
	physics.addBody(newDeadegg, "static");
	newDeadegg.myName="deadEgg";
	
	transition.to(newDeadegg, 
		{
			time=1000; 
			onComplete=function() 
				display.remove(newDeadegg);
			end
		}
	);
	return newDeadegg;
end

local function createEgg()
	if(chickenTable[1]~=nil) then	--se vuoto allora hai completato il gioco
		local posChicken=positionChicken(math.random(#chickenTable));
		local shootEgg=false;
		
		for i=1, #chickenTable, 1 do
			if(chickenTable[i].x==posChicken.x and chickenTable[i].y==posChicken.y and chickenTable[i].life>0) then
				shootEgg=true;
				break;
			end
		end
	
		if(shootEgg==true) then
			local newEgg=display.newImageRect(mainGroup, "egg.png", 60, 60);
			physics.addBody(newEgg, "dynamic", {isSensor=true;});
			newEgg.isBullet=true;
			newEgg.myName="egg";

			newEgg.x=posChicken.x;
			newEgg.y=posChicken.y+50;
			newEgg:toBack();

			transition.to(newEgg, 
				{
					y=1100;
					time=5000; 
					onComplete=function() 
						display.remove(newEgg);
						deadEgg=createDeadegg();
						deadEgg.x=newEgg.x;
						deadEgg.y=display.contentHeight-30;
						deadEgg:toBack();
					end
				}
			);
		end
	end
end

--CREO IL PRESENT CHE SCENDE
local function createPresent()
	local newPresent=display.newImageRect(mainGroup, "present.png", 50, 50);
	physics.addBody(newPresent, "dynamic", {isSensor=true;});
	
	newPresent.isBullet=true;
	newPresent.myName="present";
	newPresent:toBack();
	
	newPresent.x=posPresentX;
	newPresent.y=posPresentY;
	
	transition.to(newPresent, 
		{
			time=4000;
			y=1250;
			onComplete=function() 
				display.remove(newPresent);
			end
		}
	);
end

local function createAsteroid()
	if(levels==3 and done==0) then
		local newAsteroid=display.newImageRect(mainGroup, "asteroidFire.png", 100, 100);
		table.insert(asteroidsTable, newAsteroid);
		
		physics.addBody(newAsteroid, "dynamic", {radius=40;})
		newAsteroid.myName="asteroid";
		
		newAsteroid.x=math.random(display.contentWidth);
		newAsteroid.y=60;
		newAsteroid.life=2;
		--così oppure con transition.to
		newAsteroid:setLinearVelocity(0, 500);
	
	elseif(levels==4 and lives>0 and done==0) then 
		local newAsteroid=display.newImageRect(mainGroup, "asteroid.png", 100, 100);
		table.insert(asteroidsTable, newAsteroid);
		
		physics.addBody(newAsteroid, "dynamic", {radius=40; bounce=0.8;})
		newAsteroid.myName="asteroid";
		newAsteroid.life=2;
		
		local posAsteroid=math.random(3);
		
		if(posAsteroid==1) then
			-- Top
			newAsteroid.x=math.random(display.contentWidth);
			newAsteroid.y=-60;
			newAsteroid:setLinearVelocity(math.random(-40, 40), 300);
		elseif(posAsteroid==2) then
			--Left
			newAsteroid.x=-60;
			newAsteroid.y=math.random(500);
			newAsteroid:setLinearVelocity(math.random(40, 120), 200);
		elseif (posAsteroid==3) then
			-- Right
			newAsteroid.x=display.contentWidth+60;
			newAsteroid.y=math.random(500);
			newAsteroid:setLinearVelocity(math.random(-120, -40), 200);
		end
		
		newAsteroid:applyTorque(math.random(-6, 6));
	end
end

local function destroyAsteroid()
	for i=#asteroidsTable, 1, -1 do
		local thisAsteroid=asteroidsTable[i];
		display.remove(asteroidsTable, i);
		table.remove(asteroidsTable, i);
		rimosso=rimosso+1;
	end
end

local function resumeLaser()
	timer.resume(gameLoopTimerLaser);
end

local function pauseLaser()
	timer.pause(gameLoopTimerLaser);
end

local function finalLevelText()
	local title=display.newText(uiGroup, "Livello 4", display.contentCenterX, display.contentCenterY, native.systemFont, 70)
	title:setFillColor(0.82, 0.78, 1);
	transition.to(title, 
		{
			time=2000; 
			onComplete=function()
				display.remove(title);
			end; 
		}
	);
	
	local subTitle=display.newText(uiGroup, "Ancora asteroidi?", display.contentCenterX, display.contentCenterY+100, native.systemFont, 44);
	subTitle:setFillColor(0.82, 0.78, 1);
	transition.to(subTitle, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(subTitle);
			end; 
		}
	);
end

local function gameLoop()
	createAsteroid();
	for i=#asteroidsTable, 1, -1 do --inizia dal numero degli asteroidi, si ferma a 1 e conta con -1
		local thisAsteroid=asteroidsTable[i];
		
		if(thisAsteroid.x<-100 or thisAsteroid.x>display.contentWidth+100 or thisAsteroid.y>display.contentHeight+100) then
			display.remove(thisAsteroid);
			table.remove(asteroidsTable, i);
			rimosso=rimosso+1;	
		end
	end
	
	if(#asteroidsTable+rimosso==numAsteroid) then	--se arrivo a 25 asteroidi allora ho completato il livello N.B. messa variabile rimuovi per rimuoverne alcuni in modo da non far pesare troppo la memoria
		if(levels==3) then
			levels=levels+1;
			timer.performWithDelay(4000, destroyAsteroid);
			
			--creo funzione il cui unico scopo è di rallentare l'esecuzione del gameLoopTimerAsteroid
			local function performWithDelayAsteroid()
				gameLoopTimerAsteroid=timer.performWithDelay(500, gameLoop, numAsteroid);
			end
			
			--creo una funzione che mi avvisa che siamo all'ultimo livello
			timer.performWithDelay(2000, finalLevelText);
			
			timer.performWithDelay(7000, performWithDelayAsteroid);
			timer.performWithDelay(1000, pauseLaser);
			timer.performWithDelay(7000, resumeLaser);
		end
		
		if(levels==4) then
			destroyAsteroid();
			if(asteroidsTable[1]==nil) then
				timer.performWithDelay(25500, endGame);	--serve per far passare tutta la durata del livello
				
				--creo funzione il cui unico scopo è di rallentare l'esecuzione del gameLoopTimerLaser
				local function performWithDelayLaser()
					timer.pause(gameLoopTimerLaser);
				end
				
				timer.performWithDelay(21000, performWithDelayLaser);
			end
		end
	end
end

local function nextLevel()
	levels=levels+1;
	if(levels==2) then
		timer.performWithDelay(1000, resumeLaser);
		gameLoopTimerChicken=timer.performWithDelay(100, createChicken, 25);
	elseif(levels==3) then
		timer.performWithDelay(500, resumeLaser);
		gameLoopTimerAsteroid=timer.performWithDelay(500, gameLoop, numAsteroid);
	
	end
	--livello 4 inserito dentro il gameLoop
end

local function shoot()
	
	local newLaser=display.newImageRect(mainGroup, "laser.png", 40, 40);
	physics.addBody(newLaser, "dynamic", {isSensor=true;});
	newLaser.isBullet=true;
	newLaser.myName="laser";
	
	newLaser.y=ship.y;
	newLaser.x=ship.x;
	newLaser:toBack();
	
	transition.to(newLaser, 
		{
			y=-40; 
			time=fireSpeed; 
			onComplete=function()
				display.remove(newLaser);
			end; 
		}
	);
	audio.play(shootTrack);
end

local function dragShip(event)
	
	local ship=event.target;
	local phase=event.phase;
	
	if("began"==phase) then
		display.currentStage:setFocus(ship);
		ship.touchOffsetX=event.x-ship.x;
	
	--ship.touchOffsetX~=nil risolve il bug nel caso premessi prima di iniziare a giocare
	elseif("moved"==phase and ship.touchOffsetX~=nil) then 
		local aux=event.x-ship.touchOffsetX;
		if(aux<45) then 
			ship.x=45;
		elseif(aux>display.contentWidth-45) then
			ship.x=display.contentWidth-45;
		else
			ship.x=event.x-ship.touchOffsetX;
		end
		
	
	elseif("ended"==phase or "cancelled"==phase) then
		display.currentStage:setFocus(nil);
	end
	
	return true;
end

local function restoreShip()
	
	ship.isBodyActive=false;
	ship.x=display.contentCenterX;
	ship.y=display.contentHeight-100;
	
	transition.to(ship, 
		{
			alpha=1;
			time=2000;
			onComplete=function()
				ship.isBodyActive=true;
				died=false;
				timer.resume(gameLoopTimerLaser);
			end
		}
	);
end

local function createBlast(object)
	local newBlast=display.newImageRect(mainGroup, "rocketExplosion.png", 300, 300);
	newBlast.myName="blast";
	
	newBlast.y=object.y;
	newBlast.x=object.x;
	
	transition.to(newBlast, 
		{
			time=500; 
			onComplete=function()
				display.remove(newBlast);
			end; 
		}
	);
	audio.play(explosionTrack);

end

local function removeText(title, subTitle, hint)
	display.remove(title);
	display.remove(subTitle);
	display.remove(hint);
end

local function hintText()
	local text;
	local randomText=math.random(7);
	local hint;
	if(randomText==1 and levels<2) then
	hint=display.newText(uiGroup, "Uccidi polli scuotendo il cellulare", display.contentCenterX, display.contentCenterY+100, native.systemFont, 30);
	hint:setFillColor(0.82, 0.78, 1);
	transition.to(hint, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(hint);
			end; 
		}
	);
	elseif(randomText==2 and levels<2) then
	hint=display.newText(uiGroup, "Uccidi i polli con il doppio tap", display.contentCenterX, display.contentCenterY+100, native.systemFont, 30);
	hint:setFillColor(0.82, 0.78, 1);
	transition.to(hint, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(hint);
			end; 
		}
	);
	elseif(randomText==3 and levels<2) then
	hint=display.newText(uiGroup, "Prova a scuotere il cellulare", display.contentCenterX, display.contentCenterY+100, native.systemFont, 30);
	hint:setFillColor(0.82, 0.78, 1);
	transition.to(hint, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(hint);
			end; 
		}
	);
	elseif(randomText==4) then
	hint=display.newText(uiGroup, "Hai un solo shake, usalo saggiamente", display.contentCenterX, display.contentCenterY+100, native.systemFont, 30);
	hint:setFillColor(0.82, 0.78, 1);
	transition.to(hint, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(hint);
			end; 
		}
	);
	elseif(randomText==5) then
	hint=display.newText(uiGroup, "Hai un solo razzo, usalo saggiamente", display.contentCenterX, display.contentCenterY+100, native.systemFont, 30);
	hint:setFillColor(0.82, 0.78, 1);
	transition.to(hint, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(hint);
			end; 
		}
	);
	elseif(randomText==6) then
	hint=display.newText(uiGroup, "Prova a fare doppio tap sulla navicella", display.contentCenterX, display.contentCenterY+100, native.systemFont, 30);
	hint:setFillColor(0.82, 0.78, 1);
	transition.to(hint, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(hint);
			end; 
		}
	);
	else
	hint=display.newText(uiGroup, "Schiva i pericoli trascinando la navicella", display.contentCenterX, display.contentCenterY+100, native.systemFont, 30);
	hint:setFillColor(0.82, 0.78, 1);
	transition.to(hint, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(hint);
			end; 
		}
	);
	end
end

local function newLevelText()
	if(levels==1) then
		local title=display.newText(uiGroup, "Livello 2", display.contentCenterX, display.contentCenterY-100, native.systemFont, 70)
		title:setFillColor(0.82, 0.78, 1);
		transition.to(title, 
			{
				time=2000; 
				onComplete=function()
					display.remove(title);
				end; 
			}
		);
		
		local subTitle=display.newText(uiGroup, "Attento alle uova", display.contentCenterX, display.contentCenterY, native.systemFont, 44);
		subTitle:setFillColor(0.82, 0.78, 1);
		transition.to(subTitle, 
			{ 
				time=2000; 
				onComplete=function()
					display.remove(subTitle);
				end; 
			}
		);
		hintText();
		timer.performWithDelay(2500, nextLevel);
		
	elseif(levels==2) then
		local title=display.newText(uiGroup, "Livello 3", display.contentCenterX, display.contentCenterY-100, native.systemFont, 70)
		title:setFillColor(0.82, 0.78, 1);
		transition.to(title, 
			{
				time=2000; 
				onComplete=function()
					display.remove(title);
				end; 
			}
		);
		
		local subTitle=display.newText(uiGroup, "Asteroidi in arrivo", display.contentCenterX, display.contentCenterY, native.systemFont, 44);
		subTitle:setFillColor(0.82, 0.78, 1);
		transition.to(subTitle, 
			{ 
				time=2000; 
				onComplete=function()
					display.remove(subTitle);
				end; 
			}
		);
		hintText();
		timer.performWithDelay(2500, nextLevel);
		
	elseif(levels==3) then
		local title=display.newText(uiGroup, "Livello 4", display.contentCenterX, display.contentCenterY-100, native.systemFont, 70)
		title:setFillColor(0.82, 0.78, 1);
		transition.to(title, 
			{
				time=2000; 
				onComplete=function()
					display.remove(title);
				end; 
			}
		);
		local subTitle=display.newText(uiGroup, "Ancora asteroidi?", display.contentCenterX, display.contentCenterY, native.systemFont, 44);
		subTitle:setFillColor(0.82, 0.78, 1);
		transition.to(subTitle, 
			{ 
				time=2000; 
				onComplete=function()
					display.remove(subTitle);
				end; 
			}
		);
		hintText();
		timer.performWithDelay(2500, nextLevel);
	end
end

local function onCollision(event)

	if(event.phase=="began") then
		local obj1=event.object1;
		local obj2=event.object2;
		
		if((obj1.myName=="laser" and obj2.myName=="chicken") or (obj1.myName=="chicken" and obj2.myName=="laser")) then
			
			if(obj1.myName=="laser") then
				display.remove(obj1);
			elseif(obj2.myName=="laser") then
				display.remove(obj2)
			end
			
			--rimuovo il pollo
			for i=#chickenTable, 1, -1 do
				if(chickenTable[i]==obj1 or chickenTable[i]==obj2) then
					chickenTable[i].life=chickenTable[i].life-1;
					if(chickenTable[i].life==0) then
					
						--SERVE PER FAR SCENDERE IL PRESENT, IDEALE 1 SU 30/40 UCCISIONI
						local luckyNumber=math.random(25)
						if(luckyNumber==7) then --allora powerUp
							presentUP=1;
							posPresentX=chickenPosTable[i].x; 
							posPresentY=chickenPosTable[i].y;
						end
					
						--RIMUOVO CHICKEN
						display.remove(obj1);
						display.remove(obj2);
						table.remove(chickenPosTable, i);
						table.remove(chickenTable, i);
					end
					break;
				end
			end			
			--aumento lo score
			score=score+100;
			scoreText.text="Score: " .. score;
			
			audio.play(collisionTrack);
			
			if(chickenTable[1]==nil) then	--se vuoto allora hai completato il livello
				pauseLaser();	--metto in pausa il laser
				timer.performWithDelay(2500, newLevelText);
			end	
			
		elseif( ((obj1.myName=="ship" and obj2.myName=="egg") or (obj1.myName=="egg" and obj2.myName=="ship")) or ((obj1.myName=="ship" and obj2.myName=="asteroid") or (obj1.myName=="asteroid" and obj2.myName=="ship")) ) then
			if(died==false) then
				died=true;
				
				--perdi un powerUP
				if(powerUP>0) then
					powerUP=powerUP-1;
					fireSpeed=fireSpeed+50;
				end
				
				--diminuisco le vite
				lives=lives-1;
				livesText.text="Lives: " .. lives;
				
				audio.play(deadTrack);
				
				--fine gioco
				if(lives==0) then
					display.remove(ship);
					display.remove(eggs);
					timer.cancel(gameLoopTimerLaser);
					timer.pause(gameLoopTimerEggs);
					timer.performWithDelay(2000, endGame);
					--timer.cancel(gameLoopTimerLaser); messo in scene:hide
				else --riparto dopo un secondo
					ship.alpha=0;
					timer.pause(gameLoopTimerLaser);
					timer.performWithDelay(1000, restoreShip);
				end
			end
			
		elseif((obj1.myName=="laser" and obj2.myName=="asteroid") or (obj1.myName=="asteroid" and obj2.myName=="laser")) then
			
			if(obj1.myName=="laser") then
				display.remove(obj1);
			elseif(obj2.myName=="laser") then
				display.remove(obj2)
			end
			
			for i=#asteroidsTable, 1, -1 do
				if(asteroidsTable[i]==obj1 or asteroidsTable[i]==obj2) then
					asteroidsTable[i].life=asteroidsTable[i].life-1;
					if(asteroidsTable[i].life==0) then
						display.remove(obj1);
						display.remove(obj2);
						table.remove(asteroidsTable, i);
						rimosso=rimosso+1;	
						break;
					end
				end
			end	
			
			--aumento lo score
			score=score+100;
			scoreText.text="Score: " .. score;
			
		elseif((obj1.myName=="ship" and obj2.myName=="present") or (obj1.myName=="present" and obj2.myName=="ship")) then
			if(obj1.myName=="present") then
				display.remove(obj1);
			elseif(obj2.myName=="present") then
				display.remove(obj2)
			end
			--aumento il powerUP
			if(powerUP<4) then --massimo 3 powerUP per ora
				powerUP=powerUP+1;
				fireSpawn=fireSpawn-50;
				audio.play(powerUPTrack);
			end
			
		--se c'è collisione con il pollo allora elimino i polli circostanti
		elseif((obj1.myName=="rocket" and obj2.myName=="chicken") or (obj1.myName=="chicken" and obj2.myName=="rocket")) then
			
			local xBlast=0;
			local yBlast=0;
			
			if(obj1.myName=="rocket") then
				display.remove(obj1);
				createBlast(obj2);
				xBlast=obj2.x;
				yBlast=obj2.y;
			elseif(obj2.myName=="rocket") then
				display.remove(obj2);
				createBlast(obj1);
				xBlast=obj1.x;
				yBlast=obj1.y;
			end
			
			for i=#chickenTable, 1, -1 do
				if(chickenTable[i].x>=xBlast-150 and chickenTable[i].x<=xBlast+150 and chickenTable[i].y<=yBlast+150 and chickenTable[i].y>=yBlast-150) then
				--RIMUOVO CHICKEN
					display.remove(chickenTable[i]);
					table.remove(chickenPosTable, i);
					table.remove(chickenTable, i);
					score=score+100;
					scoreText.text="Score: " .. score;
				end	
			end
			
			if(chickenTable[1]==nil) then	--se vuoto allora hai completato il livello
				pauseLaser();	--metto in pausa il laser
				timer.performWithDelay(2500, newLevelText);
			end	
		
		elseif((obj1.myName=="rocket" and obj2.myName=="asteroid") or (obj1.myName=="asteroid" and obj2.myName=="rocket")) then
			
			local xBlast=0;
			local yBlast=0;
			
			if(obj1.myName=="rocket") then
				display.remove(obj1);
				createBlast(obj2);
				xBlast=obj2.x;
				yBlast=obj2.y;
			elseif(obj2.myName=="rocket") then
				display.remove(obj2);
				createBlast(obj1);
				xBlast=obj1.x;
				yBlast=obj1.y;
			end
			
			for i=#asteroidsTable, 1, -1 do
				if(asteroidsTable[i].x>=xBlast-150 and asteroidsTable[i].x<=xBlast+150 and asteroidsTable[i].y<=yBlast+150 and asteroidsTable[i].y>=yBlast-150) then
					display.remove(obj1);
					display.remove(obj2);
					table.remove(asteroidsTable, i);
					rimosso=rimosso+1;
					score=score+100;
					scoreText.text="Score: " .. score;
				end
			end	
			
		end
		
	end
	
	if (presentUP==1) then
	--purtroppo non si può creare un oggetto durante la collision
		timer.performWithDelay(50, createPresent);
		presentUP=0;
	end
	
end

local function lethalShake(event)
	--non faccio niente se l'ho già fatto
	if(alreadyShaked==1) then
		return true;
	end
	
	if(event.isShake) then		
		for i=#chickenTable, 1, -1 do
			if(chickenTable[i].x==100 or chickenTable[i].x==540) then
				--RIMUOVO CHICKEN
				display.remove(chickenTable[i]);
				table.remove(chickenPosTable, i);
				table.remove(chickenTable, i);
			end		
		end
		audio.play(shakeTrack);
		alreadyShaked=alreadyShaked+1;
		--NB posso farlo solo fino al livello 2
		if(chickenTable[1]==nil and levels<3) then	--se vuoto allora hai completato il livello
			pauseLaser();	--metto in pausa il laser
			timer.performWithDelay(2500, newLevelText);
		end	
	end
end

local function createRoket()
	if(alreadyBlasted==0) then	
		alreadyBlasted=alreadyBlasted+1;
		
		local newRocket=display.newImageRect(mainGroup, "rocket.png", 100, 100);
		physics.addBody(newRocket, "dynamic", {isSensor=true;});
		newRocket.isBullet=true;
		newRocket.myName="rocket";
		
		newRocket.y=ship.y;
		newRocket.x=ship.x;
		newRocket:toBack();
		
		transition.to(newRocket, 
			{
				y=-40; 
				time=fireSpeed; 
				onComplete=function()
					display.remove(newRocket);
				end; 
			}
		);
		audio.play(shootRocketTrack);
	end
end

local function shootRoket(event)
	if (event.numTaps==2) then
		createRoket();
	end
end

local function createStartDelay()
	gameLoopTimerChicken=timer.performWithDelay(100, createChicken, 25);
	gameLoopTimerEggs=timer.performWithDelay(2000, createEgg, 0);
end

local function startgame()
	local title=display.newText(uiGroup, "Livello 1", display.contentCenterX, display.contentCenterY-100, native.systemFont, 70)
		title:setFillColor(0.82, 0.78, 1);
		transition.to(title, 
			{
				time=2000; 
				onComplete=function()
					display.remove(title);
				end; 
			}
		);
		
	local subTitle=display.newText(uiGroup, "Premi e trascina la navicella", display.contentCenterX, display.contentCenterY, native.systemFont, 44);
	subTitle:setFillColor(0.82, 0.78, 1);
	transition.to(subTitle, 
		{ 
			time=2000; 
			onComplete=function()
				display.remove(subTitle);
			end; 
		}
	);
	timer.performWithDelay(2600, createStartDelay);
	
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

local function goBack()
	done=1;
	composer.gotoScene("menu",
		{
			time=800;
			effect="crossFade";
		}
	);
end


local function onKeyEvent(event)
	if (event.phase=="up" and event.keyName=="back") then
		timer.performWithDelay(100, goBack());
	end
	return true;
end

-- create()
function scene:create(event)

	local sceneGroup=self.view;
	-- Code here runs when the scene is first created but has not yet appeared on screen
	
	physics.pause();
	
	backGroup=display.newGroup();
	sceneGroup:insert(backGroup);
	
	mainGroup=display.newGroup();
	sceneGroup:insert(mainGroup);
	
	uiGroup=display.newGroup();
	sceneGroup:insert(uiGroup);
	
	local background = display.newImageRect(backGroup, "background.jpg", 800, 1400);
	background.x=display.contentCenterX;
	background.y=display.contentCenterY;
	background.alpha=0.4; --opacity
	
	ship=display.newImageRect(mainGroup, "ship.png", 175, 200);
	ship.x=display.contentCenterX;
	ship.y=display.contentHeight-100;
	physics.addBody(ship, {radius=30; isSensor=true;} );
	ship.myName="ship";
	
	backgroundTrack=audio.loadStream("audio/backgroundLoop2.mp3");
	shootTrack=audio.loadSound("audio/pew.wav");
	powerUPTrack=audio.loadSound("audio/PowerUp.mp3");
	deadTrack=audio.loadSound("audio/shipDead.mp3");
	explosionTrack=audio.loadSound("audio/Explosion.mp3");
	shootRocketTrack=audio.loadSound("audio/pewRocket.mp3");
	shakeTrack=audio.loadSound("audio/lethalShake.mp3");	
	
	livesText = display.newText(uiGroup, "Lives: " .. lives, 200, 80, native.systemFont, 36);
	scoreText = display.newText(uiGroup, "Score: " .. score, 400, 80, native.systemFont, 36);
	
	ship:addEventListener("touch", dragShip);
	ship:addEventListener("tap", shootRoket);
end


-- show()
function scene:show(event)

	local sceneGroup=self.view;
	local phase=event.phase;

	if (phase=="will") then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif (phase=="did") then
		-- Code here runs when the scene is entirely on screen
		physics.start();
		Runtime:addEventListener("collision", onCollision);
		Runtime:addEventListener( "accelerometer", lethalShake);
		Runtime:addEventListener("key", onKeyEvent);
		
		audio.play(backgroundTrack, {channel=1, loops=-1});
	
		gameLoopTimerLaser=timer.performWithDelay(fireSpawn, shoot, 0);
		
		if(levels==1) then
			startgame();
		end
	end
end


-- hide()
function scene:hide(event)

	local sceneGroup=self.view;
	local phase=event.phase;

	if (phase=="will") then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		timer.cancel(gameLoopTimerLaser);
		timer.cancel(gameLoopTimerChicken);
		timer.cancel(gameLoopTimerEggs);
		if(levels>2) then
			timer.cancel(gameLoopTimerAsteroid);
		end
		
	elseif (phase=="did") then
		-- Code here runs immediately after the scene goes entirely off screen
		Runtime:removeEventListener("collision", onCollision);
		Runtime:removeEventListener( "accelerometer", lethalShake);
		Runtime:removeEventListener("key", onKeyEvent);
		physics.pause();
		audio.stop(1);
		composer.removeScene("game");
	end
end


-- destroy()
function scene:destroy(event)

	local sceneGroup=self.view;
	-- Code here runs prior to the removal of scene's view
	audio.dispose(backgroundTrack);
	audio.dispose(shootTrack);
	audio.dispose(powerUPTrack);
	audio.dispose(deadTrack);
	audio.dispose(explosionTrack);
	audio.dispose(shootRocketTrack);
	audio.dispose(shakeTrack);
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
