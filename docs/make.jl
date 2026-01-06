using Documenter
using NDViewer

makedocs(
    sitename = "NDViewer",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://makie.org/NDViewer/stable",
    ),
    modules = [NDViewer],
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "YAML Configuration" => "yaml_config.md",
        "Theming" => "theming.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/MakieOrg/NDViewer.jl.git",
    devbranch = "main",
    push_preview = true,
)
