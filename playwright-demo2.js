// Quick demo: penguin-admin.html animation check
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('file:///C:/Users/16781/penguin-admin.html', { waitUntil: 'networkidle' });

  // Check SVG structure
  const svgInfo = await page.evaluate(() => {
    const svg = document.querySelector('svg');
    if (!svg) return { found: false };
    const elems = [];
    svg.querySelectorAll('[id]').forEach(el => elems.push(el.id));
    return {
      viewBox: svg.getAttribute('viewBox'),
      width: svg.getAttribute('width'),
      height: svg.getAttribute('height'),
      elementCount: svg.querySelectorAll('*').length,
      animatedElements: elems
    };
  });
  console.log('SVG:', JSON.stringify(svgInfo, null, 2));

  // Check anime.js animations running
  const anims = await page.evaluate(() => {
    if (typeof anime === 'undefined') return 'anime.js NOT loaded';
    return 'anime.js loaded OK';
  });
  console.log('Animation lib:', anims);

  // Check eyes/blush visibility
  const faceState = await page.evaluate(() => {
    const closedEyes = document.getElementById('closedEyes');
    const blink = document.getElementById('blinkL') || document.getElementById('eyeL');
    const mouth = document.getElementById('mouth');
    const body = document.getElementById('bodyGroup');
    return {
      closedEyesOpacity: closedEyes ? closedEyes.getAttribute('opacity') : 'N/A',
      eyesExist: !!blink,
      mouthPath: mouth ? mouth.getAttribute('d') : 'N/A',
      bodyTransform: body ? body.getAttribute('transform') : 'N/A',
    };
  });
  console.log('Face state:', JSON.stringify(faceState, null, 2));

  await page.screenshot({ path: 'C:/Users/16781/penguin-screenshot.png' });
  console.log('Screenshot: C:/Users/16781/penguin-screenshot.png');

  await browser.close();
  console.log('\n=== Pre-playwright: I could only GUESS what the penguin looked like ===');
  console.log('=== Post-playwright: I can read SVG elements, check animations, see coordinates ===');
})();
