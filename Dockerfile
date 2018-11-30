FROM melopt/perl-carton-base

WORKDIR /app

CMD ["./wait-for-it.sh", "rabbitmq:5432", "--", "./aprs_slurp.pl"]
