#!/usr/bin/env perl
#
# Author: Fred Posner <fred@qxork.com>
# Twitter: @fredposner
# Contact: http://qxork.com
# Date: 2016-03-18
# Copyright: The Palner Group, Inc.
# License: GPLv3
#
use strict;
use warnings;

#
# need CGI, JSON,
# MIME::LITE for email,
#
use CGI ();
use JSON ();
use MIME::Lite;

#
# Declare variables
#
my ($status, $input);

#
# Where do you want to send the email?
#
my $email = "ME\@MYDOMAIN.ORG";

#
# receive and parse POSTDATA
#
my $q = CGI->new;
my $json = JSON->new->utf8;
if ($q->param('POSTDATA')) {
   $input = $json->decode( $q->param('POSTDATA') );
} else {
   &SimpleJSONResponse("error","no JSON data found");
   exit(0);
}

unless (($input->{to}) && ($input->{from}) && ($input->{body}) && ($input->{id})) {
   #
   # if we don't get the required fields from flowroute,
   # return an error
   #
   &SimpleJSONResponse("error","required fields not present");
} else {
   my $msg = MIME::Lite->new(
      From => "sms-no-reply\@DOMAIN",
      To => $email,
      Subject => "SMS Received",
      Data => "Sent to: " . $input->{to} . "\n\nSent from: " . $input->{from} . "\n\nSMS: " . $input->{body} . "\n\n"
   );

   MIME::Lite->send('smtp','localhost',Timeout=>60);
   $msg->send;

   &SimpleJSONResponse("success","message sent to $email");
}

#
# Subroutines
#
sub SimpleJSONResponse() {
   my($key, $value) = @_;
   print $q->header(-type => "application/json", -charset => "utf-8");
   print $json->encode({ $key => $value });
}
