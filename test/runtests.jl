# SPDX-License-Identifier: MIT

using Random
using Test
using EcoBase
using Pkg

rsmd = get(ENV, "RSMD_CROSSWALK", "FALSE")

if rsmd == "FALSE"
    # Normal testing

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

    # Identify tests with no matching file
    superfluous = filter(f -> f ∉ filebase, testbase)
    if length(superfluous) > 0
        println()
        @info "Potentially superfluous tests:"
        for f in superfluous
            println("    + $f.jl")
        end
        println()
    end

    # Identify files with no matching test
    notest = filter(f -> f ∉ testbase, filebase)
    if length(notest) > 0
        println()
        @info "Potentially missing tests:"
        for f in notest
            println("    - $f.jl")
        end
        println()
    end

    # Seed RNG to make tests reproducible
    Random.seed!(1234)

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

    # Identify files that are cross-validating results against other packages
    # test/pkg_Package.jl should validate results against the Package package

    pkgbase = map(file -> replace(file, r"pkg_(.*).jl$" => s"\1"),
                  filter(str -> occursin(r"^pkg_.*\.jl$", str),
                         readdir()))

    # A pkg_Package.jl can only run when Package is in the test environment,
    # and Package can only be there when it admits this version of EcoBase.
    # A downstream still capped at an older EcoBase has to come out of
    # [targets] altogether - leaving it there makes the environment
    # unresolvable, and then nothing runs at all, not even our own tests. So
    # the file stays and is skipped here until that package catches up.
    available = filter(p -> !isnothing(Base.identify_package(p)), pkgbase)
    skipped = filter(p -> isnothing(Base.identify_package(p)), pkgbase)

    if length(skipped) > 0
        println()
        @warn "NOT cross validating (not in the test environment - check " *
              "whether they now allow this version of EcoBase):"
        for p in skipped
            println("    ! $p")
        end
        println()
    end

    if length(available) > 0
        @info "Cross validation packages:"
        @testset begin
            for p in available
                println("    = $p")
            end
            println()

            @testset for p in available
                fn = "pkg_$p.jl"
                println("    * Validating $p.jl ...")
                include(fn)
            end
        end
    end
end

if rsmd == "TRUE" || !haskey(ENV, "RUNNER_OS") # Crosswalk runner or local testing
    # Test RSMD crosswalk and other hygene issues

    # Identify files that are checking package hygene
    cleanbase = map(file -> replace(file, r"clean_(.*).jl$" => s"\1"),
                    filter(str -> occursin(r"^clean_.*\.jl$", str),
                           readdir()))

    if length(cleanbase) > 0
        @info "Crosswalk and clean testing:"
        @testset begin
            for c in cleanbase
                println("    = $c")
            end
            println()

            @testset for c in cleanbase
                fn = "clean_$c.jl"
                println("    * Verifying $c.jl ...")
                include(fn)
            end
        end
    end
end
