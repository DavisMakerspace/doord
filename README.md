# sentry

This readme is a stub.

## clients

Each client must register an ssl certificate with the server.

One way to create an ssl key for client `foo`:

    openssl genrsa -out foo-privkey.pem 2048

Then you need to self-sign it, at least until we have our own certificate authority!

One way to self-sign:

    openssl req -new -x509 -days 1095 -key foo-privkey.pem -out foo-cert.pem -subj /UID=foo

The UserID (UID) field is used by the server for your client's id, so be sure to set it to what the sysadmins are expecting!
