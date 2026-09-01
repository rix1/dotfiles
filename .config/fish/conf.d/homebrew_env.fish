# Homebrew paths (useful for building native deps like pikepdf/qpdf)
set -l brew_prefix (brew --prefix)

set -x CPPFLAGS "-I$brew_prefix/include"
set -x LDFLAGS "-L$brew_prefix/lib"

# Keep any existing PKG_CONFIG_PATH and append brew pkgconfig
if set -q PKG_CONFIG_PATH
    set -x PKG_CONFIG_PATH "$PKG_CONFIG_PATH:$brew_prefix/lib/pkgconfig"
else
    set -x PKG_CONFIG_PATH "$brew_prefix/lib/pkgconfig"
end
