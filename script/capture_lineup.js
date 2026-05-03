// Capture a team's lineup-graphic page as a sequence of lossless PNG frames
// (via Chrome DevTools Protocol screencast) plus a static PNG of the final state.
//
// Usage: node script/capture_lineup.js <team-slug> [base-url]
// Env:
//   HEADLESS=0       to watch the run
//   SIDE=full|offense|defense   default: full
//   REVEAL=<variant>            e.g. hike|spotlight|domino (offense), heat|blitz|crack (defense)
//   PACE=<ms>                   ms between reveals; default 1500 (offense), 1700 (defense)
//
// Output (file naming embeds side so X and TikTok captures don't collide):
//   tmp/lineup-graphics/<slug>[-<side>]-frames/frame_NNNNN.png   (sequence)
//   tmp/lineup-graphics/<slug>[-<side>].png                      (final static frame)

const { chromium } = require("@playwright/test");
const fs = require("fs");
const path = require("path");

const slug = process.argv[2];
if (!slug) {
  console.error("usage: node script/capture_lineup.js <team-slug> [base-url]");
  process.exit(1);
}
const baseUrl = process.argv[3] || "http://localhost:3000";

const SIDE   = (process.env.SIDE   || "full").toLowerCase();
const REVEAL = process.env.REVEAL || "";
const PACE   = parseInt(process.env.PACE || "0", 10);

if (!["full", "offense", "defense"].includes(SIDE)) {
  console.error(`invalid SIDE=${SIDE} (full|offense|defense)`);
  process.exit(1);
}

// Build URL with side/reveal/pace query params for non-default captures.
const qs = [];
if (SIDE !== "full") qs.push(`side=${encodeURIComponent(SIDE)}`);
if (REVEAL)          qs.push(`reveal=${encodeURIComponent(REVEAL)}`);
if (PACE > 0)        qs.push(`pace=${PACE}`);
const url = `${baseUrl}/teams/${slug}/lineup-graphic${qs.length ? "?" + qs.join("&") : ""}`;

// Side-aware output paths so the X capture (full) doesn't clobber TikTok captures.
const fileSuffix = SIDE === "full" ? "" : `-${SIDE}`;
const outDir = path.resolve(__dirname, "..", "tmp", "lineup-graphics");
const framesDir = path.join(outDir, `${slug}${fileSuffix}-frames`);
fs.mkdirSync(framesDir, { recursive: true });

// Wipe any stale frames from a previous capture so ffmpeg sees a clean sequence.
for (const f of fs.readdirSync(framesDir)) {
  if (f.startsWith("frame_") && f.endsWith(".png")) fs.unlinkSync(path.join(framesDir, f));
}

// TikTok partials render at 1080×1920 (9:16). The X full graphic is 1200×1500 (4:5).
const VIEWPORT = SIDE === "full"
  ? { width: 1200, height: 1500 }
  : { width: 1080, height: 1920 };

const REVEAL_TIMEOUT_MS = 45_000; // generous: 19s clips can take 18-20s of reveals
const HOLD_FINAL_MS     = SIDE === "full" ? 1500 : 500; // partials already hold 3.5s before signaling complete

(async () => {
  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "0" });
  const context = await browser.newContext({
    viewport: VIEWPORT,
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();

  console.log(`→ ${url}`);
  await page.goto(url, { waitUntil: "networkidle" });
  await page.waitForSelector("body[data-images-ready='true']", { timeout: 30_000 });

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

  await page.evaluate(() => window.startLineupReveals && window.startLineupReveals());

  await page.waitForSelector("body[data-reveal-complete='true']", { timeout: REVEAL_TIMEOUT_MS });
  console.log("reveal complete; holding final frame");
  await page.waitForTimeout(HOLD_FINAL_MS);

  await client.send("Page.stopScreencast");

  const elapsed = timestamps.length >= 2 ? timestamps.at(-1) - timestamps[0] : 1;
  const fps = ((timestamps.length - 1) / elapsed).toFixed(3);
  fs.writeFileSync(path.join(framesDir, "framerate.txt"), fps);
  console.log(`captured ${frameCount} frames @ ${fps} fps → ${framesDir}`);

  const pngPath = path.join(outDir, `${slug}${fileSuffix}.png`);
  await page.screenshot({ path: pngPath, fullPage: false });
  console.log(`png  → ${pngPath}`);

  await page.close();
  await context.close();
  await browser.close();
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
