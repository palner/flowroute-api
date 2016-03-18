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
# and DBI/DBD::mysql for DB operations.
#
use CGI ();
use JSON ();
use DBI;
use DBD::mysql;
use MIME::Lite;

#
# Declare variables
#
my ($status, $email, $input);

my $q = CGI->new;
my $json = JSON->new->utf8;
if ($q->param('POSTDATA')) {
   $input = $json->decode( $q->param('POSTDATA') );
} else {
   &SimpleJSONResponse("error","no JSON data found");
   exit(0);
}

#
# test that all sms values exist
# if not, return error
#

unless (($input->{to}) && ($input->{from}) && ($input->{body}) && ($input->{id})) {
   #
   # if we don't get the required fields from flowroute,
   # return an error
   #
   &SimpleJSONResponse("error","required fields not present");
} else {
   #
   # we received the required fields from flowroute
   # connect to database
   #
   my $data_source = q/DBI:mysql:database=flowroute;host=localhost/;
   my $user = q/USERNAME/;
   my $password = q/AWESOMEPASSWORD/;
   my $dbh = DBI->connect($data_source, $user, $password) or die &SimpleJSONResponse("error","cannot connect to db");

   #
   # run stored procedure add_sms
   # stores sms to database and returns the email address
   #
   my $sql = "call add_sms(?, ?, ?, ?)";
   my $sth = $dbh->prepare($sql) or die &SimpleJSONResponse("error","cannot prepare sql");
   $sth->execute( $input->{to}, $input->{from}, $input->{id}, $input->{body} );

   while ( my $row = $sth->fetchrow_arrayref() ) {
      my ($result) = @$row;
      if ($result) {
         $email = $result;
      } else {
         $email = "error";
      }
   }

   if ($email eq "fail") {
      #
      # procedure returned "fail"
      #
      &SimpleJSONResponse("error","unable to find did");
   } elsif ($email eq "error") {
      #
      # procedure did not return a response
      #
      &SimpleJSONResponse("error","unknown sql error");
   } else {
      #
      # procedure returned an email for the did
      # send a mail
      # change from email to something valid for you
      #
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
}

#
# Subroutines
#
sub SimpleJSONResponse() {
   my($key, $value) = @_;
   print $q->header(-type => "application/json", -charset => "utf-8");
   print $json->encode({ $key => $value });
}
