-- Functions for opertating on ObjectPGN representations and conversions to the file specification .PGN - 
-- https://en.wikipedia.org/wiki/Portable_Game_Notation

local Knit = require(game:GetService("ReplicatedStorage").Knit);
local TableUtil = require(Knit.Util.TableUtil);

local PGN = {};

function PGN:GeneratePGN()
    return {};
end

function PGN:GetBoardDataFromPGN(ObjectPGN)
    local DefaultData = {
        {"BT", "BH", "BB", "BQ", "BK", "BB", "BH", "BT"},
        {"BP", "BP", "BP", "BP", "BP", "BP", "BP", "BP"},
        {"",   "",   "",   "",   "",   "",   "",   "", },
        {"",   "",   "",   "",   "",   "",   "",   "", },
        {"",   "",   "",   "",   "",   "",   "",   "", },
        {"",   "",   "",   "",   "",   "",   "",   "", },
        {"WP", "WP", "WP", "WP", "WP", "WP", "WP", "WP"},
        {"WT", "WH", "WB", "WQ", "WK", "WB", "WH", "WT"},
    };

    local Data = {};

    Data = TableUtil.Copy(DefaultData,true);

    for i,v in pairs(ObjectPGN) do
        if v[3] == "Std" then
            local Piece = Data[v[1][1]][v[1][2]];
            Data[v[1][1]][v[1][2]] = "";
            Data[v[2][1]][v[2][2]] = Piece;

        elseif v[3] == "Castle" then
            local Piece = Data[v[1][1]][v[1][2]];
            Data[v[1][1]][v[1][2]] = ""; -- Empty old king
            Data[v[1][1]][v[2][2]] = Piece; -- Place new king
            local Delta = math.sign(v[1][2]-v[2][2]);
            local RookX = if (Delta == 1) then 1 else 8;
            local Rook = Data[v[1][1]][RookX];
            Data[v[1][1]][RookX] = ""; -- Empty old rook
            Data[v[1][1]][v[2][2]+Delta] = Rook; -- Place new rook
        end
        
    end
    
    return Data;
end


function PGN:IsInCheck(ObjectPGN, Color, kingY, kingX)
    -- this could be optimized but this solution is too elegant
    local _kingY,_kingX = PGN:FindPiece(ObjectPGN, Color.."K");
    kingY = kingY or _kingY;
    kingX = kingX or _kingX;

    for y,_ in pairs(ObjectPGN) do
        for x,_ in pairs(ObjectPGN[y]) do
            local PieceColor = ObjectPGN[y][x]:sub(1,1);
            if PieceColor ~= Color and PieceColor ~= "" then
                local Moves = PGN:GetMovesFor(ObjectPGN, y, x, true);
                for i,Move in pairs(Moves) do
                    if Move[1] == kingY and Move[2] == kingX then return true end;
                end
            end
        end
    end

    return false;
end


function PGN:FindPiece(ObjectPGN, Piece)
    for y, _ in pairs(ObjectPGN) do
        for x, _ in pairs(ObjectPGN[y]) do
            if ObjectPGN[y][x] == Piece then
                return y,x;
            end
        end
    end
end


function PGN:GetMovesFor(ObjectPGN, _Y, _X, shallow)

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
                        if ObjectPGN[realY] and ObjectPGN[realY][realX] ~= "" then
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
                    if ObjectPGN[realY] and ObjectPGN[realY][realX] ~= "" then
                        break;
                    end
                end
                for i = 1,8 do
                    local realY = (dir*i)+Y;
                    local realX = X;
                    table.insert(Moves,{realY,realX});
                    if ObjectPGN[realY] and ObjectPGN[realY][realX] ~= "" then
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
                        if ObjectPGN[realY] and ObjectPGN[realY][realX] ~= "" then
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
            local Color = ObjectPGN[Y][X]:sub(1,1);
            local Row = if (Color == "B") then 1 else 8;

            if (Y == Row) and (X == 5) then
                -- BUG: player can move king | rook out and in from position and can still castle.
                -- would be a bitch to fix tho
                if (ObjectPGN[Row][6] == "" and ObjectPGN[Row][7] == "" and ObjectPGN[Row][8] == Color.."T") then
                    table.insert(Moves, {Row, 7});
                end
                if (ObjectPGN[Row][4] == "" and ObjectPGN[Row][3] == "" and ObjectPGN[Row][2] == "" and ObjectPGN[Row][8] == Color.."T") then
                    table.insert(Moves, {Row, 3});
                end
            end
            
            return Moves;
        end,
        ["Pawn"] = function(Y,X)
            local Moves = {};
            local Color = if (ObjectPGN[Y][X]:sub(1,1) == "B") then 1 else -1;

            local OppositeColor = ObjectPGN[Y][X]:sub(1,1) == "B" and "W" or "B";

            if isInBounds(Y+Color, X) and ObjectPGN[Y+Color][X] == "" then
                table.insert(Moves,{Color + Y, X})
                if (Y == 2 and Color == 1) or (Y == 7 and Color == -1) then
                    if ObjectPGN[Y+Color+Color][X] == "" then
                        table.insert(Moves,{(Color + Color) + Y, X})
                    end
                end
            end

            if isInBounds(Y+Color,X+1) and (ObjectPGN[Y+Color][X+1]):sub(1,1) == OppositeColor then
                table.insert(Moves, {Y+Color, X+1})
            end
            if isInBounds(Y+Color,X-1) and (ObjectPGN[Y+Color][X-1]):sub(1,1) == OppositeColor then
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

    local Moves = PieceMoves[ObjectPGN[_Y][_X]](_Y,_X);

    local ReducedMoves = {}; -- get only legal moves
    for i,v in pairs(Moves) do
        if ((v[1]>0 and v[1]<9) and (v[2]>0 and v[2]<9)) then
            local PieceMatch = (ObjectPGN[_Y][_X]:sub(1,1) == ObjectPGN[v[1]][v[2]]:sub(1,1))
            if (not PieceMatch) then
                ReducedMoves[i] = v;
            end
        end
    end

    if not shallow then
        -- get only moves that dont result in a mate
        local SuperReducedMoves = {};
        for i,v in pairs(ReducedMoves) do
            local MovPiece = ObjectPGN[_Y][_X];
            ObjectPGN[_Y][_X] = "";
            local NewPiece = ObjectPGN[v[1]][v[2]];
            ObjectPGN[v[1]][v[2]] = MovPiece;

            if not PGN:IsInCheck(ObjectPGN, MovPiece:sub(1,1)) then
                SuperReducedMoves[i] = v;
            end

            ObjectPGN[v[1]][v[2]] = NewPiece;
            ObjectPGN[_Y][_X] = MovPiece;
        end

        return SuperReducedMoves;
    end

    return ReducedMoves;
end


function PGN:DoesColorHaveAnyMoves(ObjectPGN, Color)
    -- if a color has 0 possible moves, its a checkmate.
    for y,_ in pairs(ObjectPGN) do
        for x,_ in pairs(ObjectPGN[y]) do
            local Piece = ObjectPGN[y][x];
            if Piece:sub(1,1) == Color then
                local Moves = PGN:GetMovesFor(ObjectPGN,y,x);
                for i,v in pairs(Moves) do
                    return true;
                end
            end
        end
    end

    return false;
end


function PGN:AppendMove(ObjectPGN, Move)
    ObjectPGN[#ObjectPGN+1] = Move;
    
    return ObjectPGN;
end


function PGN:ToPGN(ObjectPGN)
    
end


return PGN;