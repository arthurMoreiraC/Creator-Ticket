local chase = {}
chase.petsList = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function createAttachment(part)
	local att = Instance.new("Attachment")
	att.Name = "FollowAttachment"
	att.Parent = part
	return att
end
local profile = require(game.ServerScriptService.ProfileHandler)
local petOffsets = {
	-- Primeira linha
	Vector3.new(-3, -1, 8),
	Vector3.new(0, -1, 9),
	Vector3.new(3, -1, 10),
	Vector3.new(6, -1, 9),
	Vector3.new(9, -1, 8),
	-- Segunda linha
	Vector3.new(-6, -1, 13),
	Vector3.new(-3, -1, 14),
	Vector3.new(0, -1, 15),
	Vector3.new(3, -1, 14),
	Vector3.new(6, -1, 13),
}
local physicsService = game:GetService("PhysicsService")
physicsService:CollisionGroupSetCollidable("Pets", "Default", false)
physicsService:CollisionGroupSetCollidable("Pets", "Pets", false)
function chase.setupFollowPet(player: Player, pets)
	local data = profile.GetData(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp: Part = character:WaitForChild("HumanoidRootPart")

	if #pets.Ordered > data.PetSlots then
		table.remove(pets.Ordered, data.PetSlots + 1)
	end
	print(pets.Ordered)
	for i, pet in ipairs(pets.Ordered) do
		local petModel = character.Mobs:FindFirstChild(pet.name .. "_" .. tostring(pet.Id))
		if not petModel then continue end


		local petAttachment = createAttachment(petModel.PrimaryPart)

		local alignPos = Instance.new("AlignPosition")
		alignPos.Name = "PAlign"
		alignPos.Attachment0 = petAttachment
		alignPos.RigidityEnabled = false
		alignPos.Responsiveness = 40
		alignPos.MaxForce = 1000
		alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
		alignPos.Position = hrp.CFrame:PointToWorldSpace(petOffsets[i])
		alignPos.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		alignPos.ForceRelativeTo = Enum.ActuatorRelativeTo.World
		alignPos.MaxAxesForce = Vector3.new(10000, 0, 10000)
		alignPos.Parent = petModel.PrimaryPart

		RunService.Heartbeat:Connect(function()
			if hrp and hrp.Parent then
				alignPos.Position = hrp.CFrame:PointToWorldSpace(petOffsets[i])
			end
		end)

		local alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Name = "POrientation"
		alignOrientation.Attachment0 = petAttachment
		alignOrientation.RigidityEnabled = false
		alignOrientation.Responsiveness = 100
		alignOrientation.MaxTorque = 10000
		alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOrientation.CFrame = hrp.CFrame
		alignOrientation.Parent = petModel.PrimaryPart

		RunService.Heartbeat:Connect(function()
			if hrp and hrp.Parent then
				alignOrientation.CFrame = hrp.CFrame
			end
		end)
		
		local petAnimator: Animator = petModel.Humanoid.Animator
		local walkTrack = petAnimator:LoadAnimation(script.Walk)
		local idleTrack = petAnimator:LoadAnimation(script.Idle)
		local petHrp: Part = petModel.HumanoidRootPart
		RunService.Heartbeat:Connect(function()
			if petHrp and petHrp.Parent then
				local speed = petHrp.AssemblyLinearVelocity.Magnitude
				if speed > 1 then
					if not walkTrack.IsPlaying then
						idleTrack:Stop()
						walkTrack:Play()
					end
				else
					if walkTrack.IsPlaying then
						walkTrack:Stop()
						idleTrack:Play()
					end
				end
			end
		end)
	end

end

return chase
