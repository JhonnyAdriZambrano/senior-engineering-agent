#!/usr/bin/env bash
# Empaqueta el agente en un ZIP DETERMINISTA (mismo contenido => mismo SHA-256).
#
# Uso:
#   bash scripts/build_zip.sh [dist|repo]      (por defecto: dist)
#
#   dist  -> senior-engineering-agent-<versión>.zip
#            Lo que un runtime consume: core/, modules/, adapters/,
#            project-knowledge-templates/, docs/, manifest.yaml,
#            capabilities.yaml, SPECIFICATION.md, README.md, CHANGELOG.md,
#            LICENSE. Whitelist explícita (más seguro que "todo menos X").
#   repo  -> senior-engineering-agent-<versión>-REPO-COMPLETO.zip
#            Repositorio completo para seguir desarrollando (incluye tests/ y
#            scripts/). Excluye .git, dist/, cachés, *.zip, .env real y
#            carpetas tests-log-*.
#
# En ambos casos la carpeta raíz DENTRO del ZIP se llama siempre
# `senior-engineering-agent/` (los @import de los adaptadores dependen de ese
# nombre). Salida: ${DIST_DIR:-<repo>/dist}.
#
# Determinismo: mtimes fijados a SOURCE_DATE_EPOCH (por defecto
# 2026-01-01T00:00:00Z), permisos normalizados, lista de archivos ordenada
# (LC_ALL=C) y `zip -X` (sin atributos extra). El script construye DOS veces y
# compara SHA-256; si difieren, falla. Además verifica que el ZIP coincide con
# el contenido preparado y que no hay secretos.

set -euo pipefail

MODE="${1:-dist}"
case "${MODE}" in dist|repo) ;; *) echo "Uso: $0 [dist|repo]" >&2; exit 2 ;; esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_NAME="senior-engineering-agent"
DIST_DIR="${DIST_DIR:-${REPO_ROOT}/dist}"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1767225600}"
export TZ=UTC LC_ALL=C

VERSION="$(python3 -c "import yaml; print(yaml.safe_load(open('${REPO_ROOT}/manifest.yaml'))['agent']['version'])")"
if [ "${MODE}" = "dist" ]; then
  ZIP_PATH="${DIST_DIR}/${PKG_NAME}-${VERSION}.zip"
else
  ZIP_PATH="${DIST_DIR}/${PKG_NAME}-${VERSION}-REPO-COMPLETO.zip"
fi

DIST_INCLUDE=(core modules adapters project-knowledge-templates docs
              manifest.yaml capabilities.yaml SPECIFICATION.md README.md
              CHANGELOG.md LICENSE)

command -v zip >/dev/null || { echo "Falta la utilidad 'zip'." >&2; exit 2; }
mkdir -p "${DIST_DIR}"

# stage_tree <dir-padre>: deja el árbol normalizado en <dir-padre>/senior-engineering-agent
stage_tree() {
  local parent="$1" stage="$1/${PKG_NAME}"
  mkdir -p "${stage}"
  if [ "${MODE}" = "dist" ]; then
    local p
    for p in "${DIST_INCLUDE[@]}"; do
      if [ -e "${REPO_ROOT}/${p}" ]; then
        mkdir -p "$(dirname "${stage}/${p}")"
        cp -R "${REPO_ROOT}/${p}" "${stage}/${p}"
      else
        echo "ADVERTENCIA: ${p} no existe en el repositorio, se omite." >&2
      fi
    done
  else
    ( cd "${REPO_ROOT}" && tar \
        --exclude='./.git' --exclude='./dist' --exclude='__pycache__' \
        --exclude='.pytest_cache' --exclude='./tests-log-*' --exclude='*.zip' \
        --exclude='./.env' --exclude='./sandbox' -cf - . ) | tar -C "${stage}" -xf -
  fi
  find "${stage}" -type d -exec chmod 755 {} +
  find "${stage}" -type f -exec chmod 644 {} +
  find "${stage}" -type f -name '*.sh' -exec chmod 755 {} +
  find "${stage}" -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +
}

# zip_tree <dir-padre> <zip-salida>
zip_tree() {
  rm -f "$2"
  ( cd "$1" && find "${PKG_NAME}" -type f | sort | zip -X -q "$2" -@ )
}

echo "== Empaquetando ${PKG_NAME} v${VERSION} (${MODE}) =="
WORK="$(mktemp -d)"; trap 'rm -rf "${WORK}"' EXIT
mkdir -p "${WORK}/a" "${WORK}/b"
stage_tree "${WORK}/a"

# Ausencia de secretos ANTES de empaquetar (complementa tests/test_agent.py).
if grep -rEl "AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{30,}|-----BEGIN (RSA |EC )?PRIVATE KEY-----" "${WORK}/a" >/dev/null 2>&1; then
  echo "ABORTADO: se detectó un posible secreto en el contenido a empaquetar." >&2
  exit 1
fi

zip_tree "${WORK}/a" "${ZIP_PATH}"

echo "== Verificando contenido (extraer y comparar) =="
mkdir -p "${WORK}/v"
unzip -q "${ZIP_PATH}" -d "${WORK}/v"
diff -r "${WORK}/v/${PKG_NAME}" "${WORK}/a/${PKG_NAME}" >/dev/null \
  || { echo "ERROR: el ZIP extraído difiere del contenido preparado." >&2; exit 1; }
echo "OK: el ZIP coincide exactamente con el contenido preparado."

echo "== Verificando determinismo (segunda construcción independiente) =="
stage_tree "${WORK}/b"
zip_tree "${WORK}/b" "${WORK}/second.zip"
H1="$(sha256sum "${ZIP_PATH}" | cut -d' ' -f1)"
H2="$(sha256sum "${WORK}/second.zip" | cut -d' ' -f1)"
if [ "${H1}" != "${H2}" ]; then
  echo "ERROR: dos construcciones consecutivas dieron SHA-256 distintos." >&2
  echo "  1) ${H1}" >&2; echo "  2) ${H2}" >&2
  exit 1
fi
echo "OK: construcción determinista."

echo "== Listo =="
echo "ZIP: ${ZIP_PATH}"
echo "Versión: ${VERSION}   Modo: ${MODE}   Archivos: $(unzip -Z1 "${ZIP_PATH}" | wc -l)"
echo "SHA-256: ${H1}"
