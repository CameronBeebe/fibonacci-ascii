#!/usr/bin/env julia
# Static Fibonacci spiral. The animated stage lives in bin/asciiplay.jl.

include(joinpath(@__DIR__, "src", "AsciiStage.jl"))
using .AsciiStage

function main()
    nlegs = isempty(ARGS) ? 8 : parse_cli_int(ARGS[1], "legs"; lo=1, hi=12)
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
