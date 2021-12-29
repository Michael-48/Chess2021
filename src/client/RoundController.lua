--[[
    Filename: RoundController.lua
    Timestamp: 12/11/2021 12:22:57
    Author: @Michael_48
    Description: the client may be able to track multiple rounds;
    this controller handles network communication to foward only relavant round data to controllers.
]]--

local Knit = require(game:GetService("ReplicatedStorage").Knit);
local ChessRoundService = Knit.GetService("ChessRoundService");

local RoundClass = require(script.Parent.RoundClass);

local RoundController = Knit.CreateController { Name = "RoundController" }

RoundController.SubscribedRounds = {};

function RoundController:OnPlayerSignalFire(GameId, Data)
    self.SubscribedRounds[GameId]:OnSignalReceived(Data);
end


function RoundController:KnitStart()
    ChessRoundService.PlayerSignal:Connect(function(...)
        self:OnPlayerSignalFire(...);
    end)
end


function RoundController:SubscribeToRound(GameId, PlayContext)
    self.SubscribedRounds[GameId] = RoundClass.new(GameId, PlayContext);
end


return RoundController