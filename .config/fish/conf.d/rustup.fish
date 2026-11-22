# rustup's own installer writes ~/.cargo/env.fish. Homebrew's rustup is
# keg-only and keeps its cargo/rustc proxies in its opt prefix instead.
if test -f $HOME/.cargo/env.fish
    source $HOME/.cargo/env.fish
else if test -d /opt/homebrew/opt/rustup/bin
    fish_add_path --path --prepend /opt/homebrew/opt/rustup/bin $HOME/.cargo/bin
end
