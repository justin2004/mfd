FROM debian:stretch
# maybe slim would work fine?

LABEL maintainer="Justin <justin2004@hotmail.com>"

WORKDIR /root

RUN set -x \
    && apt-get update \
    && apt-get install -y sbcl \
    && apt-get install -y wget \

    # i think the drakma library needs this
    && apt-get install -y libssl1.0.2

ADD install_it.lisp /root
ADD mfd.lisp        /root
ADD entry.lisp      /root

# TODO pgp verification
RUN wget 'https://beta.quicklisp.org/quicklisp.lisp'
RUN touch .sbclrc
RUN sbcl --load quicklisp.lisp --load install_it.lisp --eval '(quit)'

# TODO add a volume at /mnt ?


#STOPSIGNAL SIGTERM

CMD ["./entry.lisp", "--help"]
