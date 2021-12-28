local Knit = require(game:GetService("ReplicatedStorage").Knit);

local ServerScriptService = game:GetService("ServerScriptService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");

Knit.Assets = ReplicatedStorage.Assets;
Knit.Shared = ReplicatedStorage:WaitForChild("Shared");

Knit.AddServicesDeep(ServerScriptService:WaitForChild("Server"));

Knit.Start():Catch(warn);