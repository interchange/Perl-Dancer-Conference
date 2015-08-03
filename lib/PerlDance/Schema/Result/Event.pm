use utf8;

package PerlDance::Schema::Result::Event;

=head1 NAME

PerlDance::Schema::Result::Event - conference events such as "Lunch break",
"Lightning talks" or "Social event"

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 ACCESSORS

=head2 events_id

Primary key.

=cut

primary_column events_id => {
    data_type         => "integer",
    is_auto_increment => 1,
};

=head2 conferences_id

Conference.

FK on L<PerlDance::Schema::Result::Conference/conferencess_id> for
relation L</conference>.

=cut

column conferences_id => {
    data_type      => "integer",
    is_foreign_key => 1,
};

=head2 duration

Duration of the event in minutes.

=cut

column duration => { data_type => "smallint", };

=head2 title

Title of event.

=cut

column title => {
    data_type => "varchar",
    size      => 255,
};

=head2 abstract

Abstract of the event.

=cut

column abstract => {
    data_type     => "varchar",
    size          => 2048,
    default_value => '',
};

=head2 url

Event URL.

=cut

column url => {
    data_type     => "varchar",
    size          => 255,
    default_value => '',
};

=head2 start_time

L<DateTime> object representing start time of event.

Is nullable.

=cut

column start_time => {
    data_type => "datetime",
    is_nullable => 1,
};

=head2 room

The room/location for this event.

=cut

column room => {
    data_type     => "varchar",
    size          => 128,
    default_value => "",
};

=head1 METHODS

=head2 duration_display

If L</start_time> is defined returns a string with start and end times such as:

  09:00 - 13:00

Otherwise returns a duration string such as:

  40 minutes

=cut

sub duration_display {
    my $self = shift;
    if ( defined $self->start_time ) {
        return join( " - ",
            $self->start_time->strftime("%R"),
            $self->end_time->strftime("%R") );
    }
    else {
        return join(" ", $self->duration, "minutes");
    }
}

=head2 end_time

L<DateTime> object representing end time of event calculated from L</start_time>
and L</duration>.

=cut

sub end_time {
    my $self = shift;
    return undef unless defined $self->start_time;
    return $self->start_time->clone->add( minutes => $self->duration );
}

=head2 seo_uri

Returns a short uri comprised of L</events_id> and L</title> such as:

    23-lunch-break

=cut

sub seo_uri {
    my $self  = shift;
    my $title = lc( $self->title );
    $title =~ s/^\s+|\s+$//g;
    $title =~ s/\s+/-/g;
    return join( '-', $self->id, uri_escape_utf8($title) );
}

=head2 short_abstract

Returns a shortened (<= 200 char) version of L</abstract>.

=cut

sub short_abstract {
    my $self = shift;
    my $abstract = $self->abstract;
    return $abstract if length($abstract) <= 200;
    $abstract = substr($abstract, 0, 200);
    $abstract =~ s/\s+\S*$//;
    $abstract .= '...';
    return $abstract;
}

=head1 RELATIONS

=head2 conference

Type: belongs_to

Related object: L<PerlDance::Schema::Result::Conference>

=cut

belongs_to
  conference => 'PerlDance::Schema::Result::Conference', "conferences_id";

1;
