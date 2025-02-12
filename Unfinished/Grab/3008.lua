--[[

	Ideas:
		•
		
		Front Couch
		Floor lamp
		Plants
		Chest (hinge lid)
		Scarecrow
		Pallet
		NPCS (slime, etc.)
		Cookie jar
		Food items
		
		Shift to run
		C to crouch
		
		Inventory GUI / Furniture placement GUI / Building GUI
		
		Redstone / Wiring system.

		Camera bobble
		
		Directional walking animation.
		
		Model Separation: When you remove a part in the middle of a model, split each side of the model into individual models.
		
		Touch Welding: When you pick up a model that is anchored, automatically weld all the touching parts in the model before unanchoring it.
		
		Lerp at a speed of distance.
		
		+ gets more transparent the further your cursor is from it.
		
		GUI TextLabel that scrolls out to the left and the new text scrolls in from the right.
			IsWelding
			Colliding (both modes)
			Mode
			Rotation increment
			Rotation axis
			Grid increment
			Throw velocity
		
		GUI that says the name of the CURRENT_ITEM.
]]

HttpService = game:GetService("HttpService")
CollectionService = game:GetService("CollectionService")

LSB_ARGS = {...}
FUNCTIONS = nil

CanCollide = false
Transparency = 0.5
HumanoidSit = true

COMMAND_PREFIX = nil
COMMAND_SEPARATOR = "/"

loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/somoose/Roblox/master/LSB/Grab/Server/FUNCTIONS.lua"))()
loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/somoose/Roblox/master/LSB/Grab/Server/REMOTES.lua"))()
loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/somoose/Roblox/master/LSB/furn/Module.lua"))()
loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/somoose/Roblox/master/LSB/Grab/Server/COMMANDS.lua"))()

owner = FUNCTIONS.ReturnPlayer(LSB_ARGS[1]) or owner

local ClientGuiStringValue = Instance.new("StringValue", owner.PlayerGui)
ClientGuiStringValue.Name = "ClientGuiStringValue"
ClientGuiStringValue.Value = HttpService:GetAsync("https://raw.githubusercontent.com/somoose/Roblox/master/LSB/Grab/Client/GUI.lua")

local ClientFunctionsStringValue = Instance.new("StringValue", owner.PlayerGui)
ClientFunctionsStringValue.Name = "ClientFunctionsStringValue"
ClientFunctionsStringValue.Value = HttpService:GetAsync("https://raw.githubusercontent.com/somoose/Roblox/master/LSB/Grab/Client/FUNCTIONS.lua")

local ClientBobbleStringValue = Instance.new("StringValue", owner.PlayerGui)
ClientBobbleStringValue.Name = "ClientBobbleStringValue"
ClientBobbleStringValue.Value = HttpService:GetAsync("https://raw.githubusercontent.com/somoose/Roblox/master/LSB/Grab/Client/BOBBLE.lua")

NLS([[
Camera = workspace.CurrentCamera
PlayerGui = owner.PlayerGui
Mouse = owner:GetMouse()

Players = game:GetService("Players")
GuiService = game:GetService("GuiService")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
TweenService = game:GetService("TweenService")
CollectionService = game:GetService("CollectionService")
SoundService = game:GetService("SoundService")
HttpService = game:GetService("HttpService")

SoundService.AmbientReverb = Enum.ReverbType.Auditorium

GUI = {}
FUNCTIONS = {}
COMMANDS = {} -- Only client sided commands. Server sided commands are above.

COMMAND_PREFIX = nil
COMMAND_SEPARATOR = "/"

TARGET = nil -- Current item at the mouse.
CURRENT_ITEM = nil -- Current item being held.

HOLDING = false -- True when the user is holding an item.
DROPPING = false -- True when the user is dropping something.

ANCHORING_ENABLED = false -- When true, dropping an item that is colliding with something, will anchor it.
THROWING_ENABLED = false -- When true, holding E before releasing it in order to drop an item, will give it velocity.
COLLISION_DETECTION_ENABLED = true -- When true, the CURRENT_ITEM will be offset based on the normal the mouse is on.
CLIPPING_DETECTION_ENABLED = true -- When true, CURRENT_ITEM will be prevented from clipping through objects.
WELDING_ENABLED = true -- When true, user is able to weld CURRENT_ITEM to other items.
WELDING_BLACKLIST = {} -- A list of parts that the user is not allowed to weld to.

TOUCHING = false -- True when the CURRENT_ITEM is touching other parts.
TOUCHING_PARTS = {} -- The parts of CURRENT_ITEM and the parts they're in contact with.

MUST_BE_UNLOCKED = false -- If true, you can only pick up unlocked items.
MUST_BE_IN_RANGE = true -- If true, you can only pick up items less than or equal to MAXIMUM_GRAB_DISTANCE away.
MAXIMUM_GRAB_DISTANCE = 30 -- The max distance away from which an item can be picked up.

MOVE_LERP_RANGE = NumberRange.new(0.25, 0.3)
HOLD_DISTANCE = 5 -- The distance the item is away from the user when they are holding it.
HOLD_DISTANCE_INCREMENT = 0.5 -- The increment at which the HOLD_DISTANCE increases and decreases.
MAXIMUM_HOLD_DISTANCE = 25 -- The furthest CURRENT_ITEM can be held from the user.
MINIMUM_HOLD_DISTANCE = 2 -- The closest CURRENT_ITEM can be held to the user.
RAYCAST_HOLD_DISTANCE = 0 -- The max distance an object can be held from the user without clipping into objects.

AXIS = "Y" -- The orientation axis being edited.
ORIENTATION = CFrame.new() -- The orientation of the item being held.
ROTATION_INCREMENT_15 = math.rad(15)
ROTATION_INCREMENT_45 = math.rad(45)
ROTATION_INCREMENT_90 = math.rad(90)
ORIENTATION_INCREMENT = ROTATION_INCREMENT_45 -- The increment that the Orientation value increases at.

THROW_FORCE = 0 -- The force (velocity) used to throw the CURRENT_ITEM when dropped.
THROW_FORCE_INCREMENT = 10 -- The amount that THROW_FORCE increases by.
MAX_THROW_FORCE = 60 -- The max force that can be used to throw the item.

DEFAULT_FIELD_OF_VIEW = 70
ZOOMED_FIELD_OF_VIEW = 15
FIELD_OF_VIEW_LERP_SPEED = 0.125

--		Input KeyCodes
PICKUP_INPUT = Enum.KeyCode.E
ROTATE_INPUT = Enum.KeyCode.R
INCREASEDISTANCE_INPUT = Enum.KeyCode.Four
DECREASEDISTANCE_INPUT = Enum.KeyCode.Five
CHANGE_CAMERAMODE_INPUT = Enum.KeyCode.C
CHANGE_MODE_INPUT = Enum.KeyCode.Q
DELETE_INPUT = Enum.KeyCode.X
ZOOM_INPUT = Enum.KeyCode.Z

--		Keys Down Variables
PICKUP_INPUT_DOWN = false -- True when the pickup input is held down.
CTRL_DOWN = false -- True when the left control button is held down.
SHIFT_DOWN = false -- True when the left shift button is held down.
ALT_DOWN = false -- True when the left alt button is held down.
ROTATE_INPUT_DOWN = false -- True when the rotate input is held down.
ZOOM_INPUT_DOWN = false -- True when the zoom input is held down.

PICKUP_INPUTOBJECT = {UserInputType = Enum.UserInputType.Keyboard, KeyCode = PICKUP_INPUT} --	PICKUP Input emulation.
FIRST_INPUT_TARGET = nil -- The first TARGET detected when the E key is pressed. 

-- 		GUI Variables
PICKUP_HOLD = 0.1 -- The amount of time in seconds it takes GUI.Progress.Value to reach 360.
GRAB_CARET_SPEED = 0.5 -- The speed GUI.GrabCaret lerps at. 
PICKUP_TWEEN = nil -- The tween used to lerp the GUI.PROGRESS value. Updates with a new Tween on every E InputBegan. 
CLEAR_TEXT_ON_FOCUS = true

-- 		Event Functions
FUNCTIONS.PICKUP = nil -- The function run when an item is picked up.
FUNCTIONS.HOLDING = nil -- The function run while an item is being held.
FUNCTIONS.DROP = nil -- The function run when an item is dropped.

FUNCTIONS.ReturnPlayer = nil -- Returns the player whose name is closest to the parsed string.
FUNCTIONS.ReturnPrimaryPart = nil -- Returns the PrimaryPart of a Model.
FUNCTIONS.UpdateTarget = nil -- Updates the TARGET variable.
FUNCTIONS.UpdateRaycastHoldDistance = nil -- Updates RAYCASTHOLD_DISTANCE
FUNCTIONS.FitsCriteria = nil --	Returns true if the parsed item fits pick up criteria.
FUNCTIONS.EditFilterDescendantsInstances = nil -- Adds and removes items to the RAYCASTPARAMS.FilterDescendantsInstances
FUNCTIONS.ParentBodyMovers = nil --	Parents the BodyMovers to the item parsed to it.

BlacklistedTags = {
	ISHELD_TAG = "__ISHELD__", -- The CollectionService tag applied to items when they're picked up.
	BASE_TAG = "__BASE__",
	SPAWN_TAG = "__SPAWNLOCATION__"
}

loadstring(owner.PlayerGui.ClientBobbleStringValue.Value)()
loadstring(owner.PlayerGui.ClientFunctionsStringValue.Value)()
loadstring(owner.PlayerGui.ClientBobbleStringValue.Value)()

Base = workspace:FindFirstChild("Base")

if Base then
	CollectionService:AddTag(Base, BlacklistedTags.BASE_TAG)
	
	local SpawnLocation = Base:FindFirstChildWhichIsA("SpawnLocation")
	
	if SpawnLocation then
		CollectionService:AddTag(SpawnLocation, BlacklistedTags.SPAWN_TAG)
	end
end


-- Remotes
GrabRemote = PlayerGui:WaitForChild("GrabRemote") -- Used to pick up an item.
GetServerScriptRemote = PlayerGui:WaitForChild("GetServerScriptRemote")
DeleteRemote = PlayerGui:WaitForChild("DeleteRemote")
ChatCommandRemote = PlayerGui:WaitForChild("ChatCommandRemote")

ServerScript = GetServerScriptRemote:InvokeServer()


--		Audios
ScrollWheelClickSound = Instance.new("Sound", owner.PlayerGui) --															(SOUND)
ScrollWheelClickSound.Name = "ScrollWheelClick"
ScrollWheelClickSound.SoundId = "rbxassetid://9121005567"
ScrollWheelClickSound.PlaybackSpeed = 1
ScrollWheelClickSound.Volume = 0.75

RotateSound = Instance.new("Sound", owner.PlayerGui) --																	(SOUND)
RotateSound.Name = "Rotate"
RotateSound.SoundId = "rbxassetid://9114067301"
RotateSound.PlaybackSpeed = 1.5
RotateSound.Volume = 0.75


HighlightColorWhite = { --																								(ARRAY)
	FillColor = Color3.fromRGB(100, 100, 100),
	OutlineColor = Color3.fromRGB(255, 255, 255)
}
HighlightColorRed = { --																									(ARRAY)
	FillColor = Color3.fromRGB(255, 0, 0),
	OutlineColor = Color3.fromRGB(200, 0, 0)
}


Highlight = Instance.new("Highlight", ServerScript)
Highlight.FillTransparency = 0.8
Highlight.OutlineTransparency = 0.25
Highlight.FillColor = HighlightColorWhite.FillColor
Highlight.OutlineColor = HighlightColorWhite.OutlineColor

SelectionBox = Instance.new("SelectionBox", owner.Character)
SelectionBox.LineThickness = 0.01
SelectionBox.Transparency = 0.75
SelectionBox.Color3 = Color3.fromRGB(0, 200, 0)
SelectionBox.Transparency = 0.5

Attachment0 = Instance.new("Attachment")
AlignPosition = Instance.new("AlignPosition")
AlignOrientation = Instance.new("AlignOrientation")

AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
AlignPosition.Attachment0 = Attachment0
AlignPosition.RigidityEnabled = true
AlignPosition.MaxForce = Vector3.one * math.huge
AlignPosition.Responsiveness = Vector3.one * math.huge

AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
AlignOrientation.Attachment0 = Attachment0
AlignOrientation.RigidityEnabled = true
AlignOrientation.MaxTorque = Vector3.one * math.huge
AlignOrientation.Responsiveness = Vector3.one * math.huge

SparkParticlePart = Instance.new("Part")
SparkParticlePart.Size = Vector3.zero
SparkParticlePart.Transparency = 1
SparkParticlePart.Anchored = true
SparkParticlePart.CanCollide = false
SparkParticlePart.CanQuery = false

SparkParticleAttachment = Instance.new("Attachment", SparkParticlePart)

SparkParticleEmitter = Instance.new("ParticleEmitter", SparkParticleAttachment)
SparkParticleEmitter.Name = "SparkParticleEmitter"
SparkParticleEmitter.Texture = "http://www.roblox.com/asset/?id=7587238412"
SparkParticleEmitter.Enabled = false
SparkParticleEmitter.Brightness = 1
SparkParticleEmitter.LightEmission = 1
SparkParticleEmitter.LightInfluence = 0
SparkParticleEmitter.Rate = 10
SparkParticleEmitter.TimeScale = 1
SparkParticleEmitter.Speed = NumberRange.new(10)
SparkParticleEmitter.Lifetime = NumberRange.new(0.5, 1)
SparkParticleEmitter.Rotation = NumberRange.new(0)
SparkParticleEmitter.RotSpeed = NumberRange.new(0)
SparkParticleEmitter.SpreadAngle = Vector2.new(20, -20)
SparkParticleEmitter.Squash = NumberSequence.new(0)
SparkParticleEmitter.Acceleration = Vector3.new(0, -50, 0)
SparkParticleEmitter.Shape = Enum.ParticleEmitterShape.Box
SparkParticleEmitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
SparkParticleEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
SparkParticleEmitter.Orientation = Enum.ParticleOrientation.VelocityParallel
SparkParticleEmitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 1)
})
SparkParticleEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.25),
	NumberSequenceKeypoint.new(0.5, 0.25),
	NumberSequenceKeypoint.new(1, 0)
})
SparkParticleEmitter.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(253, 128, 8))
})

SparkParticlePart.CFrame = owner.Character.Head.CFrame * CFrame.new(0, 0, -5)



COMMANDS = {
	{
		CODE = "clipping",
		FUNCTION = function (Boolean)
			CLIPPING_DETECTION_ENABLED = Boolean == "true" and true or false
			print("Set CLIPPING_DETECTION_ENABLED to " .. tostring(CLIPPING_DETECTION_ENABLED))
		end
	},
	{
		CODE = "welding",
		FUNCTION = function (Boolean)
			WELDING_ENABLED = Boolean == "true" and true or false
			print("Set WELDING_ENABLED to " .. tostring(WELDING_ENABLED))
		end
	},
	{
		CODE = "collision",
		FUNCTION = function (Boolean)
			COLLISION_DETECTION_ENABLED = Boolean == "true" and true or false
			print("Set COLLISION_DETECTION_ENABLED to " .. tostring(COLLISION_DETECTION_ENABLED))
		end
	}
}


-- // GUI and Handling ======================================================================================================= \\
-- Functions
GUI.InputBegan = nil
GUI.InputChanged = nil
GUI.InputEnded = nil
GUI.UpdateProgressBar = nil
GUI.UpdateGrabCaret = nil

GrabCaretSize = Camera.ViewportSize.Y * 0.025
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() GrabCaretSize = Camera.ViewportSize.Y * 0.025 GUI.GrabCaret.Size = UDim2.fromOffset(GrabCaretSize, GrabCaretSize) end)

GUI.UpdateProgressBar = function () -- Uses the PROGRESS value in the GUI table.
	local Value = (GUI.PROGRESS.Value % 360 + 360) % 360

	GUI.RightBar.Rotation = math.clamp(Value - 180, -180, 0)
	
	if Value > 180 then
		GUI.LeftBar.Visible = true
		GUI.LeftBar.Rotation = math.clamp(Value - 360, -180, 0)
	else
		GUI.LeftBar.Visible = false
	end
end

GUI.UpdateGrabCaret = function (Position, InBounds)
	if InBounds then
		GUI.GrabCaret.Position = GUI.GrabCaret.Position:Lerp(UDim2.new(0, Position.X, 0, Position.Y), GRAB_CARET_SPEED)
	else
		GUI.GrabCaret.Position = GUI.GrabCaret.Position:Lerp(UDim2.new(0.5, 0, 0.5, 0), GRAB_CARET_SPEED)
	end
end

GUI.CircularProgressBarScreenGui = Instance.new("ScreenGui")
GUI.CircularProgressBar = Instance.new("Frame")
GUI.LeftBack = Instance.new("ImageLabel")
GUI.LeftBar = Instance.new("Frame")
GUI.LeftBarImage = Instance.new("ImageLabel")
GUI.RightBack = Instance.new("ImageLabel")
GUI.RightBar = Instance.new("Frame")
GUI.RightBarImage = Instance.new("ImageLabel")
GUI.GrabCaret = Instance.new("TextLabel")
GUI.PROGRESS = Instance.new("NumberValue")
GUI.PROGRESSBARBACKCOLOR = Color3.new(0, 0, 0)
GUI.PROGRESSBARIMAGECOLOR = Color3.new(150, 150, 150)
GUI.CommandBarTextBox = Instance.new("TextBox", GUI.CircularProgressBarScreenGui)
--GUI.CommandBarUICorner = Instance.new("UICorner", GUI.CommandBarTextBox)
GUI.CommandBarSuggestionScrollingFrame = Instance.new("ScrollingFrame", GUI.CircularProgressBarScreenGui)
-- \\ ======================================================================================================================== //

-- // Serialized GUI ========================================================= \\
GUI.CommandBarTextBox.Text = ""
GUI.CommandBarTextBox:GetPropertyChangedSignal("Text"):Connect(FUNCTIONS.COMMAND_BAR_TEXT_CHANGED)
GUI.CommandBarTextBox.FocusLost:Connect(FUNCTIONS.FOCUS_LOST)
GUI.CommandBarTextBox.ClearTextOnFocus = CLEAR_TEXT_ON_FOCUS
GUI.CommandBarTextBox.BorderSizePixel = 0
GUI.CommandBarTextBox.Size = UDim2.fromScale(1, 0.03)
GUI.CommandBarTextBox.Position = UDim2.fromScale(0.5, 0.475)
GUI.CommandBarTextBox.AnchorPoint = Vector2.new(0.5, 0.5)
GUI.CommandBarTextBox.BackgroundTransparency = 0.25
GUI.CommandBarTextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
GUI.CommandBarTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
GUI.CommandBarTextBox.TextStrokeTransparency = 1
GUI.CommandBarTextBox.Font = Enum.Font.Code
GUI.CommandBarTextBox.TextSize = GUI.CommandBarTextBox.Size.Y.Scale * GUI.CircularProgressBarScreenGui.AbsoluteSize.Y
GUI.CommandBarTextBox.PlaceholderText = ""
GUI.CommandBarTextBox.Visible = false
GUI.CommandBarTextBox.Interactable = false

GUI.CircularProgressBarScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.CircularProgressBarScreenGui.Name = "CircularProgressBarScreenGui"
GUI.CircularProgressBarScreenGui.IgnoreGuiInset = true
GUI.CircularProgressBarScreenGui.Parent = owner.PlayerGui

GUI.GrabCaret.AnchorPoint = Vector2.new(0.5, 0.5)
GUI.GrabCaret.Size = UDim2.fromOffset(GrabCaretSize, GrabCaretSize)
GUI.GrabCaret.Position = UDim2.new(0.5, 0, 0.5, 0)
GUI.GrabCaret.BackgroundTransparency = 1
GUI.GrabCaret.BorderColor3 = Color3.new(150, 150, 150)
GUI.GrabCaret.TextStrokeTransparency = 0
GUI.GrabCaret.TextStrokeColor3 = Color3.new(0, 0, 0)
GUI.GrabCaret.TextColor3 = Color3.new(255, 255, 255)
GUI.GrabCaret.TextScaled = true
GUI.GrabCaret.Text = "+"
GUI.GrabCaret.Name = "GrabCaret"
GUI.GrabCaret.Parent = GUI.CircularProgressBarScreenGui

GUI.CircularProgressBar.AnchorPoint = Vector2.new(0.5, 0.5)
GUI.CircularProgressBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
GUI.CircularProgressBar.BackgroundTransparency = 1
GUI.CircularProgressBar.Position = UDim2.new(0.5, 0, 0.5, 0)
GUI.CircularProgressBar.Size = UDim2.new(2.5, 0, 2.5, 0)
GUI.CircularProgressBar.Rotation = 180
GUI.CircularProgressBar.Visible = false
GUI.CircularProgressBar.Name = "CircularProgressBar"
GUI.CircularProgressBar.Parent = GUI.GrabCaret

GUI.LeftBack.Image = "rbxassetid://2094637131"
GUI.LeftBack.ImageColor3 = GUI.PROGRESSBARBACKCOLOR
GUI.LeftBack.ImageRectSize = Vector2.new(128, 256)
GUI.LeftBack.SliceCenter = Rect.new(0, 0, 128, 256)
GUI.LeftBack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GUI.LeftBack.BackgroundTransparency = 1
GUI.LeftBack.Size = UDim2.new(0.5, 0, 1, 0)
GUI.LeftBack.ZIndex = 2
GUI.LeftBack.Name = "LeftBack"
GUI.LeftBack.Parent = GUI.CircularProgressBar

GUI.LeftBar.AnchorPoint = Vector2.new(0.5, 0.5)
GUI.LeftBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GUI.LeftBar.BackgroundTransparency = 1
GUI.LeftBar.Position = UDim2.new(1, 0, 0.5, 0)
GUI.LeftBar.Size = UDim2.new(2, 0, 1, 0)
GUI.LeftBar.Name = "LeftBar"
GUI.LeftBar.Parent = GUI.LeftBack

GUI.LeftBarImage.Image = "rbxassetid://2094676785"
GUI.LeftBarImage.ImageColor3 = GUI.PROGRESSBARIMAGECOLOR
GUI.LeftBarImage.ImageRectSize = Vector2.new(128, 256)
GUI.LeftBarImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GUI.LeftBarImage.BackgroundTransparency = 1
GUI.LeftBarImage.Size = UDim2.new(0.5, 0, 1, 0)
GUI.LeftBarImage.Name = "LeftBarImage"
GUI.LeftBarImage.Parent = GUI.LeftBar

GUI.RightBack.Image = "rbxassetid://2094637131"
GUI.RightBack.ImageColor3 = GUI.PROGRESSBARBACKCOLOR
GUI.RightBack.ImageRectOffset = Vector2.new(128, 0)
GUI.RightBack.ImageRectSize = Vector2.new(128, 256)
GUI.RightBack.SliceCenter = Rect.new(0, 0, 128, 256)
GUI.RightBack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GUI.RightBack.BackgroundTransparency = 1
GUI.RightBack.Position = UDim2.new(0.5, 0, 0, 0)
GUI.RightBack.Size = UDim2.new(0.5, 0, 1, 0)
GUI.RightBack.Name = "RightBack"
GUI.RightBack.Parent = GUI.CircularProgressBar

GUI.RightBar.AnchorPoint = Vector2.new(0.5, 0.5)
GUI.RightBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GUI.RightBar.BackgroundTransparency = 1
GUI.RightBar.Position = UDim2.new(0, 0, 0.5, 0)
GUI.RightBar.Size = UDim2.new(2, 0, 1, 0)
GUI.RightBar.Name = "RightBar"
GUI.RightBar.Parent = GUI.RightBack

GUI.RightBarImage.Image = "rbxassetid://2094676785"
GUI.RightBarImage.ImageColor3 = GUI.PROGRESSBARIMAGECOLOR
GUI.RightBarImage.ImageRectOffset = Vector2.new(128, 0)
GUI.RightBarImage.ImageRectSize = Vector2.new(128, 256)
GUI.RightBarImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GUI.RightBarImage.BackgroundTransparency = 1
GUI.RightBarImage.Position = UDim2.new(0.5, 0, 0, 0)
GUI.RightBarImage.Size = UDim2.new(0.5, 0, 1, 0)
GUI.RightBarImage.Name = "RightBarImage"
GUI.RightBarImage.Parent = GUI.RightBar

GUI.PROGRESS:GetPropertyChangedSignal("Value"):Connect(GUI.UpdateProgressBar)
GUI.PROGRESS.Value = 0 -- Doesn't trigger the changed signal because NumberValues are already at 0.
GUI.UpdateProgressBar() -- Ensure that the progress has been updated to 0.
-- \\ ======================================================================== //


-- // Event Functions \\
FUNCTIONS.PICKUP = function ()
	CURRENT_ITEM = TARGET
	FUNCTIONS.EditFilterDescendantsInstances(true, CURRENT_ITEM)
	
	GrabRemote:FireServer(CURRENT_ITEM, ALT_DOWN)
	
	repeat task.wait() until CollectionService:HasTag(CURRENT_ITEM, BlacklistedTags.ISHELD_TAG)
	
	HOLDING = true
	
	GUI.GrabCaret.Visible = false
	
	if CURRENT_ITEM:IsA("BasePart") then
		FUNCTIONS.ParentBodyMovers(CURRENT_ITEM)
	elseif CURRENT_ITEM:IsA("Model") then
		FUNCTIONS.ParentBodyMovers(FUNCTIONS.ReturnPrimaryPart(CURRENT_ITEM))
	end
end

FUNCTIONS.HOLDING = function ()
	if ROTATE_INPUT_DOWN and ALT_DOWN then
		AlignOrientation.CFrame = ORIENTATION
		
		return
	end
	
	local Destination = MOVE_MODES[MOVE_MODE]()
	local NewCFrame = CFrame.new(Destination) * ORIENTATION
	
	local OldCFrame = CURRENT_ITEM:GetPivot()
	local Distance = (NewCFrame.Position - OldCFrame.Position).Magnitude
	
	NewCFrame = OldCFrame:Lerp(NewCFrame, math.clamp(Distance, MOVE_LERP_RANGE.Min, MOVE_LERP_RANGE.Max))
	
	CURRENT_ITEM:PivotTo(NewCFrame)
	
	AlignPosition.Position = NewCFrame.Position
	AlignOrientation.CFrame = NewCFrame
	
	if CURRENT_ITEM:IsA("BasePart") then
		local TouchingParts = workspace:GetPartsInPart(CURRENT_ITEM)
		
		for i, Part in pairs(TouchingParts) do
			if Part:IsDescendantOf(owner.Character) then
				TouchingParts[i] = nil
			end
		end
		
		TOUCHING_PARTS = TouchingParts
		
		if #TOUCHING_PARTS > 0 then -- CURRENT_ITEM is colliding.
			SelectionBox.Adornee = CURRENT_ITEM
		else
			SelectionBox.Adornee = nil
		end
	elseif CURRENT_ITEM:IsA("Model") then
		local IsTouching = false
		
		for i, Part in pairs(CURRENT_ITEM:GetDescendants()) do
			if Part:IsA("BasePart") then
				local TouchingParts = workspace:GetPartsInPart(Part)
				
				for i, TouchingPart in pairs(TouchingParts) do
					if TouchingPart:IsDescendantOf(owner.Character) or TouchingPart:IsDescendantOf(CURRENT_ITEM) then
						TouchingParts[i] = nil
					end
				end
				
				if #TouchingParts > 0 then
					IsTouching = true
					TOUCHING_PARTS[Part.Name .. i] = TouchingParts
				end
			end
		end
		
		TOUCHING = IsTouching
		
		if TOUCHING then
			SelectionBox.Adornee = CURRENT_ITEM
		else
			SelectionBox.Adornee = nil
		end
	end
end

FUNCTIONS.DROP = function ()
	GrabRemote:FireServer(false, false, TOUCHING_PARTS, ANCHORING_ENABLED)
	
	local startwait = tick()
	
	repeat
		if (tick() - startwait) > 2 then
			warn("Failed to drop: '" .. CURRENT_ITEM.ClassName .. "' - '" .. CURRENT_ITEM:GetFullName() .. "'")
			
			break
		end
		
		task.wait()
	until not CollectionService:HasTag(CURRENT_ITEM, BlacklistedTags.ISHELD_TAG)
	
	HOLDING = false
	
	SelectionBox.Adornee = nil
	Highlight.Adornee = nil
	
	FUNCTIONS.ParentBodyMovers(nil)
	FUNCTIONS.EditFilterDescendantsInstances(false, CURRENT_ITEM)
	
	if THROW_FORCE > 0 and THROWING_ENABLED then
		local Velocity = Camera.CFrame.LookVector * THROW_FORCE
		
		if CURRENT_ITEM:IsA("BasePart") then
			CURRENT_ITEM.AssemblyLinearVelocity = Camera.CFrame.LookVector * THROW_FORCE
		elseif CURRENT_ITEM:IsA("Model") then
			local BasePart = CURRENT_ITEM:FindFirstChildWhichIsA("BasePart")

			if BasePart then
				BasePart.AssemblyLinearVelocity = (Camera.CFrame.LookVector * THROW_FORCE)
			end
		end
	end
	
	CURRENT_ITEM = nil
end


-- // Input Handling ============================================================================================ \\
GUI.InputBegan = function (Input, GPE)
	if Input.KeyCode == Enum.KeyCode.BackSlash then
		FUNCTIONS.FOCUS_TEXTBOX()
	end
	
	if GPE then return end
	
	if Input.UserInputType == Enum.UserInputType.Keyboard then
		if Input.KeyCode == PICKUP_INPUT then
			PICKUP_INPUT_DOWN = true
			
			if CURRENT_ITEM then
				DROPPING = true

				if THROWING_ENABLED then
					local DROPSTART = tick()
					
					repeat
						if tick() - DROPSTART > 0.5 then
							THROW_FORCE = math.clamp(THROW_FORCE + THROW_FORCE_INCREMENT, 0, MAX_THROW_FORCE)
						end
						
						task.wait()
					until not DROPPING
				end
			else
				if TARGET and not ZOOM_INPUT_DOWN then
					FIRST_INPUT_TARGET = TARGET
					GUI.CircularProgressBar.Visible = true
					PICKUP_TWEEN = TweenService:Create(GUI.PROGRESS, TweenInfo.new(PICKUP_HOLD, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Value = 359.9})
					PICKUP_TWEEN:Play()
				end
			end
		elseif Input.KeyCode == Enum.KeyCode.LeftControl then
			CTRL_DOWN = true
		elseif Input.KeyCode == Enum.KeyCode.LeftShift then
			SHIFT_DOWN = true
		elseif Input.KeyCode == Enum.KeyCode.LeftAlt then
			ALT_DOWN = true
			
			Highlight.FillColor = HighlightColorRed.FillColor
			Highlight.OutlineColor = HighlightColorRed.OutlineColor
		elseif Input.KeyCode == INCREASEDISTANCE_INPUT and CURRENT_ITEM then
			HOLD_DISTANCE = math.clamp(HOLD_DISTANCE + HOLD_DISTANCE_INCREMENT, MINIMUM_HOLD_DISTANCE, MAXIMUM_HOLD_DISTANCE)
		elseif Input.KeyCode == DECREASEDISTANCE_INPUT and CURRENT_ITEM then
			HOLD_DISTANCE = math.clamp(HOLD_DISTANCE - HOLD_DISTANCE_INCREMENT, MINIMUM_HOLD_DISTANCE, MAXIMUM_HOLD_DISTANCE)
		elseif Input.KeyCode == CHECK_NETWORK_OWNER_INPUT then
			CheckOwnerRemote:FireServer(Mouse.Target)
		elseif Input.KeyCode == Enum.KeyCode.One then
			AXIS = "X"
		elseif Input.KeyCode == Enum.KeyCode.Two then
			AXIS = "Y"
		elseif Input.KeyCode == Enum.KeyCode.Three then print"gay"
			AXIS = "Z"
		elseif Input.KeyCode == ROTATE_INPUT then
			ROTATE_INPUT_DOWN = true
			
			if ALT_DOWN then
				local Offset = (Camera.CFrame - owner.Character.Head.Position).Position
				
				Camera.CameraType = Enum.CameraType.Scriptable
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				
				repeat
					--Camera.CFrame = owner.Character.Head.CFrame + Offset
					
					local MouseDelta = UserInputService:GetMouseDelta()
					
					local RotationX = MouseDelta.X * ORIENTATION_INCREMENT
					local RotationY = MouseDelta.Y * ORIENTATION_INCREMENT
					
					ORIENTATION = ORIENTATION * CFrame.Angles(math.rad(RotationY), math.rad(RotationX), 0)
					
					task.wait()
				until not ALT_DOWN or not ROTATE_INPUT_DOWN

				Camera.CameraType = Enum.CameraType.Custom
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				
				return
			end

			if not ALT_DOWN then
				RotateSound:Play()
			end
			
			if SHIFT_DOWN and CTRL_DOWN then
				ORIENTATION = CFrame.new()
				return
			end
			
			if AXIS == "X" then
				ORIENTATION = ORIENTATION * CFrame.Angles(ORIENTATION_INCREMENT, 0, 0)
			elseif AXIS == "Y" then
				ORIENTATION = ORIENTATION * CFrame.Angles(0, ORIENTATION_INCREMENT, 0)
			elseif AXIS == "Z" then
				ORIENTATION = ORIENTATION * CFrame.Angles(0, 0, ORIENTATION_INCREMENT)
			end
		elseif Input.KeyCode == CHANGE_CAMERAMODE_INPUT then
			if owner.CameraMode == Enum.CameraMode.Classic then
				owner.CameraMode = Enum.CameraMode.LockFirstPerson
			elseif owner.CameraMode == Enum.CameraMode.LockFirstPerson then
				owner.CameraMode = Enum.CameraMode.Classic
			end
		elseif Input.KeyCode == CHANGE_MODE_INPUT then
			if MODE == "Camera" then
				MODE = "Mouse"
			elseif MODE == "Mouse" then
				MODE = "Camera"
			end
		elseif Input.KeyCode == DELETE_INPUT then
			if TARGET or CURRENT_ITEM then
				DeleteRemote:FireServer(CURRENT_ITEM or TARGET)
			end
		elseif Input.KeyCode == ZOOM_INPUT then
			ZOOM_INPUT_DOWN = true
		end
	end
end

GUI.InputChanged = function (Input, GPE)
	if not GPE then
		if Input.UserInputType == Enum.UserInputType.MouseWheel then
			if CURRENT_ITEM and MOVE_MODE == "Camera" then
				ScrollWheelClickSound:Play()
				
				if Input.Position.Z > 0 then -- Up
					HOLD_DISTANCE = math.clamp(HOLD_DISTANCE + HOLD_DISTANCE_INCREMENT, MINIMUM_HOLD_DISTANCE, MAXIMUM_HOLD_DISTANCE)
				else -- Down
					HOLD_DISTANCE = math.clamp(HOLD_DISTANCE - HOLD_DISTANCE_INCREMENT, MINIMUM_HOLD_DISTANCE, MAXIMUM_HOLD_DISTANCE)
				end
			end
		end
	end
end

GUI.InputEnded = function (Input, GPE)
	if not GPE then
		if Input.UserInputType == Enum.UserInputType.Keyboard then
			if Input.KeyCode == PICKUP_INPUT then
				if CURRENT_ITEM and DROPPING then
					
					-- //////////////////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
					-- ||||||||||||||||||||||||||||||||| User is dropping CURRENT_ITEM. |||||||||||||||||||||||||||||||||
					-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////////////
					
					FUNCTIONS.DROP()
					DROPPING = false
					THROW_FORCE = 0
					
				end
				
				PICKUP_INPUT_DOWN = false
				FIRST_INPUT_TARGET = nil
				
				if PICKUP_TWEEN then
					GUI.CircularProgressBar.Visible = false
					PICKUP_TWEEN:Pause()
					PICKUP_TWEEN = nil
					GUI.PROGRESS.Value = 0
				end
			elseif Input.KeyCode == Enum.KeyCode.LeftControl then
				CTRL_DOWN = false
			elseif Input.KeyCode == Enum.KeyCode.LeftShift then
				SHIFT_DOWN = false
			elseif Input.KeyCode == Enum.KeyCode.LeftAlt then
				ALT_DOWN = false
				
				Highlight.FillColor = HighlightColorWhite.FillColor
				Highlight.OutlineColor = HighlightColorWhite.OutlineColor
			elseif Input.KeyCode == ROTATE_INPUT then
				ROTATE_INPUT_DOWN = false
			elseif Input.KeyCode == ZOOM_INPUT then
				ZOOM_INPUT_DOWN = false
			end
		end
	end
end

UserInputService.InputBegan:Connect(GUI.InputBegan)
UserInputService.InputChanged:Connect(GUI.InputChanged)
UserInputService.InputEnded:Connect(GUI.InputEnded)
-- \\ =========================================================================================================== //


-- // Main Loop \\
RunService.PostSimulation:Connect(function(Delta)
	-- Update the TARGET variable.
	FUNCTIONS.UpdateTarget()
	
	if HOLDING then
		FUNCTIONS.UpdateRaycastHoldDistance()
		
		Highlight.Adornee = nil
	else
		Highlight.Adornee = TARGET
	end
	
	if FUNCTIONS.IsFirstPerson() then
		MOVE_MODE = "Camera"
	else
		MOVE_MODE = "Mouse"
	end
	
	if SHIFT_DOWN and not CTRL_DOWN then
		ORIENTATION_INCREMENT = ROTATION_INCREMENT_90
	elseif CTRL_DOWN and not SHIFT_DOWN then
		ORIENTATION_INCREMENT = ROTATION_INCREMENT_15
	elseif not SHIFT_DOWN and not CTRL_DOWN then
		ORIENTATION_INCREMENT = ROTATION_INCREMENT_45
	elseif SHIFT_DOWN and CTRL_DOWN then
		ORIENTATION_INCREMENT = ROTATION_INCREMENT_45 -- not used.
	end
	
	-- Update GUI GrabCaret and CircularProgressBar.
	if CURRENT_ITEM and HOLDING then
		GUI.GrabCaret.Position = GUI.GrabCaret.Position:Lerp(UDim2.fromScale(0.5, 0.5), GRAB_CARET_SPEED)
		if GUI.CircularProgressBar.Visible then GUI.CircularProgressBar.Visible = false end
		
		-- /////////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
		-- ||||||||||||||||||||||||||||| User is holding CURRENT_ITEM. |||||||||||||||||||||||||||||
		-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////////////
		
		FUNCTIONS.HOLDING()
		
	else
		if not GUI.GrabCaret.Visible then GUI.GrabCaret.Visible = true end
	
		if TARGET then
			local TargetPosition, InBounds = Camera:WorldToViewportPoint(TARGET:IsA("Model") and FUNCTIONS.ReturnPrimaryPart(TARGET).Position or TARGET.Position)
			GUI.UpdateGrabCaret(TargetPosition, InBounds)
		else
			GUI.UpdateGrabCaret(UDim2.fromScale(0.5, 0.5))
			
			if PICKUP_TWEEN then PICKUP_TWEEN:Pause() end
			GUI.PROGRESS.Value = 0
			if GUI.CircularProgressBar.Visible then GUI.CircularProgressBar.Visible = false end
		end
	end
	
	if PICKUP_INPUT_DOWN then
		if TARGET then
			if TARGET == FIRST_INPUT_TARGET then
				if not CURRENT_ITEM then
					if GUI.PROGRESS.Value > 359 then
					
						-- ///////////////////////////////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
						-- |||||||||||||||||||||| User is picking up TARGET. Despite being in a RunService loop, this only runs once. ||||||||||||||||||||||
						-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//////////////////////////////////////////////////////////////////
						
						FUNCTIONS.PICKUP()
						
					end
				end
			end
		end
	end

	if ZOOM_INPUT_DOWN then
		if CURRENT_ITEM or not FUNCTIONS.IsFirstPerson() then
			Camera.FieldOfView = FUNCTIONS.Lerp(Camera.FieldOfView, DEFAULT_FIELD_OF_VIEW, FIELD_OF_VIEW_LERP_SPEED)
		else
			Camera.FieldOfView = FUNCTIONS.Lerp(Camera.FieldOfView, ZOOMED_FIELD_OF_VIEW, FIELD_OF_VIEW_LERP_SPEED)
		end
	else
		Camera.FieldOfView = FUNCTIONS.Lerp(Camera.FieldOfView, DEFAULT_FIELD_OF_VIEW, FIELD_OF_VIEW_LERP_SPEED)
	end
end)
]], owner.PlayerGui)

