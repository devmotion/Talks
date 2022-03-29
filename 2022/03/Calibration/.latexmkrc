# Local cache (we use custom TeX distribution with Nix!)
system ("mkdir -p .cache/var");
$ENV{'TEXMFHOME'} = ".cache";
$ENV{'TEXMFVAR'} = ".cache/var";

# Default source file
@default_files = ( 'talk' );

# Minted and externalization of images requires '--shell-escape'
set_tex_cmds( '--interaction=nonstopmode --shell-escape %O %P' );

# Generate PDF with LuaLaTeX
$pdf_mode = 4;

# Make output reproducible (requires us to use '%P' above!)
$ENV{'SOURCE_DATE_EPOCH'} = "1648418400"; # 2022-03-28
$pre_tex_code = "\\pdfvariable suppressoptionalinfo 512\\relax";
