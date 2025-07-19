# log

## first bench

- use golang
- expose port 81 for nginx cuz it conflicted with something else I'm unsure of. 81 worked so whatever.
- prepared bench command in [benchmarker/Makefile](./benchmarker/Makefile)

run first bench

```bach
$ make bench
docker run \
        --name benchmarker \
        --network host \
        --add-host host.docker.internal:host-gateway \
        -i private-isu-benchmarker \
        /bin/benchmarker -t http://host.docker.internal:81 -u /opt/userdata \
        | jq .
{
  "pass": true,
  "score": 0,
  "success": 584,
  "fail": 57,
  "messages": [
    "リクエストがタイムアウトしました (GET /)",
    "リクエストがタイムアウトしました (GET /@angel)",
    "リクエストがタイムアウトしました (GET /@beulah)",
    "リクエストがタイムアウトしました (GET /@deana)",
    "リクエストがタイムアウトしました (GET /@rowena)",
    "リクエストがタイムアウトしました (GET /@ursula)",
    "リクエストがタイムアウトしました (GET /posts)",
    "リクエストがタイムアウトしました (POST /login)",
    "リクエストがタイムアウトしました (POST /register)"
  ]
}
```

timed out with mysql using all if its CPU. Let the game begin.

```
$ docker stats
CONTAINER ID   NAME                      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O          BLOCK I/O        PIDS
ed12ceb19efd   private-isu-nginx-1       0.00%     4.988MiB / 15.58GiB   0.03%     169MB / 168MB    0B / 4.1kB       5
65bfba84cd5b   private-isu-app-1         1.15%     98.29MiB / 1GiB       9.60%     529MB / 177MB    0B / 0B          11
2175776172f8   private-isu-mysql-1       101.62%   600.9MiB / 1GiB       58.68%    16.4MB / 520MB   108MB / 52.6MB   50
6acb1df974e8   private-isu-memcached-1   0.02%     4.41MiB / 15.58GiB    0.03%     216kB / 170kB    0B / 0B          10
a270dd1e32cd   benchmarker               0.00%     6.941MiB / 15.58GiB   0.04%     0B / 0B          0B / 0B          7
```

## logging + profiling to see what's going on

- nginx json access log
- mysql log. + slow query log
- golang app with pprof

