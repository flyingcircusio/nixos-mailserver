How to Develop SNM
==================

Run NixOS tests
---------------

You can run the testsuite via

::

   $ nix-build tests -A extern.nixpkgs_20_03
   $ nix-build tests -A intern.nixpkgs_unstable
   ...

Contributing to the documentation
---------------------------------

The documentation is written in RST, build with Sphinx and published
by `Read the Docs <https://readthedocs.org/>`_.

For the syntax, see `RST/Sphinx Cheatsheet
<https://sphinx-tutorial.readthedocs.io/cheatsheet/>`_.

The ``shell.nix`` provides all the tooling required to build the
documentation:

::

   $ nix-shell
   $ cd docs
   $ make html
   $ firefox ./_build/html/index.html

Nixops
------

You can test the setup via ``nixops``. After installation, do

::

   $ nixops create nixops/single-server.nix nixops/vbox.nix -d mail
   $ nixops deploy -d mail
   $ nixops info -d mail

You can then test the server via e.g. \ ``telnet``. To log into it, use

::

   $ nixops ssh -d mail mailserver

Imap
----

To test imap manually use

::

   $ openssl s_client -host mail.example.com -port 143 -starttls imap
