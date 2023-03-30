FROM golang:alpine as overmind

RUN go install github.com/DarthSim/overmind/v2@v2.2.2

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

WORKDIR /app

RUN echo "gitea_runner: act_runner register --instance \$GITEA_INSTANCE --token \$GITEA_TOKEN --no-interactive; DOCKER_HOST=tcp://127.0.0.1:8081 act_runner daemon" > Procfile \
    && echo "proxy: autoscaler-proxy" >> Procfile

COPY --from=overmind /go/bin/overmind /usr/bin/overmind
COPY --from=runner /build/act_runner /usr/bin/act_runner
COPY --from=proxy /build/autoscaler-proxy /usr/bin/autoscaler-proxy

ENTRYPOINT ["overmind", "start"]
