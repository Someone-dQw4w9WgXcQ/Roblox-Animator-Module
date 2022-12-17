--!strict

local ContentProvider = game:GetService("ContentProvider")

-- ThreadPool dependency: https://github.com/Someone-dQw4w9WgXcQ/Lua-ThreadPool
local spawnWithReuse = require(game:GetService("ReplicatedStorage"):WaitForChild("ThreadPool"))

local ANIMATION_CONFIG = {
	["ClimbingAnimation"] = {
		Id = "rbxassetid://507765644",
		Speed = 1,
		Priority = Enum.AnimationPriority.Idle
	},
	["FallingAnimation"] = {
		Id = "rbxassetid://507767968",
		Speed = 1,
		Priority = Enum.AnimationPriority.Idle
	},
	["JumpingAnimation"] = {
		Id = "rbxassetid://507765000",
		Speed = 1,
		Priority = Enum.AnimationPriority.Idle
	},
	["RunningAnimation"] = {
		Id = "rbxassetid://507767714",
		Speed = 1,
		Priority = Enum.AnimationPriority.Idle,
		Looped = true
	},
	["SitAnimation"] = {
		Id = "rbxassetid://507768133",
		Speed = 1,
		Priority = Enum.AnimationPriority.Movement
	},
	["SwimmingAnimation"] = {
		Id = "rbxassetid://507784897",
		Speed = 1,
		Priority = Enum.AnimationPriority.Idle
	},
	["SwimmingIdleAnimation"] = {
		Id = "rbxassetid://481825862",
		Speed = 1,
		Priority = Enum.AnimationPriority.Idle
	},
	["ToolAnimation"] = {
		Id = "rbxassetid://507768375",
		Speed = 1,
		Priority = Enum.AnimationPriority.Movement
	}
}

local animationObjects = {}
for name, info in ANIMATION_CONFIG do
	local animation = Instance.new("Animation")
	animation.AnimationId = info.Id
	animationObjects[name] = animation
	
	spawnWithReuse(ContentProvider.PreloadAsync, ContentProvider, {info.Id})
end

return function(rig: Instance, humanoid: Humanoid, animator: Animator)
	local animationTracks = {}
	
	for name, info in ANIMATION_CONFIG do
		local animationTrack = animator:LoadAnimation(animationObjects[name])
		animationTrack.Priority = info.Priority
		animationTrack.Name = name
		animationTrack.Looped = info.Looped
		
		animationTracks[name] = animationTrack
	end

	local function adjustSpeed(name: string, speed: number)
		local animationTrack = animationTracks[name]
		animationTrack:AdjustSpeed(speed)
	end

	local function play(name: string)
		local animationTrack = animationTracks[name]
		animationTrack:Play()
	end

	local function stop(name: string)
		local animationTrack = animationTracks[name]
		animationTrack:Stop(0.2)
	end

	humanoid.Running:Connect(function(speed)
		if speed < 1 then
			stop("RunningAnimation")
		else
			play("RunningAnimation")
			adjustSpeed("RunningAnimation", ANIMATION_CONFIG.RunningAnimation.Speed * speed/16)
		end
	end)

	humanoid.Swimming:Connect(function(speed)
		if speed < 1 then
			stop("SwimmingAnimation")
			play("SwimmingIdleAnimation")
		else
			play("SwimmingAnimation")
			stop("SwimmingIdleAnimation")
		end
	end)

	humanoid.Climbing:Connect(function(speed)
		if speed == 0 then
			adjustSpeed("ClimbingAnimation", 0)
		else
			adjustSpeed("ClimbingAnimation", ANIMATION_CONFIG.ClimbingAnimation.Speed * speed/5)
		end
	end)

	rig.ChildAdded:Connect(function(object)
		if object:IsA("Tool") then
			play("ToolAnimation")
		end
	end)

	rig.ChildRemoved:Connect(function()
		if not rig:FindFirstChildOfClass("Tool") then
			stop("ToolAnimation")
		end
	end)

	if rig:FindFirstChildOfClass("Tool") then
		play("ToolAnimation")
	end

	local function stopOtherAnimations(except: string?)
		--Stop all animations except the tool animation and the except parameter
		for name, animationTrack in animationTracks do
			if name == except then continue end
			animationTrack:Stop(0.2)
		end
	end

	humanoid.StateChanged:Connect(function(_oldState, newState)
		if newState == Enum.HumanoidStateType.Climbing then
			play("ClimbingAnimation")
			stopOtherAnimations("ClimbingAnimation")
		elseif newState == Enum.HumanoidStateType.Running and humanoid.MoveDirection ~= Vector3.zero then
			play("RunningAnimation")
			stopOtherAnimations("RunningAnimation")
		elseif newState == Enum.HumanoidStateType.Freefall then
			play("JumpingAnimation")
			stopOtherAnimations("JumpingAnimation")
		elseif newState == Enum.HumanoidStateType.Swimming and humanoid.MoveDirection ~= Vector3.zero then
			play("SwimmingAnimation")
			stopOtherAnimations("SwimmingAnimation")
		elseif newState == Enum.HumanoidStateType.Seated then
			play("SitAnimation")
			stopOtherAnimations("SitAnimation")
		else
			stopOtherAnimations()
		end
	end)
end
