FROM golang:1.15.2
MAINTAINER Edward Rousseau <edward@rousseau.id.au>
RUN apt-get update && apt-get install -y jq
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT /entrypoint.sh