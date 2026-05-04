// Spawn TikTok Studio with a video uploaded and caption typed in, then leave
// the browser open for the human to review + click "Post". This is the agent
// half of the creator-copilot flow — the agent handles the tedious upload +
// typing, the human keeps final control over the publish click.
//
// Usage:  node script/post_to_tiktok.js <mp4-path> "<caption>" "[sound vibe]"
// Env:    TIKTOK_PROFILE_DIR (default ~/.tiktok-bot-profile)
//         HEADLESS=1 to run hidden (NOT recommended — defeats human-in-the-loop)
//
// One-time setup: `node script/tiktok_login.js` (or `npm run tiktok:login`).
// That launches Chromium against the persistent profile dir so you can sign in
// to @turfmonstershow once. The session cookie sticks across runs forever.
//
// Failure modes:
//   - Not logged in → exits with code 2, prints "RUN_LOGIN_FIRST".
//   - File input not found → screenshots tmp/tiktok-failure-<ts>.png + exits 1.
//   - User closes browser → exits 0 (clean cancel).

const { chromium } = require("@playwright/test");
const fs   = require("fs");
const path = require("path");
const os   = require("os");

const mp4Path   = process.argv[2];
const caption   = process.argv[3] || "";
const soundVibe = process.argv[4] || "";

if (!mp4Path) {
  console.error("usage: node script/post_to_tiktok.js <mp4-path> <caption> [sound-vibe]");
  process.exit(1);
}
if (!fs.existsSync(mp4Path)) {
  console.error("MP4 not found:", mp4Path);
  process.exit(1);
}

const profileDir = process.env.TIKTOK_PROFILE_DIR || path.join(os.homedir(), ".tiktok-bot-profile");
fs.mkdirSync(profileDir, { recursive: true });

const STUDIO_URL = "https://www.tiktok.com/tiktokstudio/upload?from=upload";
const HEADLESS   = process.env.HEADLESS === "1";

function tsName() { return new Date().toISOString().replace(/[:.]/g, "-"); }

(async () => {
  console.log(`profile: ${profileDir}`);
  console.log(`video:   ${mp4Path}`);
  console.log(`caption: ${caption.slice(0, 80)}${caption.length > 80 ? "…" : ""}`);
  if (soundVibe) console.log(`vibe:    ${soundVibe}`);

  const context = await chromium.launchPersistentContext(profileDir, {
    headless: HEADLESS,
    viewport: null,
    args: ["--start-maximized", "--disable-blink-features=AutomationControlled"],
  });

  const page = context.pages()[0] || await context.newPage();
  await page.goto(STUDIO_URL, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(2500);

  const url = page.url();
  if (url.includes("/login") || url.includes("/foryou")) {
    console.error("RUN_LOGIN_FIRST — Not logged in. Run `node script/tiktok_login.js` first.");
    await context.close();
    process.exit(2);
  }

  // Step 1: file input. TikTok Studio renders a hidden <input type="file">
  // bound to the drag-drop region. setInputFiles fills it directly without
  // simulating a real drag (works for Studio's upload widget).
  let fileInput;
  try {
    fileInput = await page.waitForSelector("input[type=\"file\"]", { timeout: 30_000, state: "attached" });
  } catch (e) {
    const failPath = path.resolve(__dirname, "..", "tmp", `tiktok-failure-${tsName()}.png`);
    await page.screenshot({ path: failPath, fullPage: true }).catch(() => {});
    console.error(`No file input found within 30s. Saved screenshot: ${failPath}`);
    process.exit(1);
  }
  await fileInput.setInputFiles(mp4Path);
  console.log("file uploaded; waiting for caption editor");

  // Step 2: caption editor appears once TikTok finishes processing the upload.
  // It's a contenteditable div, not a textarea. Selector is generic on
  // purpose — TikTok ships React class hashes so anything more specific
  // breaks weekly.
  let editor;
  try {
    editor = await page.waitForSelector("[contenteditable=\"true\"]", { timeout: 120_000 });
  } catch (e) {
    const failPath = path.resolve(__dirname, "..", "tmp", `tiktok-failure-${tsName()}.png`);
    await page.screenshot({ path: failPath, fullPage: true }).catch(() => {});
    console.error(`Caption editor never appeared (upload may have failed). Screenshot: ${failPath}`);
    process.exit(1);
  }

  if (caption) {
    // The editor may already contain the auto-generated TikTok title from the
    // filename — clear it first by selecting all + deleting.
    await editor.click();
    await page.keyboard.press("Meta+A");
    await page.keyboard.press("Delete");
    await page.keyboard.insertText(caption);
    console.log("caption typed");
  }

  // Step 3: print the sound vibe so the user knows what to search when they
  // click "Add Sound". Auto-clicking into TikTok's sound picker is fragile
  // and a high ban-risk vector — leaving it manual.
  if (soundVibe) {
    console.log(`\n  🎵 SOUND VIBE TO SEARCH: ${soundVibe}\n`);
  }

  console.log("\nREADY — review and click Post in the open browser window.");
  console.log("(Browser stays open. Close it when you're done.)\n");

  // Keep the script alive until the user closes the browser. context.close()
  // fires on window close.
  await new Promise((resolve) => context.on("close", resolve));
  console.log("browser closed; exiting");
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
