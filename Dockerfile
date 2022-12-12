# build
FROM golang:1.19 as build

WORKDIR /go/src/app
COPY . .

RUN go mod download
RUN make build

# run
FROM gcr.io/distroless/static-debian11:nonroot
COPY --from=build /go/src/app/bin/server /
CMD ["/server"]
EXPOSE 8080
