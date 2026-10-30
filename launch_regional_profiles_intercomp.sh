#!/usr/bin/env bash
set -euo pipefail

# Run from any working directory; locate the repository via this script.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="/sortref/calval/CLASS4_scores"
DATE_RANGE="20240101_20241231"
OBSERVATION="profile_PR_PF"
VARIABLE="${1:-so}"  # so or thetao

if [[ "$VARIABLE" != "so" && "$VARIABLE" != "thetao" ]]; then
  echo "Usage: $0 [so|thetao]" >&2
  exit 2
fi

MODELS=(GLO12 glo4-ens50 glonet glow)
ARGS=()
for MODEL in "${MODELS[@]}"; do
  FILE="${INPUT_DIR}/results_regional_scores_class4_${OBSERVATION}_${MODEL}_${VARIABLE}_forecast_${DATE_RANGE}.nc"
  if [[ ! -f "$FILE" ]]; then
    echo "Missing input: $FILE" >&2
    exit 1
  fi
  ARGS+=(--model "${MODEL}=${FILE}")
done

mkdir -p "${REPO_ROOT}/imgs/regional_${VARIABLE}"
python "${REPO_ROOT}/tools/plot_regional_profiles_intercomp.py" \
  --variable "$VARIABLE" \
  --date-range "$DATE_RANGE" \
  "${ARGS[@]}" \
  --output "${REPO_ROOT}/imgs/regional_${VARIABLE}"
