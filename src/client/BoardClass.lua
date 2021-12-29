--[[
    Filename: BoardClass.lua
    Timestamp: 12/19/2021 18:54:36
    Author: @Michael_48
    Description: gui code is a wreck
]]--

local Knit = require(game:GetService("ReplicatedStorage").Knit);
local Janitor = require(Knit.Util.Janitor);

local PGN = require(Knit.Shared.PGN);

local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Players = game:GetService("Players");
local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");

local BoardClass = {}
BoardClass.__index = BoardClass

function BoardClass.new(RoundClass)
    local self = setmetatable({}, BoardClass);

    self.RoundClass = RoundClass;
    self:Init();

    return self
end


function BoardClass:Init()
    self.janitor = Janitor.new();
    self.BoardTheme = "Default";
    self.SetTheme = "Default";
    self.PotentialMoves = {};

    self.Board = self:GenerateBoard();
    self.janitor:Add(self.Board);
    self.janitor:Add(RunService.RenderStepped:Connect(function()
        -- this really shouldnt be renderstepped, but it prevents a bunch of minor
        -- graphical glitches :/
        self:UpdateSelectionHover();
    end))
    self:DisplayGame(PGN:GetBoardDataFromPGN({}));
    -- Display default board
end


function BoardClass:GetSpriteOffsetForPiece(Piece)
    local PieceOffsets = {["K"] = 0, ["Q"]= 1, ["T"] = 2, ["B"] = 3, ["H"] = 4, ["P"] = 5}
    return Vector2.new(
        PieceOffsets[Piece:sub(2,2)] * 170,
        Piece:sub(1,1)=="B" and 170 or 0
    )
end


function BoardClass:DisplayGame(PieceData)
    local PieceSet = Knit.Assets.PieceSets[self.SetTheme];
    for x = 1,8 do
        for y = 1,8 do
            local Square = self.Board[x.."-"..y];

            if PieceData[x][y] ~= "" then
                local Piece = PieceSet.Piece:Clone();
                Piece.Parent = Square;
                Piece.ImageRectOffset = self:GetSpriteOffsetForPiece(PieceData[x][y])
            end
        end
    end
end


function BoardClass:ClearBoard()
    for i,v in pairs(self.Board:GetChildren()) do
        if v:FindFirstChild("Piece") then
            v.Piece:Destroy();
        end
    end
end


function BoardClass:GenerateBoard()
    local BoardSet = Knit.Assets.Boards[self.BoardTheme]
    local Board = BoardSet.Chessboard:Clone();

    local ScreenGui = Instance.new("ScreenGui");
    ScreenGui.Parent = PlayerGui;
    Board.Parent = ScreenGui;
    Board.Visible = true;

    local Color = if self.RoundClass.BoardPerspective == "B" then 0 else 1

    for Y = 1,8 do
        for X = 1,8 do
            local Square = ((Y+X)%2==1 and BoardSet.DarkSquare or BoardSet.LightSquare):Clone();
            Square.Parent = Board;
            Square.LayoutOrder = (X*8)+Y;
            Square.Name = ((Color == 0 and -(X-9) or X).."-"..(Color == 0 and -(Y-9) or Y));

            self.janitor:Add(Square.Button.MouseButton1Down:Connect(function()
                self:SelectPiece(Square.Name);
            end))

            self.janitor:Add(Square.Button.MouseButton1Up:Connect(function()
                self:AttemptPlacePiece(Square.Name);
            end))
        end
    end

    return Board;
end


function BoardClass:UnselectPiece()
    if self.SelectedPiece then
        self.Board[self.SelectedPiece].Highlight.Visible = false;
        if self.Board[self.SelectedPiece]:FindFirstChild("Piece") then
            self.Board[self.SelectedPiece].Piece.Visible = true;
        end
    end
    self.SelectedPiece = nil;

    self.CanHover = false;
end


function BoardClass:ParameterizeSquareId(Square)
    local Pos = Square:split("-");
    return {tonumber(Pos[1]),tonumber(Pos[2])};
end


function BoardClass:SelectPiece(Square)
    if not self.Board[Square]:FindFirstChild("Piece") then return end;
    if not self.RoundClass.GameStarted then return end;

    self:UnselectPiece();
    self.SelectedPiece = Square;
    self.Board[self.SelectedPiece].Highlight.Visible = true;

    -- Movement dots
    local Pos = self:ParameterizeSquareId(self.SelectedPiece);
    local PieceType = self.RoundClass.PieceData[Pos[1]][Pos[2]];

    self:RemovePotentialMoves();

    if not self.RoundClass:CanMoveFor(PieceType:sub(1,1)) then return end

    self:PlacePotentialMoves(PGN:GetMovesFor(self.RoundClass.PieceData,Pos[1],Pos[2]));

    -- HoverPiece
    local Piece = self.Board[self.SelectedPiece].Piece.ImageRectOffset;
    self.HoverPiece = Knit.Assets.PieceSets[self.SetTheme].Piece:Clone();
    self.HoverPiece.ImageRectOffset = Piece;
    self.HoverPiece.Parent = self.Board.Parent;
    self.HoverPiece.AnchorPoint = Vector2.new(.5,.5);
    self.HoverPiece.ZIndex = 60;
    self.HoverPiece.Visible = false;

    self.Board[Square].Piece.Visible = false;
    self.CanHover = true;
end


function BoardClass:UpdateSelectionHover()
    if self.CanHover then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            
            self.HoverPiece.Visible = true;
            local MousePos = UserInputService:GetMouseLocation();
            self.HoverPiece.Position = UDim2.fromOffset(MousePos.X,MousePos.Y-28);

            local Objects = PlayerGui:GetGuiObjectsAtPosition(MousePos.X,MousePos.Y-28);
            if self.HoverSquare then self.HoverSquare.BorderHighlight.Visible = false; end
            for i,v in pairs(Objects) do
                if v.Parent == self.Board then
                    self.HoverSquare = v;
                end
            end
            self.HoverSquare.BorderHighlight.Visible = true;
        end
    elseif self.HoverPiece then
        self.HoverPiece.Visible = false;
        self.HoverSquare.BorderHighlight.Visible = false;
    end
end


function BoardClass:AttemptPlacePiece(Square)
    if self.PotentialMoves[Square] then
        self:MovePiece(self.SelectedPiece, Square);
        
        local LastSquare = self.SelectedPiece;
        self:UnselectPiece();
        self:RemovePotentialMoves();

        for i,v in pairs(self.Board:GetChildren()) do
            if v:FindFirstChild("Highlight") then
                v.Highlight.Visible = false;
            end
        end
    else
        -- go back to not holding piece
        if self.SelectedPiece then
            self.Board[self.SelectedPiece].Piece.Visible = true;
        end
        self.CanHover = false;
    end
end


function BoardClass:MovePiece(OldSquare,NewSquare)
    self.RoundClass:MakeMove(self:ParameterizeSquareId(OldSquare),self:ParameterizeSquareId(NewSquare));
end


function BoardClass:RemovePotentialMoves()
    for i,v in pairs(self.PotentialMoves or {}) do
        self.Board[v[1].."-"..v[2]].MoveDot.Visible = false;
        self.Board[v[1].."-"..v[2]].AttackDot.Visible = false;
    end
    self.PotentialMoves = {};
end


function BoardClass:PlacePotentialMoves(MovePos)
    for i,v in pairs(MovePos) do
        self.PotentialMoves[v[1].."-"..v[2]] = v
        
        if self.RoundClass.PieceData[v[1]][v[2]] ~= "" then
            self.Board[v[1].."-"..v[2]].AttackDot.Visible = true;
        else
            self.Board[v[1].."-"..v[2]].MoveDot.Visible = true;
        end
    end
end

function BoardClass:UpdateBoard()
    local LastMove = self.RoundClass.LastMove;
    self.Board[LastMove[1][1].."-"..LastMove[1][2]].Highlight.Visible = true
    self.Board[LastMove[2][1].."-"..LastMove[2][2]].Highlight.Visible = true
    self:ClearBoard();
    self:DisplayGame(self.RoundClass.PieceData)
end

function BoardClass:OnGameStart()

end

function BoardClass:OnYourTurn()

end

function BoardClass:Destroy()
    self.janitor:Destroy();
end

return BoardClass
