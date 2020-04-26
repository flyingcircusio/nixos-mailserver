#  nixos-mailserver: a simple mail server
#  Copyright (C) 2016-2018  Robin Raymond
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

{ pkgs ? import <nixpkgs> {}}:

let
  sendMail = pkgs.writeTextFile {
    "name" = "send-mail-to-send-only-account";
    "text" = ''
      EHLO mail.example.com
      MAIL FROM: none@example.com
      RCPT TO: send-only@example.com
      QUIT
    '';
  };

  hashPassword = password: pkgs.runCommand
    "password-${password}-hashed"
    { buildInputs = [ pkgs.mkpasswd ]; } ''
      mkpasswd -m sha-512 ${password} > $out
    '';

in
import (pkgs.path + "/nixos/tests/make-test.nix") {

  machine =
    { config, pkgs, ... }:
    {
        imports = [
            ./../default.nix
            ./lib/config.nix
        ];

        virtualisation.memorySize = 1024;

        mailserver = {
          enable = true;
          fqdn = "mail.example.com";
          domains = [ "example.com" ];

          loginAccounts = {
              "user1@example.com" = {
                  hashedPassword = "$6$/z4n8AQl6K$kiOkBTWlZfBd7PvF5GsJ8PmPgdZsFGN1jPGZufxxr60PoR0oUsrvzm2oQiflyz5ir9fFJ.d/zKm/NgLXNUsNX/";
              };
              "send-only@example.com" = {
                  hashedPasswordFile = hashPassword "send-only";
                  sendOnly = true;
              };
          };

          vmailGroupName = "vmail";
          vmailUID = 5000;
        };
    };

  testScript =
    ''
      $machine->start;
      $machine->waitForUnit("multi-user.target");

      subtest "vmail gid is set correctly", sub {
            $machine->succeed("getent group vmail | grep 5000");
      };

      subtest "mail to send only accounts is rejected", sub {
            $machine->waitForOpenPort(25);
            # TODO put this blocking into the systemd units?
            $machine->waitUntilSucceeds("timeout 1 ${pkgs.netcat}/bin/nc -U /run/rspamd/rspamd-milter.sock < /dev/null; [ \$? -eq 124 ]");
            $machine->succeed("cat ${sendMail} | ${pkgs.netcat-gnu}/bin/nc localhost 25 | grep -q 'This account cannot receive emails'" );
      };
    '';
}
