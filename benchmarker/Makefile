all: bin/benchmarker

bin/benchmarker: *.go checker/*.go go.mod go.sum
	go build -o bin/benchmarker

bench:
	docker rm benchmarker
	docker run \
		--name benchmarker \
		--network host \
		--add-host host.docker.internal:host-gateway \
		-i private-isu-benchmarker \
		/bin/benchmarker -t http://host.docker.internal:81 -u /opt/userdata \
		| jq .
