import smtplib, sys
import argparse
import os
import uuid
import imaplib
from datetime import datetime, timedelta
import email
import time

RETRY = 100

def _send_mail(smtp_host, smtp_port, from_addr, from_pwd, to_addr, subject, starttls):
    print("Sending mail with subject '{}'".format(subject))
    message = "\n".join([
        "From: {from_addr}",
        "To: {to_addr}",
        "Subject: {subject}",
        "",
        "This validates our mail server can send to Gmail :/"]).format(
            from_addr=from_addr,
            to_addr=to_addr,
            subject=subject)


    retry = RETRY
    while True:
        with smtplib.SMTP(smtp_host, port=smtp_port) as smtp:
            if starttls:
                smtp.starttls()
            if from_pwd is not None:
                smtp.login(from_addr, from_pwd)
            try:
                smtp.sendmail(from_addr, [to_addr], message)
                return
            except smtplib.SMTPResponseException as e:
                # This is a service unavailable error
                # In this situation, we want to retry.
                if e.smtp_code == 451:
                    if retry > 0:
                        retry = retry - 1
                        time.sleep(1)
                        continue
                    else:
                        print("Error while sending mail: %s" % e)
                        exit(5)
            except Exception as e:
                print("Error while sending mail: %s" % e)
                exit(4)

def _read_mail(
        imap_host,
        imap_port,
        imap_username,
        to_pwd,
        subject,
        ignore_dkim_spf,
        show_body=False,
        delete=True):
    print("Reading mail from %s" % imap_username)

    message = None

    obj = imaplib.IMAP4_SSL(imap_host, imap_port)
    obj.login(imap_username, to_pwd)
    obj.select()

    today = datetime.today()
    cutoff = today - timedelta(days=1)
    dt = cutoff.strftime('%d-%b-%Y')
    for _ in range(0, RETRY):
        print("Retrying")
        obj.select()
        typ, data = obj.search(None, '(SINCE %s) (SUBJECT "%s")'%(dt, subject))
        if data == [b'']:
            time.sleep(1)
            continue

        uids = data[0].decode("utf-8").split(" ")
        if len(uids) != 1:
          print("Warning: %d messages have been found with subject containing %s " % (len(uids), subject))

        # FIXME: we only consider the first matching message...
        uid = uids[0]
        _, raw = obj.fetch(uid, '(RFC822)')
        if delete:
            obj.store(uid, '+FLAGS', '\\Deleted')
            obj.expunge()
        message = email.message_from_bytes(raw[0][1])
        print("Message with subject '%s' has been found" % message['subject'])
        if show_body:
            for m in message.get_payload():
                if m.get_content_type() == 'text/plain':
                    print("Body:\n%s" % m.get_payload(decode=True).decode('utf-8'))
        break

    if message is None:
        print("Error: no message with subject '%s' has been found in INBOX of %s" % (subject, imap_username))
        exit(1)

    if ignore_dkim_spf:
        return

    # gmail set this standardized header
    if 'ARC-Authentication-Results' in message:
        if "dkim=pass" in message['ARC-Authentication-Results']:
            print("DKIM ok")
        else:
            print("Error: no DKIM validation found in message:")
            print(message.as_string())
            exit(2)
        if "spf=pass" in message['ARC-Authentication-Results']:
            print("SPF ok")
        else:
            print("Error: no SPF validation found in message:")
            print(message.as_string())
            exit(3)
    else:
        print("DKIM and SPF verification failed")
        exit(4)

def send_and_read(args):
    src_pwd = None
    if args.src_password_file is not None:
        src_pwd = args.src_password_file.readline().rstrip()
    dst_pwd = args.dst_password_file.readline().rstrip()

    if args.imap_username != '':
        imap_username = args.imap_username
    else:
        imap_username = args.to_addr

    subject = "{}".format(uuid.uuid4())

    _send_mail(smtp_host=args.smtp_host,
               smtp_port=args.smtp_port,
               from_addr=args.from_addr,
               from_pwd=src_pwd,
               to_addr=args.to_addr,
               subject=subject,
               starttls=args.smtp_starttls)

    _read_mail(imap_host=args.imap_host,
               imap_port=args.imap_port,
               imap_username=imap_username,
               to_pwd=dst_pwd,
               subject=subject,
               ignore_dkim_spf=args.ignore_dkim_spf)

def read(args):
    _read_mail(imap_host=args.imap_host,
               imap_port=args.imap_port,
               to_addr=args.imap_username,
               to_pwd=args.imap_password,
               subject=args.subject,
               ignore_dkim_spf=args.ignore_dkim_spf,
               show_body=args.show_body,
               delete=False)

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers()

parser_send_and_read = subparsers.add_parser('send-and-read', description="Send a email with a subject containing a random UUID and then try to read this email from the recipient INBOX.")
parser_send_and_read.add_argument('--smtp-host', type=str)
parser_send_and_read.add_argument('--smtp-port', type=str, default=25)
parser_send_and_read.add_argument('--smtp-starttls', action='store_true')
parser_send_and_read.add_argument('--from-addr', type=str)
parser_send_and_read.add_argument('--imap-host', required=True, type=str)
parser_send_and_read.add_argument('--imap-port', type=str, default=993)
parser_send_and_read.add_argument('--to-addr', type=str, required=True)
parser_send_and_read.add_argument('--imap-username', type=str, default='', help="username used for imap login. If not specified, the to-addr value is used")
parser_send_and_read.add_argument('--src-password-file', type=argparse.FileType('r'))
parser_send_and_read.add_argument('--dst-password-file', required=True, type=argparse.FileType('r'))
parser_send_and_read.add_argument('--ignore-dkim-spf', action='store_true', help="to ignore the dkim and spf verification on the read mail")
parser_send_and_read.set_defaults(func=send_and_read)

parser_read = subparsers.add_parser('read', description="Search for an email with a subject containing 'subject' in the INBOX.")
parser_read.add_argument('--imap-host', type=str, default="localhost")
parser_read.add_argument('--imap-port', type=str, default=993)
parser_read.add_argument('--imap-username', required=True, type=str)
parser_read.add_argument('--imap-password', required=True, type=str)
parser_read.add_argument('--ignore-dkim-spf', action='store_true', help="to ignore the dkim and spf verification on the read mail")
parser_read.add_argument('--show-body', action='store_true', help="print mail text/plain payload")
parser_read.add_argument('subject', type=str)
parser_read.set_defaults(func=read)

args = parser.parse_args()
args.func(args)
