FROM golang:1.25-alpine AS build
ARG VERSION=dev
WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=${VERSION}" -o /out/demo-app .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/demo-app /demo-app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/demo-app"]
