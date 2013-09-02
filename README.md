# sentry

`sentry` is a server for monitoring and controlling physical access via GPIO on the back and SSL on the front.

## Client info

Each client must register an ssl certificate with the server.

One way to create an ssl key for client `foo`:

    openssl genrsa -out foo-privkey.pem 2048

Then you need to self-sign it, at least until we have our own certificate authority!

One way to self-sign:

    openssl req -new -x509 -days 1095 -key foo-privkey.pem -out foo-cert.pem -subj /UID=foo

The UserID (UID) field is used by the server for your client's id, so be sure to set it to what the sysadmins are expecting!

Once you have your certificate registered, assuming the sentry server is running on host `sentry.host.tld` on port `1234`, you can test connecting using `socat`:

    socat - ssl:sentry.host.tld:1234,cafile=sentry-cert.pem,cert=foo-cert.pem,key=foo-privkey.pem

If you sucessfully connect and receive a welcome message, you should be good to go!
