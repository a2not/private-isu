# log

## first bench

- use golang
- expose port 81 for nginx cuz it conflicted with something else I'm unsure of. 81 worked so whatever.
- prepared bench command in benchmarker/Makefile

run first bench

```bach
$ make bench
docker run --network host --add-host host.docker.internal:host-gateway -i private-isu-benchmarker /bin/benchmarker -t http://host.docker.internal:81 -u /opt/userdata
{"pass":true,"score":0,"success":688,"fail":56,"messages":["リクエストがタイムアウトしました (GET /)","リクエストがタイムアウトしました (GET /@alice)","リクエストがタイム
アウトしました (GET /@evelyn)","リクエストがタイムアウトしました (POST /login)","リクエストがタイムアウトしました (POST /register)"]}
```

timed out with mysql using all if its CPU. Let the game begin.

```
$ docker stats
CONTAINER ID   NAME                      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O       PIDS
14151628ecb7   cranky_bouman             0.00%     6.801MiB / 15.58GiB   0.04%     0B / 0B           0B / 0B         8
ed12ceb19efd   private-isu-nginx-1       0.00%     4.957MiB / 15.58GiB   0.03%     50.4MB / 50.4MB   0B / 4.1kB      5
65bfba84cd5b   private-isu-app-1         0.94%     108.2MiB / 1GiB       10.57%    162MB / 53.1MB    0B / 0B         10
2175776172f8   private-isu-mysql-1       100.13%   540.5MiB / 1GiB       52.78%    5.21MB / 159MB    71.5MB / 30MB   52
6acb1df974e8   private-isu-memcached-1   0.01%     4.188MiB / 15.58GiB   0.03%     66.9kB / 53kB     0B / 0B         10
```

