FROM golang:1.24-bookworm as builder
ARG SNOWFLAKE_REPO
ARG SNOWFLAKE_REPO_ANCHOR
ENV CGO_ENABLED=0
RUN git clone $SNOWFLAKE_REPO snowflake && cd snowflake && git checkout $SNOWFLAKE_REPO_ANCHOR
RUN cd snowflake/client && go get -d && go build -gcflags "all=-N -l" -o snowflake-client
RUN cd snowflake/proxy && go get -d && go build -gcflags "all=-N -l" -o snowflake-proxy
RUN cd snowflake/broker && go get -d && go build -gcflags "all=-N -l" -o snowflake-broker
RUN cd snowflake/server && go get -d && go build -gcflags "all=-N -l" -o snowflake-server
RUN go install github.com/gortc/stund@latest


FROM gcr.io/distroless/static as broker
COPY --from=builder /go/snowflake/broker/snowflake-broker /snowflake-broker
CMD /snowflake-broker


FROM gcr.io/distroless/static as proxy
COPY --from=builder /go/snowflake/proxy/snowflake-proxy /snowflake-proxy
CMD /snowflake-proxy

FROM gcr.io/distroless/static as server
COPY --from=builder /go/snowflake/server/snowflake-server /snowflake-server
CMD /snowflake-server

FROM containers.torproject.org/tpo/tpa/base-images/debian:stable as tor-server
RUN apt update -y && apt install -y apt-transport-tor curl wget gnupg
RUN echo 'deb [signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org bookworm main' > /etc/apt/sources.list.d/tor.list
RUN wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/deb.torproject.org-keyring.gpg >/dev/null
RUN apt update -y && apt install -y tor deb.torproject.org-keyring
COPY --from=builder /go/snowflake/server/snowflake-server /snowflake-server
COPY torrc /torrc

CMD /usr/bin/tor -f /torrc


# Maybe try in the future: https://github.com/lipanski/docker-static-website

FROM busybox:latest as fileserver

COPY --from=builder /go/snowflake/client/snowflake-client /www/snowflake-client
COPY --from=builder /go/snowflake/broker/snowflake-broker /www/snowflake-broker
COPY --from=builder /go/snowflake/proxy/snowflake-proxy /www/snowflake-proxy
COPY --from=builder /go/snowflake/server/snowflake-server /www/snowflake-server
COPY --from=builder /go/bin/stund /www/stund

CMD ["httpd", "-p", "80" ,"-h", "/www", "-f"]
