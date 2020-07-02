How to Develop SNM
==================

Run tests
---------

You can run the testsuite via

::

   nix-build tests -A extern.nixpkgs_20_03
   nix-build tests -A intern.nixpkgs_unstable
   ...

Nixops
------

You can test the setup via ``nixops``. After installation, do

::

   nixops create nixops/single-server.nix nixops/vbox.nix -d mail
   nixops deploy -d mail
   nixops info -d mail

You can then test the server via e.g. \ ``telnet``. To log into it, use

::

   nixops ssh -d mail mailserver

Imap
----

To test imap manually use

::

   openssl s_client -host mail.example.com -port 143 -starttls imap
