#!/usr/bin/env bash
# Linux Privilege Audit (SUID/SGID & Capabilities)
# Author: Matías Lagos (Mati)

set -eo pipefail

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "[!] Run as root (sudo)." >&2
    exit 1
  fi
}

ts() { date +"%Y-%m-%d_%H-%M-%S"; }

init_out() {
  local name="$*"
  [[ -z "$name" ]] && name="report_$(ts)"
  name="${name// /_}"

  OUT_DIR="./$name"
  mkdir -p -- "$OUT_DIR" || { echo "[!] No pude crear '$OUT_DIR'"; exit 1; }

  LOG_MD="$OUT_DIR/REPORT.md"
  CSV_SUID="$OUT_DIR/suid_files.csv"
  CSV_SGID="$OUT_DIR/sgid_files.csv"
  CSV_CAPS="$OUT_DIR/capabilities.csv"
  CSV_PATH="$OUT_DIR/path_risks.csv"

  # inicializar con cabeceras mínimas
  echo "path,owner,group,perm,sha256" >"$CSV_SUID"
  echo "path,owner,group,perm,sha256" >"$CSV_SGID"
  echo "path,capabilities" >"$CSV_CAPS"
  echo "issue,detail" >"$CSV_PATH"

  cat >"$LOG_MD" <<EOF
# Linux Privilege Audit Report
Time: $(date -Is)
Host: $(hostname) ($(uname -srmo))

## Summary
- SUID files: $(basename "$CSV_SUID")
- SGID files: $(basename "$CSV_SGID")
- File capabilities: $(basename "$CSV_CAPS")
- PATH risks: $(basename "$CSV_PATH")
EOF
}

hash_file() { [[ -f "$1" ]] && sha256sum "$1" 2>/dev/null | awk '{print $1}' || echo "NA"; }

scan_suid_sgid() {
  echo "[*] Scanning SUID..."
  find / -xdev -perm -4000 -type f 2>/dev/null | sort | while read -r f; do
    [[ -f "$f" ]] || continue
    PERM=$(stat -c "%A" "$f" 2>/dev/null || echo "?")
    OWN=$(stat -c "%U" "$f" 2>/dev/null || echo "?")
    GRP=$(stat -c "%G" "$f" 2>/dev/null || echo "?")
    SHA=$(hash_file "$f")
    printf "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" "$f" "$OWN" "$GRP" "$PERM" "$SHA" >>"$CSV_SUID"
  done

  echo "[*] Scanning SGID..."
  find / -xdev -perm -2000 -type f 2>/dev/null | sort | while read -r f; do
    [[ -f "$f" ]] || continue
    PERM=$(stat -c "%A" "$f" 2>/dev/null || echo "?")
    OWN=$(stat -c "%U" "$f" 2>/dev/null || echo "?")
    GRP=$(stat -c "%G" "$f" 2>/dev/null || echo "?")
    SHA=$(hash_file "$f")
    printf "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" "$f" "$OWN" "$GRP" "$PERM" "$SHA" >>"$CSV_SGID"
  done
}

scan_caps() {
  if command -v getcap >/dev/null 2>&1; then
    getcap -r / 2>/dev/null | sort | while read -r line; do
      f=${line%% = *}
      caps=${line#*= }
      [[ -f "$f" ]] || continue
      printf "\"%s\",\"%s\"\n" "$f" "$caps" >>"$CSV_CAPS"
    done
  else
    echo "[!] getcap not installed (apt install -y libcap2-bin)." >&2
  fi
}

check_path_risks() {
  IFS=':' read -ra PARTS <<< "${PATH:-}"
  [[ ":$PATH:" == *":.:"* ]] && printf "\"%s\",\"%s\"\n" "PATH includes dot (.)" "$PATH" >>"$CSV_PATH"
  for d in "${PARTS[@]}"; do
    [[ -d "$d" ]] || continue
    PERM=$(stat -c "%A" "$d" 2>/dev/null || echo "?")
    if [[ "$PERM" == *"w"* ]]; then
      if stat -c "%a" "$d" 2>/dev/null | grep -qE '.{2}[2367]$'; then
        printf "\"%s\",\"%s (%s)\"\n" "World-writable PATH dir" "$d" "$PERM" >>"$CSV_PATH"
      fi
    fi
  done
}

main() {
  require_root
  init_out "$@"
  echo "[i] Output dir: $OUT_DIR"
  scan_suid_sgid
  scan_caps
  check_path_risks
  echo "[+] Done. Report in: $OUT_DIR"
}

main "$@"
