local Knit = require(game:GetService("ReplicatedStorage").Knit);
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal);

local HttpService = game:GetService("HttpService");

local ChessRoundClass;

local ChessRoundService = Knit.CreateService {
    Name = "ChessRoundService";
    Client = {};
}

-- Rudimentary Enum to represent the possible contexts a-
-- player can have while subscribed to the round
ChessRoundService.PlayContexts = {"TeamWhite", "TeamBlack", "TeamBoth", "Spectator"};
-- Rudimentary Enum to represent the possible playtypes a Round Instance can use
ChessRoundService.RoundTypes = {"VersusAI", "VersusPlayer", "VersusSelf"};

ChessRoundService.Client.PlayerSignal = RemoteSignal.new();
ChessRoundService.ActiveRounds = {};


function ChessRoundService:CreateRound(RoundType)
    assert(not self.RoundTypes[RoundType], "Invalid PlayContext");

    local GameId = HttpService:GenerateGUID(false);
    self.ActiveRounds[GameId] = ChessRoundClass.new(GameId, RoundType);

    return GameId;
end


function ChessRoundService:GetAvailableRounds(PlayContext)
    assert(not self.PlayContexts[PlayContext], "Invalid PlayContext");

    local JoinableRounds = {};

    for _i, RoundInstance in pairs(self.ActiveRounds) do
        if RoundInstance:IsJoinableForContext(PlayContext) then
            JoinableRounds[#JoinableRounds+1] = RoundInstance.GameId;
        end
    end

    return JoinableRounds;
end


function ChessRoundService:GetRound(GameId)
    assert(self.ActiveRounds[GameId], "Invalid GameId");
    return self.ActiveRounds[GameId];
end


function ChessRoundService:KnitStart()
    ChessRoundClass = require(script.parent.ChessRoundClass);
end

-- CLIENT

function ChessRoundService.Client:MakeMove(Player, GameId, Move)
    ChessRoundService:GetRound(GameId):MakeMove(Player,Move);
end

function ChessRoundService.Client:AddPlayer(Player, GameId, PlayContext)
    ChessRoundService:GetRound(GameId):AddPlayer(Player, PlayContext);
end

function ChessRoundService.Client:CreateRound(Player, ...)
    return ChessRoundService:CreateRound(...);
end

function ChessRoundService.Client:GetAvailableRounds(Player, ...)
    return ChessRoundService:GetAvailableRounds(...);
end

return ChessRoundService;