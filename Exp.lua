local profileModule = require(game.ServerScriptService.ProfileHandler)
local module = {}
local evolutionModule = require(game.ReplicatedStorage.Stats.Evolutions)
local infoEvoModule =require(script.EvoLevelInfo)

function module.lvlUp(player: Player)
	local data = profileModule.GetData(player)
	local max = 150 * 1.6 ^ data.Level + 1
	data.Level += 1
	data.XP -= max
	evolutionModule.addEvolutionToInventory(player, infoEvoModule.evos[data.Level])
	local lvlUpVfx = game.ReplicatedStorage.Vfx.LevelUp:Clone()
	lvlUpVfx.CFrame = player.Character.PrimaryPart.CFrame
	lvlUpVfx.Parent = workspace
	for _, emitter: ParticleEmitter in lvlUpVfx:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			if emitter:GetAttribute("EmitDelay") then
				task.wait(emitter:GetAttribute("EmitDelay"))
			end
			emitter:Emit(emitter:GetAttribute("EmitCount"))
		end
	end
	task.wait(5)
	lvlUpVfx:Destroy()
end
function module.addExp(player: Player, amount: number)
	local data = profileModule.GetData(player)
	if data then
		local max = 150 * 1.6 ^ data.Level + 1
		data.XP += amount
		if data.XP > max then
			module.lvlUp(player)
		end
		profileModule.SetValue(player, "XP", data.XP)
		profileModule.SetValue(player, "Level", data.Level)
		game.ReplicatedStorage.Events.Exp.ChangeUi:FireClient(player, data.XP, max)
	end
end
return module
