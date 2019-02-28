# aprs_slurp, the trusty perl script

## Install Carton:

    $ sudo cpan -i Carton

## Install Dependencies:

    $ carton install


## Config
The script can be configured to connect to specific APRS-IS and RabbitMQ hosts

  * APRS_SERVER - the hostname:port of the APRS-IS server to connect to 
  * APRS_USERNAME - your APRS-IS username
  * RABBITMQ_HOST - rabbitmq hostname to connect to (default: 'localhost')
  * RABBITMQ_PORT - rabbitmq port to connect to (default: 5672)
  * RABBITMQ_USERNAME - rabbitmq username (default: 'guest')
  * RABBITMQ_PASSWORD - rabbitmq password (default: 'guest')
  * RABBITMQ_VHOST - rabbitmq vhost to publish to (default: 'aprs')

## Run it:

    $ carton exec ./aprs_slurp.pl

## Profit!
