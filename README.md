# NAME

Perl-Dancer-Conference - Perl Dancer Conference website

# MAPS

The maps are loaded by the Javascript in public/js/index.js.

# Geo::IP lookups

On a Debian system install the following packages:

```
geoip-bin libgeoip-dev geoip-database-contrib
```

and add the following Dancer environment:

```
geoip_database:
  city: /usr/share/GeoIP/GeoLiteCity.dat
  country4: /usr/share/GeoIP/GeoIP.dat
  country6: /usr/share/GeoIP/GeoIPv6.dat
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

