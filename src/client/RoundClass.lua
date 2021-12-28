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
    self.TeamRound = Data.TeamRound;

    if Data.GameStart then
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
        (self.PlayContext == "Spectator") or (self.PlayContext == "TeamBoth")
        and (self.TeamRound == PieceColor)
    );
end


function RoundClass:MakeMove(OldSquare,NewSquare)
    if self.PieceData[OldSquare[1]][OldSquare[2]]:sub(2,2) == "K" and math.abs(OldSquare[2]-NewSquare[2]) == 2 then
        ChessRoundService:MakeMove(self.GameId, {OldSquare, NewSquare, "Castle"});
    else
        ChessRoundService:MakeMove(self.GameId, {OldSquare, NewSquare, "Std"});
    end
end


function RoundClass:IsInCheck(Color, kingY, kingX)
    -- this could be optimized but this solution is too elegant
    local _kingY,_kingX = self:FindPiece(Color.."K");
    kingY = kingY or _kingY;
    kingX = kingX or _kingX;

    for y,_ in pairs(self.PieceData) do
        for x,_ in pairs(self.PieceData[y]) do
            local PieceColor = self.PieceData[y][x]:sub(1,1);
            if PieceColor ~= Color and PieceColor ~= "" then
                local Moves = self:GetMovesFor(y,x,true);
                for i,Move in pairs(Moves) do
                    if Move[1] == kingY and Move[2] == kingX then return true end;
                end
            end
        end
    end

    return false;
end


function RoundClass:FindPiece(Piece)
    for y, _ in pairs(self.PieceData) do
        for x, _ in pairs(self.PieceData[y]) do
            if self.PieceData[y][x] == Piece then
                return y,x;
            end
        end
    end
end


function RoundClass:GetMovesFor(_Y,_X,shallow)

    local function isInBounds(Y,X)
        return (Y>0 and Y<9) and (X>0 and X<9)
    end

    local MoveAlgorithms = {
        ["Horse"] = function(Y,X)
            return {
                {Y+2, X+1}, {Y+2, X-1},
                {Y-2, X+1}, {Y-2, X-1},
                {Y+1, X-2}, {Y-1, X-2},
                {Y+1, X+2}, {Y-1, X+2}
            }
        end,
        ["Bishop"] = function(Y,X)
            local Moves = {};
            for _x = -1, 1, 2 do
                for _y = -1, 1, 2 do
                    for i = 1,8 do
                        local realY = (i*_y)+Y;
                        local realX = (i*_x)+X;
                        table.insert(Moves,{realY,realX});
                        if self.PieceData[realY] and self.PieceData[realY][realX] ~= "" then
                            break;
                        end
                    end
                end
            end

            return Moves;
        end,
        ["Tower"] = function(Y,X)
            local Moves = {};
            -- repetition :(
            for dir = -1,1,2 do
                for i = 1,8 do
                    local realY = Y;
                    local realX = (dir*i)+X;
                    table.insert(Moves,{realY,realX});
                    if self.PieceData[realY] and self.PieceData[realY][realX] ~= "" then
                        break;
                    end
                end
                for i = 1,8 do
                    local realY = (dir*i)+Y;
                    local realX = X;
                    table.insert(Moves,{realY,realX});
                    if self.PieceData[realY] and self.PieceData[realY][realX] ~= "" then
                        break;
                    end
                end
            end

            return Moves;
        end,
        ["Queen"] = function(Y,X)
            local Moves = {};
            for _x = -1, 1 do
                for _y = -1, 1 do
                    for i = 1,8 do
                        local realY = (i*_y)+Y;
                        local realX = (i*_x)+X;
                        table.insert(Moves,{realY,realX});
                        if self.PieceData[realY] and self.PieceData[realY][realX] ~= "" then
                            break;
                        end
                    end
                end
            end

            return Moves;
        end,
        ["King"] = function(Y,X)
            local Moves = {};
            for _x = -1,1 do
                for _y = -1,1 do
                    table.insert(Moves,{_y+Y,_x+X});
                end
            end

            -- castling
            local Color = self.PieceData[Y][X]:sub(1,1);
            local Row = if (Color == "B") then 1 else 8;

            if (Y == Row) and (X == 5) then
                -- BUG: player can move king | rook out and in from position and can still castle.
                -- would be a bitch to fix tho
                if (self.PieceData[Row][6] == "" and self.PieceData[Row][7] == "" and self.PieceData[Row][8] == Color.."T") then
                    table.insert(Moves, {Row, 7});
                end
                if (self.PieceData[Row][4] == "" and self.PieceData[Row][3] == "" and self.PieceData[Row][2] == "" and self.PieceData[Row][8] == Color.."T") then
                    table.insert(Moves, {Row, 3});
                end
            end
            
            return Moves;
        end,
        ["Pawn"] = function(Y,X)
            local Moves = {};
            local Color = if (self.PieceData[Y][X]:sub(1,1) == "B") then 1 else -1;

            local OppositeColor = self.PieceData[Y][X]:sub(1,1) == "B" and "W" or "B";

            if isInBounds(Y+Color, X) and self.PieceData[Y+Color][X] == "" then
                table.insert(Moves,{Color + Y, X})
                if (Y == 2 and Color == 1) or (Y == 7 and Color == -1) then
                    if self.PieceData[Y+Color+Color][X] == "" then
                        table.insert(Moves,{(Color + Color) + Y, X})
                    end
                end
            end

            if isInBounds(Y+Color,X+1) and (self.PieceData[Y+Color][X+1]):sub(1,1) == OppositeColor then
                table.insert(Moves, {Y+Color, X+1})
            end
            if isInBounds(Y+Color,X-1) and (self.PieceData[Y+Color][X-1]):sub(1,1) == OppositeColor then
                table.insert(Moves, {Y+Color, X-1})
            end
            return Moves;
        end
    };

    local PieceMoves = {
        ["BP"] = MoveAlgorithms.Pawn,
        ["WP"] = MoveAlgorithms.Pawn,
        ["BH"] = MoveAlgorithms.Horse,
        ["WH"] = MoveAlgorithms.Horse,
        ["BB"] = MoveAlgorithms.Bishop,
        ["WB"] = MoveAlgorithms.Bishop,
        ["BT"] = MoveAlgorithms.Tower,
        ["WT"] = MoveAlgorithms.Tower,
        ["BQ"] = MoveAlgorithms.Queen,
        ["WQ"] = MoveAlgorithms.Queen,
        ["BK"] = MoveAlgorithms.King,
        ["WK"] = MoveAlgorithms.King
    };

    local Moves = PieceMoves[self.PieceData[_Y][_X]](_Y,_X);

    local ReducedMoves = {}; -- get only legal moves
    for i,v in pairs(Moves) do
        if ((v[1]>0 and v[1]<9) and (v[2]>0 and v[2]<9)) then
            local PieceMatch = (self.PieceData[_Y][_X]:sub(1,1) == self.PieceData[v[1]][v[2]]:sub(1,1))
            if (not PieceMatch) then
                ReducedMoves[i] = v;
            end
        end
    end

    if not shallow then
        -- get only moves that dont result in a mate
        local SuperReducedMoves = {};
        for i,v in pairs(ReducedMoves) do
            local MovPiece = self.PieceData[_Y][_X];
            self.PieceData[_Y][_X] = "";
            local NewPiece = self.PieceData[v[1]][v[2]];
            self.PieceData[v[1]][v[2]] = MovPiece;

            if not self:IsInCheck(MovPiece:sub(1,1)) then
                SuperReducedMoves[i] = v;
            end

            self.PieceData[v[1]][v[2]] = NewPiece;
            self.PieceData[_Y][_X] = MovPiece;
        end

        return SuperReducedMoves;
    end

    return ReducedMoves;
end


function RoundClass:Destroy()
    self.BoardClass:Destroy();
end


return RoundClass