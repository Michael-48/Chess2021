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
    local PreObjectPGN = PGN:GetBoardDataFromPGN(self.PGN);
    if PreObjectPGN[Move[1][1]][Move[1][2]]:sub(2,2) == "K" and math.abs(Move[1][2]-Move[2][2]) == 2 then
        Move[3] = "Castle";
    else
        Move[3] = "Std";
    end

    self.PGN = PGN:AppendMove(self.PGN, Move);
    self.TeamRound = if (self.TeamRound == "W") then "B" else "W";

    -- Check if Checkmate
    local ObjectPGN = PGN:GetBoardDataFromPGN(self.PGN);
    if PGN:IsInCheck(ObjectPGN, self.TeamRound) and not PGN:DoesColorHaveAnyMoves(ObjectPGN, self.TeamRound) then
        self:ConcludeRound();
        return;
    end

    -- Respond if is versusAI
    if Player and self.RoundType == "VersusAI" then
        task.spawn(function()
            local NewMove = self:GetAIMove(self.TeamRound, ObjectPGN);
            self:MakeMove(false,NewMove);
        end)
    end

    local Data = {};

    for i,Player in pairs(self.TeamAuthorizedPlayers.AllPlayers) do
        Data[Player] = {};
        Data[Player].NextMove = true;
        Data[Player].PGN = self.PGN;
        Data[Player].LastMove = Move;
        Data[Player].TeamRound = self.TeamRound;
    end

    for i,Player in pairs(self.TeamAuthorizedPlayers.AllPlayers) do
        print("Hey")
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
    if self.RoundType == "VersusPlayer" then
        return (#self.TeamAuthorizedPlayers.White ~= 0) and (#self.TeamAuthorizedPlayers.Black ~= 0);
    else
        return true;
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


function ChessRound:GetAIMove(...)
    local ChessAIService = Knit.GetService("ChessAIService");
    return ChessAIService:GetSunfishMove(...);
end


function ChessRound:ConcludeRound()
    print(self.TeamRound.." Loses...");
end


function ChessRound:IsJoinableForContext(PlayContext)
    -- Temp
    return true;
end


function ChessRound:Destroy()
    
end

return ChessRound