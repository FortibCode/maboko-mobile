#!/usr/bin/env bash
# Construction de la version web de Maboko sur Vercel.
#
# Vercel ne connait pas Flutter : aucun de ses environnements ne le fournit.
# Le SDK est donc recupere ici, a chaque construction, puis la version web
# est compilee dans build/web — le dossier que vercel.json publie.
#
# La version est figee : une construction qui suit « stable » changerait de
# compilateur sans prevenir, et une mise en ligne qui marchait hier pourrait
# echouer demain sans qu'une seule ligne du projet ait bouge.

set -euo pipefail

VERSION_FLUTTER="${VERSION_FLUTTER:-3.44.1}"
DOSSIER_SDK="${DOSSIER_SDK:-$HOME/flutter}"

echo "==> Maboko : construction de la version web"

if [ ! -d "$DOSSIER_SDK" ]; then
    echo "==> recuperation de Flutter $VERSION_FLUTTER"
    git clone --depth 1 --branch "$VERSION_FLUTTER" \
        https://github.com/flutter/flutter.git "$DOSSIER_SDK"
fi

export PATH="$DOSSIER_SDK/bin:$PATH"

# Vercel construit dans un dossier appartenant a un autre utilisateur que
# celui qui a clone le SDK ; git refuse alors d'y travailler.
git config --global --add safe.directory "$DOSSIER_SDK" || true

flutter --version
flutter config --enable-web --no-analytics >/dev/null 2>&1 || true
flutter pub get

# L'adresse de l'API peut etre imposee depuis les variables du projet Vercel.
# Sans elle, la valeur compilee par defaut s'applique.
SUPPLEMENT=""
if [ -n "${API_BASE_URL:-}" ]; then
    echo "==> API visee : $API_BASE_URL"
    SUPPLEMENT="--dart-define=API_BASE_URL=$API_BASE_URL"
fi

if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then
    SUPPLEMENT="$SUPPLEMENT --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID"
fi

# shellcheck disable=SC2086
flutter build web --release $SUPPLEMENT

echo "==> construction terminee : build/web"
