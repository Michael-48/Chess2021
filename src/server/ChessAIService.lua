local Knit = require(game:GetService("ReplicatedStorage").Knit);
local PGN = require(Knit.Shared.PGN);

local ChessAIService = Knit.CreateService {
    Name = "ChessAIService";
    Client = {};
}

function ChessAIService:GetFirstMove(Color,ObjectPGN)
    for y,_ in pairs(ObjectPGN) do
        for x,_ in pairs(ObjectPGN[y]) do
            if ObjectPGN[y][x]:sub(1,1) == Color then
                local Moves = PGN:GetMovesFor(ObjectPGN, y, x);
                for i,v in pairs(Moves) do
                    return {{y,x}, {v[1],v[2]}}
                end
            end
        end
    end
end


function ChessAIService:GetSunfishMove(Color,ObjectPGN)
    local sunfish = require(script.Parent.sunfish);

    -- convert to a sunfish-scheme board layout
    local nameConversion = {
        ["BT"] = "r",
        ["BH"] = "n",
        ["BB"] = "b",
        ["BQ"] = "q",
        ["BK"] = "k",
        ["BP"] = "p",

        ["WT"] = "R",
        ["WH"] = "N",
        ["WB"] = "B",
        ["WQ"] = "Q",
        ["WK"] = "K",
        ["WP"] = "P",

        [""] = "."
    }
    local CurrentPosition = '         \n         \n ';
    for y,_ in pairs(ObjectPGN) do
        for x,_ in pairs(ObjectPGN[y]) do
            CurrentPosition ..= nameConversion[ObjectPGN[Color == "B" and -(y-9) or y][Color == "B" and -(x-9) or x]];
        end
        CurrentPosition ..= "\n ";
    end
    CurrentPosition ..= '        \n          '

    local pos = sunfish.Position.new(Color == "B" and sunfish.swapcase(CurrentPosition) or CurrentPosition, 0, {true,true}, {true,true}, 0, 0);
    print(pos.board)
    local Move = sunfish.search(pos, 1e3);
    Move[1] = (119 - Move[0 + sunfish.__1])
    Move[2] = (119 - Move[1 + sunfish.__1])
    print(Move);
    local RealMove = {{math.floor(Move[1]/10)-1, Move[1]%10}, {math.floor(Move[2]/10)-1, Move[2]%10}}
    return RealMove;
end

return ChessAIService;