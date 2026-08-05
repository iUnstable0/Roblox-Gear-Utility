local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JointsService = game:GetService("JointsService")

local Toolbar = plugin:CreateToolbar("Gears Utility")

local LoadGearsButton = Toolbar:CreateButton(
	"Load Gears",
	"Load gears on Roblox",
	"rbxassetid://5711524831"
)
local LoadGearsWithoutFixingButton = Toolbar:CreateButton(
	"Load Gears Without Fixing",
	"Load gears on Roblox (without fixing them)",
	"rbxassetid://5711524831"
)
local FixObjectButton = Toolbar:CreateButton(
	"Fix Object",
	"Fix object and its children",
	"rbxassetid://6172144323"
)
local UpdateModulePackagesButton = Toolbar:CreateButton(
	"Update Packages",
	"Update gear module packages",
	"rbxassetid://6022668955"
)

local GearAttributeKeys = {
	"id",
	"name",
	"description",
	"favoriteCount",
	"offSaleDeadline",
	"price",
	"lowestPrice",
	"lowestResalePrice",
	"priceStatus",
	"totalQuantity",
	"hasResellers",
	"isOffSale",
}

local LoadLibraryFunction = "local function LoadLibrary(Library)"
local TreeTab = "\t\t\t\t\t"

local READMESource = [[
	--[[
		This folder contains gears that GearUtility failed to load in.

		It is normal for the following gears to fail to load because Roblox made them so:
			- 103360212 skull rug
			- 27476125 NoobTube
			- 44084677 Tomahawk
			- 91366868 Gear
			- 445119186 .
			- 445120580 .
			- 445146200 .
			- 2535472650 The Great Sword Justice
			- 2845969550 Badimo Arm Cannon
			- 806882461 __
			- 445136641 .
			- 2936947382 Gear of Mystery
			- 23307906 Cooooool!!!
			- 445122594  .
			- 445122795 .
			- 445132899 .
			- 806754856 _
			- 445118914 .
			- 445127715 .
			- 445118715 .

		If you see any other gears that failed to load in that is not listed above, just re-run "Load Gears" and the plugin will try to load them in again
	\]\]--
]]

local function ParseModulePath(ModuleName)
	return `game:GetService("ReplicatedStorage").GearModulesFolder.{ModuleName}`
end

local LoadLibraryRequire = `require({ParseModulePath("LoadLibrary")})(Library)`

-- 225918694 NOT FOR SALE
-- 187430232 GONE
-- 376407361 GONE

local ReplaceList = {
	[754568173] = ParseModulePath("SwordModule"), -- Sword Module
	[172349822] = ParseModulePath("GearModule"), -- Gear Module
	[191816425] = ParseModulePath("MultiPurposeModule"), -- Multi Purpose Module
	[201433042] = ParseModulePath("ScaleCharacterModule"), -- Scale Character Module
	[1075123174] = ParseModulePath("GearService"), -- GearService
	[199238756] = ParseModulePath("SkateboardModule"), -- Skateboard Module
	[836581200] = ParseModulePath("PackageMaker"), -- Package Maker
	[180464321] = ParseModulePath("HalloweenMonsterCustomesLibrary"), -- Halloween Monster Costumes Library
	[185791213] = ParseModulePath("GuitarModule"), -- Guitar Module
	[236215724] = ParseModulePath("SwapGear"), -- Swap Gear
	[206209239] = ParseModulePath("GLib"), -- GLib
	[242620010] = ParseModulePath("ROrbTool"), -- O-Orb Tool
	[182191976] = ParseModulePath("HalloweenFireworkLibrary"), -- Halloween Firework Library
	[215583981] = ParseModulePath("DusekCarCarHandle"), -- Dusek Car CarHandle
	[215075770] = ParseModulePath("IglooOfSolitudeSnowHat"), -- Igloo Of Solitude Snow Hat
	[230095940] = ParseModulePath("GrannyCrossbowBolt"), -- Granny's Crossbow Bolt
	[277359293] = ParseModulePath("DinoPlushAssets"), -- Dino Plush Assets

	["NPCModule = require%(game%.ServerScriptService%.MainModule%)"] =
		`NPCModule = require({ParseModulePath("MultiPurposeModule")})`,
}

local LoadGearsCooldown = false

local function IsScript(Object)
	return Object:IsA("Script") or Object:IsA("LocalScript") or Object:IsA("ModuleScript")
end

local function CreateTestScript()
	local Success = pcall(function()
		local NewScript = Instance.new("Script")

		NewScript.Name = "GearUtility_TestScript"
		NewScript.Parent = JointsService
	end)

	return Success
end

local function EditTestScript(Script)
	return pcall(function()
		Script.Source = 'print("Works!")'
	end)
end

local function CheckScriptPermission()
	local Success = CreateTestScript()

	if not Success then
		print("Please allow plugin access to create scripts")

		repeat
			task.wait(1)
		until CreateTestScript()
	end

	Success = EditTestScript(JointsService:WaitForChild("GearUtility_TestScript"))

	if not Success then
		print("Please allow plugin access to edit scripts")

		repeat
			task.wait(1)
		until EditTestScript(JointsService:WaitForChild("GearUtility_TestScript"))
	end

	for _, Object in ipairs(JointsService:GetChildren()) do
		if Object:IsA("Script") and Object.Name == "GearUtility_TestScript" then
			Object:Destroy()
		end
	end
end

local function FixScript(Script)
	local NeedModules = false
	local Fixed = false

	if Script.Source:find("LoadLibrary") then
		NeedModules = true

		if not Script.Source:find(LoadLibraryFunction, 1, true) then
			local LoadLibraryCode = LoadLibraryFunction .. "\n"
			LoadLibraryCode ..= "\treturn " .. LoadLibraryRequire .. "\n"
			LoadLibraryCode ..= "end"

			Script.Source = LoadLibraryCode .. "\n\n" .. Script.Source
			Fixed = true
		end
	end

	for Key, Value in pairs(ReplaceList) do
		if Script.Source:find(Key) then
			NeedModules = true
			Script.Source = Script.Source:gsub(Key, Value)
			Fixed = true
		end
	end

	return NeedModules, Fixed, Script.ClassName
end

local function Fix(Object)
	CheckScriptPermission()

	local FixedScripts = {
		Script = 0,
		LocalScript = 0,
		ModuleScript = 0,
	}

	print(`Fixing {Object:GetFullName()}`)

	local Time = os.time()
	local TotalFixed = 0
	local CreateModule = false

	if IsScript(Object) then
		local NeedModules, Fixed, ScriptType = FixScript(Object)

		if NeedModules then
			CreateModule = true
		end

		if Fixed then
			FixedScripts[ScriptType] += 1
			TotalFixed += 1
		end
	end

	for _, Descendant in ipairs(Object:GetDescendants()) do
		if IsScript(Descendant) then
			local NeedModules, Fixed, ScriptType = FixScript(Descendant)

			if NeedModules then
				CreateModule = true
			end

			if Fixed then
				FixedScripts[ScriptType] += 1
				TotalFixed += 1
			end
		end
	end

	print(
		`Fixed {Object:GetFullName()} and its descendants`
			.. `\n{TreeTab}- Time taken: {os.time() - Time} seconds`
			.. `\n{TreeTab}- Scripts fixed: {FixedScripts.Script}`
			.. `\n{TreeTab}- LocalScripts fixed: {FixedScripts.LocalScript}`
			.. `\n{TreeTab}- ModuleScripts fixed: {FixedScripts.ModuleScript}`
			.. `\n{TreeTab}- Total fixed: {TotalFixed}`
	)

	ChangeHistoryService:SetWaypoint(`Fixed {Object:GetFullName()} and its descendants`)
	Selection:Set({ Object })

	return CreateModule
end

local function UpdateModulePackage()
	print("Updating gear module packages")

	local Time = os.time()
	local GearModulesFolder = ReplicatedStorage:FindFirstChild("GearModulesFolder")

	if GearModulesFolder then
		GearModulesFolder:Destroy()
	end

	GearModulesFolder = script.GearModulesFolder:Clone()
	GearModulesFolder.Parent = ReplicatedStorage

	Fix(GearModulesFolder)

	print(
		"Gear module packages updated"
			.. `\n{TreeTab}- Time taken: {os.time() - Time} seconds`
	)
end

local function LoadGears(FixGears)
	if LoadGearsCooldown then
		warn("Gears are still loading. Please wait before trying again.")
		return
	end

	LoadGearsCooldown = true

	print("Initializing")

	local FailedGearsFolder = ServerStorage:FindFirstChild("FailedGears")
	local GearsFolder = ServerStorage:FindFirstChild("GearsFolder")

	local FailedGearsFolderAlreadyExists = FailedGearsFolder ~= nil
	local GearsFolderAlreadyExists = GearsFolder ~= nil

	if not FailedGearsFolderAlreadyExists then
		FailedGearsFolder = Instance.new("Folder")
		FailedGearsFolder.Name = "FailedGears"
		FailedGearsFolder.Parent = ServerStorage

		ChangeHistoryService:SetWaypoint("Created FailedGears folder")
	end

	local FailedGears = FailedGearsFolder:GetChildren()
	local README = FailedGearsFolder:FindFirstChild("README")

	if not README then
		CheckScriptPermission()

		README = Instance.new("LocalScript")
		README.Name = "README"
		README.Disabled = true
		README.Source = READMESource
		README.Parent = FailedGearsFolder
	else
		README.Source = READMESource
	end

	if #FailedGears > 1 or (#FailedGears > 0 and not README) then
		print(
			`Found {#FailedGears} failed gears`
				.. "; the plugin will try to load them again"
		)
	end

	if not GearsFolderAlreadyExists then
		GearsFolder = Instance.new("Folder")
		GearsFolder.Name = "GearsFolder"
		GearsFolder.Parent = ServerStorage

		ChangeHistoryService:SetWaypoint("Created GearsFolder folder")
	end

	local function FormatGearEntryName(Gear)
		return `{Gear.id} {Gear.name}`
	end

	local function CreateGearEntry(Gear, TargetFolder)
		local GearEntryName = FormatGearEntryName(Gear)
		local TargetGearEntry = TargetFolder:FindFirstChild(GearEntryName)

		if TargetGearEntry then
			warn(
				`Skipping {GearEntryName}`
					.. ` because it already exists in {TargetFolder:GetFullName()}`
			)

			return TargetGearEntry
		end

		local NewGearEntry = Instance.new("Folder")
		NewGearEntry.Name = GearEntryName

		for _, Key in ipairs(GearAttributeKeys) do
			NewGearEntry:SetAttribute(`data_{Key}`, Gear[Key])
		end

		NewGearEntry.Parent = TargetFolder

		return NewGearEntry
	end

	print("Fetching gears list")

	local Gears = HttpService:JSONDecode(
		HttpService:GetAsync("https://raw.githubusercontent.com/iUnstable0/Roblox/main/Gears-Detailed.json")
	)

	print(
		"Got gears list"
			.. `\n{TreeTab}- Total gears: {#Gears.data}`
			.. `\n{TreeTab}- Last updated: {Gears["last-updated"]}`
	)

	-- Remove ROBLOX Tablet gears due to ban risk:
	-- https://devforum.roblox.com/t/open-source-gear-utility/1776131/34?u=iunstable0
	local FilteredGears = {}

	for _, Gear in ipairs(Gears.data) do
		if not string.find(string.lower(tostring(Gear.name)), "roblox tablet", 1, true) then
			table.insert(FilteredGears, Gear)
		end
	end

	print(
		`Excluded {#Gears.data - #FilteredGears} ROBLOX Tablet gears due to ban risk`
			.. `\n{TreeTab}https://devforum.roblox.com/t/open-source-gear-utility/1776131/34?u=iunstable0`
	)

	Gears.data = FilteredGears

	if GearsFolderAlreadyExists then
		print(
			"Existing GearsFolder found; only loading new gears"
				.. `\n{TreeTab}Tip: Delete GearsFolder and run Load Gears again`
				.. " to reload and fix every gear"
		)

		local ExistingGearIds = {}

		for _, Gear in ipairs(GearsFolder:GetChildren()) do
			table.insert(ExistingGearIds, Gear:GetAttribute("data_id"))
		end

		local MissingGears = {}

		for _, Gear in ipairs(Gears.data) do
			if not table.find(ExistingGearIds, Gear.id) then
				table.insert(MissingGears, Gear)
			end
		end

		print(`Excluded {#Gears.data - #MissingGears} gears because they are already loaded`)
		Gears.data = MissingGears
	end

	local TotalGears = #Gears.data
	local Completed = 0
	local SuccessfullyLoaded = 0
	local Failed = 0

	print(`Now loading {TotalGears} gears in {GearsFolder:GetFullName()}`)

	local Time = os.time()

	for _, Gear in ipairs(Gears.data) do
		task.spawn(function()
			local OperationSucceeded, Result, Detail = xpcall(function()
				local LoadSucceeded, InsertedModelOrError = pcall(function()
					return InsertService:LoadAsset(Gear.id)
				end)

				local FailedGearEntry = FailedGearsFolder:FindFirstChild(FormatGearEntryName(Gear))
				local GearPreviouslyFailed = FailedGearEntry ~= nil

				local IsGear = false

				if not LoadSucceeded then
					CreateGearEntry(Gear, FailedGearsFolder)
					return "load_failed", InsertedModelOrError
				end

				local InsertedModel = InsertedModelOrError
				local NewGearEntry = CreateGearEntry(Gear, GearsFolder)


				for _, Child in ipairs(InsertedModel:GetChildren()) do
					if Child:IsA("Tool") or Child:IsA("HopperBin") then
						IsGear = true

						Child.Parent = NewGearEntry
					end
				end

				if not IsGear then
					NewGearEntry.Parent = FailedGearsFolder

					for _, Child in ipairs(InsertedModel:GetChildren()) do
						Child.Parent = NewGearEntry
					end
				end

				InsertedModel:Destroy()

				if not IsGear then
					return "load_failed", `Asset is not a gear (didn't find either a "Tool" or a "HopperBin" in the model)`
				end

				if FailedGearEntry then
					FailedGearEntry:Destroy()
				end

				if GearPreviouslyFailed then
					return "retry_succeeded"
				end

				return "loaded"
			end, debug.traceback)

			Completed += 1
			local Progress = Completed

			if not OperationSucceeded then
				Failed += 1

				warn(
					`Unexpected error processing {Progress}/{TotalGears} gears`
						.. `\n{TreeTab}Gear name: {Gear.name}`
						.. `\n{TreeTab}Gear ID: {Gear.id}`
						.. `\n{TreeTab}Error: {Result}`
				)
			elseif Result == "load_failed" then
				Failed += 1

				warn(
					`Failed to load gear ({Progress}/{TotalGears} processed)`
						.. `\n{TreeTab}Gear name: {Gear.name}`
						.. `\n{TreeTab}Gear ID: {Gear.id}`
						.. `\n{TreeTab}Reason: {tostring(Detail)}`
				)
			else
				SuccessfullyLoaded += 1

				local Message = if Result == "retry_succeeded"
					then "Retried loading and succeeded"
					else "Loaded"

				print(
					`{Message} gear ({Progress}/{TotalGears} processed)`
						.. `\n{TreeTab}Gear name: {Gear.name}`
						.. `\n{TreeTab}Gear ID: {Gear.id}`
						.. `\n{TreeTab}Successfully loaded: {SuccessfullyLoaded}`
				)
			end
		end)
	end

	repeat
		task.wait()
	until Completed >= TotalGears

	print(
		`Finished processing {Completed} gears in {GearsFolder:GetFullName()}`
			.. `\n{TreeTab}Successfully loaded: {SuccessfullyLoaded}`
			.. `\n{TreeTab}Failed: {Failed}`
			.. `\n{TreeTab}Time taken: {os.time() - Time} seconds`
	)

	ChangeHistoryService:SetWaypoint(
		`Processed {Completed} gears in {GearsFolder:GetFullName()}`
			.. ` ({SuccessfullyLoaded} loaded, {Failed} failed)`
	)

	if FixGears and Fix(GearsFolder) then
		UpdateModulePackage()
	end

	LoadGearsCooldown = false
end

LoadGearsButton.ClickableWhenViewportHidden = true
LoadGearsWithoutFixingButton.ClickableWhenViewportHidden = true
FixObjectButton.ClickableWhenViewportHidden = true
UpdateModulePackagesButton.ClickableWhenViewportHidden = true

LoadGearsButton.Click:Connect(function()
	LoadGears(true)
end)

LoadGearsWithoutFixingButton.Click:Connect(function()
	LoadGears(false)
end)

FixObjectButton.Click:Connect(function()
	local SelectedObjects = Selection:Get()

	if #SelectedObjects == 0 then
		error("Please select an object to fix")
	elseif #SelectedObjects > 1 then
		error("Please select only one object")
	elseif SelectedObjects[1].Name == "GearUtilityPlugin" then
		error("You cannot fix this script")
	end

	if Fix(SelectedObjects[1]) then
		UpdateModulePackage()
	end
end)

UpdateModulePackagesButton.Click:Connect(function()
	UpdateModulePackage()
end)
