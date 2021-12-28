local Knit = require(game:GetService("ReplicatedStorage").Knit);
local ChessRoundService = Knit.GetService("ChessRoundService");
local PGN = require(Knit.Shared.PGN);

local Players = game:GetService("Players");

local ChessRound = {};
ChessRound.__index = ChessRound;

function ChessRound.new(Id, RoundType)
    local self = setmetatable({}, ChessRound);

    self.GameId = Id;
    self.RoundType = RoundType;
    self.TeamAuthorizedPlayers = {
        White = {};
        Black = {};
        AllPlayers = {};
    }
    return self;
end


function ChessRound:AddPlayer(Player, PlayContext)
    assert(self:IsJoinableForContext(PlayContext), "Player not Authorized to join Round");

    self:GetAuthorizedForContext(Player.UserId, PlayContext);

    if self:IsReadyToStart() then
        self:StartRound();
    end
end


function ChessRound:MakeMove(Player, Move)
    self.PGN = PGN:AppendMove(self.PGN, Move);

    self.TeamRound = if (self.TeamRound == "W") then "B" else "W";

    local Data = {};

    for i,Player in pairs(self.TeamAuthorizedPlayers.AllPlayers) do
        Data[Player] = {};
        Data[Player].NextMove = true;
        Data[Player].PGN = self.PGN;
        Data[Player].TeamRound = self.TeamRound;
    end

    for i,Player in pairs(self.TeamAuthorizedPlayers.AllPlayers) do
        ChessRoundService.Client.PlayerSignal:Fire(Players:GetPlayerByUserId(Player), self.GameId, Data[Player]);
    end
end


function ChessRound:GetAuthorizedForContext(PlayerId,PlayContext)
    if PlayContext == ChessRoundService.PlayContexts[1] then -- TeamWhite
        table.insert(self.TeamAuthorizedPlayers.White, PlayerId);
    elseif PlayContext == ChessRoundService.PlayContexts[2] then -- TeamBlack
        table.insert(self.TeamAuthorizedPlayers.Black, PlayerId);
    elseif PlayContext == ChessRoundService.PlayContexts[3] then -- TeamBoth
        table.insert(self.TeamAuthorizedPlayers.White, PlayerId);
        table.insert(self.TeamAuthorizedPlayers.Black, PlayerId);
    elseif PlayContext == ChessRoundService.PlayContexts[4] then -- Spectator
        -- None for now
    end
    table.insert(self.TeamAuthorizedPlayers.AllPlayers, PlayerId);
end


function ChessRound:IsReadyToStart()
    if (#self.TeamAuthorizedPlayers.White == 1) and (#self.TeamAuthorizedPlayers.Black == 1) then
        return true;
    else
        return false;
    end
end


function ChessRound:StartRound()
    self.PGN = PGN:GeneratePGN();
    self.TeamRound = "W";

    local Data = {};

    for i,Player in pairs(self.TeamAuthorizedPlayers.AllPlayers) do
        Data[Player] = {};
        Data[Player].GameStart = true;
        Data[Player].TeamRound = self.TeamRound;
        Data[Player].PGN = self.PGN
    end

    for i,Player in pairs(self.TeamAuthorizedPlayers.White) do
        Data[Player].YourTurn = true;
    end

    for i,Player in pairs(self.TeamAuthorizedPlayers.AllPlayers) do
        ChessRoundService.Client.PlayerSignal:Fire(Players:GetPlayerByUserId(Player), self.GameId, Data[Player]);
    end
end


function ChessRound:IsJoinableForContext(PlayContext)
    -- Temp
    return true;
end


function ChessRound:Destroy()
    
end

return ChessRound