-- A fresh module avoids Studio's require cache after a Rojo update.
local copy = game.ReplicatedStorage.BombGame.MenuTheme:Clone()
copy.Parent = game.ReplicatedStorage.BombGame
local ok, problem = pcall(function() require(copy).Apply(game.StarterGui.SubGui) end)
copy:Destroy()
assert(ok, problem)
