using Test

include(joinpath(@__DIR__, "..", "src", "AsciiStage.jl"))
using .AsciiStage

@testset "fibonacci sequence" begin
    @test fibonacci(8) == [1, 1, 2, 3, 5, 8, 13, 21]
    @test fibonacci(1) == [1]
    @test fibonacci(2) == [1, 1]
end

@testset "spiral and bars match the original art" begin
    @test render_spiral([1]) == "·●"
    @test render_spiral([1, 1, 2]) == "●─╮\n ·╯"
    @test render_spiral(fibonacci(4)) == "╭─╮\n│·╯\n│  \n●  "
    @test bars(fibonacci(4)) == "1 █\n1 █\n2 ██\n3 ███"
end

@testset "named sequences are not fibonacci-only" begin
    @test lucas(6) == [2, 1, 3, 4, 7, 11]
    @test arithmetic(5; start=3, step=2) == [3, 5, 7, 9, 11]
    @test geometric(4; start=1, ratio=3) == [1, 3, 9, 27]
    @test triangular(5) == [1, 3, 6, 10, 15]
    @test primes(5) == [2, 3, 5, 7, 11]
    @test sequence("lucas", 6) == lucas(6)
    @test sequence("primes", 5) == primes(5)
    @test_throws ErrorException sequence("nope", 3)
end

@testset "canvas drawing" begin
    blank = Canvas(4, 2)
    @test String(blank) == "    \n    "
    stamp!(blank, 2, 1, 'A')
    stamp!(blank, 0, 1, 'Z')  # off-canvas is ignored
    @test String(blank) == " A  \n    "
    stroked = Canvas(5, 3)
    line!(stroked, 1, 2, 5, 2, '─')
    @test String(stroked) == "     \n─────\n     "
end

@testset "function plot is a sized frame" begin
    plotted = plot_function("sin"; width=21, height=9)
    lines = split(plotted, '\n')
    @test length(lines) == 9
    @test all(length(line) == 21 for line in lines)
    @test occursin('●', plotted)
    flat = plot_function("zero"; width=7, height=5)
    @test split(flat, '\n')[3] == "●●●●●●●"
end

@testset "agent rules" begin
    shark = fill(Critter(:empty, 0, 0), 3, 3)
    shark[2, 2] = Critter(:shark, 0, 0)
    starved = wator_step(shark)
    @test all(cell.kind == :empty for cell in starved)

    fish = fill(Critter(:empty, 0, 0), 1, 2)
    fish[1, 1] = Critter(:fish, 3, 0)
    bred = wator_step(fish; fish_breed=3)
    @test bred[1, 1].kind == :fish
    @test bred[1, 2].kind == :fish

    hunt = fill(Critter(:empty, 0, 0), 1, 2)
    hunt[1, 1] = Critter(:shark, 0, 1)
    hunt[1, 2] = Critter(:fish, 0, 0)
    eaten = wator_step(hunt)
    @test eaten[1, 1].kind == :empty
    @test eaten[1, 2].kind == :shark

    roam = fill(Critter(:empty, 0, 0), 1, 2)
    roam[1, 1] = Critter(:shark, 2, 2)
    pup = wator_step(roam; shark_breed=3)
    @test pup[1, 1].kind == :shark
    @test pup[1, 2].kind == :shark

    blinker = falses(5, 5)
    blinker[3, 2:4] .= true
    turned = life_step(blinker)
    @test turned[2, 3] && turned[3, 3] && turned[4, 3]
    @test count(turned) == 3
end

@testset "scenes move and stay rectangular" begin
    wave1 = scene_frame("wave", 1; width=20, height=7)
    wave2 = scene_frame("wave", 4; width=20, height=7)
    @test wave1 != wave2
    @test length(split(wave1, '\n')) == 7
    @test all(length(line) == 20 for line in split(wave1, '\n'))
    donut1 = scene_frame("donut", 1; width=36, height=14)
    donut2 = scene_frame("donut", 10; width=36, height=14)
    @test donut1 != donut2
    @test count(c -> c != ' ', donut1) > 20
    @test !occursin('\e', donut1)
    grown = spiral_after(fibonacci(4), sum(fibonacci(4)))
    @test grown == render_spiral(fibonacci(4))
    @test spiral_after(fibonacci(4), 1) != grown
    @test "wator" in scene_names()
    @test "donut" in scene_names()
    @test "life" in scene_names()
end

@testset "jsonl frames are harness-safe" begin
    frames = collect_frames("wave"; nframes=3, width=12, height=5, seed=1)
    payload = frames_jsonl(frames)
    @test length(split(payload, '\n')) == 3
    @test startswith(payload, "{\"i\":1,")
    @test occursin("\"w\":12", payload)
    @test occursin("\"h\":5", payload)
    @test !occursin('\e', payload)
    @test !occursin("\e[", payload)
end

@testset "static fibonacci command is unchanged" begin
    script = joinpath(@__DIR__, "..", "fibonacci_art.jl")
    out = read(`$(Base.julia_cmd()) $script 4`, String)
    @test occursin("legs: 1, 1, 2, 3", out)
    @test occursin("╭─╮\n│·╯\n│  \n●  ", out)
    @test endswith(chomp(out), "3 ███")
end
