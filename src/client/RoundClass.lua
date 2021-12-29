local Knit = require(game:GetService("ReplicatedStorage").Knit);
local ChessRoundService = Knit.GetService("ChessRoundService");
local PGN = require(Knit.Shared.PGN);
local BoardClass = require(script.Parent.BoardClass);

local RoundClass = {}
RoundClass.__index = RoundClass


function RoundClass.new(GameId, PlayContext)
    local self = setmetatable({}, RoundClass)

    self.GameId = GameId;
    self.PlayContext = PlayContext;

    self:Init();

    return self
end


function RoundClass:Init()
    self.BoardPerspective = if (self.PlayContext == "TeamBlack") then "B" else "W";
    self.Board = BoardClass.new(self);

    task.spawn(function()
        ChessRoundService:AddPlayer(self.GameId, self.PlayContext);
    end)
end


function RoundClass:OnSignalReceived(Data)
    self.PieceData = PGN:GetBoardDataFromPGN(Data.PGN);
    self.LastMove = Data.LastMove;
    self.TeamRound = Data.TeamRound;

    if Data.GameStart then
        self.GameStarted = true;
        self.Board:OnGameStart();
    end
    if Data.NextMove then
        self.Board:UpdateBoard();
    end
    if Data.YourTurn then
        self.Board:OnYourTurn();
    end
end


function RoundClass:CanMoveFor(PieceColor)
    -- PieceColor "B" | "W"

    -- Crazy Bool logic :(
    return 
        (((self.PlayContext == "TeamWhite") and (PieceColor == "W")) or
        ((self.PlayContext == "TeamBlack") and (PieceColor == "B")) or
        (self.PlayContext == "Spectator") or (self.PlayContext == "TeamBoth"))
        and (self.TeamRound == PieceColor)
    
end


function RoundClass:MakeMove(OldSquare,NewSquare)
    ChessRoundService:MakeMove(self.GameId, {OldSquare, NewSquare});
end


function RoundClass:Destroy()
    self.BoardClass:Destroy();
end


return RoundClass