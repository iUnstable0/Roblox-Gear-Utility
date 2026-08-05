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
local LoadModulesButton = Toolbar:CreateButton(
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

local TreeTab = "\t\t\t\t\t"

local READMESource = [=[
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
	]]
]=]

local function ParseModulePath(ModuleName)
	return `game:GetService("ReplicatedStorage").GearModulesFolder.{ModuleName}`
end

-- 225918694 NOT FOR SALE
-- 187430232 GONE
-- 376407361 GONE

local ModuleList = {
	{ AssetId = 754568173, ModuleName = "SwordModule" }, -- Sword Module
	{ AssetId = 172349822, ModuleName = "GearModule" }, -- Gear Module
	{ AssetId = 191816425, ModuleName = "MultiPurposeModule" }, -- Multi Purpose Module
	{ AssetId = 201433042, ModuleName = "ScaleCharacterModule" }, -- Scale Character Module
	{ AssetId = 1075123174, ModuleName = "GearService" }, -- GearService
	{ AssetId = 199238756, ModuleName = "SkateboardModule" }, -- Skateboard Module
	{ AssetId = 836581200, ModuleName = "PackageMaker" }, -- Package Maker
	{ AssetId = 180464321, ModuleName = "HalloweenMonsterCustomesLibrary" }, -- Halloween Monster Costumes Library
	{ AssetId = 185791213, ModuleName = "GuitarModule" }, -- Guitar Module
	{ AssetId = 236215724, ModuleName = "SwapGear" }, -- Swap Gear
	{ AssetId = 206209239, ModuleName = "GLib" }, -- GLib
	{ AssetId = 242620010, ModuleName = "ROrbTool" }, -- O-Orb Tool
	{ AssetId = 182191976, ModuleName = "HalloweenFireworkLibrary" }, -- Halloween Firework Library
	{ AssetId = 215583981, ModuleName = "DusekCarCarHandle" }, -- Dusek Car CarHandle
	{ AssetId = 215075770, ModuleName = "IglooOfSolitudeSnowHat" }, -- Igloo Of Solitude Snow Hat
	{ AssetId = 230095940, ModuleName = "GrannyCrossbowBolt" }, -- Granny's Crossbow Bolt
	{ AssetId = 277359293, ModuleName = "DinoPlushAssets" }, -- Dino Plush Assets
}

local LoadGearsCooldown = false
local FixObjectCooldown = false
local LoadModulesCooldown = false

local function IsScript(Object)
	return Object:IsA("Script") or Object:IsA("LocalScript") or Object:IsA("ModuleScript")
end

-- gets the index of the end of a long bracket (long string/long comment [[...]] or [=*[...]=*] etc.)
local function GetLongBracketEndIndex(Source, StartIndex)
	local EqualSigns = Source:sub(StartIndex):match("^%[(=*)%[")

	if EqualSigns == nil then
		return nil
	end

	local ClosingDelimiter = `]{EqualSigns}]`

	local ContentIndex = StartIndex + #EqualSigns + 2

	local _, ClosingIndex = Source:find(ClosingDelimiter, ContentIndex, true)

	return ClosingIndex or #Source
end

-- same as the function above but for strings
local function GetStringEndIndex(Source, StartIndex, Quote)
	local ContentIndex = StartIndex + 1

	while ContentIndex <= #Source do
		local TargetChar = Source:sub(ContentIndex, ContentIndex)

		-- print(ContentIndex)

		if TargetChar == "\\" then
			-- print(`found escape, skip escape and next char ({TargetChar}{Source:sub(ContentIndex + 1, ContentIndex + 1)})`)
			ContentIndex += 2
		elseif TargetChar == Quote then
			-- print("found end quote!")
			return ContentIndex
		else
			-- print(`{TargetChar} not quote`)
			ContentIndex += 1
		end
	end

	-- print("didnt find quote, return length of source")
	return #Source
end

local function RewriteCodeSegments(Source, RewriteSegment)
	local Pieces = {}

	local SegmentStart = 1
	local Index = 1
	local TotalReplaced = 0

	local function AppendCodeSegment(EndIndex)
		if EndIndex < SegmentStart then
			return
		end

		local RewrittenSegment, Count = RewriteSegment(
			Source:sub(SegmentStart, EndIndex)
		)

		table.insert(Pieces, RewrittenSegment)

		TotalReplaced += Count or 0
	end

	while Index <= #Source do
		local Character = Source:sub(Index, Index)

		local ProtectedEnd = nil

		if Character == "\"" or Character == "'" or Character == "`" then
			ProtectedEnd = GetStringEndIndex(Source, Index, Character)
		elseif Character == "-" and Source:sub(Index, Index + 1) == "--" then
			ProtectedEnd = GetLongBracketEndIndex(Source, Index + 2)

			if ProtectedEnd == nil then
				local NewlineIndex = Source:find("\n", Index + 2, true)
				ProtectedEnd = if NewlineIndex then NewlineIndex - 1 else #Source
			end
		elseif Character == "[" then
			ProtectedEnd = GetLongBracketEndIndex(Source, Index)
		end

		if ProtectedEnd then
			AppendCodeSegment(Index - 1)

			table.insert(Pieces, Source:sub(Index, ProtectedEnd))

			Index = ProtectedEnd + 1
			SegmentStart = Index
		else
			Index += 1
		end
	end

	AppendCodeSegment(#Source)

	return table.concat(Pieces), TotalReplaced
end

local function ReplaceStandalonePattern(Segment, Pattern, Replacement)
	local TotalReplaced = 0
	local Count = 0

	Segment, Count = Segment:gsub(`^{Pattern}`, function()
		return Replacement
	end)

	TotalReplaced += Count

	Segment, Count = Segment:gsub(
		`([^%w_%.:]){Pattern}`,
		function(Prefix)
			return Prefix .. Replacement
		end
	)

	TotalReplaced += Count

	return Segment, TotalReplaced
end

local function FixModuleCalls(Source)
	return RewriteCodeSegments(Source, function(Segment)
		local TotalReplaced = 0

		for _, Module in ipairs(ModuleList) do
			local RequirePattern = `require%f[^%w_]%s*%(%s*{tostring(Module.AssetId)}%s*%)`

			local ReplacementCall = `require({ParseModulePath(Module.ModuleName)})`
			local Count

			Segment, Count = ReplaceStandalonePattern(
				Segment,
				RequirePattern,
				ReplacementCall
			)

			TotalReplaced += Count
		end

		local NPCModulePattern = "NPCModule%f[^%w_]%s*=%s*"
			.. "require%f[^%w_]%s*%(%s*"
			.. "game%.ServerScriptService%.MainModule%s*%)"

		local NPCModuleReplacement =
			`NPCModule = require({ParseModulePath("MultiPurposeModule")})`
		local NPCCount

		Segment, NPCCount = ReplaceStandalonePattern(
			Segment,
			NPCModulePattern,
			NPCModuleReplacement
		)

		TotalReplaced += NPCCount

		return Segment, TotalReplaced
	end)
end

local function FindPattern(Source, Pattern)
	local Found = false

	RewriteCodeSegments(Source, function(Segment)
		if not Found and Segment:find(Pattern) then
			Found = true
		end

		return Segment, 0
	end)

	return Found
end

local function FindStandalonePattern(Source, Pattern)
	if FindPattern(Source, `^{Pattern}`) then
		return true
	end

	return FindPattern(Source, `[^%w_%.:]{Pattern}`)
end

local function TryCreateTestScript()
	local NewScript = Instance.new("Script")
	local Success, Error = pcall(function()
		NewScript.Name = `GearUtility_TestScript_{HttpService:GenerateGUID(false)}`
		NewScript.Parent = JointsService
	end)

	if not Success then
		NewScript:Destroy()
		return false, Error
	end

	return true, NewScript
end

local function EditTestScript(TestScript)
	return pcall(function()
		TestScript.Source = 'print("Works!")'
	end)
end

local function CheckScriptPermission()
	local Success, Result = TryCreateTestScript()

	if not Success then
		print("Please allow plugin access to create scripts")

		repeat
			task.wait(1)
			Success, Result = TryCreateTestScript()
		until Success
	end

	local TestScript = Result
	Success = EditTestScript(TestScript)

	if not Success then
		print("Please allow plugin access to edit scripts")

		repeat
			task.wait(1)
			Success = EditTestScript(TestScript)
		until Success
	end

	TestScript:Destroy()
end

local function FixScript(Script)
	local OriginalSource = Script.Source

	local UpdatedSource, Count = FixModuleCalls(OriginalSource)

	local NeedModules = Count > 0 or FindPattern(
		UpdatedSource,
		"%.%s*GearModulesFolder%f[^%w_]"
	)

	local HasLoadLibrary = FindStandalonePattern(
		UpdatedSource,
		"LoadLibrary%f[^%w_]%s*%("
	)

	if HasLoadLibrary then
		local LoadLibraryFixed = FindPattern(
			UpdatedSource,
			"%f[%w_]function%f[^%w_]%s+LoadLibrary%f[^%w_]%s*%("
		)

		if not LoadLibraryFixed then
			LoadLibraryFixed = FindPattern(
				UpdatedSource,
				"%f[%w_]local%f[^%w_]%s+LoadLibrary%f[^%w_]"
			)
		end

		if not LoadLibraryFixed then
			LoadLibraryFixed = FindStandalonePattern(
				UpdatedSource,
				"LoadLibrary%f[^%w_]%s*="
			)
		end

		if not LoadLibraryFixed then
			NeedModules = true
			UpdatedSource = `local function LoadLibrary(Library)\n\treturn require({ParseModulePath("LoadLibrary")})(Library)\nend\n\n{UpdatedSource}`
		end
	end

	local Fixed = UpdatedSource ~= OriginalSource

	if Fixed then
		Script.Source = UpdatedSource
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

	print(`Fixing everything inside {Object:GetFullName()}`)

	local Time = os.time()
	local TotalFixed = 0
	local RequireModules = false

	if IsScript(Object) then
		local NeedModules, Fixed, ScriptType = FixScript(Object)

		if NeedModules then
			RequireModules = true
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
				RequireModules = true
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

	return RequireModules
end

local function LoadModulesOperation()
	print("Loading gear modules")

	local Time = os.time()
	local ExistingGearModulesFolder = ReplicatedStorage:FindFirstChild("GearModulesFolder")
	local GearModules = script:FindFirstChild("GearModulesFolder")

	if not GearModules then
		error("Gear modules package is missing from the plugin. Please create a bug report on GitHub", 0)
	end

	local NewGearModulesFolder = GearModules:Clone()
	NewGearModulesFolder.Name = `GearModulesFolder_{HttpService:GenerateGUID(false)}`

	local Success, Error = xpcall(function()
		NewGearModulesFolder.Parent = ReplicatedStorage
		Fix(NewGearModulesFolder)
	end, debug.traceback)

	if not Success then
		NewGearModulesFolder:Destroy()
		error(Error, 0)
	end

	NewGearModulesFolder.Name = "GearModulesFolder"

	if ExistingGearModulesFolder then
		ExistingGearModulesFolder:Destroy()
	end

	print(
		"Gear module packages loaded"
			.. `\n{TreeTab}- Time taken: {os.time() - Time} seconds`
	)
end

local function LoadModules()
	if LoadModulesCooldown then
		warn("Modules are still loading. Please wait before trying again.")
		return false
	end

	LoadModulesCooldown = true

	local Success, Error = xpcall(LoadModulesOperation, debug.traceback)

	LoadModulesCooldown = false

	if not Success then
		warn(`Failed to load gear module packages:\n{Error}`)
	end

	return Success
end

local function CountFailedGearEntries(FailedGearsFolder)
	local Count = 0

	for _, Child in ipairs(FailedGearsFolder:GetChildren()) do
		if Child:IsA("Folder") then
			Count += 1
		end
	end

	return Count
end

local function LoadGearsOperation(FixGears)
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

	ChangeHistoryService:SetWaypoint("Initialized README")

	local FailedGearCount = CountFailedGearEntries(FailedGearsFolder)

	if FailedGearCount > 0 then
		print(
			`Found {FailedGearCount} failed gears`
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

	local function FindGearEntry(TargetFolder, GearId)
		local TargetGearEntry

		for _, GearEntry in ipairs(TargetFolder:GetChildren()) do
			if GearEntry:IsA("Folder") and GearEntry:GetAttribute("data_id") == GearId then
				if TargetGearEntry then
					GearEntry:Destroy()
				else
					TargetGearEntry = GearEntry
				end
			end
		end

		return TargetGearEntry
	end

	local function UpdateGearEntry(GearEntry, Gear)
		GearEntry.Name = FormatGearEntryName(Gear)

		for _, Key in ipairs(GearAttributeKeys) do
			GearEntry:SetAttribute(`data_{Key}`, Gear[Key])
		end
	end

	local function CreateGearEntry(Gear, TargetFolder)
		local GearEntryName = FormatGearEntryName(Gear)
		local TargetGearEntry = FindGearEntry(TargetFolder, Gear.id)

		if TargetGearEntry then
			UpdateGearEntry(TargetGearEntry, Gear)

			warn(
				`Skipping {GearEntryName}`
					.. ` because it already exists in {TargetFolder:GetFullName()}`
			)

			return TargetGearEntry, false
		end

		local NewGearEntry = Instance.new("Folder")
		UpdateGearEntry(NewGearEntry, Gear)
		NewGearEntry.Parent = TargetFolder

		return NewGearEntry, true
	end

	print("Fetching gears list")

	local Gears = HttpService:JSONDecode(
		HttpService:GetAsync("https://raw.githubusercontent.com/iUnstable0/Roblox-Gear-Utility/main/Gears-Detailed.json")
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
		if not tostring(Gear.name):lower():find("roblox tablet", 1, true) then
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
			local ExistingGearId = Gear:GetAttribute("data_id")

			if ExistingGearId ~= nil then
				ExistingGearIds[ExistingGearId] = true
			end
		end

		local MissingGears = {}

		for _, Gear in ipairs(Gears.data) do
			if not ExistingGearIds[Gear.id] then
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
			local InsertedModel
			local NewGearEntry

			local NewGearEntryWasCreated = false

			local OperationSucceeded, Result, Detail = xpcall(function()
				local LoadSucceeded, InsertedModelOrError = pcall(function()
					return InsertService:LoadAsset(Gear.id)
				end)

				local FailedGearEntry = FindGearEntry(FailedGearsFolder, Gear.id)
				local GearPreviouslyFailed = FailedGearEntry ~= nil

				if not LoadSucceeded then
					NewGearEntry, NewGearEntryWasCreated = CreateGearEntry(Gear, FailedGearsFolder)

					return "load_failed", InsertedModelOrError
				end

				InsertedModel = InsertedModelOrError

				local IsGear = false

				for _, Child in ipairs(InsertedModel:GetChildren()) do
					if Child:IsA("Tool") or Child:IsA("HopperBin") then
						IsGear = true
						break
					end
				end

				if IsGear then
					NewGearEntry, NewGearEntryWasCreated = CreateGearEntry(Gear, GearsFolder)

					for _, Child in ipairs(InsertedModel:GetChildren()) do
						if Child:IsA("Tool") or Child:IsA("HopperBin") then
							Child.Parent = NewGearEntry
						end
					end
				elseif FailedGearEntry then
					NewGearEntry = FailedGearEntry
					UpdateGearEntry(NewGearEntry, Gear)

					for _, Child in ipairs(NewGearEntry:GetChildren()) do
						Child:Destroy()
					end
				else
					NewGearEntry, NewGearEntryWasCreated = CreateGearEntry(Gear, FailedGearsFolder)
				end

				if not IsGear then
					for _, Child in ipairs(InsertedModel:GetChildren()) do
						Child.Parent = NewGearEntry
					end
				end

				InsertedModel:Destroy()
				InsertedModel = nil

				if not IsGear then
					return "load_failed", `Asset is not a gear (didn't find either a "Tool" or a "HopperBin" in the model)`
				end

				if FailedGearEntry then
					FailedGearEntry:Destroy()
					-- print(`Removed previous failed gear entry for {Gear.name} ({Gear.id}) because it was successfully loaded`)
				end

				if GearPreviouslyFailed then
					return "retry_succeeded"
				end

				return "loaded"
			end, debug.traceback)

			Completed += 1
			local Progress = Completed

			if not OperationSucceeded then
				if InsertedModel then
					pcall(function()
						InsertedModel:Destroy()
					end)
				end

				if NewGearEntryWasCreated and NewGearEntry and NewGearEntry.Parent then
					pcall(function()
						NewGearEntry:Destroy()
					end)
				end
			end

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
		LoadModules()
	end
end

local function LoadGears(FixGears)
	if LoadGearsCooldown then
		warn("Gears are still loading. Please wait before trying again.")
		return
	end

	LoadGearsCooldown = true

	local Success, Error = xpcall(function()
		LoadGearsOperation(FixGears)
	end, debug.traceback)

	LoadGearsCooldown = false

	if not Success then
		warn(`Gear loading stopped because of an unexpected error:\n{Error}`)
	end
end

LoadGearsButton.ClickableWhenViewportHidden = true
LoadGearsWithoutFixingButton.ClickableWhenViewportHidden = true
FixObjectButton.ClickableWhenViewportHidden = true
LoadModulesButton.ClickableWhenViewportHidden = true

LoadGearsButton.Click:Connect(function()
	LoadGears(true)
end)

LoadGearsWithoutFixingButton.Click:Connect(function()
	LoadGears(false)
end)

FixObjectButton.Click:Connect(function()
	if FixObjectCooldown then
		warn("Fix operation is still running. Please wait before trying again.")
		return
	end

	FixObjectCooldown = true

	local Success, Error = xpcall(function()
		local SelectedObjects = Selection:Get()

		if #SelectedObjects == 0 then
			error("Please select an object to fix")
		elseif #SelectedObjects > 1 then
			error("Please select only one object")
		elseif SelectedObjects[1] == script then
			error("You cannot fix this script")
		end

		if Fix(SelectedObjects[1]) then
			LoadModules()
		end
	end, debug.traceback)

	FixObjectCooldown = false

	if not Success then
		warn(`Failed to run fix operation:\n{Error}`)
	end
end)

LoadModulesButton.Click:Connect(function()
	LoadModules()
end)
