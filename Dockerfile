FROM melopt/perl-carton-base

WORKDIR /app

CMD ./wait-for-it.sh $RABBITMQ_HOST:$RABBITMQ_PORT -- ./aprs_slurp.pl
