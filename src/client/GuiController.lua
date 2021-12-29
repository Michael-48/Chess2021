local Knit = require(game:GetService("ReplicatedStorage").Knit)

local GuiController = Knit.CreateController { Name = "GuiController" }

function GuiController:KnitStart()
    local ChessRoundService = Knit.GetService("ChessRoundService");
    local RoundController = Knit.GetController("RoundController");
    
    local Joinable = ChessRoundService:GetAvailableRounds("TeamBlack");
    if #Joinable == 0 then
        local GameId = ChessRoundService:CreateRound("VersusAI");
        RoundController:SubscribeToRound(GameId, "TeamWhite");
    else
        RoundController:SubscribeToRound(Joinable[1], "TeamBlack");
    end
end

function GuiController:KnitInit()
    
end

return GuiController