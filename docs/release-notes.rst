Release Notes
=============

NixOS 20.09
-----------

- IMAP and Submission with TLS wrapped-mode are now enabled by default
  on ports 993 and 465 respectively
- OpenDKIM is now sandboxed with Systemd
- New `forwards` option to forwards emails to external addresses
  (`Merge Request <https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/193>`__)
- New `sendingFqdn` option to specify the fqdn of the machine sending
  email (`Merge Request <https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/187>`__)
- Move the Gitlab wiki to `ReadTheDocs
  <https://nixos-mailserver.readthedocs.io/en/latest/>`_
