FROM melopt/perl-carton-base

WORKDIR /app

CMD ["carton", "exec", "./aprs_slurp.pl"]

