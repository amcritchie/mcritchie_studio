// One-time TikTok login. Opens Chromium against the persistent profile dir
// at TIKTOK_PROFILE_DIR (default ~/.tiktok-bot-profile), navigates to the
// TikTok login page, and waits for you to sign in to @turfmonstershow. The
// session cookie is then stored in the profile dir and reused indefinitely
// by post_to_tiktok.js.
//
// Run once per account / per machine. Re-run only if TikTok signs you out.

const { chromium } = require("@playwright/test");
const fs   = require("fs");
const path = require("path");
const os   = require("os");

const profileDir = process.env.TIKTOK_PROFILE_DIR || path.join(os.homedir(), ".tiktok-bot-profile");
fs.mkdirSync(profileDir, { recursive: true });

(async () => {
  console.log(`profile dir: ${profileDir}`);
  console.log("Opening TikTok login. Sign in as @turfmonstershow, then close the window.\n");

  const context = await chromium.launchPersistentContext(profileDir, {
    headless: false,
    viewport: null,
    args: ["--start-maximized", "--disable-blink-features=AutomationControlled"],
  });

  const page = context.pages()[0] || await context.newPage();
  await page.goto("https://www.tiktok.com/login");

  // Wait for the user to close the window. Once closed, the persistent
  // context flushes cookies + storage to disk.
  await new Promise((resolve) => context.on("close", resolve));
  console.log("login session saved. you can now run script/post_to_tiktok.js");
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
