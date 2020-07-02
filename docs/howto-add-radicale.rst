How to Add Radicale to SNM
==========================

Configuration by @dotlambda

.. code:: nix

   { config, pkgs, lib, ... }:

   with lib;

   let
     mailAccounts = config.mailserver.loginAccounts;
     htpasswd = pkgs.writeText "radicale.users" (concatStrings
       (flip mapAttrsToList mailAccounts (mail: user:
         mail + ":" + user.hashedPassword + "\n"
       ))
     );

   in {
     services.radicale = {
       enable = true;
       config = ''
         [auth]
         type = htpasswd
         htpasswd_filename = ${htpasswd}
         htpasswd_encryption = crypt
       '';
     };

     services.nginx = {
       enable = true;
       virtualHosts = {
         "cal.example.com" = {
           forceSSL = true;
           enableACME = true;
           locations."/" = {
             proxyPass = "http://localhost:5232/";
             extraConfig = ''
               proxy_set_header  X-Script-Name /;
               proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
               proxy_pass_header Authorization;
             '';
           };
         };
       };
     };

     networking.firewall.allowedTCPPorts = [ 80 443 ];
   }
