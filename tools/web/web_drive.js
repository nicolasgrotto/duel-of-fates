const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const http = require('http');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const [scriptFile, widthArg, heightArg, outDir, urlArg] = process.argv.slice(2);
const width = Number(widthArg);
const height = Number(heightArg);
const url = urlArg || 'http://127.0.0.1:8000/index.html';
const port = 9300 + (width % 90);
const steps = JSON.parse(fs.readFileSync(scriptFile, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const profile = path.resolve(outDir, 'profile_' + width);

const KEYS = {
  Enter: ['Enter', 'Enter', 13], Escape: ['Escape', 'Escape', 27], ArrowUp: ['ArrowUp', 'ArrowUp', 38], ArrowDown: ['ArrowDown', 'ArrowDown', 40],
  ArrowLeft: ['ArrowLeft', 'ArrowLeft', 37], ArrowRight: ['ArrowRight', 'ArrowRight', 39], Space: [' ', 'Space', 32], Shift: ['Shift', 'ShiftLeft', 16],
};
for (const ch of 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') KEYS[ch] = [ch.toLowerCase(), 'Key' + ch, ch.charCodeAt(0)];
for (const d of '0123456789') KEYS[d] = [d, 'Digit' + d, d.charCodeAt(0)];

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
function getJson(address) {
  return new Promise((resolve, reject) => {
    http.get(address, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

(async () => {
  const chrome = spawn(CHROME, ['--headless=new', '--remote-debugging-port=' + port, '--user-data-dir=' + profile, '--window-size=' + width + ',' + height, '--hide-scrollbars', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required', 'about:blank'], { stdio: 'ignore' });
  let targets = null;
  for (let i = 0; i < 60 && !targets; i++) {
    await sleep(500);
    try { targets = await getJson('http://127.0.0.1:' + port + '/json'); } catch (e) { targets = null; }
  }
  const page = targets.find((t) => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((resolve) => (ws.onopen = resolve));
  let id = 0;
  const pending = new Map();
  const logs = [];
  ws.onmessage = (m) => {
    const msg = JSON.parse(m.data);
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg.result || msg.error); pending.delete(msg.id); }
    if (msg.method === 'Runtime.consoleAPICalled') logs.push(msg.params.type + ': ' + msg.params.args.map((a) => a.value ?? a.description ?? '').join(' '));
    if (msg.method === 'Runtime.exceptionThrown') logs.push('exception: ' + msg.params.exceptionDetails.text);
  };
  const send = (method, params = {}) => new Promise((resolve) => { const n = ++id; pending.set(n, resolve); ws.send(JSON.stringify({ id: n, method, params })); });
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url });

  async function keyDown(name) { const [key, code, vk] = KEYS[name]; await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); }
  async function keyUp(name) { const [key, code, vk] = KEYS[name]; await send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); }

  for (const step of steps) {
    if (step.wait) await sleep(step.wait);
    if (step.key) { for (let i = 0; i < (step.times || 1); i++) { await keyDown(step.key); await sleep(step.hold || 120); await keyUp(step.key); await sleep(step.gap || 220); } }
    if (step.down) await keyDown(step.down);
    if (step.up) await keyUp(step.up);
    if (step.mouseDown) await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: step.mouseDown[0], y: step.mouseDown[1], button: 'left', buttons: 1, clickCount: 1 });
    if (step.mouseUp) await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: step.mouseUp[0], y: step.mouseUp[1], button: 'left', buttons: 0, clickCount: 1 });
    if (step.move) await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: step.move[0], y: step.move[1], buttons: 0 });
    if (step.shot) {
      const shot = await send('Page.captureScreenshot', { format: 'png' });
      fs.writeFileSync(path.join(outDir, step.shot + '_' + width + '.png'), Buffer.from(shot.data, 'base64'));
      console.log('shot', step.shot);
    }
  }
  fs.writeFileSync(path.join(outDir, 'console_' + width + '.log'), logs.join('\n'));
  ws.close();
  chrome.kill();
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
