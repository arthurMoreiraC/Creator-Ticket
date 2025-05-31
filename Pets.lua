export type Pet = {
	name: string,
	baseDamage: number,
	rarity: string,
	model: Model,
	Aspeed: number,
	world: string,
	level: number,
	lastPos: number,
	coinMultiplier:number
}

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local folder = Instance.new("Folder")
		folder.Name = "Mobs"
		folder.Parent = char
	end)
end)

local runService = game:GetService("RunService")
local profile = nil
if runService:IsServer() then
	profile = require(game.ServerScriptService:WaitForChild("ProfileHandler"))
else
	profile = game.ReplicatedStorage.Events.GetData:InvokeServer()
end
local followModule = require(script.Chase)
local lastThin = nil
local pets = {}
pets.petsIds = {}
pets.createdPets = {}
pets.__index = pets
pets.EquippedPetInstances = {}
game.Players.PlayerAdded:Connect(function(player)
	pets.EquippedPetInstances[player] = {
		Ordered = {}, 
		Map = {}, 
	}
end)
function pets.new(pet: Pet)
	local self = setmetatable({}, pets)
	self.name = pet.name
	self.baseDamage = pet.baseDamage
	self.rarity = pet.rarity
	self.Aspeed = pet.Aspeed
	self.world = pet.world
	self.level = pet.level
	self.Xp = pet.Xp or 0
	self.lastPos = pet.lastPos
	self.Id = pet.Id or require(game.ReplicatedStorage.Misc.Ui.PetIdManager).getUniqueId()
	self.CoinMultiplier = pet.coinMultiplier
	pets.petsIds[self.Id] = self
	pets.createdPets[self] = self
	return self
end
function pets:levelUp(player: Player)
	self.level += 1
	self.baseDamage = self.baseDamage ^ self.level
	local data = profile.GetData(player)
	data.Pets[tostring(self.Id)].level = self.level
	data.Pets[tostring(self.Id)].baseDamage = self.baseDamage
	profile.SetValue(player, "Pets", data.Pets)
	game.ReplicatedStorage.Events.Pets.ChangeUi:FireClient(player, profile.GetData(player).Pets)
end
function pets:addXp(player:Player, amount: number)
	self.Xp += amount
	local data = profile.GetData(player)
	local levelAmount = (100 * 1.3 ^ self.level) / 4
	print(self.Id.." recebeu ".. amount.." de xp")
	data.Pets[tostring(self.Id)].Xp = self.Xp
	if self.Xp >= levelAmount then
		self.Xp -= levelAmount
		self:levelUp(player)
		return
	end
	profile.SetValue(player, "Pets", data.Pets)
	game.ReplicatedStorage.Events.Pets.ChangeUi:FireClient(player, data.Pets)
end

function pets:addToInventory(player: Player)
	local data = profile.GetData(player)
	if not data then
		warn("nao adicionei o"..self.name.." erro na data")
	end
	local petTable = data.Pets
	petTable[tostring(self.Id)] = self
	profile.SetValue(player, "Pets", petTable)
	game.ReplicatedStorage.Events.Pets.ChangeUi:FireClient(player, data.Pets)
	
	
end
function pets:removeFromInventory(player: Player)
	local data = profile.GetData(player)
	if not data then
		warn("nao removi o"..self.name.." erro na data")
	end
	local petTable = data.Pets
	petTable[tostring(self.Id)] = nil
	profile.SetValue(player, "Pets", petTable)
	game.ReplicatedStorage.Events.Pets.ChangeUi:FireClient(player, data.Pets)
end
function pets:equip(player: Player)
	local data = profile.GetData(player)
	if not data then
		warn("Não equipou o " .. self.name .. " — erro na data")
		return
	end

	local equippedPets = data.EquippedPets or {}
	local currentPetsValue = 0

	-- Conta pets já equipados
	for _, _ in pairs(equippedPets) do
		currentPetsValue += 1
	end

	if currentPetsValue > data.PetSlots then
		warn("Limite de pets equipados atingido")
		return
	end

	equippedPets[self.Id] = self -- Use o ID único como chave
	data.EquippedPets = equippedPets

	profile.SetValue(player, "EquippedPets", pets.EquippedPetInstances[player].Map)
	profile.SetValue(player, "PetsValue", currentPetsValue + 1)

	local hrp = player.Character:WaitForChild("HumanoidRootPart")
	if player.Character.Mobs:FindFirstChild(self.name .. "_" .. tostring(self.Id)) then return end
	local petClone = game.ReplicatedStorage.Pets:FindFirstChild(self.name):Clone()
	if not petClone then
		warn("Modelo do pet não encontrado: " .. self.name)
		return
	end

	petClone.Name = self.name .. "_" .. tostring(self.Id)
	petClone.Parent = player.Character.Mobs
	petClone:SetPrimaryPartCFrame(hrp.CFrame)

	game.ReplicatedStorage.Events.Pets.ChangeUi:FireClient(player, data.Pets, petClone.Name)

	local equipped = pets.EquippedPetInstances[player]
	equipped.Map[self.Id] = self
	table.insert(equipped.Ordered, self)
	followModule.setupFollowPet(player, pets.EquippedPetInstances[player])
end

function pets:unequip(player: Player)
	local data = profile.GetData(player)
	if not data then
		warn("Erro ao acessar dados ao desequipar " .. self.name)
		return
	end

	local equippedPets = data.EquippedPets or {}
	local currentPetsValue = 0

	for _, _ in pairs(equippedPets) do
		currentPetsValue += 1
	end

	if not equippedPets[self.Id] then
		warn("Pet não equipado: " .. self.name)
		return
	end

	-- Remove o modelo do personagem
	local mobFolder = player.Character:FindFirstChild("Mobs")
	local petModel = mobFolder and mobFolder:FindFirstChild(self.name .. "_" .. tostring(self.Id))
	if petModel then
		petModel:Destroy()
	end
	followModule.petsList[self.Id] = nil
	local equipped = pets.EquippedPetInstances[player]
	-- Remove o pet usando a chave do ID
	equipped.Map[self.Id] = nil

	-- Remove da ordem
	for i, pet in ipairs(equipped.Ordered) do
		if pet.Id == self.Id then
			table.remove(equipped.Ordered, i)
			break
		end
	end
	followModule.setupFollowPet(player, pets.EquippedPetInstances[player])
	profile.SetValue(player, "EquippedPets", pets.EquippedPetInstances[player].Map)
	profile.SetValue(player, "PetsValue", currentPetsValue - 1)
	print(equippedPets)
	game.ReplicatedStorage.Events.Pets.ChangeUi:FireClient(player, data.Pets)
end


function pets:returnData(player: Player)
	return self
end
return pets
