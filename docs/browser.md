# Browser Automation (Playwright + Chromium)

The devdocker ships with Playwright and a headless Chromium browser pre-installed.

## Quick Start

```bash
# Verify installation
playwright --version

# Run Playwright tests
npx playwright test

# Open a page headlessly
playwright open --headless https://example.com
```

## Using the Playwright API (Node.js)

```js
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('https://example.com');
  console.log(await page.title());
  await browser.close();
})();
```

## Using with Python

```bash
pip install playwright
# Browser binary is already installed at /opt/playwright-browsers — no need to run `playwright install`
# The PLAYWRIGHT_BROWSERS_PATH env var is set globally in the image
```

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto("https://example.com")
    print(page.title())
    browser.close()
```

## Connecting to a Host Browser (CDP)

Run a real Chrome/Chromium on your host machine with remote debugging enabled,
then connect to it from inside the container. This is useful when you need a
full GUI browser (extensions, profiles, etc.).

**On the host:**

```bash
google-chrome --remote-debugging-port=9222
# or: chromium --remote-debugging-port=9222
```

**From the container:**

```js
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.connectOverCDP('http://host.docker.internal:9222');
  const context = browser.contexts()[0];
  const page = context.pages()[0] || await context.newPage();
  console.log(await page.title());
  // Don't close — the host browser stays open
})();
```

`host.docker.internal` resolves to the host machine (configured via `extra_hosts` in docker-compose).

## Exposing the Container's Headless Browser to the Host

The container maps port `9223 → 9222`. You can run a headless Chromium server
inside the container and connect to it from the host:

**In the container:**

```bash
npx playwright open --headless --remote-debugging-port=9222 https://example.com
```

**From the host:**

Connect a browser or DevTools client to `http://localhost:9223`.
