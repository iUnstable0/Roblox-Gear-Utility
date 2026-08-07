# Roblox Gear Utility

Loads classic ROBLOX gears into your game and fixes supported deprecated script dependencies on the fly.

## DANGER!! READ FIRST

If you decide to skip my plugin and load the gears manually from the JSON file, REMEMBER TO EXCLUDE "ROBLOX Tablet" gears (meaning DONT load them into your game) as they can get your game and account permanently deleted!

Example:

```luau
tostring(Gear.name):lower():find("roblox tablet", 1, true)
```

The plugin excludes these gears automatically.

[Read more about the ROBLOX Tablet risk](https://devforum.roblox.com/t/open-source-gear-utility/1776131/34?u=iunstable0).

## Gears

This repo contains ROBLOX gears with descriptions and other info in `Gears-Detailed.json`.

There are also other random things I scraped, like faces, hairs, and heads, but the main focus is gears.

## Plugin

The plugin needs permission to make HTTP requests and to create and edit scripts. Install the plugin from this link https://create.roblox.com/store/asset/9513198930 as it includes the packaged modules needed to fix the gears. Don't install the plugin from a local file because it wont work

The plugin can be used to load the gears into your game and fix supported scripts on the fly! (script manipulation)

> [!IMPORTANT]
> **Gear data is stored directly in attributes!** Every gear folder includes useful searchable data such as its ID, name, description, price, favorite count, sale status, quantity, and reseller information. You can use these attributes in Studio or read them from your own scripts without having to look through the JSON file again.

The plugin adds four toolbar buttons:

- **Load Gears** loads gears into `ServerStorage.GearsFolder` and fixes supported scripts.
- **Load Gears Without Fixing** loads the gears without modifying their scripts.
- **Fix Object** fixes supported scripts inside one selected object and its children.
- **Update Packages** updates the gear module packages in `ReplicatedStorage.GearModulesFolder`.

The plugin fixes supported scripts by:

- Replacing `require()` calls with auto preloaded modules (or manually load the modules with the **Update Packages** function).
- Fixing `LoadLibrary` usage.
- Applying other small script fixes.

Gears that fail to load are stored in `ServerStorage.FailedGears`. Run **Load Gears** again to retry them. If `ServerStorage.GearsFolder` already exists, the plugin only loads gears that are not already there. Delete the folder and run **Load Gears** again if you want to reload and fix every gear.

I might consider fixing Non-FE gears and client-sided InsertService gears in the future

## How to use

1. [Install the plugin](https://create.roblox.com/store/asset/9513198930) and open your game in Roblox Studio.
2. Open the **View** tab in Studio and enable **Output**. The plugin shows its progress, loaded and failed gear counts, and any errors there.
3. Click **Load Gears** to load and fix the gears, or **Load Gears Without Fixing** if you only want to load them.
4. Allow HTTP requests and script creation/editing if Studio asks for permission.
5. Be patient and keep an eye on the **Output** window. Loading thousands of gears takes time, so wait for the finished message before running the plugin again.

After loading, find the gears and their data attributes inside `ServerStorage.GearsFolder`. Gears that could not be loaded are placed inside `ServerStorage.FailedGears` so you can retry them later.

## Links

- [Plugin](https://create.roblox.com/store/asset/9513198930)
- [DevForum post](https://devforum.roblox.com/t/fixed-open-source-gear-utility/1776131)
