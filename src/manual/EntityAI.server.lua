-- Положить обычный Script ВНУТРЬ модели монстра (назови модель "Entity",
-- у модели должны быть Humanoid и HumanoidRootPart, PrimaryPart = HumanoidRootPart).
local monster = script.Parent
local humanoid = monster:WaitForChild("Humanoid")
local root = monster:WaitForChild("HumanoidRootPart")
local Players = game:GetService("Players")

-- смерть при касании
for _, part in ipairs(monster:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			local char = hit.Parent
			local h = char and char:FindFirstChildOfClass("Humanoid")
			if h and Players:GetPlayerFromCharacter(char) then
				h.Health = 0
			end
		end)
	end
end

-- преследование ближайшего игрока
local function nearest()
	local best, dist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local d = (hrp.Position - root.Position).Magnitude
			if d < dist then best, dist = hrp, d end
		end
	end
	return best
end

while task.wait(0.4) do
	local target = nearest()
	if target then humanoid:MoveTo(target.Position) end
end
