const { test, expect } = require("@playwright/test");
const { login } = require("./helpers");

// ---------------------------------------------------------------------------
// Page loads
// ---------------------------------------------------------------------------

test("dashboard loads with agent cards", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("body")).toContainText("McRitchie Studio");
  // Seeded agents should appear
  await expect(page.locator("body")).toContainText("Alex");
  await expect(page.locator("body")).toContainText("Mack");
});

test("agents page loads", async ({ page }) => {
  await page.goto("/agents");
  await expect(page.locator("body")).toContainText("Alex");
  await expect(page.locator("body")).toContainText("Mack");
});

test("agent detail loads", async ({ page }) => {
  await page.goto("/agents/alex");
  await expect(page.locator("body")).toContainText("Alex");
  await expect(page.locator("body")).toContainText("orchestrator");
});

test("tasks page loads with stage badges", async ({ page }) => {
  await page.goto("/tasks");
  await expect(page.locator("body")).toContainText("Review agent protocol");
  await expect(page.locator("body")).toContainText("Scrape odds data");
  await expect(page.locator("body")).toContainText("Deploy v2.0");
});

test("task detail loads", async ({ page }) => {
  await page.goto("/tasks");
  // Click the first task link
  await page.click("text=Review agent protocol");
  await expect(page.locator("body")).toContainText("Review agent protocol");
  await expect(page.locator("body")).toContainText("Audit inter-agent messaging");
});

test("activities page loads", async ({ page }) => {
  await page.goto("/activities");
  await expect(page.locator("body")).toContainText("Assigned scrape task to Mack");
  await expect(page.locator("body")).toContainText("Started scraping odds data");
});

test("usages page loads", async ({ page }) => {
  await page.goto("/usages");
  // Page loads without error (may be empty table)
  await expect(page.locator("body")).toBeVisible();
});

// ---------------------------------------------------------------------------
// Authentication
// ---------------------------------------------------------------------------

test("login with valid credentials", async ({ page }) => {
  await login(page, "alex@test.com", "pass");
  // Username should appear in header
  await expect(page.locator("body")).toContainText("Alex Test");
});

test("invalid login stays on page with error", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[name="email"]', "alex@test.com");
  await page.fill('input[name="password"]', "wrong");
  await page.click('input[type="submit"], button[type="submit"]');
  // Should stay on login page with error flash
  await expect(page.locator("body")).toContainText(/invalid|incorrect/i);
});

// ---------------------------------------------------------------------------
// Navigation links
// ---------------------------------------------------------------------------

test("nav links work without errors", async ({ page }) => {
  await page.goto("/");

  // Dashboard
  await page.click("text=Dashboard");
  await expect(page).toHaveURL("/");

  // Agents
  await page.click("text=Agents");
  await expect(page).toHaveURL("/agents");

  // Tasks
  await page.click("text=Tasks");
  await expect(page).toHaveURL("/tasks");

  // Activity
  await page.click("text=Activity");
  await expect(page).toHaveURL("/activities");

  // Errors
  await page.click("text=Errors");
  await expect(page).toHaveURL("/error_logs");
});

// ---------------------------------------------------------------------------
// Theme toggle
// ---------------------------------------------------------------------------

test("theme toggle switches dark/light and updates localStorage", async ({ page }) => {
  await page.goto("/");

  // Wait for Alpine.js to initialize (loaded via defer)
  await page.waitForFunction(() => window.Alpine, null, { timeout: 10_000 });

  // Default is dark
  const html = page.locator("html");
  await expect(html).toHaveClass(/dark/);

  // Click theme toggle button
  await page.click('button[title="Toggle theme"]');

  // Should switch to light (dark class removed)
  await expect(html).not.toHaveClass(/dark/);

  // localStorage should be updated
  const theme = await page.evaluate(() => localStorage.getItem("theme"));
  expect(theme).toBe("light");
});

test("theme persists on reload", async ({ page }) => {
  await page.goto("/");
  await page.waitForFunction(() => window.Alpine, null, { timeout: 10_000 });

  // Toggle to light
  await page.click('button[title="Toggle theme"]');
  await expect(page.locator("html")).not.toHaveClass(/dark/);

  // Reload
  await page.reload();

  // Should still be light
  await expect(page.locator("html")).not.toHaveClass(/dark/);
  const theme = await page.evaluate(() => localStorage.getItem("theme"));
  expect(theme).toBe("light");
});

test("dark mode is default for fresh context", async ({ context }) => {
  // Fresh context has no localStorage
  const page = await context.newPage();
  await page.goto("/");
  await expect(page.locator("html")).toHaveClass(/dark/);
});
