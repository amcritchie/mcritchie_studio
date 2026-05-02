// Capture a team's lineup-graphic page as a sequence of lossless PNG frames
// (via Chrome DevTools Protocol screencast) plus a static PNG of the final state.
//
// Usage: node script/capture_lineup.js <team-slug> [base-url]
// Env: HEADLESS=0 to watch the run
//
// Output:
//   tmp/lineup-graphics/<slug>-frames/frame_NNNNN.png   (sequence)
//   tmp/lineup-graphics/<slug>.png                      (final static frame)
//
// Assemble to MP4 separately via ffmpeg (see Content::GenerateLineupAssets / rake).

const { chromium } = require("@playwright/test");
const fs = require("fs");
const path = require("path");

const slug = process.argv[2];
if (!slug) {
  console.error("usage: node script/capture_lineup.js <team-slug> [base-url]");
  process.exit(1);
}
const baseUrl = process.argv[3] || "http://localhost:3000";
const url = `${baseUrl}/teams/${slug}/lineup-graphic`;

const outDir = path.resolve(__dirname, "..", "tmp", "lineup-graphics");
const framesDir = path.join(outDir, `${slug}-frames`);
fs.mkdirSync(framesDir, { recursive: true });

// Wipe any stale frames from a previous capture so ffmpeg sees a clean sequence.
for (const f of fs.readdirSync(framesDir)) {
  if (f.startsWith("frame_") && f.endsWith(".png")) fs.unlinkSync(path.join(framesDir, f));
}

const VIEWPORT = { width: 1200, height: 1500 };
const REVEAL_TIMEOUT_MS = 30_000;
const HOLD_FINAL_MS = 1500;

(async () => {
  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "0" });
  const context = await browser.newContext({
    viewport: VIEWPORT,
    deviceScaleFactor: 2, // page renders at 2x; downsampled by ffmpeg → AA effect
  });
  const page = await context.newPage();

  console.log(`→ ${url}`);
  await page.goto(url, { waitUntil: "networkidle" });
  await page.waitForSelector("body[data-images-ready='true']", { timeout: 30_000 });

  // Start a CDP screencast BEFORE triggering the reveal cascade so the recorder
  // is already streaming frames when reveals begin (avoids losing the first ~1s).
  // Frames come as base64 PNG at 2x device pixels for ffmpeg lanczos downsample.
  const client = await context.newCDPSession(page);
  let frameCount = 0;
  const timestamps = [];
  client.on("Page.screencastFrame", async ({ data, sessionId, metadata }) => {
    timestamps.push(metadata.timestamp);
    const filename = path.join(framesDir, `frame_${String(frameCount++).padStart(5, "0")}.png`);
    fs.writeFileSync(filename, Buffer.from(data, "base64"));
    try {
      await client.send("Page.screencastFrameAck", { sessionId });
    } catch (_) {
      /* session may have already stopped */
    }
  });

  await client.send("Page.startScreencast", {
    format: "png",
    everyNthFrame: 1,
    maxWidth: VIEWPORT.width * 2,
    maxHeight: VIEWPORT.height * 2,
  });
  console.log("screencast started; settling 600ms before triggering reveals");
  await page.waitForTimeout(600);

  // Trigger the reveal cascade only now that screencast is live.
  await page.evaluate(() => window.startLineupReveals && window.startLineupReveals());

  await page.waitForSelector("body[data-reveal-complete='true']", { timeout: REVEAL_TIMEOUT_MS });
  console.log("reveal complete; holding final frame");
  await page.waitForTimeout(HOLD_FINAL_MS);

  await client.send("Page.stopScreencast");

  // Record actual capture rate so ffmpeg can play back at real-time speed.
  const elapsed = timestamps.length >= 2 ? timestamps.at(-1) - timestamps[0] : 1;
  const fps = ((timestamps.length - 1) / elapsed).toFixed(3);
  fs.writeFileSync(path.join(framesDir, "framerate.txt"), fps);
  console.log(`captured ${frameCount} frames @ ${fps} fps → ${framesDir}`);

  // Static PNG of the final fully-revealed state (also at 2x).
  const pngPath = path.join(outDir, `${slug}.png`);
  await page.screenshot({ path: pngPath, fullPage: false });
  console.log(`png  → ${pngPath}`);

  await page.close();
  await context.close();
  await browser.close();
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
