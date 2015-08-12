package PerlDance::Routes::PayPal;

use Dancer ':syntax';
use Dancer::Plugin::Interchange6;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::FlashNote;
use Dancer::Plugin::Form;

use Try::Tiny;
use Data::Transpose::Validator;
use DateTime;
use Business::PayPal::API::ExpressCheckout;

use POSIX qw(strftime);

# Retrieve a token and send user to PayPal

post '/paypal/setrequest' => sub {
    my $amount = shop_cart->total;
    my $config = config->{paypal};
    my $ppapi = paypal_api($config);
    my $user = logged_in_user;
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

        flash error => 'Payment with PayPal failed. Please contact <a href="mailto:2015@perl.dance">2015@perl.dance</a> for assistance.';
        warning "No PayPal token: ", \%ppresponse;
        return redirect uri_for('cart');
    }
};

# Checkout response from PayPal

get '/paypal/getrequest' => sub {
    my $ppapi = paypal_api(config->{paypal});
    my $pptoken = session->{paypaltoken};
    my %details = $ppapi->GetExpressCheckoutDetails($pptoken);

    debug "Details for $pptoken: ", \%details;

    if ($details{Ack} eq 'Success') {
        my $user = logged_in_user;

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
                    first_name => $details{FirstName},
                    last_name => $details{LastName},
                });

                debug "Created new user with id ", $user->id, " for email $email";
            }
        }

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

        my %order_details = (first_name => $details{FirstName},
                             last_name => $details{LastName},
                             city => $details{CityName},
                         );

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

    # show error
    my $form = form('payment');

    return template 'checkout_confirm', {
        paypal_user => config->{email_id},
        form => $form,
        # bounce the error from the remote server into the form
        payment_error => "Payment error.",
        paypal_email => config->{paypal}->{email_id},
        paypal_return_url => request->base . 'paypal-complete',
        paypal_notify_url => request->base . 'paypal-notify',
        expand_credit_card_tab => undef,
    };
};

post '/paypal/maintenance' => sub {
    my %params = params('body');
    my %errors;
    my $form = form('paypal-maintenance');
    my $valid;
    my $validator = Data::Transpose::Validator->new;
    my $tokens = {form => $form};

    if ($params{form_submit}) {
        $validator->prepare(
            email => {
                required  => 1,
                validator => 'EmailValid'
            },
        );

        $valid = $validator->transpose( \%params );

        PerlDance::Routes::add_validator_errors_token( $validator,
                                                       $tokens );
    }

    if ($valid) {
        my $email = $params{email};

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

    template 'paypal_maintenance', $tokens;
};

sub complete_transaction {
	my ($user, $payment_method, $payment_id, $payment_status, $payment_mode, $country_iso_code, $order_details) = @_;

	my $date = DateTime->now;
	my $sum = shop_cart->total;

    debug "Completing transaction for user: ", ref($user);
    debug "Order details: ", $order_details;

    # create address
    my $address = schema->resultset('Address')->create({
        users_id => $user->id,
        city => $order_details->{city},
        country_iso_code => $country_iso_code,
    });

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
            to      => '2015@perl.dance',
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
