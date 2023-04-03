FROM golang:alpine as hivemind

RUN go install github.com/DarthSim/hivemind@v1.1.0

FROM golang:alpine as runner

WORKDIR /build

RUN apk add make

COPY . .

RUN make build

FROM golang:alpine as proxy

RUN apk add git

WORKDIR /build

RUN git clone https://github.com/JonasBak/autoscaler-proxy.git .

RUN go build .

FROM alpine

RUN apk add tmux

RUN mkdir /app /data && chown 10000:10000 /app /data

USER 10000

WORKDIR /data

RUN echo "gitea_runner: test -f .runner || act_runner register --instance \$GITEA_INSTANCE --token \$GITEA_TOKEN --no-interactive; DOCKER_HOST=tcp://127.0.0.1:8081 act_runner daemon" > /app/Procfile \
    && echo "proxy: autoscaler-proxy \$AUTOSCALER_OPTS" >> /app/Procfile

COPY --from=hivemind /go/bin/hivemind /usr/bin/hivemind
COPY --from=runner /build/act_runner /usr/bin/act_runner
COPY --from=proxy /build/autoscaler-proxy /usr/bin/autoscaler-proxy

ENTRYPOINT ["hivemind", "--root", "/data", "/app/Procfile"]
