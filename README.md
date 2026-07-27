# nightshade-frost

Driving the [nightshade](https://github.com/matthewjberger/nightshade) engine
from [Frost](https://github.com/matthewjberger/frost). The bindings are
generated from the engine's own command manifest, so they cannot drift from what
the engine exposes.

```frost
import "nightshade.frost"

main :: fn() -> i64 {
    app := open()
    cube := spawn_cube(app, 0.0, 0.5, 0.0)
    set_color(app, cube, 0.2, 0.6, 1.0, 1.0)
    while (frame(app)) {
        rotate(app, cube, 0.0, 1.0, 0.0, delta_time(app))
    }
    close(app)
    0
}
```

## The chain

`dump_manifest`, an example in `nightshade-api`, prints the command manifest
beside the command and reply schemas. `nightshade_bindgen.frost` reads that json
and writes `nightshade.frost`: 349 commands, 9 types, one extern per command
spelling the C ABI and one wrapper under the name a program reads. The wrappers
link against `nightshade_c`, the engine's C ABI library.

The manifest gives each field a role rather than a C type, which is what the
generated wrappers are built on.

| the manifest says | the wrapper takes or answers with |
| --- | --- |
| `entity` | `Entity`, passed by value the way C passes it |
| `text` | a `str`, copied NUL-terminated for the call and freed after it |
| `bytes`, `floats`, `indices`, `refs`, `vec3_list` | one slice, split into a pointer and a length at the boundary |
| `strs` | a `[]str`, built into the `char **` C reads and torn down after |
| reply `opt_entity` | `-> (found: bool, entity: Entity)` rather than an out parameter |
| reply `entities`, `strings`, `bytes`, `text` | a `linear` resource, which the compiler refuses to let a program drop |

## Building

```
just manifest    # regenerate nightshade.json from the engine
just dll         # build the C ABI library and put it beside the programs
just bindgen     # regenerate nightshade.frost from nightshade.json
just game        # build and run the game
just all         # all four, in order
```

`compiler` picks which compiler builds the Frost. It defaults to `frost`, the
bootstrap compiler written in Rust. `just compiler=frostc all` builds the same
sources with the self-hosted one.

Requires `frost` on PATH, a Rust toolchain for the engine side, and a checkout
of nightshade beside this one. Point the `nightshade` variable at it if it lives
somewhere else.

## The game

`game.frost` is a first-person coin hunt. WASD walks, the mouse looks, space
jumps, shift sprints, and walking into a coin takes it. Escape quits.

## Layout

```
nightshade.json           the engine's command surface, as dumped
nightshade_bindgen.frost  reads that and writes the binding
nightshade.frost          the binding, generated
game.frost                the game
```
