# NAME

Perl-Dancer-Conference - Perl Dancer Conference website

# MAPS

The maps are loaded by the Javascript in public/js/index.js.

# Geo::IP lookups

On a Debian system install the following packages:

```
geoip-bin libgeoip-dev geoip-database-contrib
```

If your Dancer app is behind a proxy then you will also need:

```
  Plack::Middleware::XForwardedFor
```

and add environment something like:

```
plack_middlewares:
  -
    - XForwardedFor
    - trust
    -
      - 10.17.17.0/24
```

