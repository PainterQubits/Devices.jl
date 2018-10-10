using Documenter, Devices
using FileIO

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs==0.17.5", "mkdocs-material==2.9.4" ,"python-markdown-math"),
    julia  = "0.7",
    osname = "linux",
    repo   = "github.com/PainterQubits/Devices.jl.git"
)
