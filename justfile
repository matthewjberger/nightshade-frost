set windows-shell := ["powershell.exe", "-NoProfile", "-Command"]

nightshade := "../nightshade"

# Which compiler builds the Frost. `frost` is the bootstrap compiler written in
# Rust, `frostc` is the one written in Frost. Both accept the same language:
#
#   just compiler=frostc game
compiler := "frost"

default:
    @just --list

# Regenerates nightshade.json, the command surface the bindings are built from.
# Windows redirection writes utf-16, so the bytes are written rather than piped.
[windows]
manifest:
    [IO.File]::WriteAllLines("$PWD/nightshade.json", (cargo run -q --manifest-path {{nightshade}}/crates/nightshade-api/Cargo.toml --example dump_manifest))

[unix]
manifest:
    cargo run -q --manifest-path {{nightshade}}/crates/nightshade-api/Cargo.toml --example dump_manifest > nightshade.json

# Builds the C ABI library and puts it beside the programs that link it.
[windows]
dll:
    cargo build --release --manifest-path {{nightshade}}/crates/nightshade-api/bindings/c/Cargo.toml
    cp {{nightshade}}/crates/nightshade-api/bindings/c/target/release/nightshade_c.dll .
    cp {{nightshade}}/crates/nightshade-api/bindings/c/target/release/nightshade_c.dll.lib .

[unix]
dll:
    cargo build --release --manifest-path {{nightshade}}/crates/nightshade-api/bindings/c/Cargo.toml
    cp {{nightshade}}/crates/nightshade-api/bindings/c/target/release/libnightshade_c.so .

# Regenerates nightshade.frost from nightshade.json.
[windows]
bindgen:
    {{compiler}} --link -o nightshade_bindgen.exe nightshade_bindgen.frost
    ./nightshade_bindgen.exe

[unix]
bindgen:
    {{compiler}} --link -o nightshade_bindgen nightshade_bindgen.frost
    ./nightshade_bindgen

# Builds and runs the game.
[windows]
game:
    {{compiler}} --link --libs nightshade_c.dll.lib -o game.exe game.frost
    ./game.exe

[unix]
game:
    {{compiler}} --link --libs=-lnightshade_c -o game game.frost
    ./game

# Everything, from a clean checkout to a running game.
all: manifest dll bindgen game
