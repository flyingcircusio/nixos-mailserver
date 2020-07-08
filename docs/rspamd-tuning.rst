How to tune spam filtering
==========================

SNM comes with the `rspamd spam filtering system <https://rspamd.com/>`_
enabled by default. Although its out-of-the-box performance is good, you
can increase its efficiency by tuning its behaviour.

A) Auto-learning
~~~~~~~~~~~~~~~~

Moving spam email to the Junk folder (and false-positives out of it) will
trigger an automatic training of the Bayesian filters, improving filtering
of future emails.

B) Train from existing folders
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you kept previous spam, you can train the filter from it. Note that the
`rspamd FAQ <https://rspamd.com/doc/faq.html#how-can-i-learn-messages>`_
indicates that *you should always learn both classes with almost equal
amount of messages to increase performance of the statistical engine.*

You can run the training in a root shell as follows:

.. code:: bash

  # Path to the controller socket
  export RSOCK="/var/run/rspamd/worker-controller.sock"

  # Learn the Junk folder as spam
  rspamc -h $RSOCK learn_spam /var/vmail/$DOMAIN/$USER/.Junk/cur/

  # Learn the INBOX as ham
  rspamc -h $RSOCK learn_ham /var/vmail/$DOMAIN/$USER/cur/

  # Check that training was successful
  rspamc -h $RSOCK stat | grep learned

C) Tune symbol weight
~~~~~~~~~~~~~~~~~~~~~

The ``X-Spamd-Result`` header is automatically added to your emails, detailing
the scoring decisions. The `modules documentation <https://rspamd.com/doc/modules/>`_
details the meaning of each symbol. You can tune the weight if a symbol if needed.

.. code:: nix

  services.rspamd.locals = {
    "groups.conf".text = ''
      symbols {
        "FORGED_RECIPIENTS" { weight = 0; }
      }'';
  };

D) Tune action thresholds
~~~~~~~~~~~~~~~~~~~~~~~~~

After scoring the message, rspamd decides on an action based on configurable thresholds.
By default, rspamd will tell postfix to reject any message with a score higher than 15.
If you experience issues in scoring or want to stay on the safe side, you can disable
this behaviour by tuning the configuration. For example:

.. code:: nix

  services.rspamd.extraConfig = ''
    actions {
      reject = null; # Disable rejects, default is 15
      add_header = 6; # Add header when reaching this score
      greylist = 4; # Apply greylisting when reaching this score
    }
  '';


E) Access the rspamd web UI
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Rspamd comes with `a web interface <https://rspamd.com/webui/>`_ that displays statistics
and history of past scans. **We do NOT recommend using it to change the configuration**
as doing so will override values from the configuration set in the previous sections.

The UI is served on the ``/var/run/rspamd/worker-controller.sock`` Unix socket. Here are
two ways to access it from your browser.

With ssh forwarding
^^^^^^^^^^^^^^^^^^^

For occasional access, the simplest way is to forward the socket to localhost and open
http://localhost:3333 in your browser.

.. code:: shell

  ssh -L 3333:/run/rspamd/worker-controller.sock $HOSTNAME

With an nginx reverse-proxy
^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you have a secured nginx reverse proxy set on the host, you can use it to expose the socket.
**Keep in mind the UI is unsecured by default, you need to setup an authentication scheme**, for
exemple with `basic auth <https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/>`_:

.. code:: nix

  services.nginx.virtualHosts.rspamd = {
    forceSSL = true;
    enableACME = true;
    basicAuthFile = "/basic/auth/hashes/file";
    serverName = "rspamd.example.com";
    locations = {
      "/" = {
        proxyPass = "http://unix:/run/rspamd/worker-controller.sock:/";
      };
    };
  };
