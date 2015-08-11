use Test::More;
use warnings;
use strict;

use Dancer qw/config debug set/;
use Business::PayPal::API::ExpressCheckout;

my $config = config->{paypal};

die unless defined $config;

my $ppapi  = Business::PayPal::API::ExpressCheckout->new(
    Username  => $config->{id},
    Password  => $config->{password},
    Signature => $config->{signature},
    sandbox   => $config->{sandbox},
);

my %pprequest = (
    OrderTotal      => 30,
    currencyID      => $config->{currencycode},
    ReturnURL       => $config->{returnurl},
    CancelURL       => $config->{cancelurl},
    BuyerEmail      => 'user@example.com',
    Address         => { Name => "Test User", PostalCode => 'xyz' },
    AddressOverride => 1,
);

debug \%pprequest;

my %ppresponse = $ppapi->SetExpressCheckout(%pprequest);

debug \%ppresponse;

my $pptoken = $ppresponse{Token};

