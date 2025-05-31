local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EquipPetEvent = ReplicatedStorage.Events.Pets.Equip
local UnequipPetEvent = ReplicatedStorage.Events.Pets.Unequip
local removeEvent = ReplicatedStorage.Events.Pets.RemovePet
local Players = game:GetService("Players")
local PetsModule = require(ReplicatedStorage.Stats.Pets)
local profile = require(game.ServerScriptService.ProfileHandler)

EquipPetEvent.OnServerEvent:Connect(function(player, id: number)
	local EquippedPetInstances = PetsModule.EquippedPetInstances
	EquippedPetInstances[player] = EquippedPetInstances[player] or {
		Map = {},
		Ordered = {},
	}
	local data = profile.GetData(player)
	local petData = data.Pets[tostring(id)]
	if not petData then return end 

	local petInstance = EquippedPetInstances[player].Map[id]

	if not petInstance then
		petInstance = PetsModule.new({
			name = petData.name,
			baseDamage = petData.baseDamage,
			rarity = petData.rarity,
			model = game.ReplicatedStorage.Pets:FindFirstChild(petData.name),
			Aspeed = petData.Aspeed,
			world = petData.world,
			level = petData.level,
			lastPos = petData.lastPos,
			Id = id,
		})
	end

	petInstance:equip(player)
end)

game.ReplicatedStorage.Events.Pets.AddToInventoryGacha.OnServerEvent:Connect(function(player, petData)
	local EquippedPetInstances = PetsModule.EquippedPetInstances
	EquippedPetInstances[player] = EquippedPetInstances[player] or {
		Map = {},
		Ordered = {},
	}
	local data = profile.GetData(player)
	
		local petInstance = PetsModule.new({
			name = petData.name,
			baseDamage = petData.baseDamage,
			rarity = petData.rarity,
			model = game.ReplicatedStorage.Pets:FindFirstChild(petData.name),
			Aspeed = petData.Aspeed,
			world = petData.world,
			level = petData.level,
			lastPos = petData.lastPos,
		})


	petInstance:addToInventory(player)
end)


UnequipPetEvent.OnServerEvent:Connect(function(player, id: number)
	local EquippedPetInstances = PetsModule.EquippedPetInstances
	local equipped = EquippedPetInstances[player]
	if not equipped or not equipped.Map then return end

	local petInstance = equipped.Map[id]

	if not petInstance then
		warn("PetInstance não encontrado para desequipar. ID:", id)
		return
	end

	petInstance:unequip(player)
end)

removeEvent.OnServerEvent:Connect(function(player, id: number)
	local EquippedPetInstances = PetsModule.EquippedPetInstances
	EquippedPetInstances[player] = EquippedPetInstances[player] or {
		Map = {},
		Ordered = {},
	}
	local data = profile.GetData(player)
	local petInstance = EquippedPetInstances[player].Map[id] or data.Pets[tostring(id)]
	
	petInstance:removeFromInventory(player)
end)
Players.PlayerRemoving:Connect(function(player)
	PetsModule.EquippedPetInstances[player] = nil
end)
