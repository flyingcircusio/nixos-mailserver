# Generate an attribute sets containing all tests for all releaeses
# It looks like:
# - extern.nixpkgs_20.03
# - extern.nixpkgs_unstable
# - intern.nixpkgs_20.03
# - intern.nixpkgs_unstable

with builtins;

let
  sources = import ../nix/sources.nix;

  releases = listToAttrs (map genRelease releaseNames);

  genRelease = name: {
    name = name;
    value = import sources."${name}" {};
  };

  genTest = testName: release:
  let
    pkgs = releases."${release}";
    test = pkgs.callPackage (./. + "/${testName}.nix") { };
  in {
    "name"= builtins.replaceStrings ["." "-"] ["_" "_"] release;
    "value"= test;
  };

  releaseNames = [
    "nixpkgs-unstable"
  ];

  testNames = [
    "intern"
    "extern"
    "clamav"
    "multiple"
  ];

  # Generate an attribute set containing one test per releases
  genTests = testName: {
    name = testName;
    value = listToAttrs (map (genTest testName) (builtins.attrNames releases));
  };
  
in listToAttrs (map genTests testNames)
