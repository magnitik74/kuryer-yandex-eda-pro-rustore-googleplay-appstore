#!/bin/bash
# Деплой docs/ + Flutter web demo в публичный репо kurier-pro-eda-pages
# Запускать из корня проекта: bash scripts/deploy-pages-local.sh
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_URL="https://github.com/magnitik74/kurier-pro-eda-pages.git"
TMP=$(mktemp -d)
PAGES_DIR="$TMP/pages"

echo "== Подготовка локального репо (без клона пустого репо) =="
rm -rf "$PAGES_DIR"
mkdir -p "$PAGES_DIR"
cd "$PAGES_DIR"

# Инициализируем локально
git init
git checkout -b main
git config user.name "magnitik74"
git config user.email "magnitik74@users.noreply.github.com"
git remote add origin "https://github.com/magnitik74/kurier-pro-eda-pages.git"

echo "== Копирую политику (index.html + md + demo.html) =="
mkdir -p privacy-policy
cp "$OLDPWD"/docs/index.html privacy-policy/index.html
cp "$OLDPWD"/docs/privacy_policy.md privacy-policy/privacy_policy.md
cp "$OLDPWD"/docs/demo.html demo.html

echo "== Копирую Flutter web demo, если собран =="
if [ -d "$OLDPWD/build/web" ]; then
  rm -rf demo
  mkdir -p demo
  cp -r "$OLDPWD"/build/web/* demo/
  echo "Демо обновлено."
else
  echo "build/web не найден — демо не обновляю (сначала: flutter build web --release)."
fi

git config user.name "magnitik74"
git config user.email "magnitik74@users.noreply.github.com"
git remote set-url origin "https://github.com/magnitik74/kurier-pro-eda-pages.git"
git add -A
if git diff --staged --quiet; then
  echo "Изменений нет."
else
  git commit -m "Deploy from kuryer-yandex-eda-pro: $(date -u +'%Y-%m-%d %H:%M UTC')"
  git push --force origin main
  echo "== Запушено в kurier-pro-eda-pages =="
fi
echo "Готово. URL: https://magnitik74.github.io/kurier-pro-eda-pages/privacy-policy/"