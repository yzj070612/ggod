// Deep analysis: my penguin vs user's description
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('file:///C:/Users/16781/penguin-admin.html', { waitUntil: 'networkidle' });

  const report = await page.evaluate(() => {
    const svg = document.querySelector('svg');
    const getColor = (el) => el ? el.getAttribute('fill') : 'MISSING';
    const getPos = (el) => el ? `${el.getAttribute('cx')||el.getAttribute('x')},${el.getAttribute('cy')||el.getAttribute('y')}` : 'MISSING';
    const getSize = (el) => el ? `${el.getAttribute('rx')||el.getAttribute('width')}x${el.getAttribute('ry')||el.getAttribute('height')}` : 'MISSING';

    // Count elements by body part
    const parts = {
      body: { outer: getColor(svg.querySelector('#bodyOuter')), belly: getColor(svg.querySelector('#bodyBelly')), type: 'onesie (ellipse)' },
      head: { hood: getColor(svg.querySelector('#hoodOuter')), facePlate: getColor(svg.querySelector('#hoodFace')), hoodBand: !!svg.querySelector('#hoodBand') },
      face: {
        skin: getColor(svg.querySelector('#face')),
        eyesLeft: !!svg.querySelector('#eyeL'),
        eyesSize: getSize(svg.querySelector('#eyeL')),
        brows: !!svg.querySelector('#browL'),
        blush: !!svg.querySelector('#blushL'),
        mouth: !!svg.querySelector('#mouth'),
        closedEyes: !!svg.querySelector('#closedEyes'),
        bangs: !!svg.querySelector('#bangs'),
      },
      hair: {
        top: !!svg.querySelector('#hairTop'),
        sideLeft: !!svg.querySelector('#hairSideL'),
        sideRight: !!svg.querySelector('#hairSideR'),
      },
      hoodDecor: {
        eyes: !!svg.querySelector('#hoodEyeL'),
        beak: !!svg.querySelector('#hoodBeak'),
        band: !!svg.querySelector('#hoodBand'),
      },
      limbs: {
        armLeft: !!svg.querySelector('#armL'),
        armRight: !!svg.querySelector('#armR'),
        footLeft: !!svg.querySelector('#footL'),
        footRight: !!svg.querySelector('#footR'),
      },
      extras: {
        speechBubble: !!svg.querySelector('#speechBubble'),
        hearts: !!svg.querySelector('#heart1'),
        epaulets: !!svg.querySelector('#epauletL'),
      }
    };
    return parts;
  });

  console.log('=== MY PENGUIN SVG ===\n');
  console.log('BODY:');
  console.log(JSON.stringify(report.body, null, 2));
  console.log('\nHEAD/HOOD:');
  console.log(JSON.stringify(report.head, null, 2));
  console.log('\nFACE:');
  console.log(JSON.stringify(report.face, null, 2));
  console.log('\nHAIR:');
  console.log(JSON.stringify(report.hair, null, 2));
  console.log('\nHOOD DECORATION:');
  console.log(JSON.stringify(report.hoodDecor, null, 2));
  console.log('\nLIMBS:');
  console.log(JSON.stringify(report.limbs, null, 2));
  console.log('\nEXTRAS:');
  console.log(JSON.stringify(report.extras, null, 2));

  // Check proportion (2-head body)
  const proportion = await page.evaluate(() => {
    const body = document.querySelector('#bodyOuter');
    const head = document.querySelector('#hoodOuter');
    if (!body || !head) return 'cannot measure';
    const bodyH = parseFloat(body.getAttribute('ry')) * 2;
    const headH = parseFloat(head.getAttribute('ry')) * 2;
    const bodyW = parseFloat(body.getAttribute('rx')) * 2;
    const headW = parseFloat(head.getAttribute('rx')) * 2;
    return {
      headSize: `${headW}x${headH}`,
      bodySize: `${bodyW}x${bodyH}`,
      totalHeight: headH + bodyH,
      headToBodyRatio: (headH / (headH + bodyH)).toFixed(2),
      idealChibiRatio: 'head should be ~1/3 of total for 2-head chibi'
    };
  });
  console.log('\nPROPORTION:');
  console.log(JSON.stringify(proportion, null, 2));

  await page.screenshot({ path: 'C:/Users/16781/penguin-analysis.png', fullPage: true });
  console.log('\nScreenshot: C:/Users/16781/penguin-analysis.png');
  await browser.close();
})();
