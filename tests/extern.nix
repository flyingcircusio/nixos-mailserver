#  nixos-mailserver: a simple mail server
#  Copyright (C) 2016-2017  Robin Raymond
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program. If not, see <http://www.gnu.org/licenses/>

import <nixpkgs/nixos/tests/make-test.nix> {

  nodes =
    { server = { config, pkgs, ... }:
        {
            imports = [
                ./../default.nix
            ];

            mailserver = {
              enable = true;
              domain = "example.com";

              hostPrefix = "mail";
              loginAccounts = {
                  user1 = {
                      hashedPassword = "$6$/z4n8AQl6K$kiOkBTWlZfBd7PvF5GsJ8PmPgdZsFGN1jPGZufxxr60PoR0oUsrvzm2oQiflyz5ir9fFJ.d/zKm/NgLXNUsNX/";
                  };
                  user2 = {
                      hashedPassword = "$6$u61JrAtuI0a$nGEEfTP5.eefxoScUGVG/Tl0alqla2aGax4oTd85v3j3xSmhv/02gNfSemv/aaMinlv9j/ZABosVKBrRvN5Qv0";
                  };
              };

              enableImap = true;
            };
        };
      client = { config, pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ fetchmail msmtp procmail ];
      };
    };

  testScript =
  let
    fetchmailRc =
    ''
        poll SERVER with proto IMAP
            user 'user1\@example.com' there with password 'user1' is 'root' here
            mda procmail
    '';

    procmailRc =
    ''
        DEFAULT=\$HOME/mail
    '';

    msmtpRc = 
    ''
        account        test
        host           SERVER
        port           587
        from           user2\@example.com
        user           user2\@example.com
        password       user2
    '';
    email1 =
    ''
        From: User2 <user2\@example.com>
        To: User1 <user1\@example.com>
        Cc:
        Bcc:
        Subject: This is a test Email from user2 to user1
        Reply-To:

        Hello User1,

        how are you doing today?
    '';
  in
    ''
      startAll;

      $server->waitForUnit("multi-user.target");
      $client->waitForUnit("multi-user.target");

      subtest "imap retrieving mail", sub {
          $client->succeed("mkdir ~/mail");
          $client->succeed("echo '${fetchmailRc}' > ~/.fetchmailrc");
          $client->succeed("echo '${procmailRc}' > ~/.procmailrc");
          $client->succeed("sed -i s/SERVER/`getent hosts server | awk '{ print \$1 }'`/g ~/.fetchmailrc");
          $client->succeed("chmod 0700 ~/.fetchmailrc");
          $client->succeed("cat ~/.fetchmailrc >&2");
          # fetchmail returns EXIT_CODE 1 when no new mail
          $client->succeed("fetchmail -v || [ \$? -eq 1 ] >&2");
      };

      subtest "submission port send mail", sub {
          $client->succeed("echo '${msmtpRc}' > ~/.msmtprc");
          $client->succeed("sed -i s/SERVER/`getent hosts server | awk '{ print \$1 }'`/g ~/.msmtprc");
          $client->succeed("cat ~/.msmtprc >&2");
          $client->succeed("echo '${email1}' > mail.txt");
          # send email from user2 to user1
          $client->succeed("msmtp -a test --tls=on --tls-certcheck=off --auth=on user1\@example.com < mail.txt >&2");
      };

      subtest "imap retrieving mail 2", sub {
          # give the mail server some time to process the mail
          $client->succeed("sleep 5");
          # fetchmail returns EXIT_CODE 0 when it retrieves mail
          $client->succeed("fetchmail -v >&2");
      };

      subtest "remove sensitive information on submission port", sub {
        $client->succeed("cat ~/mail/* >&2");
        # make sure our IP is _not_ in the email header
        $client->fail("grep `ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print \$2}' | cut -f1  -d'/'` ~/mail/*");
      };
    '';
}
