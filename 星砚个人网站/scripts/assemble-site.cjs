/**
 * assemble-site.cjs —— 把星砚站点的构建产物整理成可直接发布的静态目录。
 *
 *   F:/素材/AI摄影/星砚/dist/client  →  F:/WorkBuddy/星砚个人网站/site
 *
 * 注意：只处理**根路径**构建（base = /）。产物里的资源引用是绝对路径 /assets/...，
 * 只有部署在站点根目录才成立。若要用子路径（GitHub Pages 的 <用户>.github.io/<仓库>/），
 * 请改用 scripts/gh-pages-build.sh —— 它会以 CLIENT_BASE_PATH 重新构建。
 *
 * 用法：node scripts/assemble-site.cjs
 */
const fs = require('node:fs');
const path = require('node:path');

const SRC = 'F:/素材/AI摄影/星砚/dist/client';
const OUT = 'F:/WorkBuddy/星砚个人网站/site';

const APP_NAME = '星砚 · 可交互个人简历';

function rmrf(p) {
  if (fs.existsSync(p)) fs.rmSync(p, { recursive: true, force: true });
}
function copyDir(from, to) {
  fs.mkdirSync(to, { recursive: true });
  for (const e of fs.readdirSync(from, { withFileTypes: true })) {
    const s = path.join(from, e.name);
    const d = path.join(to, e.name);
    if (e.isDirectory()) copyDir(s, d);
    else fs.copyFileSync(s, d);
  }
}

const srcHtml = path.join(SRC, 'client/index.html');
if (!fs.existsSync(srcHtml)) {
  console.error(`找不到构建产物：${srcHtml}\n请先构建（见 AGENTS.md「生产构建与发布」）。`);
  process.exit(1);
}

let html = fs.readFileSync(srcHtml, 'utf8');

// ---- 防误用：确认这是根路径构建 ----
// 若 dist/client 是上一次为 GitHub Pages 子路径构建留下的，资源前缀会带仓库名，
// 直接发布到平台会全部 404（白屏）。这里提前拦下。
const firstAsset = (html.match(/(?:src|href)="(\/assets\/[^"]*)"/) || [])[1];
if (!firstAsset) {
  const anyAbs = (html.match(/(?:src|href)="(\/[^"]*assets\/[^"]*)"/) || [])[1];
  if (anyAbs) {
    console.error(
      `构建产物的资源前缀是 ${anyAbs}，不是 /assets/。\n` +
        `说明 dist/client 是「子路径」构建的产物，不能用于平台根路径发布。\n` +
        `请重新以根路径构建：\n` +
        `  cd F:/素材/AI摄影/星砚 && NODE_ENV=production CLIENT_BASE_PATH=/ \\\n` +
        `    npx vite build --config vite.preview.config.ts\n` +
        `（或直接跑 bash scripts/gh-pages-build.sh，不带参数即为根路径）`,
    );
    process.exit(1);
  }
  console.error('构建产物中未找到 /assets/ 资源引用，疑似构建异常。');
  process.exit(1);
}

// ---- 整理产物 ----
rmrf(OUT);
fs.mkdirSync(OUT, { recursive: true });

copyDir(path.join(SRC, 'assets'), path.join(OUT, 'assets'));
fs.copyFileSync(path.join(SRC, 'favicon.svg'), path.join(OUT, 'favicon.svg'));
fs.copyFileSync(path.join(SRC, 'routes.json'), path.join(OUT, 'routes.json'));

const map = {
  '{{{__platform__}}}': '{}',
  '{{{appAvatar}}}': '/favicon.svg',
  '{{appAvatar}}': '/favicon.svg',
  '{{appName}}': APP_NAME,
  '{{appDescription}}': APP_NAME,
  '{{appId}}': '',
  '{{userId}}': '',
  '{{tenantId}}': '',
  '{{userName}}': '',
  '{{csrfToken}}': '',
  '{{environment}}': 'online',
  '{{basename}}': '/',
};
for (const [k, v] of Object.entries(map)) html = html.split(k).join(v);

const left = html.match(/\{\{\{?[^}]*\}\}\}?/g);
if (left) {
  console.error('UNRESOLVED PLACEHOLDERS:', [...new Set(left)]);
  process.exit(1);
}
fs.writeFileSync(path.join(OUT, 'index.html'), html);

console.log('site written to', OUT);
console.log('files:', fs.readdirSync(OUT).join(', '));
console.log('index.html bytes:', fs.statSync(path.join(OUT, 'index.html')).size);
