function delta-toggle --description 'Toggle delta side-by-side'
  set -l cur (git config --global --get delta.side-by-side)
  if test "$cur" = "true"
    git config --global --unset delta.side-by-side 2>/dev/null; or true
  else
    git config --global delta.side-by-side true
  end
end
