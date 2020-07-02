A Complete Backup Guide
=======================

This is really easy. First off you should have a backup of your
``configuration.nix`` file where you have the server config (but that is
already in a git repository right?)

Next you need to backup ``/var/vmail`` or whatever you have specified
for the option ``mailDirectory``. This is where all the mails reside.
Good options are a cron job with ``rsync`` or ``scp``. But really
anything works, as it is simply a folder with plenty of files in it. If
your backup solution does not preserve the owner of the files don’t
forget to ``chown`` them to ``virtualMail:virtualMail`` if you copy them
back (or whatever you specified as ``vmailUserName``, and
``vmailGoupName``).

Finally you can (optionally) make a backup of ``/var/dkim`` (or whatever
you specified as ``dkimKeyDirectory``). If you should lose those don’t
worry, new ones will be created on the fly. But you will need to repeat
step ``B)5`` and correct all the ``dkim`` keys.
