# Dynamic scenes, agent models, and the headless frame protocol.
# JSONL frames are plain text on purpose: a host can paint them later
# without parsing terminal control codes.

struct Critter
    kind::Symbol
    age::Int
    energy::Int
end

function neighbor_cells(h, w, y, x)
    cells = Tuple{Int,Int}[]
    for (dy, dx) in ((-1, 0), (1, 0), (0, -1), (0, 1))
        yy, xx = y + dy, x + dx
        if 1 <= yy <= h && 1 <= xx <= w
            push!(cells, (yy, xx))
        end
    end
    return cells
end

function wator_step(grid::Matrix{Critter}; fish_breed::Int=3, shark_breed::Int=8, init_energy::Int=3, rng::Random.AbstractRNG=Random.MersenneTwister(0))
    h, w = size(grid)
    sharks = [(y, x) for y in 1:h for x in 1:w if grid[y, x].kind == :shark]
    fishes = [(y, x) for y in 1:h for x in 1:w if grid[y, x].kind == :fish]
    shuffle!(rng, sharks)
    shuffle!(rng, fishes)
    next = fill(Critter(:empty, 0, 0), h, w)
    for (y, x) in sharks
        _move_shark!(next, grid, y, x; shark_breed, init_energy, rng)
    end
    for (y, x) in fishes
        next[y, x].kind == :shark && continue
        _move_fish!(next, grid, y, x; fish_breed, rng)
    end
    return next
end

function _free_destinations(next, grid, nbrs, old)
    dests = [(yy, xx) for (yy, xx) in nbrs if grid[yy, xx].kind == old && next[yy, xx].kind == :empty]
    return dests
end

function _move_shark!(next, grid, y, x; shark_breed, init_energy, rng)
    crit = grid[y, x]
    nbrs = neighbor_cells(size(grid)..., y, x)
    shuffle!(rng, nbrs)
    meals = _free_destinations(next, grid, nbrs, :fish)
    if !isempty(meals)
        dest = meals[1]
        age = crit.age + 1
        next[dest...] = Critter(:shark, age >= shark_breed ? 0 : age, init_energy)
        if age >= shark_breed && next[y, x].kind == :empty
            next[y, x] = Critter(:shark, 0, init_energy)
        end
        return
    end
    energy = crit.energy - 1
    energy < 0 && return
    dests = _free_destinations(next, grid, nbrs, :empty)
    dest = isempty(dests) ? (y, x) : dests[1]
    next[dest[1], dest[2]].kind == :empty || return
    age = crit.age + 1
    breeding = dest != (y, x) && age >= shark_breed
    next[dest...] = Critter(:shark, breeding ? 0 : age, energy)
    if breeding && next[y, x].kind == :empty
        next[y, x] = Critter(:shark, 0, init_energy)
    end
end

function _move_fish!(next, grid, y, x; fish_breed, rng)
    crit = grid[y, x]
    nbrs = neighbor_cells(size(grid)..., y, x)
    shuffle!(rng, nbrs)
    dests = _free_destinations(next, grid, nbrs, :empty)
    dest = isempty(dests) ? (y, x) : dests[1]
    next[dest[1], dest[2]].kind == :empty || return
    age = crit.age + 1
    breeding = dest != (y, x) && age >= fish_breed
    next[dest...] = Critter(:fish, breeding ? 0 : age, 0)
    if breeding && next[y, x].kind == :empty
        next[y, x] = Critter(:fish, 0, 0)
    end
end

function life_step(grid::AbstractMatrix{Bool})
    h, w = size(grid)
    out = falses(h, w)
    for y in 1:h, x in 1:w
        neighbors = 0
        for dy in -1:1, dx in -1:1
            dy == 0 && dx == 0 && continue
            yy, xx = y + dy, x + dx
            if 1 <= yy <= h && 1 <= xx <= w && grid[yy, xx]
                neighbors += 1
            end
        end
        out[y, x] = grid[y, x] ? (neighbors == 2 || neighbors == 3) : neighbors == 3
    end
    return out
end

function raster(cells::Dict{Tuple{Int,Int},Char})
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

function spiral_after(lengths::Vector{Int}, steps::Int)
    dirs = [(1, 0), (0, -1), (-1, 0), (0, 1)]
    cells = Dict{Tuple{Int,Int},Char}()
    x = y = 0
    cells[(0, 0)] = '·'
    n = length(lengths)
    drawn = 0
    for (i, len) in enumerate(lengths)
        dx, dy = dirs[mod1(i, 4)]
        nxt = dirs[mod1(i + 1, 4)]
        for step in 1:len
            drawn >= steps && break
            x += dx
            y += dy
            drawn += 1
            turning = step == len && i < n
            cells[(x, y)] = turning ? TURN[((dx, dy), nxt)] : (dx != 0 ? '─' : '│')
        end
        drawn >= steps && break
    end
    drawn > 0 && (cells[(x, y)] = '●')
    return raster(cells)
end

function wave_frame(tick::Int; width::Int, height::Int)
    canvas = Canvas(width, height)
    for x in 1:width
        y = 1 + round(Int, (height - 1) * (0.5 + 0.42 * sin((x + 2tick) / 3)))
        stamp!(canvas, x, clamp(y, 1, height), '●')
        y2 = 1 + round(Int, (height - 1) * (0.5 + 0.22 * sin((x - tick) / 2.2)))
        stamp!(canvas, x, clamp(y2, 1, height), '·')
    end
    return String(canvas)
end

function plot_scene(tick::Int; width::Int, height::Int)
    canvas = Canvas(width, height)
    for x in 1:width
        t = (x - 1) / max(width - 1, 1) * 2π
        yv = sin(t + tick / 3)
        row = 1 + round(Int, (1 - yv) / 2 * (height - 1))
        stamp!(canvas, x, clamp(row, 1, height), '●')
    end
    return String(canvas)
end

function bars_scene(tick::Int; width::Int, height::Int, seed::Int)
    kind = seed % 2 == 0 ? "primes" : "fibonacci"
    lengths = sequence(kind, min(height, 8))
    canvas = Canvas(width, height)
    for (i, len) in enumerate(lengths)
        i > height && break
        shown = min(len, max(tick, 0), max(width - 4, 0))
        for (k, ch) in enumerate(lpad(string(lengths[i]), 3))
            k <= width && stamp!(canvas, k, i, ch)
        end
        for x in 1:shown
            stamp!(canvas, 4 + x, i, '█')
        end
    end
    return String(canvas)
end

function blit_art!(canvas::Canvas, art::AbstractString)
    lines = split(art, '\n', keepempty=true)
    isempty(lines) && return canvas
    ah = length(lines)
    aw = maximum(length, lines)
    y0 = max(1, (canvas.height - ah) ÷ 2 + 1)
    x0 = max(1, (canvas.width - aw) ÷ 2 + 1)
    for (dy, line) in enumerate(lines)
        for (dx, ch) in enumerate(line)
            ch == ' ' && continue
            stamp!(canvas, x0 + dx - 1, y0 + dy - 1, ch)
        end
    end
    return canvas
end

function fibonacci_scene(tick::Int; width::Int, height::Int, legs::Int)
    lengths = fibonacci(legs)
    art = spiral_after(lengths, max(tick, 0))
    canvas = Canvas(width, height)
    blit_art!(canvas, art)
    return String(canvas)
end

function wator_grid(width::Int, height::Int; seed::Int=1)
    rng = Random.MersenneTwister(seed)
    grid = fill(Critter(:empty, 0, 0), height, width)
    for y in 1:height, x in 1:width
        roll = rand(rng)
        if roll < 0.06
            grid[y, x] = Critter(:shark, 0, 3)
        elseif roll < 0.30
            grid[y, x] = Critter(:fish, rand(rng, 0:2), 0)
        end
    end
    return grid
end

function render_critters(grid::Matrix{Critter})
    h, w = size(grid)
    canvas = Canvas(w, h)
    glyph = Dict(:fish => '~', :shark => '▲', :empty => ' ')
    for y in 1:h, x in 1:w
        stamp!(canvas, x, y, glyph[grid[y, x].kind])
    end
    return String(canvas)
end

function wator_frame(tick::Int; width::Int, height::Int, seed::Int)
    grid = wator_grid(width, height; seed)
    rng = Random.MersenneTwister(seed + 17)
    for _ in 1:max(tick, 0)
        grid = wator_step(grid; rng)
    end
    return render_critters(grid)
end

function life_frame(tick::Int; width::Int, height::Int, seed::Int)
    # Empty field on purpose. A soup reaches this glider within a generation,
    # so the documented traveler never leaves the corner. `seed` stays in the
    # signature so callers match the other scenes; the glider does not use it.
    grid = falses(height, width)
    if height >= 5 && width >= 6
        grid[2, 3] = true
        grid[3, 4] = true
        grid[4, 2] = grid[4, 3] = grid[4, 4] = true
    end
    for _ in 1:max(tick, 0)
        grid = life_step(grid)
    end
    canvas = Canvas(width, height)
    for y in 1:height, x in 1:width
        grid[y, x] && stamp!(canvas, x, y, '●')
    end
    return String(canvas)
end

function donut_frame(tick::Int; width::Int, height::Int)
    A = tick * 0.07
    B = tick * 0.03
    cosA, sinA = cos(A), sin(A)
    cosB, sinB = cos(B), sin(B)
    cells = fill(' ', height, width)
    depth = fill(0.0, height, width)
    shade = collect(".,-~:;=!*#\$@")
    R1, R2, K2 = 1.0, 2.0, 5.0
    # Characters are about twice as tall as they are wide, so Y is scaled down.
    K1 = width * K2 * 3 / (8 * (R1 + R2))
    θ = 0.0
    while θ <= 2π
        cosθ, sinθ = cos(θ), sin(θ)
        φ = 0.0
        while φ <= 2π
            cosφ, sinφ = cos(φ), sin(φ)
            circx = R2 + R1 * cosθ
            circy = R1 * sinθ
            x = circx * (cosB * cosφ + sinA * sinB * sinφ) - circy * cosA * sinB
            y = circx * (sinB * cosφ - sinA * cosB * sinφ) + circy * cosA * cosB
            z = K2 + cosA * circx * sinφ + circy * sinA
            ooz = 1 / z
            xp = round(Int, width / 2 + 1 + K1 * ooz * x)
            yp = round(Int, height / 2 + 1 - (K1 * ooz * y) / 2)
            light = cosφ * cosθ * sinB - cosA * cosθ * sinφ - sinA * sinθ +
                    cosB * (cosA * sinθ - cosθ * sinA * sinφ)
            if 1 <= xp <= width && 1 <= yp <= height && ooz > depth[yp, xp]
                depth[yp, xp] = ooz
                cells[yp, xp] = shade[clamp(round(Int, max(light, 0) * 8) + 1, 1, length(shade))]
            end
            φ += 0.02
        end
        θ += 0.07
    end
    return join((String(@view cells[y, :]) for y in 1:height), '\n')
end

function scene_names()
    return ["fibonacci", "bars", "plot", "wave", "donut", "wator", "life"]
end

function scene_frame(name::AbstractString, tick::Int; width::Int=48, height::Int=18, seed::Int=1, legs::Int=8)
    name == "wave" && return wave_frame(tick; width, height)
    name == "donut" && return donut_frame(tick; width, height)
    name == "wator" && return wator_frame(tick; width, height, seed)
    name == "life" && return life_frame(tick; width, height, seed)
    name == "plot" && return plot_scene(tick; width, height)
    name == "bars" && return bars_scene(tick; width, height, seed)
    name == "fibonacci" && return fibonacci_scene(tick; width, height, legs)
    error("unknown scene: $name")
end

function collect_frames(name::AbstractString; nframes::Int=30, width::Int=48, height::Int=18, seed::Int=1, legs::Int=8)
    return [scene_frame(name, tick; width, height, seed, legs) for tick in 1:nframes]
end

function json_escape(text::AbstractString)
    buf = IOBuffer()
    for ch in text
        if ch == '\\'
            print(buf, "\\\\")
        elseif ch == '"'
            print(buf, "\\\"")
        elseif ch == '\n'
            print(buf, "\\n")
        elseif ch == '\r'
            print(buf, "\\r")
        elseif ch == '\t'
            print(buf, "\\t")
        else
            print(buf, ch)
        end
    end
    return String(take!(buf))
end

function frames_jsonl(frames::AbstractVector{<:AbstractString})
    lines = String[]
    for (i, text) in enumerate(frames)
        rows = split(text, '\n', keepempty=true)
        w = isempty(rows) ? 0 : maximum(length, rows)
        h = length(rows)
        push!(lines, "{\"i\":$i,\"w\":$w,\"h\":$h,\"text\":\"$(json_escape(text))\"}")
    end
    return join(lines, '\n')
end
