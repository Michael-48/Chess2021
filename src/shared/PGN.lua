-- this isint a class. the entire point of PGN is that its representation, metadata, etc-
-- is contained within a single string. so we keep it that way.
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


function PGN:AppendMove(ObjectPGN, Move)
    ObjectPGN[#ObjectPGN+1] = Move;
    
    return ObjectPGN;
end


function PGN:ToPGN(ObjectPGN)
    
end


return PGN;