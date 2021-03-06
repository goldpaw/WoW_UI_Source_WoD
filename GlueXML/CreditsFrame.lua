function CreditsFrame_OnShow(self)
	StopGlueAmbience();
	CreditsFrame.creditsType = GetClientDisplayExpansionLevel() + 1;	--Expansion levels are off by one from credits indices.
	CreditsFrame.maxCreditsType = GetClientDisplayExpansionLevel() + 1;
	CreditsFrame_Update(self);
end

function CreditsFrame_OnHide(self)
	ShowCursor();
end

function CreditsFrame_Update(self)
	PlayGlueMusic(GLUE_CREDITS_SOUND_KITS[CreditsFrame.creditsType]);
	CreditsLogo:SetTexture(EXPANSION_LOGOS[CreditsFrame.creditsType-1]);

	CreditsFrame_SetSpeed(CREDITS_SCROLL_RATE_PLAY);
	CreditsScrollFrame:SetVerticalScroll(0);
	CreditsScrollFrame.scroll = 0;
	CreditsScrollFrame.scrollMax = CreditsScrollFrame:GetVerticalScrollRange() + 768;
	self.artCount = getn(CREDITS_ART_INFO[CreditsFrame.creditsType]);
	self.currentArt = 0;
	self.fadingIn = nil;
	self.fadingOut = nil;
	self.cacheArt = 0;
	self.cacheIndex = 1;
	self.cacheElapsed = 0;
	self.alphaIn = 0;
	self.alphaOut = 0;
	
	for i=1, NUM_CREDITS_ART_TEXTURES_HIGH, 1 do
		for j=1, NUM_CREDITS_ART_TEXTURES_WIDE, 1 do
			_G["CreditsArtAlt"..(((i - 1) * NUM_CREDITS_ART_TEXTURES_WIDE) + j)]:Hide();
			_G["CreditsArtCache"..(((i - 1) * NUM_CREDITS_ART_TEXTURES_WIDE) + j)]:SetAlpha(0.005);
		end
	end

	CreditsFrame_CacheTextures(self, 1);

	-- Set Credits Text
	CreditsText:SetText(GetCreditsText(CreditsFrame.creditsType));

	-- Set Switch Button Text
	local creditsType = CreditsFrame.creditsType;
	if ( creditsType < CreditsFrame.maxCreditsType ) then
		CreditsFrameSwitchButton1:Show();
		CreditsFrameSwitchButton1:SetText(CREDITS_TITLES[creditsType + 1]);
		CreditsFrameSwitchButton1:SetID(creditsType + 1);
	else
		CreditsFrameSwitchButton1:Hide();
	end
	if ( creditsType > 1 ) then
		CreditsFrameSwitchButton2:Show();
		CreditsFrameSwitchButton2:SetText(CREDITS_TITLES[creditsType - 1]);
		CreditsFrameSwitchButton2:SetID(creditsType - 1);
	else
		CreditsFrameSwitchButton2:Hide();
	end
end

function CreditsFrame_Switch(self, buttonID)
	PlaySound("igMainMenuOptionCheckBoxOff");
	CreditsFrame.creditsType = buttonID;
	CreditsFrame_Update(self);
	GlueParent_OpenSecondaryScreen("credits");
end

function CreditsFrame_SetArtTextures(self,textureName, index, alpha)
	local info = CREDITS_ART_INFO[self.creditsType][index];
	if ( not info ) then
		return;
	end
	local path = CREDITS_ART_INFO[self.creditsType].path;
	if ( not path ) then
		path = "";
	end

	local texture;
	local texIndex = 1;
	local width, height;
	_G[textureName..1]:SetPoint("TOPLEFT", "CreditsFrame", "TOPLEFT", info.offsetx, info.offsety - 128);
	for i=1, NUM_CREDITS_ART_TEXTURES_HIGH, 1 do
		height = info.h - ((i - 1) * 256);
		if ( height > 256 ) then
			height = 256;
		end
		for j=1, NUM_CREDITS_ART_TEXTURES_WIDE, 1 do
			texture = _G[textureName..(((i - 1) * NUM_CREDITS_ART_TEXTURES_WIDE) + j)];
			width = info.w - ((j - 1) * 256);
			if ( width > 256 ) then
				width = 256;
			end
			if ( (width <= 0) or (height <= 0) ) then
				texture:Hide();
			else
				texture:SetTexture("Interface\\Glues\\Credits\\"..path..info.file..texIndex);
				texture:SetWidth(width);
				texture:SetHeight(height);
				texture:SetAlpha(alpha);
				texture:Show();
				texIndex = texIndex + 1;
			end
		end
	end
end

function CreditsFrame_CacheTextures(self, index)
	self.cacheArt = index;
	self.cacheIndex = 1;
	self.cacheElapsed = 0;

	local info = CREDITS_ART_INFO[CreditsFrame.creditsType][index];
	if ( not info ) then
		return;
	end
	local path = CREDITS_ART_INFO[CreditsFrame.creditsType].path;
	if ( not path ) then
		path = "";
	end

	CreditsArtCache1:SetTexture("Interface\\Glues\\Credits\\"..path..info.file.."1");
end

function CreditsFrame_UpdateCache(self)
	if ( self.cacheIndex >= (NUM_CREDITS_ART_TEXTURES_WIDE * NUM_CREDITS_ART_TEXTURES_HIGH) ) then
		return;
	end
	if ( self.cacheElapsed < CACHE_WAIT_TIME ) then
		return;
	end

	self.cacheElapsed = self.cacheElapsed - CACHE_WAIT_TIME;
	self.cacheIndex = self.cacheIndex + 1;

	local info = CREDITS_ART_INFO[self.creditsType][self.cacheArt];
	if ( not info ) then
		return;
	end
	local path = CREDITS_ART_INFO[self.creditsType].path;
	if ( not path ) then
		path = "";
	end

	_G["CreditsArtCache"..self.cacheIndex]:SetTexture("Interface\\Glues\\Credits\\"..path..info.file..self.cacheIndex);
end

function CreditsFrame_UpdateArt(self, index, elapsed)
	if (index > (self.currentArt + 1) ) then
		return;
	end

	if ( index == self.currentArt ) then
		if ( self.fadingOut ) then
			self.alphaOut = max(self.alphaOut - (CREDITS_FADE_RATE * elapsed), 0);

			for i=1, NUM_CREDITS_ART_TEXTURES_HIGH, 1 do
				for j=1, NUM_CREDITS_ART_TEXTURES_WIDE, 1 do
					_G["CreditsArtAlt"..(((i - 1) * NUM_CREDITS_ART_TEXTURES_WIDE) + j)]:SetAlpha(self.alphaOut);
				end
			end

			if ( self.alphaOut <= 0 ) then
				self.fadingOut = nil;
				CreditsFrame_CacheTextures(self, self.currentArt + 1);
			end
		end

		if ( self.fadingIn ) then
			local maxAlpha = CREDITS_ART_INFO[self.creditsType][self.currentArt].maxAlpha;
			self.alphaIn = min(self.alphaIn + (CREDITS_FADE_RATE * elapsed), maxAlpha);
			for i=1, NUM_CREDITS_ART_TEXTURES_HIGH, 1 do
				for j=1, NUM_CREDITS_ART_TEXTURES_WIDE, 1 do
					_G["CreditsArt"..(((i - 1) * NUM_CREDITS_ART_TEXTURES_WIDE) + j)]:SetAlpha(self.alphaIn);
				end
			end

			if ( self.alphaIn >= maxAlpha ) then
				self.fadingIn = nil;
			end
		end
		return;
	end

	if ( self.currentArt > 0 ) then
		self.fadingOut = 1;
		self.alphaOut = CREDITS_ART_INFO[self.creditsType][self.currentArt].maxAlpha;
		CreditsFrame_SetArtTextures(self, "CreditsArtAlt", self.currentArt, self.alphaOut);
	end

	self.fadingIn = 1;
	self.alphaIn = 0;
	self.currentArt = index;
	CreditsFrame_SetArtTextures(self, "CreditsArt", index, self.alphaIn);
end

function CreditsFrame_SetSpeed(speed)
	PlaySound("igMainMenuOptionCheckBoxOff");
	CREDITS_SCROLL_RATE = speed;
	CreditsFrame_UpdateSpeedButtons();
end

function CreditsFrame_SetSpeedButtonActive(button, active)
	if ( active ) then
		button:LockHighlight();
		button:GetHighlightTexture():SetAlpha(0.5);
	else
		button:UnlockHighlight();
		button:GetHighlightTexture():SetAlpha(1);
	end
end

function CreditsFrame_UpdateSpeedButtons()
	local activeButton;
	if ( CREDITS_SCROLL_RATE == CREDITS_SCROLL_RATE_REWIND ) then
		activeButton = CreditsFrameRewindButton;
	elseif ( CREDITS_SCROLL_RATE == CREDITS_SCROLL_RATE_PAUSE ) then
		activeButton = CreditsFramePauseButton;
	elseif ( CREDITS_SCROLL_RATE == CREDITS_SCROLL_RATE_PLAY ) then
		activeButton = CreditsFramePlayButton;
	elseif ( CREDITS_SCROLL_RATE == CREDITS_SCROLL_RATE_FASTFORWARD ) then
		activeButton = CreditsFrameFastForwardButton;
	end
	
	CreditsFrame_SetSpeedButtonActive(CreditsFrameRewindButton, activeButton == CreditsFrameRewindButton);
	CreditsFrame_SetSpeedButtonActive(CreditsFramePauseButton, activeButton ==  CreditsFramePauseButton);
	CreditsFrame_SetSpeedButtonActive(CreditsFramePlayButton, activeButton == CreditsFramePlayButton);
	CreditsFrame_SetSpeedButtonActive(CreditsFrameFastForwardButton, activeButton == CreditsFrameFastForwardButton);
end

function CreditsFrame_OnUpdate(self, elapsed)
	if ( not CreditsScrollFrame:IsShown() ) then
		return;
	end

	CreditsScrollFrame.scroll = CreditsScrollFrame.scroll + (CREDITS_SCROLL_RATE * elapsed);
	CreditsScrollFrame.scroll = max(CreditsScrollFrame.scroll, 1);
	
	if ( CreditsScrollFrame.scroll >= CreditsScrollFrame.scrollMax ) then
		GlueParent_CloseSecondaryScreen();
		return;
	end

	self.cacheElapsed = self.cacheElapsed + elapsed;
	CreditsFrame_UpdateCache(self);

	CreditsScrollFrame:SetVerticalScroll(CreditsScrollFrame.scroll);
	CreditsFrame_UpdateArt(self, ceil(self.artCount * (CreditsScrollFrame.scroll / CreditsScrollFrame.scrollMax)), elapsed);
end

function CreditsFrame_OnScrollRangeChanged()
	CreditsScrollFrame.scrollMax = CreditsScrollFrame:GetVerticalScrollRange() + 768;
end

function CreditsFrame_OnKeyDown(self, key)
	if ( key == "ESCAPE" ) then
		GlueParent_CloseSecondaryScreen();
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	end
end
