A Complete Setup Guide
======================

Mail servers can be a tricky thing to set up. This guide is supposed to
run you through the most important steps to achieve a 10/10 score on
``mail-tester.com``.

What you need:

-  A server with a public IP (referred to as ``server-IP``)
-  A Fully Qualified Domain Name (``FQDN``) where your server is
   reachable, so that other servers can find yours. Common FQDN include
   ``mx.example.com`` (where ``example.com`` is a domain you own) or
   ``mail.example.com``. The domain is referred to as ``server-domain``
   (``example.com`` in the above example) and the ``FQDN`` is referred
   to by ``server-FQDN`` (``mx.example.com`` above).
-  A list of domains you want to your email server to serve. (Note that
   this does not have to include ``server-domain``, but may of course).
   These will be referred to as ``domains``. As an example,
   ``domains = [ example1.com, example2.com ]``.

A) Setup server
~~~~~~~~~~~~~~~

The following describes a server setup that is fairly complete. Even
though there are more possible options (see ``default.nix``), these
should be the most common ones.

.. code:: nix

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
       fqdn = <server-FQDN>;
       domains = [ <domains> ];

       # A list of all login accounts. To create the password hashes, use
       # mkpasswd -m sha-512 "super secret password"
       loginAccounts = {
           "user1@example.com" = {
               hashedPassword = "$6$/z4n8AQl6K$kiOkBTWlZfBd7PvF5GsJ8PmPgdZsFGN1jPGZufxxr60PoR0oUsrvzm2oQiflyz5ir9fFJ.d/zKm/NgLXNUsNX/";

               aliases = [
                   "postmaster@example.com"
                   "postmaster@example2.com"
               ];

               # Make this user the catchAll address for domains example.com and
               # example2.com
               catchAll = [
                   "example.com"
                   "example2.com"
               ];
           };

           "user2@example.com" = { ... };
       };

       # Extra virtual aliases. These are email addresses that are forwarded to
       # loginAccounts addresses.
       extraVirtualAliases = {
           # address = forward address;
           "abuse@example.com" = "user1@example.com";
       };

       # Use Let's Encrypt certificates. Note that this needs to set up a stripped
       # down nginx and opens port 80.
       certificateScheme = 3;

       # Enable IMAP and POP3
       enableImap = true;
       enablePop3 = true;
       enableImapSsl = true;
       enablePop3Ssl = true;

       # Enable the ManageSieve protocol
       enableManageSieve = true;

       # whether to scan inbound emails for viruses (note that this requires at least
       # 1 Gb RAM for the server. Without virus scanning 256 MB RAM should be plenty)
       virusScanning = false;
     };
   }

After a ``nixos-rebuild switch --upgrade`` your server should be good to
go. If you want to use ``nixops`` to deploy the server, look in the
subfolder ``nixops`` for some inspiration.

B) Setup everything else
~~~~~~~~~~~~~~~~~~~~~~~~

Step 1: Set DNS entry for server
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Add a DNS record to the domain ``server-domain`` with the following
entries

================ ===== ==== ======== =============
Name (Subdomain) TTL   Type Priority Value
================ ===== ==== ======== =============
``server-FQDN``  10800 A             ``server-IP``
================ ===== ==== ======== =============

This resolves DNS queries for ``server-FQDN`` to ``server-IP``. You can
test if your setting is correct by

::

   ping <server-FQDN>
   64 bytes from <server-FQDN> (<server-IP>): icmp_seq=1 ttl=46 time=21.3 ms
   ...

Note that it can take a while until a DNS entry is propagated.

Step 2: Set rDNS (reverse DNS) entry for server
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Wherever you have rented your server, you should be able to set reverse
DNS entries for the IP’s you own. Add an entry resolving ``server-IP``
to ``server-FQDN``

You can test if your setting is correct by

::

   host <server-IP>
   <server-IP>.in-addr.arpa domain name pointer <server-FQDN>.

Note that it can take a while until a DNS entry is propagated.

Step 3: Set ``MX`` Records
^^^^^^^^^^^^^^^^^^^^^^^^^^

For every ``domain`` in ``domains`` do: \* Add a ``MX`` record to the
domain ``domain``

::

   | Name (Subdomain) | TTL   | Type | Priority | Value             |
   | ---------------- | ----- | ---- | -------- | ----------------- |
   | `domain`         |       | MX   | 10       | `server-FQDN`     |

You can test this via

::

   dig -t MX <domain>

   ...
   ;; ANSWER SECTION:
   <domain>    10800   IN  MX  10 <server-FQDN>
   ...

Note that it can take a while until a DNS entry is propagated.

Step 4: Set ``SPF`` Records
^^^^^^^^^^^^^^^^^^^^^^^^^^^

For every ``domain`` in ``domains`` do: \* Add a ``SPF`` record to the
domain ``domain``

::

   | Name (Subdomain) | TTL   | Type | Priority | Value                         |
   | ---------------- | ----- | ---- | -------- | -----------------             |
   | `domain`         | 10800 | TXT  |          | `v=spf1 ip4:<server-IP> -all` |

You can check this with ``dig -t TXT <domain>`` similar to the last
section. Note that ``SPF`` records are set as ``TXT`` records since
RFC1035.

Note that it can take a while until a DNS entry is propagated. If you
want to use multiple servers for your email handling, don’t forget to
add all server IP’s to this list.

Step 5: Set ``DKIM`` signature
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In this section we assume that your ``dkimSelector`` is set to ``mail``.
If you have a different selector, replace all ``mail``\ ’s below
accordingly.

For every ``domain`` in ``domains`` do: \* Go to your server and
navigate to the dkim key directory (by default ``/var/dkim``). There you
will find a public key for any domain in the ``domain.txt`` file. It
will look like
``mail._domainkey IN TXT "v=DKIM1; r=postmaster; g=*; k=rsa; p=<really-long-key>" ; ----- DKIM mail for domain.tld``
\* Add a ``DKIM`` record to the domain ``domain``

::

   | Name (Subdomain)         | TTL   | Type | Priority | Value                          |
   | ----------------         | ----- | ---- | -------- | -----------------              |
   | mail._domainkey.`domain` | 10800 | TXT  |          | `v=DKIM1; p=<really-long-key>` |

You can check this with ``dig -t TXT mail._domainkey.<domain>`` similar
to the last section.

Note that it can take a while until a DNS entry is propagated.

Step 6: Set ``DMARC`` record
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For every ``domain`` in ``domains`` do:

-  Add a ``DMARC`` record to the domain ``domain``

   ==================== ===== ==== ======== ====================
   Name (Subdomain)     TTL   Type Priority Value
   ==================== ===== ==== ======== ====================
   \_dmarc.\ ``domain`` 10800 TXT           ``v=DMARC1; p=none``
   ==================== ===== ==== ======== ====================

You can check this with ``dig -t TXT _dmarc.<domain>`` similar to the
last section.

Note that it can take a while until a DNS entry is propagated.

C) Test your Setup
~~~~~~~~~~~~~~~~~~

Write an email to your aunt (who has been waiting for your reply far too
long), and sign up for some of the finest newsletters the Internet has.
Maybe you want to sign up for the `SNM Announcement
List <https://www.freelists.org/list/snm>`__?

Besides that, you can send an email to
`mail-tester.com <https://www.mail-tester.com/>`__ and see how you
score, and let `mxtoolbox.com <http://mxtoolbox.com/>`__ take a look at
your setup, but if you followed the steps closely then everything should
be awesome!
