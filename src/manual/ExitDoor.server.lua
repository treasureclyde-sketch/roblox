-- Положить Script ВНУТРЬ яркого Part-выхода. Поставь где-то дальше пустой Part
-- с именем "NextLevelSpawn" — туда телепортнёт при касании выхода.
local Players = game:GetService("Players")
local debounce = {}

script.Parent.Touched:Connect(function(hit)
	local plr = Players:GetPlayerFromCharacter(hit.Parent)
	if plr and not debounce[plr.UserId] then
		debounce[plr.UserId] = true
		local target = workspace:FindFirstChild("NextLevelSpawn")
		if target and hit.Parent.PrimaryPart then
			hit.Parent:PivotTo(CFrame.new(target.Position + Vector3.new(0, 3, 0)))
		elseif target then
			hit.Parent:MoveTo(target.Position)
		end
		task.wait(2)
		debounce[plr.UserId] = nil
	end
end)
