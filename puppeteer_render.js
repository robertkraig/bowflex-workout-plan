// puppeteer_render.js
// Usage: node puppeteer_render.js input.html output.pdf
const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
    const [,, inputHtml, outputPdf] = process.argv;
    if (!inputHtml || !outputPdf) {
        console.error('Usage: node puppeteer_render.js input.html output.pdf');
        process.exit(1);
    }
    const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
    const page = await browser.newPage();
    const html = fs.readFileSync(inputHtml, 'utf8');
    await page.setContent(html, { waitUntil: 'networkidle0' });
    await page.pdf({ path: outputPdf, format: 'A4', printBackground: true });
    await browser.close();
})();
