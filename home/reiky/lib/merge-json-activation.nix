{
  lib,
  pkgs,
}: {
  target,
  source,
}:
lib.hm.dag.entryAfter ["writeBoundary"] ''
  set -eu
  target=${lib.escapeShellArg target}
  source=${lib.escapeShellArg source}
  tmp="$target.tmp.$$"
  trap 'rm -f "$tmp"' EXIT
  mkdir -p "$(dirname "$target")"

  if [ -f "$target" ]; then
    ${pkgs.jq}/bin/jq -s '
      def deepmerge($left; $right):
        if ($left | type) == "object" and ($right | type) == "object" then
          reduce ($right | keys_unsorted[]) as $key
            ($left; .[$key] = deepmerge(.[$key]; $right[$key]))
        else
          $right
        end;
      deepmerge(.[0]; .[1])
    ' "$target" "$source" > "$tmp"
    chmod --reference="$target" "$tmp" 2>/dev/null || true
  else
    cp "$source" "$tmp"
  fi

  mv "$tmp" "$target"
  trap - EXIT
''
