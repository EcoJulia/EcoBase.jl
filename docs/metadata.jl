# SPDX-License-Identifier: MIT

using Pkg

# Update EcoBase folder packages 
Pkg.activate(".")
Pkg.update()

# Update examples folder packages
if isdir("examples")
    if isfile("examples/Project.toml")
        Pkg.activate("examples")
        Pkg.update()
        "EcoBase" ∈ [p.name for p in values(Pkg.dependencies())] &&
            Pkg.rm("EcoBase")
        Pkg.develop("EcoBase")
    end
end

# Update docs folder packages
Pkg.activate("docs")
Pkg.update()
"EcoBase" ∈ [p.name for p in values(Pkg.dependencies())] &&
    Pkg.rm("EcoBase")
Pkg.develop("EcoBase")

# Reformat files in package
using JuliaFormatter
using EcoBase
format(EcoBase)

# Carry out crosswalk for metadata
using ResearchSoftwareMetadata
ResearchSoftwareMetadata.crosswalk()
