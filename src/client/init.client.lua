local Knit = require(game:GetService("ReplicatedStorage").Knit);

local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts;
local ReplicatedStorage = game:GetService("ReplicatedStorage");

Knit.Assets = ReplicatedStorage:WaitForChild("Assets");
Knit.Shared = ReplicatedStorage:WaitForChild("Shared");

Knit.AddControllersDeep(StarterPlayerScripts);

Knit.Start():Catch(warn);