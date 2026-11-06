module AsciiStage

using Random

export fibonacci, lucas, arithmetic, geometric, triangular, primes, sequence,
       render_spiral, bars, Canvas, stamp!, line!, plot_function,
       Critter, wator_step, life_step, spiral_after, scene_frame, scene_names,
       collect_frames, frames_jsonl, parse_cli_int

function parse_cli_int(text::AbstractString, name::AbstractString; lo::Int=typemin(Int), hi::Int=typemax(Int))
    value = tryparse(Int, text)
    if value === nothing
        error("$name must be an integer, got $(repr(text))")
    elseif value < lo
        error("$name must be at least $lo, got $value")
    elseif value > hi
        error("$name must be at most $hi, got $value")
    end
    return value
end

function fibonacci(n::Int)
    seq = Vector{Int}(undef, n)
    a, b = 1, 1
    for i in 1:n
        seq[i] = a
        a, b = b, a + b
    end
    return seq
end

function lucas(n::Int)
    seq = Vector{Int}(undef, n)
    a, b = 2, 1
    for i in 1:n
        seq[i] = a
        a, b = b, a + b
    end
    return seq
end

function arithmetic(n::Int; start::Int=1, step::Int=1)
    return [start + (i - 1) * step for i in 1:n]
end

function geometric(n::Int; start::Int=1, ratio::Int=2)
    seq = Vector{Int}(undef, n)
    value = start
    for i in 1:n
        seq[i] = value
        value *= ratio
    end
    return seq
end

function triangular(n::Int)
    return [i * (i + 1) ÷ 2 for i in 1:n]
end

function primes(n::Int)
    found = Int[]
    candidate = 2
    while length(found) < n
        if all(candidate % d != 0 for d in 2:isqrt(candidate))
            push!(found, candidate)
        end
        candidate += 1
    end
    return found
end

function sequence(kind::AbstractString, n::Int; start::Int=1, step::Int=1, ratio::Int=2)
    kind == "fibonacci" && return fibonacci(n)
    kind == "lucas" && return lucas(n)
    kind == "arithmetic" && return arithmetic(n; start=start, step=step)
    kind == "geometric" && return geometric(n; start=start, ratio=ratio)
    kind == "triangular" && return triangular(n)
    kind == "primes" && return primes(n)
    error("unknown sequence: $kind")
end

const TURN = Dict{Tuple{Tuple{Int,Int},Tuple{Int,Int}},Char}(
    ((1, 0), (0, -1)) => '╯',  # right, then up
    ((0, -1), (-1, 0)) => '╮', # up, then left
    ((-1, 0), (0, 1)) => '╭',  # left, then down
    ((0, 1), (1, 0)) => '╰',   # down, then right
)

function render_spiral(lengths::Vector{Int})
    return spiral_after(lengths, sum(lengths))
end

function bars(lengths::Vector{Int})
    pad = length(string(maximum(lengths)))
    return join((lpad(n, pad) * " " * "█"^n for n in lengths), '\n')
end

mutable struct Canvas
    width::Int
    height::Int
    cells::Matrix{Char}
end

function Canvas(width::Int, height::Int)
    return Canvas(width, height, fill(' ', height, width))
end

function stamp!(canvas::Canvas, x::Int, y::Int, ch::Char)
    if 1 <= x <= canvas.width && 1 <= y <= canvas.height
        canvas.cells[y, x] = ch
    end
    return canvas
end

function Base.String(canvas::Canvas)
    return join((String(@view canvas.cells[y, :]) for y in 1:canvas.height), '\n')
end

function line!(canvas::Canvas, x0::Int, y0::Int, x1::Int, y1::Int, ch::Char='●')
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = x0 < x1 ? 1 : -1
    sy = y0 < y1 ? 1 : -1
    err = dx + dy
    x, y = x0, y0
    while true
        stamp!(canvas, x, y, ch)
        x == x1 && y == y1 && break
        e2 = 2err
        if e2 >= dy
            err += dy
            x += sx
        end
        if e2 <= dx
            err += dx
            y += sy
        end
    end
    return canvas
end

const PLOT_FUNCS = Dict{String,Function}(
    "sin" => sin,
    "cos" => cos,
    "zero" => _ -> 0.0,
    "x2" => x -> x^2,
    "abs" => abs,
)

function plot_function(name::AbstractString; width::Int=41, height::Int=15)
    f = get(PLOT_FUNCS, String(name)) do
        error("unknown plot: $name")
    end
    xmin, xmax = name == "sin" || name == "cos" ? (0.0, 2π) : (-1.0, 1.0)
    ymin, ymax = name == "x2" ? (0.0, 1.0) : (-1.0, 1.0)
    canvas = Canvas(width, height)
    span = ymax - ymin
    for x in 1:width
        t = xmin + (x - 1) / max(width - 1, 1) * (xmax - xmin)
        yv = clamp(Float64(f(t)), ymin, ymax)
        row = 1 + round(Int, (ymax - yv) / span * (height - 1))
        stamp!(canvas, x, row, '●')
    end
    return String(canvas)
end

include("stage.jl")

end
