# --- Build stage ---------------------------------------------------------
FROM golang:1.24-alpine AS build

WORKDIR /src

# Cache module downloads separately from source changes.
COPY go.mod ./
RUN go mod download

COPY . .

# VERSION is passed by CI (git SHA / image tag) and baked into the binary,
# so GET /version reports exactly which build is running.
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -trimpath \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/demo-app .

# --- Runtime stage --------------------------------------------------------
# distroless/static: no shell, no package manager, runs as nonroot (uid 65532).
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/demo-app /demo-app

EXPOSE 8080
ENTRYPOINT ["/demo-app"]
