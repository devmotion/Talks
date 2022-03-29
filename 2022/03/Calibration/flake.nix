{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };
  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib; eachSystem allSystems (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      tex = pkgs.texlive.combine {
        inherit (pkgs.texlive) scheme-basic
          adjustbox aobs-tikz arev
          beamer biber biblatex booktabs
          catchfile collectbox csquotes
          emoji environ eulervm
          fancyvrb float fontawesome fontspec fourier framed fvextra
          gillius
          hanging
          latexmk lineno luamplib luatexbase
          mathdesign mathtools metapost microtype minted
          pgfopts pgfplots polyglossia
          tcolorbox
          upquote
          xstring;
      };
    in rec {
      devShell = pkgs.mkShell {
        buildInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.gawk
          pkgs.glibcLocales
          pkgs.julia-mono
          pkgs.julia-bin
          pkgs.ncurses
          pkgs.noto-fonts-emoji
          pkgs.which
          tex
        ];
        shellHook = ''
          export OSFONTDIR="${pkgs.julia-mono}/share/fonts//;${pkgs.noto-fonts-emoji}/share/fonts//"
        '';
      };
    });
}
