// Playwright Demo — "seeing" without seeing
// Install: npm install playwright
// Run: node playwright-demo.js
// Shows what Claude can now perceive about HTML pages through browser automation

const { chromium } = require('playwright');

(async () => {
  console.log('=== Launching browser ===\n');
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Load cave-runner.html
  const filePath = 'file:///C:/Users/16781/cave-runner.html';
  await page.goto(filePath, { waitUntil: 'networkidle' });
  console.log('Loaded: cave-runner.html\n');

  // ===== 1. PAGE STRUCTURE =====
  console.log('1. PAGE TITLE:', await page.title());

  const canvasInfo = await page.evaluate(() => {
    const canvas = document.querySelector('canvas');
    if (!canvas) return { found: false };
    return {
      found: true,
      width: canvas.width,
      height: canvas.height,
      id: canvas.id || '(no id)'
    };
  });
  console.log('   Canvas:', JSON.stringify(canvasInfo));

  // ===== 2. GAME STATE (read from JS variables) =====
  const gameState = await page.evaluate(() => {
    // cave-runner.js exposes these globals
    return {
      gravity: typeof gravity !== 'undefined' ? gravity : 'NOT FOUND',
      gameOver: typeof gameOver !== 'undefined' ? gameOver : 'NOT FOUND',
      score: typeof score !== 'undefined' ? score : 'NOT FOUND',
      playerX: typeof player !== 'undefined' ? player.x : 'NOT FOUND',
      playerY: typeof player !== 'undefined' ? player.y : 'NOT FOUND',
      playerVX: typeof player !== 'undefined' ? player.vx : 'NOT FOUND',
      playerVY: typeof player !== 'undefined' ? player.vy : 'NOT FOUND',
    };
  });
  console.log('\n2. GAME STATE AT LOAD:');
  Object.entries(gameState).forEach(([k, v]) => console.log(`   ${k} = ${v}`));

  // ===== 3. SCREENSHOT =====
  await page.screenshot({ path: 'C:/Users/16781/cave-runner-screenshot.png' });
  console.log('\n3. SCREENSHOT SAVED: C:/Users/16781/cave-runner-screenshot.png');

  // ===== 4. SIMULATE KEYPRESS & CHECK STATE =====
  console.log('\n4. SIMULATING KEY PRESS (Space = jump)...');
  await page.keyboard.press('Space');

  // Wait a few frames
  await page.waitForTimeout(100);

  const afterJump = await page.evaluate(() => ({
    playerY: typeof player !== 'undefined' ? player.y : 'N/A',
    playerVY: typeof player !== 'undefined' ? player.vy : 'N/A',
    isJumping: typeof player !== 'undefined' ? player.isJumping : 'N/A',
    onGround: typeof player !== 'undefined' ? player.onGround : 'N/A',
  }));
  Object.entries(afterJump).forEach(([k, v]) => console.log(`   ${k} = ${v}`));

  // ===== 5. CHECK DOM ELEMENTS EXIST =====
  console.log('\n5. VISIBLE ELEMENTS CHECK:');
  const visibility = await page.evaluate(() => {
    const results = [];
    const ids = ['gameCanvas', 'score', 'gameOver', 'startScreen', 'instructions'];
    ids.forEach(id => {
      const el = document.getElementById(id);
      results.push(`${id}: ${el ? 'EXISTS (visible=' + !el.hidden + ')' : 'MISSING'}`);
    });
    return results;
  });
  visibility.forEach(v => console.log('   ' + v));

  // ===== 6. API CALL DEMO: What happens when a problem is detected =====
  console.log('\n6. AUTO-FIX DEMO:');
  console.log('   If game crashes -> read error from console -> fix code -> reload -> verify');
  console.log('   This loop previously required YOU to test and report.');

  await browser.close();
  console.log('\n=== DONE ===');
  console.log('Screenshot saved. Load it to see what I "see" now.');
})();
