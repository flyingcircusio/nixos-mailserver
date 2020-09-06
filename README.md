# ![Simple Nixos MailServer][logo]
![license](https://img.shields.io/badge/license-GPL3-brightgreen.svg)
[![pipeline status](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/badges/master/pipeline.svg)](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/commits/master)


## Release branches

For each NixOS release, we publish a branch. You then have to use the
SNM branch corresponding to your NixOS version.

* For NixOS 20.03
   -  Use the [SNM branch `nixos-20.03`](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/tree/nixos-20.03)
   - [Release notes](#nixos-2003)
* For NixOS 19.09
   - Use the [SNM branch `nixos-19.09`](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/tree/nixos-19.09)
* For NixOS unstable
   - Use the [SNM branch `master`](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/tree/master)

[Subscribe to SNM Announcement List](https://www.freelists.org/list/snm)
This is a very low volume list where new releases of SNM are announced, so you
can stay up to date with bug fixes and updates. All announcements are signed by
the gpg key with fingerprint

```
D9FE 4119 F082 6F15 93BD  BD36 6162 DBA5 635E A16A
```


## Features
### v2.0
 * [x] Continous Integration Testing
 * [x] Multiple Domains
 * Postfix MTA
    - [x] smtp on port 25
    - [x] submission tls on port 465
    - [x] submission starttls on port 587
    - [x] lmtp with dovecot
 * Dovecot
    - [x] maildir folders
    - [x] imap with tls on port 993
    - [x] pop3 with tls on port 995
    - [x] imap with starttls on port 143
    - [x] pop3 with starttls on port 110
 * Certificates
    - [x] manual certificates
    - [x] on the fly creation
    - [x] Let's Encrypt
 * Spam Filtering
    - [x] via rspamd
 * Virus Scanning
    - [x] via clamav
 * DKIM Signing
    - [x] via opendkim
 * User Management
    - [x] declarative user management
    - [x] declarative password management
 * Sieves
    - [x] A simple standard script that moves spam
    - [x] Allow user defined sieve scripts
    - [x] ManageSieve support
 * User Aliases
    - [x] Regular aliases
    - [x] Catch all aliases

### In the future

  * DKIM Signing
    - [ ] Allow a per domain selector

### Changelog and How to Stay Up-to-Date

See the [mailing list archive](https://www.freelists.org/archive/snm/)

### Quick Start

```nix
{ config, pkgs, ... }:
{
  imports = [
    (builtins.fetchTarball {
      # Pick a commit from the branch you are interested in
      url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/A-COMMIT-ID/nixos-mailserver-A-COMMIT-ID.tar.gz";
      # And set its hash
      sha256 = "0000000000000000000000000000000000000000000000000000";
    })
  ];

  mailserver = {
    enable = true;
    fqdn = "mail.example.com";
    domains = [ "example.com" "example2.com" ];
    loginAccounts = {
        "user1@example.com" = {
            hashedPassword = "$6$/z4n8AQl6K$kiOkBTWlZfBd7PvF5GsJ8PmPgdZsFGN1jPGZufxxr60PoR0oUsrvzm2oQiflyz5ir9fFJ.d/zKm/NgLXNUsNX/";

            aliases = [
                "info@example.com"
                "postmaster@example.com"
                "postmaster@example2.com"
            ];
        };
    };
  };
}
```

For a complete list of options, see `default.nix`.



## How to Set Up a 10/10 Mail Server Guide
Check out the [Complete Setup Guide](https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html) in the project's documentation.

## How to Backup

Checkout the [Complete Backup Guide](https://nixos-mailserver.readthedocs.io/en/latest/backup-guide.html). Backups are easy with `SNM`.

## Development

See the [How to Develop SNM](https://nixos-mailserver.readthedocs.io/en/latest/howto-develop.html) wiki page.

## Release notes

### nixos-20.03

- Rspamd is upgraded to 2.0 which deprecates the SQLite Bayes
  backend. We then moved to the Redis backend (the default since
  Rspamd 2.0). If you don't want to relearn the Redis backend from the
  scratch, we could manually run

      rspamadm statconvert --spam-db /var/lib/rspamd/bayes.spam.sqlite --ham-db /var/lib/rspamd/bayes.ham.sqlite -h 127.0.0.1:6379 --symbol-ham BAYES_HAM --symbol-spam BAYES_SPAM

  See the [Rspamd migration
  notes](https://rspamd.com/doc/migration.html#migration-to-rspamd-20)
  and [this SNM Merge
  Request](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/164)
  for details.

## Contributors
See the [contributor tab](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/graphs/master)

### Alternative Implementations
 * [NixCloud Webservices](https://github.com/nixcloud/nixcloud-webservices)

### Credits
 * send mail graphic by [tnp_dreamingmao](https://thenounproject.com/dreamingmao)
   from [TheNounProject](https://thenounproject.com/) is licensed under
   [CC BY 3.0](http://creativecommons.org/~/3.0/)
 * Logo made with [Logomakr.com](https://logomakr.com)




[logo]: logo/logo.png
