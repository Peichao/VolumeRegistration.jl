using VolumeRegistration
using Documenter

makedocs(;
    modules=[VolumeRegistration],
    authors="Vilim <vilim@neuro.mpg.de> and contributors",
    repo="https://github.com/portugueslab/VolumeRegistration.jl/blob/{commit}{path}#L{line}",
    sitename="VolumeRegistration.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://portugueslab.github.io/VolumeRegistration.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Usage examples" => "examples.md",
    ],
)

deploydocs(;
    repo="github.com/portugueslab/VolumeRegistration.jl",
)
