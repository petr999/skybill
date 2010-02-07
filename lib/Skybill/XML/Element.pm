#!/usr/bin/perl -w
package Skybill::XML::Element;
use strict;
use warnings;

use base qw/XML::LibXML::Element/;

sub new{
	my $self = shift;
	return bless $self->SUPER::new( @_ ), $self;
}

sub setAttribute{
	my ( $self, $name, $value ) = @_;
	$self->SUPER::setAttribute( $name, $value ) if defined $value;
}

1;
