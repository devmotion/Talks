# Calibration of probabilistic predictive models

[![](https://img.shields.io/badge/show-PDF-brightgreen.svg)](https://talks.widmann.dev/2022/03/calibration.pdf)

This talk I gave at the [Machine Learning Journal Club of the Gatsby unit at UCL](https://www.ucl.ac.uk/gatsby/).

## Note

The talk was compiled with [`latexmk`](http://personal.psu.edu/~jcc8/software/latexmk/) (TeXLive 2021).
You can follow the
[official installation instructions](https://www.tug.org/texlive/acquire-netinstall.html).
Additionally, [`curl`](https://curl.se/) and [`GNU awk`](https://www.gnu.org/software/gawk/manual/gawk.html) have to be installed.

For increased reproducibility, we also provide a `nix` environment with a pinned software setup:
1. Install [nix](https://github.com/NixOS/nix#installation).
2. Navigate to this folder and activate the environment by running
   ```shell
   nix develop
   ```
   in a terminal (you might have to [add support for flakes](https://nixos.wiki/wiki/Flakes)).
   Alternatively, if you use [direnv](https://direnv.net/), you can activate the environment by executing
   ```shell
   direnv allow
   ```
   in a terminal.
3. Finally run `latexmk` in the nix shell.

Additionally, you can rerun the code examples and regenerate the corresponding figures.
The code was executed with Julia 1.7.2.
It is available in the nix shell.
Alternatively, you can download the official binaries from the [Julia webpage](https://julialang.org/downloads/).
If `julia` is installed on your computer, navigate to this folder, open a terminal, and install all Julia dependencies by running
``` shell
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```
The option `--startup-file=no` increases reproducibility by eliminating any user-specific customizations. You may add other arguments such as `--color=yes` if you prefer colorized output. 
Afterwards you can run the examples and generate the figures by running
``` shell
julia --project=. --startup-file=no penguins.jl
```
Again other command line arguments such as `--color=yes` could be added.
