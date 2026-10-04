#!/usr/bin/env bash
# 把星砚站点同步到 GitHub Pages 仓库目录。
#
# 用法:
#   bash scripts/gh-pages-build.sh                    # 根路径部署（仓库名 <用户名>.github.io）
#   bash scripts/gh-pages-build.sh xingyan-resume     # 子路径部署（仓库名 xingyan-resume）
#
# 为什么需要区分：
#   产物的资源引用是绝对路径（/assets/...）。放在 https://<用户>.github.io/ 根下没问题；
#   但放在 https://<用户>.github.io/<仓库名>/ 下就会 404，必须让构建 base 变成 /<仓库名>/。
#   构建 base 由环境变量 CLIENT_BASE_PATH 控制（见 @lark-apaas/coding-preset-vite-react）。
set -euo pipefail

# Git Bash(MSYS) 会把命令行里的 /xingyan-resume/ 当成 Windows 路径转换掉，
# 导致 CLIENT_BASE_PATH 变成 /C:/Users/.../xingyan-resume/ —— 必须关掉路径转换。
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

REPO_NAME="${1:-}"
SRC="F:/素材/AI摄影/星砚"
OUT="F:/WorkBuddy/星砚个人网站/github-pages"

if [ -z "$REPO_NAME" ]; then
  BASE_PATH="/"
  echo ">> 根路径部署（仓库名应为 <用户名>.github.io）"
else
  BASE_PATH="/${REPO_NAME}/"
  echo ">> 子路径部署：base = ${BASE_PATH}"
fi

cd "$SRC"

echo ">> [1/4] 清理旧产物"
rm -rf dist/client/assets

echo ">> [2/4] 构建前端（base=${BASE_PATH}）"
NODE_ENV=production CLIENT_BASE_PATH="$BASE_PATH" \
  npx vite build --config vite.preview.config.ts

echo ">> [3/4] 校验产物"
grep -q "cs-fab-logo" dist/client/assets/index-*.js && echo "   ✅ 挂件 logo 已打包"
if grep -q "27岁" dist/client/assets/index-*.js; then echo "   ❌ 产物含「27岁」"; exit 1; else echo "   ✅ 无「27岁」"; fi
if grep -q "\"${BASE_PATH}assets/" dist/client/client/index.html; then
  echo "   ✅ HTML 资源前缀为 ${BASE_PATH}"
else
  echo "   ❌ HTML 资源前缀不是 ${BASE_PATH}，构建 base 未生效"; exit 1
fi

echo ">> [4/4] 同步到 GitHub 仓库目录"
# 注意：不能 rm -rf 整个目录 —— 里面有 .git
mkdir -p "$OUT"
rm -rf "$OUT/assets"
find "$OUT" -maxdepth 1 -type f \( -name '*.html' -o -name 'favicon.svg' -o -name 'routes.json' \) -delete
cp -r dist/client/assets "$OUT/assets"
cp dist/client/favicon.svg "$OUT/favicon.svg"
cp dist/client/routes.json "$OUT/routes.json"

# HTML：替换平台 HBS 占位符；basename 必须与部署路径一致
PY="C:/Users/qiyul/.workbuddy-ai/binaries/python/versions/3.13.12/python.exe"
[ -x "$PY" ] || PY="$(command -v python3 || command -v python)"
"$PY" - "$SRC/dist/client/client/index.html" "$OUT/index.html" "$BASE_PATH" <<'PY'
import sys, re
src, dst, base = sys.argv[1], sys.argv[2], sys.argv[3]
html = open(src, encoding='utf-8').read()
app_name = '星砚 · 可交互个人简历'
mapping = {
    '{{{__platform__}}}': '{}',
    '{{{appAvatar}}}': '/favicon.svg',
    '{{appAvatar}}': '/favicon.svg',
    '{{appName}}': app_name,
    '{{appDescription}}': app_name,
    '{{appId}}': '', '{{userId}}': '', '{{tenantId}}': '',
    '{{userName}}': '', '{{csrfToken}}': '',
    '{{environment}}': 'online',
    '{{basename}}': base,
}
for k, v in mapping.items():
    html = html.replace(k, v)
# favicon 引用是写死的绝对路径 /favicon.svg，不含构建 base，需手动补上前缀
if base != '/':
    html = html.replace('href="/favicon.svg"', 'href="%sfavicon.svg"' % base)
left = set(re.findall(r'\{\{\{?[^}]*\}\}\}?', html))
if left:
    print('UNRESOLVED PLACEHOLDERS:', left, file=sys.stderr)
    sys.exit(1)
# 兜底检查：不应再有未加 base 前缀的 /assets/ 绝对引用
if base != '/':
    stray = set(re.findall(r'="/(?!%s)assets/[^"]*"' % re.escape(base.strip('/')), html))
    if stray:
        print('STRAY ABSOLUTE ASSET REFS:', stray, file=sys.stderr)
        sys.exit(1)
open(dst, 'w', encoding='utf-8').write(html)
print('   index.html 已生成（basename=%s）' % base)
PY

# GitHub Pages 没有 SPA 回退，/messages 这类前端路由会 404 —— 用 404.html 兜底
cp "$OUT/index.html" "$OUT/404.html"
# 关掉 Jekyll，避免下划线开头的文件被忽略
touch "$OUT/.nojekyll"

echo
echo "✅ 已同步到 $OUT"
ls -la "$OUT"
