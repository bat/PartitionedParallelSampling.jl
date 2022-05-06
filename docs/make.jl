# Use
#
#     DOCUMENTER_DEBUG=true julia --color=yes make.jl local [nonstrict] [fixdoctests]
#
# for local builds.

using Documenter
using PartitionedParallelSampling

# Doctest setup
DocMeta.setdocmeta!(
    PartitionedParallelSampling,
    :DocTestSetup,
    :(using PartitionedParallelSampling);
    recursive=true,
)

makedocs(
    sitename = "PartitionedParallelSampling",
    modules = [PartitionedParallelSampling],
    format = Documenter.HTML(
        prettyurls = !("local" in ARGS),
        canonical = "https://bat.github.io/PartitionedParallelSampling.jl/stable/"
    ),
    pages = [
        "Home" => "index.md",
        "API Documentation" => "stable_api.md",
        "Internal API" => "internal_api.md",
        "LICENSE" => "LICENSE.md",
    ],
    doctest = ("fixdoctests" in ARGS) ? :fix : true,
    linkcheck = !("nonstrict" in ARGS),
    strict = !("nonstrict" in ARGS),
)

deploydocs(
    repo = "github.com/bat/PartitionedParallelSampling.jl.git",
    forcepush = true,
    push_preview = true,
)
