FROM golang:1.15.2
MAINTAINER Edward Rousseau <edward@rousseau.id.au>
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT /entrypoint.sh