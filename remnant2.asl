// Remnant 2 Autosplitter 0.0.2
// Adapted from the Remnant 1 autosplitter.

// == Version States ==
state("Remnant2-Win64-Shipping", "unified") {}

startup
{
	settings.Add("wait_for_first_load", false, "Wait for first load");
	settings.Add("warn_unsupported_version", true, "Show a warning when starting a version of the game that isn't supported by the autosplitter.");
}

init
{
	vars.isLoading = settings["wait_for_first_load"];
	vars.loadCount = 0;
	vars.wasPlaying = !vars.isLoading;
	version = "unified";

	// Find the pointer to the "isPlaying" var.
	int offset = 0x7000000;
	int len =    0x0ffffff;
	var data = memory.ReadBytes(modules.First().BaseAddress+offset, len);
	string hits = "";
	// I don't know what this pattern means or why it works, I just looked for patterns in the hex viewer across some versions and found this.
	byte[] pattern = new byte[] {1, 0, 0, 0, 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
	int hit = 0;

	for (int o = 0; o < len; o += 0x10) {
		bool match = true;
		for (int i = 0; i < pattern.Length; i++) {
			if (data[o + i] != pattern[i]) {
				match = false;
				break;
			}
		}
		if (match) {
			hit = o;
		}
	}

	if (hit > 0) {
		vars.isPlaying = new DeepPointer(modules.First().BaseAddress + offset + hit + 0x10, 0, 0x170);
	} else {
		print("[Remnant 2 ASL]: Unable to find pointer to isPlaying var");
		if (settings["warn_unsupported_version"]) {
			MessageBox.Show("Unable to find pointer to attach to remnant 2. Is the game running?\n Contact the developers for help!", "Remnant ASL", MessageBoxButtons.OK, MessageBoxIcon.Error);
		}
		return;
	}
}

onStart {
	vars.loadCount = 0;
	vars.isLoading = settings["wait_for_first_load"];
}

update {
	bool isPlaying = false;
	try {
		isPlaying = vars.isPlaying != null && game != null && vars.isPlaying.Deref<int>(game) == 1;
	} catch (Exception e) {}
	vars.isLoading = !isPlaying;
	if (!vars.wasPlaying && isPlaying) {
		vars.loadCount++;
		print("Flipped");
	}
	vars.wasPlaying = isPlaying;
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