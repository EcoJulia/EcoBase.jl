using Test

# Identify files in test/ that are testing matching files in src/
#  - src/Source.jl will be matched by test/test_Source.jl

filebase = String[]
for (root, dirs, files) in walkdir("../src")
    append!(filebase,
            map(file -> replace(file, r"(.*).jl" => s"\1"),
                filter(file -> occursin(r".*\.jl", file), files)))
end

testbase = map(file -> replace(file, r"test_(.*).jl" => s"\1"),
                filter(str -> occursin(r"^test_.*\.jl$", str), readdir()))

@testset "EcoBase.jl" begin
    println()
    @info "Running tests for files:"
    for t in testbase
        println("    = $t.jl")
    end
    println()

    @info "Running tests..."
    @testset for t in testbase
        fn = "test_$t.jl"
        println("    * Testing $t.jl ...")
        include(fn)
    end
end

# Identify tests with no matching file
superfluous = filter(f -> f ∉ filebase, testbase)
if length(superfluous) > 0
    println()
    @info "Potentially superfluous tests:"
    for f in superfluous
        println("    + $f.jl")
    end
end

# Identify files with no matching test
notest = filter(f -> f ∉ testbase, filebase)
if length(notest) > 0
    println()
    @info "Potentially missing tests:"
    for f in notest
        println("    - $f.jl")
    end
end
