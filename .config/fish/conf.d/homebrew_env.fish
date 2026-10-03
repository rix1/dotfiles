# Homebrew paths (useful for building native deps like pikepdf/qpdf).
# HOMEBREW_PREFIX comes from 00_path.fish.
set -q HOMEBREW_PREFIX; or return

set -x CPPFLAGS "-I$HOMEBREW_PREFIX/include"
set -x LDFLAGS "-L$HOMEBREW_PREFIX/lib"

# Keep any existing PKG_CONFIG_PATH and append brew pkgconfig
if set -q PKG_CONFIG_PATH
    set -x PKG_CONFIG_PATH "$PKG_CONFIG_PATH:$HOMEBREW_PREFIX/lib/pkgconfig"
else
    set -x PKG_CONFIG_PATH "$HOMEBREW_PREFIX/lib/pkgconfig"
end
