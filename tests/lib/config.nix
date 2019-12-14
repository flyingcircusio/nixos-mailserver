{
    security.dhparams.defaultBitSize = 1024; # minimum size required by dovecot

    # For slow non-kvm tests.
    # nixos/modules/testing/test-instrumentation.nix also sets this. I don't know if there's a better way than etc to override theirs.
    environment.etc."systemd/system.conf.d/bigdefaulttimeout.conf".text = ''
      [Manager]
      # Allow extremely slow start (default for test-VMs is 5 minutes)
      DefaultTimeoutStartSec=15min
    '';
}
