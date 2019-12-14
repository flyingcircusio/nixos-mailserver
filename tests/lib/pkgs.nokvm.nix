let
    pkgs = (import <nixpkgs> { system = builtins.currentSystem; config = {}; });
    patchedMachinePM = pkgs.writeTextFile {
        name = "Machine.pm.patched-to-wait-longer-for-vm";
        text = builtins.replaceStrings ["alarm 600;"] ["alarm 1200;"] (builtins.readFile (<nixpkgs>+"/nixos/lib/test-driver/Machine.pm"));
    };
in
(pkgs // {
    qemu_test = with pkgs; stdenv.mkDerivation {
        name = "qemu_test_no_kvm";
        buildInputs = [ coreutils qemu_test ];
        inherit qemu_test;
        inherit coreutils;
        builder = builtins.toFile "builder.sh" ''
            PATH=$coreutils/bin:$PATH
            mkdir -p $out/bin
            cp $qemu_test/bin/* $out/bin/
            ln -sf $out/bin/qemu-system-${stdenv.hostPlatform.qemuArch} $out/bin/qemu-kvm
        '';
    };
    stdenv = pkgs.stdenv // {
        mkDerivation = args: (pkgs.stdenv.mkDerivation (args // (
            pkgs.lib.optionalAttrs (args.name == "nixos-test-driver") {
                installPhase = args.installPhase + ''
                    rm $libDir/Machine.pm
                    cp ${patchedMachinePM} $libDir/Machine.pm
                '';
            }
        )));
    };
})
