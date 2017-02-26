#!/usr/bin/perl
use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);
use JSON;
use strict;
use warnings;
use POSIX;
use Net::AMQP::RabbitMQ;
use Data::Printer;

my $mq = Net::AMQP::RabbitMQ->new();

$mq->connect($ENV{'RABBITMQ_HOST'}, { user => $ENV{'RABBITMQ_USER'}, password => $ENV{'RABBITMQ_PASSWORD'}, vhost => $ENV{'RABBITMQ_VHOST'}, port => $ENV{'RABBITMQ_PORT'} });

my $json = JSON->new->allow_nonref;

my $is = new Ham::APRS::IS('rotate.aprs.net:10152', 'W5ISP-13', 'appid' => 'aprs.me 0.0.1');
$is->connect('retryuntil' => 3) || die "Failed to connect: $is->{error}";

my $channel = 1;

$mq->channel_open($channel);
$mq->exchange_declare($channel, "aprs:messages", {exchange_type => 'topic'});
$mq->exchange_declare($channel, "aprs:archive", {exchange_type => 'direct', durable => 1});
$mq->queue_declare($channel, "aprs:archive", {durable => 1, auto_delete => 0});
$mq->queue_bind($channel, "aprs:messages", "aprs:archive", 1, {});

until (0)
{
  my $l = $is->getline_noncomment();
  next if (!defined $l);

  my %packetdata;
  my $retval = parseaprs($l, \%packetdata);
  my $keys;
  my $values;
  my $jsonpacket;

  if ($retval == 1)
  {
      $jsonpacket = $json->encode(\%packetdata);
      my $publish_key = "aprs." . $packetdata{srccallsign};
      $mq->publish($channel, $publish_key, $jsonpacket, { exchange => "aprs:messages" });
      $mq->publish($channel, $publish_key, $jsonpacket, { exchange => "aprs:archive", persistent => 1});
   }
   else
   {
     if (exists($packetdata{resultmsg})) {
       warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
     }
   }
}

$mq->disconnect();
$is->disconnect() || die "Failed to disconnect: $is->{error}";
