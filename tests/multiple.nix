# This tests is used to test features requiring several mail domains.

{ pkgs ? import <nixpkgs> {}}:

let
    hashPassword = password: pkgs.runCommand
      "password-${password}-hashed"
      { buildInputs = [ pkgs.mkpasswd ]; }
      ''
        mkpasswd -m sha-512 ${password} > $out
      '';

    password = pkgs.writeText "password" "password";

    domainGenerator = domain: { config, pkgs, ... }: {
      imports = [../default.nix];
      virtualisation.memorySize = 1024;
      mailserver = {
        enable = true;
        fqdn = "mail.${domain}";
        domains = [ domain ];
        localDnsResolver = false;
        loginAccounts = {
          "user@${domain}" = {
            hashedPasswordFile = hashPassword "password";
          };
        };
        enableImap = true;
        enableImapSsl = true;
      };
      services.dnsmasq = {
        enable = true;
        extraConfig = ''
          mx-host=domain1.com,domain1,10
          mx-host=domain2.com,domain2,10
        '';
      };
    };

in

pkgs.nixosTest {
  name = "multiple";
  nodes = {
    domain1 = {...}: {
      imports = [
        ../default.nix
        (domainGenerator "domain1.com")
      ];
      mailserver.forwards = {
        "non-local@domain1.com" = ["user@domain2.com" "user@domain1.com"];
        "non@domain1.com" = ["user@domain2.com" "user@domain1.com"];
      };
    };
    domain2 = domainGenerator "domain2.com";
    client = { config, pkgs, ... }: {
      environment.systemPackages = [
        (pkgs.writeScriptBin "mail-check" ''
          ${pkgs.python3}/bin/python ${../scripts/mail-check.py} $@
        '')];
    };
  };
  testScript = ''
    start_all()

    domain1.wait_for_unit("multi-user.target")
    domain2.wait_for_unit("multi-user.target")

    # TODO put this blocking into the systemd units?
    domain1.wait_until_succeeds(
        "timeout 1 ${pkgs.netcat}/bin/nc -U /run/rspamd/rspamd-milter.sock < /dev/null; [ $? -eq 124 ]"
    )
    domain2.wait_until_succeeds(
        "timeout 1 ${pkgs.netcat}/bin/nc -U /run/rspamd/rspamd-milter.sock < /dev/null; [ $? -eq 124 ]"
    )

    # user@domain1.com sends a mail to user@domain2.com
    client.succeed(
        "mail-check send-and-read --smtp-port 587 --smtp-starttls --smtp-host domain1 --from-addr user@domain1.com --imap-host domain2 --to-addr user@domain2.com --src-password-file ${password} --dst-password-file ${password} --ignore-dkim-spf"
    )

    # Send a mail to the address forwarded and check it is in the recipient mailbox
    client.succeed(
        "mail-check send-and-read --smtp-port 587 --smtp-starttls --smtp-host domain1 --from-addr user@domain1.com --imap-host domain2 --to-addr non-local@domain1.com --imap-username user@domain2.com --src-password-file ${password} --dst-password-file ${password} --ignore-dkim-spf"
    )
  '';
}
