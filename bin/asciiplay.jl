#!/usr/bin/env julia
# Play a math, graphics, or agent scene in the terminal.
#   julia bin/asciiplay.jl donut
#   julia bin/asciiplay.jl wator --frames 40 --jsonl

const _ROOT = dirname(@__DIR__)
include(joinpath(_ROOT, "src", "AsciiStage.jl"))
using .AsciiStage

function _need(args, i)
    i < length(args) || error("missing value after $(args[i])")
    return args[i + 1], i + 1
end

function parse_play_args(args)
    scene = "donut"
    opts = Dict{Symbol,Any}(
        :nframes => 80,
        :fps => 16,
        :width => 64,
        :height => 24,
        :seed => 1,
        :legs => 8,
        :jsonl => false,
        :list => false,
    )
    flags = Dict(
        "--frames" => :nframes,
        "--fps" => :fps,
        "--width" => :width,
        "--height" => :height,
        "--seed" => :seed,
        "--legs" => :legs,
    )
    flag_bounds = Dict(
        :nframes => (1, typemax(Int)),
        :fps => (1, typemax(Int)),
        :width => (1, typemax(Int)),
        :height => (1, typemax(Int)),
        :seed => (typemin(Int), typemax(Int)),
        :legs => (1, 12),
    )
    i = 1
    positional = String[]
    while i <= length(args)
        arg = args[i]
        if arg == "--jsonl"
            opts[:jsonl] = true
        elseif arg == "--list" || arg == "list"
            opts[:list] = true
        elseif haskey(flags, arg)
            value, i = _need(args, i)
            lo, hi = flag_bounds[flags[arg]]
            opts[flags[arg]] = parse_cli_int(value, arg; lo, hi)
        elseif startswith(arg, "-")
            error("unknown option: $arg")
        else
            push!(positional, arg)
        end
        i += 1
    end
    if !isempty(positional)
        scene = positional[1]
    end
    return scene, opts
end

function play_scene(scene::AbstractString, opts; io::IO=stdout)
    scene in scene_names() || error("unknown scene: $scene. try: $(join(scene_names(), ", "))")
    frames = collect_frames(
        scene;
        nframes=opts[:nframes],
        width=opts[:width],
        height=opts[:height],
        seed=opts[:seed],
        legs=opts[:legs],
    )
    if opts[:jsonl]
        println(io, frames_jsonl(frames))
        return
    end
    live = io isa Base.TTY
    live && print(io, "\e[?1049h\e[?25l")
    try
        for (i, frame) in enumerate(frames)
            live && print(io, "\e[H\e[2J")
            println(io, scene, "  ", i, "/", length(frames), "   seed ", opts[:seed])
            println(io, frame)
            live && sleep(1 / opts[:fps])
        end
    finally
        live && print(io, "\e[?25h\e[?1049l")
    end
end

function main()
    scene, opts = parse_play_args(ARGS)
    if opts[:list]
        println(join(scene_names(), "\n"))
        return
    end
    play_scene(scene, opts)
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
