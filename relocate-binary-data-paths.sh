#!/usr/bin/env sh
set -eu

# Rewrite baked-in Cabal data-dir paths in copied Haskell libraries.
#
# Cabal's generated Paths_* modules may compile an absolute data-dir such as
# /root/.stack/snapshots/.../share/... into .a/.so/.hi files. The package
# registration files can be sed-rewritten, but compiled literals need a
# binary-safe in-place rewrite as well.
#
# Usage: relocate-binary-data-paths.sh REWRITE_MAP LIB_ROOT
#
# REWRITE_MAP is tab-separated: OLD_PATH<TAB>NEW_PATH, one rewrite per line.
# Replacement strings are kept exactly the same byte length. When NEW_PATH is
# shorter, it is padded with harmless directory components such as /, /., /./.
# This avoids changing binary file sizes and avoids NUL padding, which is safer
# for both C strings and length-prefixed literals.

export LC_ALL=C

if [ "$#" -ne 2 ]; then
  echo "usage: $0 REWRITE_MAP LIB_ROOT" >&2
  exit 2
fi

map_file=$1
lib_root=$2

if [ ! -s "$map_file" ] || [ ! -d "$lib_root" ]; then
  exit 0
fi

pad_to_old_length() {
  old=$1
  new=$2
  old_len=${#old}
  new_len=${#new}

  if [ "$new_len" -gt "$old_len" ]; then
    cat >&2 <<ERR
new path is longer than old path; cannot patch safely:
  old ($old_len): $old
  new ($new_len): $new
Use a shorter ROOT/PKG_DB export path or rebuild the package with a relocatable prefix.
ERR
    exit 1
  fi

  diff=$((old_len - new_len))
  suffix=
  while [ "$diff" -ge 2 ]; do
    suffix=${suffix}/.
    diff=$((diff - 2))
  done
  if [ "$diff" -eq 1 ]; then
    suffix=${suffix}/
  fi

  printf '%s' "${new}${suffix}"
}

tab=$(printf '\t')
rewrites_file=$(mktemp)
hits_file=$(mktemp)
log_file=$(mktemp)
trap 'rm -f "$rewrites_file" "$hits_file" "$log_file"' HUP INT TERM EXIT

# Precompute padded replacements. This fails before touching binaries if any
# replacement would be too long.
while IFS= read -r line || [ -n "${line:-}" ]; do
  [ -n "${line:-}" ] || continue
  case $line in
    *"$tab"*) ;;
    *) echo "bad rewrite-map line, expected OLD<TAB>NEW: $line" >&2; exit 2 ;;
  esac
  old=${line%%$tab*}
  new=${line#*$tab}
  padded=$(pad_to_old_length "$old" "$new")
  if [ "$old" != "$padded" ]; then
    printf '%s\t%s\n' "$old" "$padded" >> "$rewrites_file"
  fi
done < "$map_file"

if [ ! -s "$rewrites_file" ]; then
  exit 0
fi

# Deliberately avoid following symlinks so this cannot patch outside LIB_ROOT.
find "$lib_root" -type f -print | while IFS= read -r file; do
  file_hits=0

  while IFS= read -r line || [ -n "${line:-}" ]; do
    old=${line%%$tab*}
    padded=${line#*$tab}

    : > "$hits_file"
    if grep -aobF -- "$old" "$file" > "$hits_file"; then
      while IFS=: read -r offset _; do
        [ -n "$offset" ] || continue
        printf '%s' "$padded" | dd of="$file" bs=1 seek="$offset" conv=notrunc status=none
        file_hits=$((file_hits + 1))
      done < "$hits_file"
    fi
  done < "$rewrites_file"

  if [ "$file_hits" -gt 0 ]; then
    printf '%s\t%s\n' "$file_hits" "$file" >> "$log_file"
  fi
done

if [ -s "$log_file" ]; then
  patched_files=$(wc -l < "$log_file" | awk '{print $1}')
  patched_occurrences=$(awk '{sum += $1} END {print sum + 0}' "$log_file")
  echo "relocated ${patched_occurrences} baked-in data-dir path(s) in ${patched_files} file(s) under ${lib_root}"
fi

rm -f "$rewrites_file" "$hits_file" "$log_file"
trap - HUP INT TERM EXIT
