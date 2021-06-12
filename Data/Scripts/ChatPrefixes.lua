--[[

	Chat Pefixes
	by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

	Version 1.0.0
	Created May 6, 2021
	Last Updated May 6, 2021

	Adding Prefixes:

		Add a group inside the "Prefixes" group of the template.
			NOTE: It's easiest to copy+paste so that all the custom properties are already there.

	Adding Players to Prefixes:

		1) Add a group inside the prefix group you want the player to be in
		2) Add a string custom property named "PlayerId"
		3) Copy and paste the final section of the player's URL on the CoreGames website
			• For instance, my full CoreGames URL is https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8
			• So, what we would add to the custom property is the final part: f9df3457225741c89209f6d484d0eba8

--]]
local RootGroup = script:GetCustomProperty("RootGroup"):WaitForObject()
local PrefixesGroup = RootGroup:GetCustomProperty("PrefixesGroup"):WaitForObject()

local CHAT_PREFIX_AND_USERNAME_FORMAT = "%s%s"
local CHAT_ORANGE_FORMAT_ALL = "[All] %s%s: %s"
-- Not used yet until Core implements a way to see if a message is in all chat or in team chat
local CHAT_ORANGE_FORMAT_TEAM = "[Team] %s %s: %s"

-- A cache of player prefixes to be used when a message is sent by a player
-- This is populated when a player joins; when a player leaves, their entry is set to nil (deleted)
local playerPrefixes = {}

-- nil OnMessage(Player speaker, table parameters)
-- The connection for when a chat message is received; this is what adds the prefix to the chat message
local function OnMessage(speaker, parameters)
	local prefix = playerPrefixes[speaker]

	-- If there is no prefix cached for the player, we do nothing special to the message
	if not prefix then
		return
	end

	local isOrange = prefix:GetCustomProperty("IsOrange")
	local prefixText = prefix:GetCustomProperty("Prefix")

	-- If the prefix isn't blank, we need to add a space behind it. Can't do this in the format incase the prefix is blank.
	-- Otherwise, there would be double spaces (for no reason) in chat.
	if type(prefixText) ~= "string" then
		prefixText = ""
	elseif prefixText ~= "" then
		prefixText = prefixText .. " "
	end

	if isOrange then
		-- Broadcast a message (to all players), replacing the premade format with the prefix, player name, and message
		Chat.BroadcastMessage(string.format(CHAT_ORANGE_FORMAT_ALL, prefixText, speaker.name, parameters.message))
		-- Chat.BroadcastMessage is orange and is already in chat by this point so now we can set the prior message to nil so it doesn't show in chat
		parameters.message = ""
	else
		-- Replace the username to be `%prefix %username`
		parameters.speakerName = string.format(CHAT_PREFIX_AND_USERNAME_FORMAT, prefixText, speaker.name)
	end
end

-- bool AssignPrefix(Player player, CoreObject prefix)
-- Returns true if the player has permission to the prefix or false if not
local function AssignPrefix(player, prefix)
	-- This will check the possible players assigned to a prefix and if the player joining's id matches, then return true
	for _, otherPlayer in ipairs(prefix:GetChildren()) do
		local playerId = otherPlayer:GetCustomProperty("PlayerId")
		if playerId and player.id == playerId then
			return true
		end
	end

	local perk = prefix:GetCustomProperty("Perk")

	-- We want to make sure the custom property is a valid Perk NetReference
	-- Usually, I do an early return here. But, if in the future we want to add more conditions, like if Core added GUILDS/CLANS/ORGANIZATIONS PLEASE MANTICORE :(, then an early escape would ruin that.
	if perk.isAssigned and perk:IsA("NetReference") and perk.referenceType == NetReferenceType.CREATOR_PERK then
		-- If the perk is timed, the number will be greater than 0. If permanent or repeatable, infinity. Therefore, 0 if the player doesn't owner it, so false
		return player:GetPerkTimeRemaining(perk) > 0
	end
end

-- CoreGroup GetPrefix(Player player)
-- Returns the highest prefix that the player has permissions to. Nil if none is found.
local function GetPrefix(player)
	for _, prefix in ipairs(PrefixesGroup:GetChildren()) do
		if AssignPrefix(player, prefix) then
			return prefix
		end
	end
end

-- nil OnPlayerJoined(Player player)
-- Assign the prefix to a player when they join
local function OnPlayerJoined(player)
	playerPrefixes[player] = GetPrefix(player)
end

-- nil OnPlayerLeft(Player player)
-- Remove the cached player entry when they leave
local function OnPlayerLeft(player)
	if not playerPrefixes[player] then
		return
	end

	playerPrefixes[player] = nil
end

Game.playerJoinedEvent:Connect(OnPlayerJoined)
Game.playerLeftEvent:Connect(OnPlayerLeft)

Chat.receiveMessageHook:Connect(OnMessage)
