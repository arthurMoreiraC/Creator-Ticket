local profile = require(game.ServerScriptService.ProfileHandler)
local petsModule = require(game.ReplicatedStorage.Stats.Pets)
game.ReplicatedStorage.Events.GetData.OnServerInvoke = function(player)
	local valu = profile.GetData(player)
	return valu
end
local mobModule = require(game.ReplicatedStorage.Misc.Mobs)
local invModule = require(game.ReplicatedStorage.Stats.Itens)
local evolutionModule = require(game.ReplicatedStorage.Stats.Evolutions)
local petDataModule = require(game.ReplicatedStorage:WaitForChild("Stats").Pets.PetInfo)
local questsModule = require(game.ReplicatedStorage.Misc.Quests)
game.Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local data = profile.GetData(player)
	local maxExp = 100 * 1.6 ^ data.Level + 1
	for item: string, value: number in data.Items do
		game.ReplicatedStorage.Events.Inventory.ChangeUi:FireClient(player, item, value)
	end 
	task.wait(0.1)
	local EquippedPetInstances = petsModule.EquippedPetInstances
	local counter = 0
	if data.EquippedPets and #data.EquippedPets + 1 > 0 then
		for _, pet in data.EquippedPets do
			local petData = pet
			data.EquippedPets[counter] = nil
			local petCoisa = petsModule.new(petData)
			if data.Pets[tostring(pet.Id)] then
				data.Pets[tostring(pet.Id)] = nil
				profile.SetValue(player, "Pets", data.Pets)
			end
			EquippedPetInstances[player].Map[pet.Id] = pet
			petCoisa:addToInventory(player)
			petCoisa:equip(player)
			counter += 1
		end
	else
		print("equipped pets eh nil")
	end
	print(data.Pets)
	if data.XP > maxExp then
		data.XP -= maxExp
		data.Level += 1
		profile.SetValue(player, "XP", data.XP)
		profile.SetValue(player, "Level", data.Level)
	end
	evolutionModule.equipEvolution(player, data.EquippedTrans)
	game.ReplicatedStorage.Events.Power.ChangeUi:FireClient(player, data.Power)
	game.ReplicatedStorage.Events.Coins.ChangeUi:FireClient(player, data.Cash)
	game.ReplicatedStorage.Events.Exp.ChangeUi:FireClient(player, data.XP, maxExp)
	game.ReplicatedStorage.Events.Pets.ChangeUi:FireClient(player, data.Pets)
	
	local quest4 = questsModule.new(4, data.Level>5 and 1 or 2, player, 1)
	quest4:progressQuest(data.Quest4Progress)
	local quest2 = questsModule.new(2, math.round(data.Level /2), player, 2)
	task.spawn(function()
		while task.wait(1) do
			quest2:progressQuest(1)
		end
	end)
end)
