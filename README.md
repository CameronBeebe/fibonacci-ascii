# fibonacci-ascii

A small Julia stage for dynamic ASCII in the terminal: math, graphics, and agent-based models. Fibonacci is still the static default, and one of the scenes.

## Static spiral

```bash
julia fibonacci_art.jl
julia fibonacci_art.jl 6
```

The argument is the number of spiral legs, from 1 to 12. The default is 8.

## Play a scene

```bash
julia bin/asciiplay.jl list
julia bin/asciiplay.jl donut
julia bin/asciiplay.jl wator --frames 60 --fps 12 --seed 3
julia bin/asciiplay.jl life --width 60 --height 20
julia bin/asciiplay.jl fibonacci --frames 40 --legs 8
julia bin/asciiplay.jl wave
julia bin/asciiplay.jl plot
julia bin/asciiplay.jl bars
```

Scenes:

- `fibonacci` grows the original spiral, one step per frame
- `bars` grows a bar chart of a sequence
- `plot` and `wave` draw moving curves
- `donut` is a shaded spinning torus
- `wator` is a fish-and-shark agent model
- `life` is Conway's Game of Life, including a glider

On a terminal, playback uses the alternate screen and restores the cursor on exit. Piped output just prints frames.

Named sequences, for bars and for code that `using`s the module: `fibonacci`, `lucas`, `arithmetic`, `geometric`, `triangular`, `primes`.

## Headless frames

This is the embed point for a host such as Hermes. It is plain data, not a terminal session:

```bash
julia bin/asciiplay.jl donut --jsonl --frames 3 --width 48 --height 18
```

Each line is one frame:

```text
{"i":1,"w":48,"h":18,"text":"..."}
```

`text` uses `\n` between rows. There are no clear-screen or cursor codes. A host can paint `text` into a panel and choose its own frame rate. Scene names are a fixed list; they are not evaluated as Julia.

## Tests

```bash
julia test/runtests.jl
```
