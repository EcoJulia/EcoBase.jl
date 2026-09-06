# SPDX-License-Identifier: MIT

module CleanJuliaFormatter
using Test
using EcoBase
using Git
using Pkg
using JuliaFormatter

include("GitUtils.jl")
using .GitUtils

# Metadata crosswalk testing only works on Julia v1.8 and after due to Project.toml changes
# Also does not currently work on Windows runners on GitHub due to file writing issues
if VERSION ≥ VersionNumber("1.8.0") &&
   (!haskey(ENV, "RUNNER_OS") || ENV["RUNNER_OS"] ≠ "Windows")
    @testset "JuliaFormatter" begin
        git_dir = readchomp(`$(Git.git()) rev-parse --show-toplevel`)
        @test_nowarn format(EcoBase)
        @test is_repo_clean(git_dir, strict = haskey(ENV, "RUNNER_OS"))
    end
else
    @test_broken VERSION ≥ VersionNumber("1.8.0") &&
                 (!haskey(ENV, "RUNNER_OS") || ENV["RUNNER_OS"] ≠ "Windows")
end

end
