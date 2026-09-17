#!/usr/bin/env bash
#
# Skillcraft - Install or link skills to Codex skills directory
# Usage:
#   ./scripts/install.sh [--link] [--dest <path>] [skillname ...]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"

DEFAULT_DEST="${CODEX_HOME:-${HOME}/.codex}/skills"
DEST_DIR="${DEFAULT_DEST}"
MODE="copy"
SELECTED_SKILLS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--link)
      MODE="link"
      shift
      ;;
    -c|--copy)
      MODE="copy"
      shift
      ;;
    -d|--dest)
      DEST_DIR="$2"
      shift 2
      ;;
    -h|--help)
      cat << 'HELP'
Usage: ./scripts/install.sh [options] [skillname ...]

Options:
  -l, --link       Create symbolic links to ~/.codex/skills (ideal for active development)
  -c, --copy       Copy files to ~/.codex/skills (default)
  -d, --dest DIR   Target skills directory (default: $CODEX_HOME/skills or ~/.codex/skills)
  -h, --help       Show this help message

Examples:
  ./scripts/install.sh            # Copy all skills to ~/.codex/skills
  ./scripts/install.sh --link     # Symlink all skills to ~/.codex/skills
  ./scripts/install.sh --link ppt # Symlink only ppt
  ./scripts/install.sh --link code # Symlink only code
HELP
      exit 0
      ;;
    *)
      SELECTED_SKILLS+=("$1")
      shift
      ;;
  esac
done

mkdir -p "${DEST_DIR}"

declare -a TARGET_SKILLS=()

if [[ ${#SELECTED_SKILLS[@]} -eq 0 ]]; then
  for item in "${SKILLS_DIR}"/*; do
    if [[ -d "${item}" ]]; then
      TARGET_SKILLS+=("$(basename "${item}")")
    fi
  done
else
  for item in "${SELECTED_SKILLS[@]}"; do
    target_path="${SKILLS_DIR}/${item}"
    if [[ -d "${target_path}" ]]; then
      TARGET_SKILLS+=("${item}")
    else
      echo "[ERROR] Skill not found: ${item}" >&2
      exit 1
    fi
  done
fi

echo "=========================================="
echo "Skillcraft Installer"
echo "Mode:   ${MODE}"
echo "Source: ${SKILLS_DIR}"
echo "Dest:   ${DEST_DIR}"
echo "=========================================="

for skill in "${TARGET_SKILLS[@]}"; do
  src_path="${SKILLS_DIR}/${skill}"
  dest_path="${DEST_DIR}/${skill}"

  if [[ ! -d "${src_path}" ]]; then
    echo "[WARN] Skill directory does not exist: ${src_path}, skipping."
    continue
  fi

  if [[ "${MODE}" == "link" ]]; then
    rm -rf "${dest_path}"
    ln -sfn "${src_path}" "${dest_path}"
    echo "[OK] Linked: ${skill} -> ${dest_path}"
  else
    rm -rf "${dest_path}"
    mkdir -p "${dest_path}"
    rsync -a --exclude='.git' "${src_path}/" "${dest_path}/"
    echo "[OK] Copied: ${skill} -> ${dest_path}"
  fi
done

echo ""
echo "Installation complete! Restart Codex or open a new turn to load newly installed skills."
