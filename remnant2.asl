// Remnant 2 Autosplitter 0.0.1
// Adapter from the Remnant 1 autosplitter.

// == Version States ==

// Use an empty state descriptor instead for whenever we find an unsupported version
state("Remnant-Win64-Shipping") {}

// Steam versions
state("Remnant2-Win64-Shipping", "STEAM-397429") {
	bool isPlaying : 0x07D6C788, 0x470, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-382873") {
	bool isPlaying : 0x07C25590, 0x158, 0x210, 0xB0, 0x1A1;
}

state("Remnant2-Win64-Shipping", "STEAM-396261") {
	bool isPlaying : 0x07D5A740, 0x0, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-400313") {
	bool isPlaying : 0x07D8F558, 0x470, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-402459") {
	bool isPlaying : 0x07D8F5F0, 0x0, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-408516") {
	bool isPlaying : 0x07F0EAF0, 0x0, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-410790") {
	bool isPlaying : 0x07F0FB70, 0x0, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-417127_UE") {
	bool isPlaying : 0x07F36D50, 0x0, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-419098_UE") {
	bool isPlaying : 0x07F37DD0, 0x0, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-420332_UE") {
	bool isPlaying : 0x07F37E50, 0x0, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-444163_UE") {
	bool isPlaying : 0x07B96EB0, 0x0, 0x170;
}

state("Remnant2-Win64-Shipping", "STEAM-446618_UE") {
	bool isPlaying : 0x07B96F30, 0x0, 0x170;
}
// =============================

startup {
	// NOTE: IF YOU'RE GOING TO ADD A NEW VERSION, PUT THE HASH IN THIS DICTIONARY!
	// You'll also want to add the steam version of the hash if you've got the access to it

	vars.hashToVersion = new Dictionary<string, string> {
		// == Steam ==
		{"446B0F47363EC9D7EEE64C78E8D74D2D", "402459"},
		{"72FAF81E831F7120D3B0E7A66A6947D1", "400313"},
		{"76197FF9D374E59E32BF6E5004D2DA89", "397429"},
		{"B128B471801EA627591095DBB8BFA362", "382873"},
		{"7D7D642AF6D9EC18E70FF2E38119E365", "396261"},
		{"3E7A7635A1B7AFE3AC17C1AF0209E42B", "408516"},
		{"31D20BA00F81BC1FA1AAD87A9DA158D2", "410790"},
		{"585EFE2CC65C71ADDC8AC3084DD58EAC", "417127_UE"},
		{"85A75AE0A371D5127F6DAACE20E67E2D", "419098_UE"},
		{"E0DB6CE3F050CC2E38D39AC0128D9089", "420332_UE"},
		{"2A3F51DCCCC13AC275B82DC58176ED23", "444163_UE"},
		{"B6416C378428CBF480E0A7B9BE686121", "446618_UE"},
	};
	settings.Add("wait_for_first_load", false, "Wait for first load");
	settings.Add("warn_unsupported_version", true, "Show a warning when starting a version of the game that isn't supported by the autosplitter.");
}

init
{
	vars.isLoading = settings["wait_for_first_load"];
	vars.loadCount = 0;
	vars.isLoading = true;
	vars.gameModule = modules.First();
	// Default Value is something like: `K:\RemnantFromTheAshes\Remnant\Binaries\Win64\Remnant-Win64-Shipping.exe`
	// Technically you can (easily) have an Epic install without the .egstore due to the way Epic launches their games but y'know *meh*
	vars.gameStorefront = Directory.Exists(vars.gameModule.FileName + "/../../../../.egstore") ? "EGS" : "STEAM";
	
	// Creating a hash of the file seems to be a relatively *ok* way of detecting the version.
	// For some reason getting the product version from the exe itself, doesn't work, and it just returns an empty string
	// You could fix this by creating a DLL Component instead of an ASL, which is alot of effort and I don't feel like doing that.
	using (var stream = new FileStream(vars.gameModule.FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, 16 * 1024 * 1024))
	{
	    byte[] checksum = System.Security.Cryptography.MD5.Create().ComputeHash(stream);
	    vars.gameHash = BitConverter.ToString(checksum).Replace("-", String.Empty);
	}

	if(!vars.hashToVersion.ContainsKey(vars.gameHash)) {
		print("[Remnant 2 ASL]: Unknown/Unsupported Game Hash: " + vars.gameHash.ToString());
		Clipboard.SetText(vars.gameHash.ToString());
		if (settings["warn_unsupported_version"]) {
			MessageBox.Show("Unknown Game Hash: \"" + vars.gameHash.ToString() + "\" \n Contact the developers for help!\nHash Copied to clipboard...", "Remnant ASL", MessageBoxButtons.OK, MessageBoxIcon.Error);
		}
		return;
	}

	version = (vars.gameStorefront + "-" + vars.hashToVersion[vars.gameHash]);
	print("[Remnant 2 ASL]: Game Storefront: " + vars.gameStorefront.ToString());
	print("[Remnant 2 ASL]: Game Hash: " + vars.gameHash.ToString());
	print("[Remnant 2 ASL]: ASL Version: " + version.ToString());
}

onStart {
	vars.loadCount = 0;
	vars.isLoading = settings["wait_for_first_load"];
}

update {
	vars.isLoading = !current.isPlaying;
	if (!old.isPlaying && current.isPlaying) {
		vars.loadCount++;
		print("Flipped");
	}
}

isLoading
{
	if (settings["wait_for_first_load"] && vars.loadCount == 0) {
		return true;
	}
	return vars.isLoading;
}

// Pause the IGT timer when the game closes
exit
{
	timer.IsGameTimePaused = true;
}