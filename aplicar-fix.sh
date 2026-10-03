#!/usr/bin/env bash

set -Eeuo pipefail

PACOTE="com.movile.leiturinha"
ATIVIDADE="com.movile.leiturinha/.MainActivity"

erro() {
    printf 'Erro: %s\n' "$*" >&2
    exit 1
}

if (( EUID != 0 )); then
    printf 'Obtendo acesso administrativo para modificar a instalação no Waydroid...\n'
    exec sudo -i bash "$0" "$@"
fi

command -v waydroid >/dev/null 2>&1 || erro "o comando waydroid não foi encontrado."

if ! waydroid status 2>/dev/null | grep -q $'Container:\tRUNNING'; then
    erro "o contêiner do Waydroid não está em execução. Inicie-o e tente novamente."
fi

CAMINHO_BASE="$({ waydroid shell -- pm path "$PACOTE" || true; } \
    | tr -d '\r' \
    | sed -n 's#^package:\(.*\)/base\.apk$#\1#p' \
    | head -n 1)"

[[ -n "$CAMINHO_BASE" ]] || erro "o aplicativo $PACOTE não está instalado."

SPLIT_ARM64="$CAMINHO_BASE/split_config.arm64_v8a.apk"
DESTINO="$CAMINHO_BASE/lib/arm64"

waydroid shell -- test -f "$SPLIT_ARM64" \
    || erro "o split ARM64 não foi encontrado em $SPLIT_ARM64."

QUANTIDADE="$({ waydroid shell -- unzip -l "$SPLIT_ARM64" || true; } \
    | grep -cE 'lib/arm64-v8a/[^/]+\.so$' || true)"

(( QUANTIDADE > 0 )) || erro "o split ARM64 não contém bibliotecas .so."

printf 'Instalação detectada: %s\n' "$CAMINHO_BASE"
printf 'Extraindo %d bibliotecas ARM64...\n' "$QUANTIDADE"

waydroid shell -- mkdir -p "$DESTINO"
waydroid shell -- unzip -j -o "$SPLIT_ARM64" 'lib/arm64-v8a/*.so' -d "$DESTINO"

# O shell interno é necessário para expandir o curinga dentro do Android.
waydroid shell -- sh -c \
    "chown system:system '$DESTINO'/*.so && chmod 0755 '$DESTINO' '$DESTINO'/*.so"

# Em imagens sem SELinux, restorecon pode não existir ou não fazer nada.
waydroid shell -- restorecon -RF "$CAMINHO_BASE/lib" 2>/dev/null || true

waydroid shell -- test -s "$DESTINO/libreactnative.so" \
    || erro "libreactnative.so não foi extraída corretamente."

waydroid shell -- am force-stop "$PACOTE"

printf 'Iniciando o Leiturinha para validação...\n'
if ! waydroid shell -- am start -W -n "$ATIVIDADE"; then
    printf 'Aviso: o fix foi aplicado, mas a atividade não pôde ser iniciada automaticamente.\n' >&2
fi

printf '\nFix aplicado com sucesso.\n'
printf 'Se o aplicativo ainda estiver fechado, abra-o normalmente pelo Waydroid.\n'
