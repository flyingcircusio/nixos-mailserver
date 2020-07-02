let
  nixpkgs = (import ./nix/sources.nix).nixpkgs-unstable;
  pkgs = import nixpkgs {};
in
pkgs.mkShell {
  buildInputs = with pkgs; [
  (python3.withPackages(p: [p.sphinx p.sphinx_rtd_theme]))
  niv
  jq clamav
  ];
}
