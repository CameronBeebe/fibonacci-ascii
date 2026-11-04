#!/usr/bin/env julia
# A spiral whose successive legs are the next Fibonacci number long,
# plus a bar row of the same lengths.

const TURN = Dict{Tuple{Tuple{Int,Int},Tuple{Int,Int}},Char}(
    ((1, 0), (0, -1)) => '╯',  # right, then up
    ((0, -1), (-1, 0)) => '╮', # up, then left
    ((-1, 0), (0, 1)) => '╭',  # left, then down
    ((0, 1), (1, 0)) => '╰',   # down, then right
)

function fibonacci(n::Int)
    seq = Vector{Int}(undef, n)
    a, b = 1, 1
    for i in 1:n
        seq[i] = a
        a, b = b, a + b
    end
    return seq
end

function render_spiral(lengths::Vector{Int})
    dirs = [(1, 0), (0, -1), (-1, 0), (0, 1)]
    cells = Dict{Tuple{Int,Int},Char}()
    x = y = 0
    cells[(0, 0)] = '·'
    n = length(lengths)
    for (i, len) in enumerate(lengths)
        dx, dy = dirs[mod1(i, 4)]
        nxt = dirs[mod1(i + 1, 4)]
        for step in 1:len
            x += dx
            y += dy
            turning = step == len && i < n
            cells[(x, y)] = turning ? TURN[((dx, dy), nxt)] : (dx != 0 ? '─' : '│')
        end
    end
    cells[(x, y)] = '●'
    xs = (p[1] for p in keys(cells))
    ys = (p[2] for p in keys(cells))
    xmin, xmax = extrema(xs)
    ymin, ymax = extrema(ys)
    lines = String[]
    for yy in ymin:ymax
        line = IOBuffer()
        for xx in xmin:xmax
            print(line, get(cells, (xx, yy), ' '))
        end
        push!(lines, String(take!(line)))
    end
    return join(lines, '\n')
end

function bars(lengths::Vector{Int})
    pad = length(string(maximum(lengths)))
    return join((lpad(n, pad) * " " * "█"^n for n in lengths), '\n')
end

function main()
    nlegs = isempty(ARGS) ? 8 : parse(Int, ARGS[1])
    1 <= nlegs <= 12 || error("choose between 1 and 12 legs")
    lengths = fibonacci(nlegs)
    ratio = nlegs >= 2 ? lengths[end] / lengths[end - 1] : 1.0
    println("Fibonacci spiral")
    println("legs: ", join(string.(lengths), ", "))
    println("φ ≈ ", round(ratio; digits = 6), "   (golden ratio ≈ 1.618034)")
    println()
    println(render_spiral(lengths))
    println()
    println("growth")
    println(bars(lengths))
end

main()
