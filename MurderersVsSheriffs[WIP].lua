-- murderers vs sheriffs duels [wip]

local players = cloneref(game:GetService("Players"))
local client = players.LocalPlayer
local camera = workspace.CurrentCamera
local inputs = cloneref(game:GetService("UserInputService"))
local storage = cloneref(game:GetService("ReplicatedStorage"))
local characters = storage:WaitForChild("HiddenCharacters")

for _, v in getreg() do
	if type(v) == "thread" and value ~= coroutine.running() then
		local script = getscriptfromthread(v)
		if script and script.Name == "BAC_" then
			pcall(function()
				task.cancel(v)
				coroutine.close(v)
			end)
		end
	end
end

getgenv().global = getgenv()

function global.declare(self, index, value, check)
	if self[index] == nil then
		self[index] = value
	elseif check then
		local methods = { "remove", "Disconnect" }

		for _, method in methods do
			pcall(function()
				value[method](value)
			end)
		end
	end

	return self[index]
end

declare(global, "services", {})

function global.get(service)
	return services[service]
end

declare(declare(services, "loop", {}), "cache", {})

get("loop").new = function(self, index, func, disabled)
	if disabled == nil and (func == nil or typeof(func) == "boolean") then
		disabled = func func = index
	end

	self.cache[index] = {
		["enabled"] = (not disabled),
		["func"] = func,
		["toggle"] = function(self, boolean)
			if boolean == nil then
				self.enabled = not self.enabled
			else
				self.enabled = boolean
			end
		end,
		["remove"] = function()
			self.cache[index] = nil
		end
	}

	return self.cache[index]
end

declare(get("loop"), "connection", cloneref(game:GetService("RunService")).RenderStepped:Connect(function(delta)
	for _, loop in get("loop").cache do
		if loop.enabled then
			local success, result = pcall(function()
				loop.func(delta)
			end)

			if not success then
				warn(result)
			end
		end
	end
end), true)

declare(declare(services, "property", {}), "cache", {})

get("property").change = function(self, instance, properties, cache)
	for property, value in properties do
		pcall(function()
			declare(declare(self.cache, instance, {}), property, instance[property])
			instance[property] = value
		end)
	end
end

get("property").revert = function(self, instance, cache)
	if self.cache[instance] then
		for property, value in self.cache[instance] do
			pcall(function()
				instance[property] = value self.cache[instance][property] = nil
			end)
		end
	end
end

declare(services, "new", {})

get("new").drawing = function(class, properties)
	local drawing = Drawing.new(class)
	for property, value in properties do
		pcall(function()
			drawing[property] = value
		end)
	end
	return drawing
end

declare(declare(services, "player", {}), "cache", {})

get("player").find = function(self, player)
	for character, data in self.cache do
		if data.player == player then
			return character
		end
	end
end

get("player").check = function(self, player)
	local success, check = pcall(function()
		local character = player:IsA("Player") and player.Character or player
		local children = { character.Humanoid, character.HumanoidRootPart }

		return children and character.Parent ~= nil
	end)

	return success and check
end

get("player").new = function(self, player)
	local function cache(character)
		self.cache[character] = {
			["player"] = player,
			["drawings"] = {
				["box"] = get("new").drawing("Square", { Visible = false }),
				["boxFilled"] = get("new").drawing("Square", { Visible = false, Filled = true }),
				["boxOutline"] = get("new").drawing("Square", { Visible = false }),
				["name"] = get("new").drawing("Text", { Visible = false, Center = true}),
				["distance"] = get("new").drawing("Text", { Visible = false, Center = true}),
				["weapon"] = get("new").drawing("Text", { Visible = false, Center = true}),
			}
		}
	end

	local function check(character)
		if self:check(character) then
			cache(character)
		else
			local listener; listener = character.ChildAdded:Connect(function()
				if self:check(character) then
					cache(character) listener:Disconnect()
				end
			end)
		end
	end

	if player.Character then check(player.Character) end
	player.CharacterAdded:Connect(check)
end

get("player").remove = function(self, player)
	if player:IsA("Player") then
		local character = self:find(player)
		if character then
			self:remove(character)
		end
	else
		local drawings = self.cache[player].drawings self.cache[player] = nil
		for _, drawing in drawings do
			drawing:Remove()
		end
	end
end

get("player").update = function(self, character, data)
	if not self:check(character) then
		self:remove(character)
	end

	local player = data.player
	local root = character.HumanoidRootPart
	local humanoid = character.Humanoid
	local drawings = data.drawings
	local visuals = features.visuals
	local hitbox = features.hitbox
	local weapon = character:FindFirstChildWhichIsA("Tool")

	if character.Parent ~= characters then
		if hitbox.enabled then
			get("property"):change(character.HumanoidRootPart, {
				Size = Vector3.new(hitbox.size, hitbox.size, hitbox.size),
				Color =	hitbox.color,
				Material = hitbox.material,
				CanCollide = false,
				Transparency = hitbox.transparency,
			})
		end

		if self:check(client) then
			data.distance = (client.Character.HumanoidRootPart.CFrame.Position - root.CFrame.Position).Magnitude
		end

		data.view, data.visible = camera:WorldToViewportPoint(root.CFrame.Position)
	end

	local function check()
		local team; if visuals.teamCheck then team = player.Team ~= client.Team else team = true end
		return visuals.enabled and data.distance and team and humanoid.Health > 0 and character.Parent ~= characters
	end

	if data.visible and check() then
		local scale = 1 / (data.view.Z * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2) * 1000
		local width, height = math.floor(4.5 * scale), math.floor(6 * scale)
		local x, y = math.floor(data.view.X), math.floor(data.view.Y)
		local xPosition, yPostion = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))


		drawings.box.Size = Vector2.new(width, height)
		drawings.box.Position = Vector2.new(xPosition, yPostion)
		drawings.boxFilled.Size = drawings.box.Size
		drawings.boxFilled.Position = drawings.box.Position
		drawings.boxOutline.Size = drawings.box.Size
		drawings.boxOutline.Position = drawings.box.Position

		drawings.box.Color = visuals.boxes.color
		drawings.box.Thickness = 1
		drawings.boxFilled.Color = visuals.boxes.filled.color
		drawings.boxFilled.Transparency = visuals.boxes.filled.transparency
		drawings.boxOutline.Color = visuals.boxes.outline.color
		drawings.boxOutline.Thickness = 3

		drawings.boxOutline.ZIndex = drawings.box.ZIndex - 1
		drawings.boxFilled.ZIndex = drawings.boxOutline.ZIndex - 1

		drawings.name.Text = `[ {player.Name} ]`
		drawings.name.Size = math.max(math.min(math.abs(12.5 * scale), 12.5), 10)
		drawings.name.Position = Vector2.new(x, (yPostion - drawings.name.TextBounds.Y) - 2)
		drawings.name.Color = visuals.names.color
		drawings.name.Outline = visuals.names.outline.enabled
		drawings.name.OutlineColor = visuals.names.outline.color

		drawings.name.ZIndex = drawings.box.ZIndex + 1

		drawings.distance.Text = `[ {math.floor(data.distance)} ]`
		drawings.distance.Size = math.max(math.min(math.abs(11 * scale), 11), 10)
		drawings.distance.Position = Vector2.new(x, (yPostion + height) + (drawings.distance.TextBounds.Y * 0.25))
		drawings.distance.Color = visuals.distance.color
		drawings.distance.Outline = visuals.distance.outline.enabled
		drawings.distance.OutlineColor = visuals.distance.outline.color
		
		drawings.weapon.Text = `[ {weapon or "none"} ]`
		drawings.weapon.Size = math.max(math.min(math.abs(11 * scale), 11), 10)
		drawings.weapon.Position = visuals.distance.enabled and Vector2.new(drawings.distance.Position.x, drawings.distance.Position.Y + (drawings.weapon.TextBounds.Y * 0.75)) or drawings.distance.Position
		drawings.weapon.Color = visuals.weapon.color
		drawings.weapon.Outline = visuals.weapon.outline.enabled
		drawings.weapon.OutlineColor = visuals.weapon.outline.color
	end

	pcall(function()
		drawings.box.Visible = (check() and data.visible and visuals.boxes.enabled)
		drawings.boxFilled.Visible = (check() and drawings.box.Visible and visuals.boxes.filled.enabled)
		drawings.boxOutline.Visible = (check() and drawings.box.Visible and visuals.boxes.outline.enabled)
		drawings.name.Visible = (check() and data.visible and visuals.names.enabled)
		drawings.distance.Visible = (check() and data.visible and visuals.distance.enabled)
		drawings.weapon.Visible = (check() and data.visible and visuals.weapon.enabled)
	end)
end

declare(get("player"), "loop", get("loop"):new(function ()
	for character, data in get("player").cache do
		get("player"):update(character, data)
	end
end), true)

declare(services, "view", {})

get("view").visible = function(part, whitelist)
	return #camera:GetPartsObscuringTarget({part:GetPivot().Position}, whitelist) == 0
end

declare(services, "closest", {})

get("closest").mouse = function(distance, visibleCheck)
	local closest; distance = distance or math.huge
	local mouse = inputs:GetMouseLocation()

	for character, data in get("player").cache do
		pcall(function()
			local magnitude = (mouse - Vector2.new(data.view.X, data.view.Y)).Magnitude
			if magnitude < distance and data.visible and character.Parent ~= characters then
				if visibleCheck and get("view").visible(character.HumanoidRootPart, { character, client.Character }) then
					closest = character distance = magnitude
				elseif not visibleCheck then
					closest = character distance = magnitude
				end
			end
		end)
	end

	return closest
end

declare(global, "features", {})

features.toggle = function(self, feature, boolean)
	if self[feature] then
		if boolean == nil then
			self[feature].enabled = not self[feature].enabled
		else
			self[feature].enabled = boolean
		end

		if self[feature].toggle then
			task.spawn(function()
				self[feature]:toggle()
			end)
		end
	end
end

declare(features, "hitbox", {
	["enabled"] = false,
	["size"] = 10,
	["color"] = Color3.fromRGB(255, 255, 255),
	["material"] = Enum.Material.ForceField,
	["transparency"] = 0.5
})

features.hitbox.toggle = function(self)
	if not self.enabled then
		for character ,_ in get("player").cache do
			get("property"):revert(character.HumanoidRootPart)
		end
	end
end

declare(features, "visuals", {
	["enabled"] = true,
	["teamCheck"] = false,

	["boxes"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(255, 255, 255),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
		},
		["filled"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(255, 255, 255),
			["transparency"] = 0.25
		},
	},
	["names"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(255, 255, 255),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
		},
	},
	["health"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(0, 255, 0),
		["colorLow"] = Color3.fromRGB(255, 0, 0),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0)
		},
		["text"] = {
			["enabled"] = true,
			["outline"] = {
				["enabled"] = true,
			},
		}
	},
	["distance"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(255, 255, 255),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
		},
	},
	["weapon"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(255, 255, 255),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
		},
	}
})

declare(features, "crosshair", {
	["enabled"] = true,
	["size"] = 10,
	["color"] = Color3.fromRGB(255, 255, 255),
	["distance"] = 10,
	["thickness"] = 1,
	["followMouse"] = true,
	["outline"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(0, 0, 0),
		["thickness"] = 2
	},
	["spinning"] = {
		["enabled"] = true,
		["speed"] = 6,
		["angle"] = 0
	},
	["lines"] = {
		["top"] = { angle = 0, drawing = get("new").drawing("Line", { Visible = false }) },
		["topOutline"] = { drawing = get("new").drawing("Line", { Visible = false }) },
		["bottom"] = { angle = 180, drawing = get("new").drawing("Line", { Visible = false }) },
		["bottomOutline"] = { drawing = get("new").drawing("Line", { Visible = false }) },
		["left"] = { angle = 270, drawing = get("new").drawing("Line", { Visible = false }) },
		["leftOutline"] = { drawing = get("new").drawing("Line", { Visible = false }) },
		["right"] = { angle = 90, drawing = get("new").drawing("Line", { Visible = false }) },
		["rightOutline"] = { drawing = get("new").drawing("Line", { Visible = false }) },
	}
})

declare(features.crosshair, "loop", get("loop"):new(function()
	local crosshair = features.crosshair
	local mouse = inputs:GetMouseLocation()
	local center = crosshair.followMouse and Vector2.new(mouse.X, mouse.Y) or camera.ViewportSize * 0.5

	crosshair.spinning.angle = (crosshair.spinning.angle + (crosshair.spinning.speed / 10)) % 360
	local angle = crosshair.spinning.enabled and crosshair.spinning.angle or 0

	for index, line in crosshair.lines do
		if index:match("Outline") then
			if crosshair.enabled then
				local adornee = crosshair.lines[index:gsub("Outline", "")]
				local thickness = crosshair.thickness + crosshair.outline.thickness

				local fromX = center.X - ((crosshair.distance - (thickness / 4)) * math.sin(math.rad(angle + adornee.angle)))
				local fromY = center.Y + ((crosshair.distance - (thickness / 4)) * math.cos(math.rad(angle + adornee.angle)))
				local toX = center.X - (((crosshair.size + crosshair.distance) + (thickness / 4)) * math.sin(math.rad(angle + adornee.angle)))
				local toY = center.Y + (((crosshair.size + crosshair.distance) + (thickness / 4)) * math.cos(math.rad(angle + adornee.angle)))

				line.drawing.From = Vector2.new(fromX, fromY)
				line.drawing.To = Vector2.new(toX, toY)

				line.drawing.Color = crosshair.outline.color
				line.drawing.Thickness = thickness

				line.drawing.ZIndex = adornee.drawing.ZIndex - 1
			end

			line.drawing.Visible = crosshair.enabled and crosshair.outline.enabled
		else
			if crosshair.enabled then
				local fromX = center.X - (crosshair.distance * math.sin(math.rad(angle + line.angle)))
				local fromY = center.Y + (crosshair.distance * math.cos(math.rad(angle + line.angle)))
				local toX = center.X - ((crosshair.size + crosshair.distance) * math.sin(math.rad(angle + line.angle)))
				local toY = center.Y + ((crosshair.size + crosshair.distance) * math.cos(math.rad(angle + line.angle)))

				line.drawing.From = Vector2.new(fromX, fromY)
				line.drawing.To = Vector2.new(toX, toY)

				line.drawing.Color = crosshair.color
				line.drawing.Thickness = crosshair.thickness
			end

			line.drawing.Visible = crosshair.enabled
		end
	end
end), true)

declare(features, "target", {
	["enabled"] = true,
	["visibleCheck"] = true,
	["fov"] = {
		["enabled"] = true,
		["show"] = true,
		["amount"] = 200,
		["color"] = Color3.fromRGB(255, 255, 255),
		["drawing"] = get("new").drawing("Circle", { Visible = false }),
		["thickness"] = 1,
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
			["drawing"] = get("new").drawing("Circle", { Visible = false }),
			["thickness"] = 2
		}
	},
	["showTarget"] = {
		["enabled"] = true,
		["name"] = {
			["enabled"] = true,
			["size"] = 14,
			["color"] = Color3.fromRGB(255, 255, 255),
			["drawing"] = get("new").drawing("Text", { Visible = false, Center = true}),
			["outline"] = {
				["enabled"] = true,
				["color"] = Color3.fromRGB(0, 0, 0),
			},
		},
		["distance"] = {
			["enabled"] = true,
			["size"] = 14,
			["color"] = Color3.fromRGB(255, 255, 255),
			["drawing"] = get("new").drawing("Text", { Visible = false, Center = true}),
			["outline"] = {
				["enabled"] = true,
				["color"] = Color3.fromRGB(0, 0, 0),
			},
		},
		["weapon"] = {
			["enabled"] = true,
			["size"] = 14,
			["color"] = Color3.fromRGB(255, 255, 255),
			["drawing"] = get("new").drawing("Text", { Visible = false, Center = true}),
			["outline"] = {
				["enabled"] = true,
				["color"] = Color3.fromRGB(0, 0, 0),
			},
		}
	}
})

declare(features.target, "loop", get("loop"):new(function()
	local target = features.target
	local fov = target.fov
	local showTarget = target.showTarget
	local closest = get("closest").mouse(fov.enabled and fov.amount or math.huge, features.target.visibleCheck)
	local mouse = inputs:GetMouseLocation()

	target.player = closest

	if fov.enabled and fov.show then
		fov.drawing.Position = Vector2.new(mouse.X, mouse.Y)
		fov.drawing.Color = fov.color
		fov.drawing.Thickness = fov.thickness
		fov.drawing.Radius = fov.amount

		fov.outline.drawing.Position = fov.drawing.Position
		fov.outline.drawing.Color = fov.outline.color
		fov.outline.drawing.Thickness = fov.thickness + fov.outline.thickness
		fov.outline.drawing.Radius = fov.drawing.Radius

		fov.outline.drawing.ZIndex = fov.drawing.ZIndex - 1
	end

	if showTarget.enabled then
		local crosshairSpace = (features.crosshair.enabled and features.crosshair.size +  features.crosshair.distance or 0)
		showTarget.name.drawing.Position = Vector2.new(mouse.X, mouse.Y + crosshairSpace + showTarget.name.drawing.TextBounds.Y)
		showTarget.name.drawing.Text = `[ {target.player and target.player.Name or "none"} ]`
		showTarget.name.drawing.Size = showTarget.name.size
		showTarget.name.drawing.Color = showTarget.name.color
		showTarget.name.drawing.Outline = showTarget.name.outline.enabled
		showTarget.name.drawing.OutlineColor = showTarget.name.outline.color
	end

	fov.drawing.Visible = target.enabled and fov.enabled and fov.show
	fov.outline.drawing.Visible = target.enabled and fov.enabled and fov.show and fov.outline.enabled
	showTarget.name.drawing.Visible = target.enabled and showTarget.enabled and showTarget.name.enabled
end), true)

for _, player in players:GetPlayers() do
	if player ~= client and not get("player"):find(player) then
		get("player"):new(player)
	end
end

declare(get("player"), "added", players.PlayerAdded:Connect(function(player)
	get("player"):new(player)
end), true)

declare(get("player"), "removing", players.PlayerRemoving:Connect(function(player)
	get("player"):remove(player)
end), true)

local namecall; namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	local arguments = {...}
	local method = getnamecallmethod():lower()

	if not checkcaller() and self.Name == "Shoot" and method == "fireserver" then
		
		pcall(function()
			if features.target.player then
				arguments[3] = features.target.player.HumanoidRootPart
				arguments[4] = features.target.player.HumanoidRootPart.CFrame.Position
			end
		end)

		return namecall(self, unpack(arguments))
	end
		
	return namecall(self, ...)
end))
