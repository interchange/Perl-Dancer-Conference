package PerlDance::Routes::PayPal;

use Dancer2 appname => 'PerlDance';
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DataTransposeValidator;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Deferred;
use Dancer2::Plugin::TemplateFlute;

use Try::Tiny;
use DateTime;
use Business::PayPal::API::ExpressCheckout;

use POSIX qw(strftime);

# Retrieve a token and send user to PayPal

post '/paypal/setrequest' => sub {
    my $amount = shop_cart->total;
    my $config = config->{paypal};
    my $ppapi = paypal_api($config);
    my $user = schema->current_user;
    my $email;
    my $address;

    if ($user) {
        $email = $user->email;

        # address passed to PayPal
        $address = {
            Name => join(' ', $user->first_name, $user->last_name),
        };

        # check whether we have a primary address
        my $address_rs = $user->addresses({type => 'primary'});

        if ($address_rs->count) {
            my $user_address = $address_rs->first;

            # we need at least postal code and street address
            if ($user_address->postal_code && $user_address->address) {
                $address->{Street1} = $user_address->address;
                $address->{PostalCode} = $user_address->postal_code;
                $address->{CityName} = $user_address->city;
                $address->{Country} = $user_address->country_iso_code;
            }
        }
    };

    # for testing failures
    # $address->{PostalCode} = 'xyz';

    my %pprequest = (
                     OrderTotal    => $amount,
                     currencyID    => $config->{currencycode},
                     ReturnURL     => $config->{returnurl},
                     CancelURL     => $config->{cancelurl},
                     BuyerEmail    => $email,
                     Address       => $address,
                     AddressOverride => 1,
                    );

    debug "PayPal /setrequest request: ", to_dumper(\%pprequest);
    my %ppresponse = $ppapi->SetExpressCheckout(%pprequest);
    debug "PayPal /setrequest response: ", to_dumper(\%ppresponse);

    my $pptoken = $ppresponse{Token};

    # payment date to be stored in the database
    my %payment_data = (
        payment_mode => 'paypal',
        payment_action => 'setrequest',
        # not supported by Interchange6::Schema
        # currency => 'EUR',
        sessions_id => session->id,
        amount => $amount,
    );

    if ($pptoken) {
        session paypaltoken => $pptoken;

        # store in database
        $payment_data{status} = 'success';

        schema->resultset('PaymentOrder')->create(\%payment_data);

        # redirect to PayPal
        my $ppurl;

        if ($config->{sandbox}) {
            $ppurl = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout';
        }
        else {
            $ppurl = 'https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout';
        }

        $ppurl .= "&token=$ppresponse{Token}&useraction=commit";
        debug "Redirecting to PayPal: $ppurl.";

        return redirect $ppurl;
    }
    else {
        # store in database
        $payment_data{status} = 'failure';

        schema->resultset('PaymentOrder')->create(\%payment_data);

        my $conf_email = config->{conference_email};

        deferred error => qq{Payment with PayPal failed. Please contact <a href="mailto:$conf_email">$conf_email</a> for assistance.};
        warning "No PayPal token: ", \%ppresponse;
        return redirect uri_for('cart');
    }
};

# Checkout response from PayPal

get '/paypal/getrequest' => sub {
    my $ppapi = paypal_api(config->{paypal});
    my $pptoken = session('paypaltoken');
    my %details = $ppapi->GetExpressCheckoutDetails($pptoken);

    debug "Details for $pptoken: ", \%details;

    if ($details{Ack} eq 'Success') {
        my $user = schema->current_user;

        if (! $user) {
            # use email address passed from PayPal
            my $email = $details{Payer};
            my $username = lc($email);

            # check whether user already exists
            $user = schema->resultset('User')->find({
                username => $username,
            });

            if (! $user) {
                $user = schema->resultset('User')->create({
                    username => $username,
                    email => $email,
                    first_name => $details{FirstName} || '',
                    last_name => $details{LastName} || '',
                });



                debug "Created new user with id ", $user->id, " for email $email";
            }
        }
        $user->update_or_create_related('conferences_attended',
                                      {
                                       conferences_id => setting('conferences_id'),
                                       confirmed => 1,
                                      });

        ## now ask PayPal to xfer the money
        my $ppsum = shop_cart->total;
        my $total = $ppsum;

        my %payinfo = $ppapi->DoExpressCheckoutPayment(
            Token => $pptoken,
            PaymentAction => 'Sale',
            PayerID => $details{PayerID},
            currencyID => 'EUR',
            ItemTotal => $ppsum,
            OrderTotal => $total );

        debug "Pay info: ", \%payinfo;

        if ($payinfo{Ack} eq 'Failure') {
            # handle unexpected failure
            session cart_paypal_error => 1;
            warning "PayPal money transfer failed: ", \%payinfo;
            return redirect uri_for('cart');
        }

        # register successful payment
        debug "Paypal complete: ", $details{PayerID};

        my %order_details = (first_name => $details{FirstName} || '',
                             last_name => $details{LastName} || '',
                             city => $details{CityName} || '',
                             company => $details{PayerBusiness} || '',
                             address => $details{Street1} || '',
                             address_2 => $details{Street2} || '',
                             postal_code => $details{PostalCode} || '',
                            );

        # handle "Name", which is the name set for the delivery in
        # paypal unclear if it's the right thing to do, but this
        # record goes in addresses, not in users, so probably makes
        # sense.
        if ($details{Name} and $details{Name} =~ /\w/) {
            my ($first, $last) = split(' ', $details{Name}, 2);
            $order_details{first_name} = $first;
            $order_details{last_name} = $last;
        }
        debug "Order details: ", \%order_details;

        my $order = complete_transaction($user, 'PayPal', $details{PayerID} , 'paid', '', $details{Country}, \%order_details);
        my $date = strftime("%Y%m%d %H:%M:%S", localtime);

        # Record paypal payment
        my $payment = schema->resultset('PaymentOrder')->new({
            payment_mode => 'paypal',
            payment_action => 'charge',
            # not supported by Interchange6::Schema
            # currency => 'EUR',
            status => 'success',
            orders_id => $order->id,
            sessions_id =>  session->id,
            amount => $order->total_cost,
            payment_id => $details{PayerID},
        });
        $payment->insert;

        # flag order as recent one
        session order_receipt => $order->order_number;

        return redirect "/profile/orders/" . $order->order_number;
    }

    deferred error => "Sorry: the PayPal payment failed. Please contact us and we will do our best to help.";
    warning "PayPal error: ", \%details;
    redirect '/cart';
};

post '/paypal/maintenance' => sub {
    my $form = form('paypal-maintenance');
    my $data = validator( $form->values->as_hashref, 'email-valid' );

    if ( $data->{valid} ) {

        my $email = $data->{values}->{email};

        PerlDance::Routes::send_email(
                template => "email/paypal_maintenance",
                tokens   => {
                    email => $email,
                    cart => shop_cart(),
                },
                subject => "Request for payment from $email",
            );

        $form->reset;

        return template 'paypal_sent',
    }

    my $tokens = { data => $data, form => $form };
    template 'paypal_maintenance', $tokens;
};

get '/paypal/cancel' => sub {
    debug "Paypal cancelled";
    deferred info => "Payment with PayPal was cancelled";
    return redirect ('/cart');
};


sub complete_transaction {
	my ($user, $payment_method, $payment_id, $payment_status, $payment_mode, $country_iso_code, $order_details) = @_;

	my $date = DateTime->now;
	my $sum = shop_cart->total;

    debug "Completing transaction for user: ", ref($user);
    debug "Order details: ", $order_details;

    my %address_hash = (
                        users_id => $user->id,
                        country_iso_code => $country_iso_code,
                        %$order_details,
                       );
    debug to_dumper(\%address_hash);
    # create address
    my $address = schema->resultset('Address')->search(\%address_hash)->first ||
      schema->resultset('Address')->create(\%address_hash)->discard_changes;

    unless ($user->addresses->search({ type => 'primary' })->first) {
        debug "No primary address found, making this the primary one";
        $address->update({ type => 'primary'  });
    }

	# Transaction
	my $transactions = schema->resultset('Order')->create({
        users_id => $user->id,
        email => $user->email,
        order_number => '',
		subtotal => $sum, 
		total_cost => $sum,
		handling => 0,
		salestax => 0, 
		order_date => $date,
		payment_method => $payment_method,
        payment_number => $payment_id,
        payment_status => $payment_status,
        shipping_addresses_id => $address->id,
        billing_addresses_id => $address->id,
#		status => 'wird bearbeitet',
	});
    $transactions->discard_changes; # to get the code populated
    my $order_number = $transactions->orders_id;
    debug "Order number is $order_number";
    $transactions->order_number($order_number);

	$transactions->update;

	# Orderline
	my $item_number = 1;
	for my $item (cart->products_array){
		my $product = schema->resultset('Product')->find($item->sku);

		my $orderline = schema->resultset('Orderline')->new({
            orders_id => $transactions->id,
            order_position => $item_number,
			sku => $product->sku,
            name => $product->name,
            short_description => $product->short_description,
            description => $product->description,
			quantity => $item->quantity,
			price => $product->price,
            weight => $product->weight,
			subtotal => $product->price * $item->quantity,
            status => 'paid',
  		});
		$orderline->insert;
		$item_number += 1;

        # reduce inventory
        my $inventory = $product->inventory;

        if ($inventory) {
            $inventory->decrement($item->quantity);
        }
        else {
            warning "No inventory for product ", $product->sku;
        }
	}

	cart->clear;

	debug "Order $order_number added";
    debug "Notifying shop owner";
    PerlDance::Routes::send_email(
            template => "profile/order",
            tokens => {
                       order   => $transactions,
                       hide_profile_link => 1,
            },
            to      => setting("conference_email"),
            subject => setting("conference_name") . " Order $order_number",
        );
	return $transactions;
}

sub paypal_api {
    my $config = shift;

    Business::PayPal::API::ExpressCheckout->new (
        Username  => $config->{id},
        Password  => $config->{password},
        Signature => $config->{signature},
        sandbox   => $config->{sandbox},
    );
}
