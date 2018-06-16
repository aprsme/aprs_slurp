#!/usr/bin/perl
use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);
use JSON;
use strict;
use warnings;
use POSIX;
use Net::AMQP::RabbitMQ;
use utf8;
use Encode qw( encode_utf8 );
#use Net::Statsd;

#$Net::Statsd::HOST = $ENV{'STATSD_HOST'} || "localhost";
#$Net::Statsd::PORT = $ENV{'STATSD_PORT'} || 8125;

my $mq = Net::AMQP::RabbitMQ->new();

my $rabbitmq_host = $ENV{'RABBITMQ_HOST'} || "localhost";
my $rabbitmq_user = $ENV{'RABBITMQ_USER'} || "guest";
my $rabbitmq_password = $ENV{'RABBITMQ_PASSWORD'} || "guest";
my $rabbitmq_vhost = $ENV{'RABBITMQ_VHOST'} || "aprs";
my $rabbitmq_port = $ENV{'RABBITMQ_PORT'} || 5672;
$mq->connect($rabbitmq_host, { user => $rabbitmq_user, password => $rabbitmq_password, vhost => $rabbitmq_vhost, port => $rabbitmq_port });

my $json = JSON->new->allow_nonref;

my $aprs_server = $ENV{'APRS_SERVER'} || "204.110.191.245:10152";
my $is = new Ham::APRS::IS($aprs_server, 'W5ISP-13', 'appid' => 'aprs.me 0.1.0');
$is->connect('retryuntil' => 3) || die "Failed to connect: $is->{error}";

p $is->{error};

my $channel = 1;

$mq->channel_open($channel);
$mq->exchange_declare($channel, "aprs:messages", {exchange_type => 'topic'});
$mq->queue_declare($channel, "aprs:archive", {durable => 1, auto_delete => 0});
$mq->queue_bind($channel, "aprs:archive", "aprs:messages", '#', {});

until (0)
{
  my $l = $is->getline_noncomment(1);
  if (!defined $l) {
    #Net::Statsd::increment('aprs.ingest.connectionlost');
    print "\n[no connection, reconnecting]\n";
    $is->disconnect();
    $is->connect('retryuntil' => 100);
    next;
  }

  my %packetdata;
  my $retval = parseaprs($l, \%packetdata);
  my $keys;
  my $values;
  my $jsonpacket;

  if ($retval == 1)
  {
      #Net::Statsd::increment('aprs.ingest.packets.valid');
      $jsonpacket = $json->encode(\%packetdata);
      my $publish_key = "aprs." . $packetdata{srccallsign};
      $mq->publish($channel, $publish_key, encode_utf8($jsonpacket), { exchange => "aprs:messages", persistent => 1});
   }
   else
   {
     if (exists($packetdata{resultmsg})) {
       #Net::Statsd::increment('aprs.ingest.packets.invalid');
       warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
     }
   }
}

$mq->disconnect();
$is->disconnect() || die "Failed to disconnect: $is->{error}";
