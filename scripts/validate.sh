#!/usr/bin/env bash
#
# Skillcraft - Validate skill structures and frontmatter
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"

SYSTEM_VALIDATOR="/home/ubuntu/.codex/skills/.system/skill-creator/scripts/quick_validate.py"

echo "=========================================="
echo "Skillcraft Validator"
echo "Scanning: ${SKILLS_DIR}"
echo "=========================================="

FAILED=0
CHECKED=0

for item in "${SKILLS_DIR}"/*; do
  if [[ -d "${item}" ]]; then
    skill_name="$(basename "${item}")"
    CHECKED=$((CHECKED + 1))
    echo -n "Checking skill [${skill_name}]... "

    # 1. Check SKILL.md existence
    if [[ ! -f "${item}/SKILL.md" ]]; then
      echo "FAIL: SKILL.md missing"
      FAILED=$((FAILED + 1))
      continue
    fi

    # 2. Run Python quick_validate if available
    if [[ -f "${SYSTEM_VALIDATOR}" ]]; then
      if ! output="$(python3 "${SYSTEM_VALIDATOR}" "${item}" 2>&1)"; then
        echo "FAIL: ${output}"
        FAILED=$((FAILED + 1))
        continue
      fi
    else
      # Fallback inline python validator
      if ! python3 -c "
import sys, re, yaml
from pathlib import Path
content = Path('${item}/SKILL.md').read_text()
m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if not m:
    sys.exit('Missing or invalid YAML frontmatter')
data = yaml.safe_load(m.group(1))
assert 'name' in data and 'description' in data, 'Missing name or description'
" 2>&1; then
        echo "FAIL: frontmatter validation failed"
        FAILED=$((FAILED + 1))
        continue
      fi
    fi

    # 3. Check agents/openai.yaml if present
    if [[ -f "${item}/agents/openai.yaml" ]]; then
      if ! python3 -c "import yaml, sys; yaml.safe_load(open('${item}/agents/openai.yaml'))" 2>/dev/null; then
        echo "FAIL: Invalid YAML in agents/openai.yaml"
        FAILED=$((FAILED + 1))
        continue
      fi
    fi

    echo "OK"
  fi
done

echo "=========================================="
echo "Checked ${CHECKED} skills. Failures: ${FAILED}"
if [[ ${FAILED} -ne 0 ]]; then
  exit 1
fi
echo "All skills passed validation!"
