#  nixos-mailserver: a simple mail server
#  Copyright (C) 2016  Robin Raymond
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

{ config, pkgs, ... }:

let
  dovecot_maildir = "maildir:" + mail_dir + "/%d/%n/";
  vmail_user = [{
    name = vmail_user_name;
    isNormalUser = false;
    uid = vmail_id_start;
    home = mail_dir;
    createHome = true;
    group = vmail_group_name;
  }];

  # accountsToUser :: String -> UserRecord
  accountsToUser = x: {
    name = x + "@" + domain;
    isNormalUser = false;
    group = vmail_group_name;
  };

  # mail_user :: [ UserRecord ]
  mail_user = map accountsToUser login_accounts;

  # valiasToString :: { from = "..."; to = "..." } -> String
  valiasToString = x: x.from + "@" + domain + " " + x.to "@" + domain + "\n";

  # valiasFile :: [ String ]
  valiasFile = map valiasToString valiases;
in
{
  networking.hostName = host_prefix + "." + domain;
  
  environment.systemPackages = with pkgs; [
    dovecot opendkim openssh postfix clamav rspamd rmilter
  ];
  
  # set the vmail gid to a specific value
  users.groups = {
    vmail = { gid = vmail_id_start; };
  };
  
  # define all users
  users.extraUsers = vmail_user ++ mail_user;
  
 
  # rspamd
  services.rspamd = {
    enable = true;
  };

  imports = [ 
    ./mail-server/dovecot.nix  # dovecot
    ./mail-server/postfix.nix  # postfix
  ];
}
