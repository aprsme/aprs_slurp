#FROM melopt/perl-carton-base
FROM melopt/perl-alt:latest-build AS package_deps

FROM package_deps AS builder

### We copy all cpanfiles (this includes the optional cpanfile.snapshot)
### to the application directory, and we install the dependencies. Note
### that by default pdi-build-deps will install our apps dependencies
### under /deps. This is important later on.
COPY cpanfile* /app/
RUN cd /app && pdi-build-deps

### Copy the rest of the application to the app folder
COPY . /app/
COPY wait-for-it.sh /app/

### Now for the fourth and final stage, the runtime edition. We start from the
### runtime version and add all the files from the build phase
FROM melopt/perl-alt:latest-runtime

### Copy the App dependencies and the app code
COPY --from=builder /deps/ /deps/
COPY --from=builder /app/ /app/

WORKDIR /app

CMD ./aprs_slurp.pl
