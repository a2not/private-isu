# log

## first bench (score: 0)

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

## logging + profiling to see what's going on (score: 0)

- nginx json access log
- mysql log. + slow query log
- golang app with pprof

## analyze MySQL slow query w/ pt-query-digest (score: 29414)

```
make pt-query-digest
```

in `./webapp/analyzed-slow.log`

```
Reading from STDIN ...

# 5s user time, 90ms system time, 1.00k rss, 36.00k vsz
# Current date: Sat Jul 19 12:09:33 2025
# Hostname: d0b3e9bc38b7
# Files: STDIN
# Overall: 93.58k total, 26 unique, 6.40 QPS, 0.41x concurrency __________
# Time range: 2025-07-19T07:12:20 to 2025-07-19T11:15:58
# Attribute          total     min     max     avg     95%  stddev  median
# ============     ======= ======= ======= ======= ======= ======= =======
# Exec time          5936s     1us      7s    63ms   293ms   339ms    27us
# Lock time           37ms       0     2ms       0     1us    10us       0
# Rows sent          1.94M       0   9.77k   21.72    2.90  440.07       0
# Rows examine     956.42M       0  97.68k  10.47k  97.04k  29.95k       0
# Query size         3.69M      17 132.31k   41.36   80.10  652.73   31.70

# Profile
# Rank Query ID                            Response time   Calls R/Call V/
# ==== =================================== =============== ===== ====== ==
#    1 0x624863D30DAC59FA16849282195BE09F  4199.2965 70.7%  4812 0.8727  1.45 SELECT comments
#    2 0x422390B42D4DD86C7539A5F45EB76A80  1534.0183 25.8%  4948 0.3100  0.61 SELECT comments
#    3 0x4858CF4D8CAA743E839C127C71B69E75    73.9858  1.2%   195 0.3794  0.80 SELECT posts
#    6 0xCDEB1AFF2AE2BE51B2ED5CF03D4E749F    16.2993  0.3%    42 0.3881  1.04 SELECT comments
# MISC 0xMISC                               111.9490  1.9% 83579 0.0013   0.0 <22 ITEMS>

# Query 1: 0.33 QPS, 0.29x concurrency, ID 0x624863D30DAC59FA16849282195BE09F at byte 20879042
# This item is included in the report because it matches --limit.
# Scores: V/M = 1.45
# Time range: 2025-07-19T07:12:21 to 2025-07-19T11:15:58
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count          5    4812
# Exec time     70   4199s    28ms      7s   873ms      4s      1s   412ms
# Lock time     18     7ms       0   573us     1us     3us     9us     1us
# Rows sent      0  13.56k       0       3    2.89    2.90    0.55    2.90
# Rows examine  47 458.93M  97.66k  97.66k  97.66k  97.04k       0  97.04k
# Query size    10 385.66k      79      83   82.07   80.10    0.13   80.10
# String:
# Databases    isuconp
# Hosts        private-isu-app-1.private-isu_my_network
# Users        root
# Query_time distribution
#   1us
#  10us
# 100us
#   1ms
#  10ms  ################
# 100ms  ################################################################
#    1s  #######################
#  10s+
# Tables
#    SHOW TABLE STATUS FROM `isuconp` LIKE 'comments'\G
#    SHOW CREATE TABLE `isuconp`.`comments`\G
# EXPLAIN /*!50100 PARTITIONS*/
SELECT * FROM `comments` WHERE `post_id` = 9995 ORDER BY `created_at` DESC LIMIT 3\G
```

Let's add an index to the slowest query.

```sql
ALTER TABLE `comments` ADD INDEX `comments_post_id_created_at` (`post_id`, `created_at`);
```

bench
```
{
  "pass": true,
  "score": 29414,
  "success": 27552,
  "fail": 0,
  "messages": []
}
```

Why not persists this fix with docker compose. How can I do that?

Turns out MySQL docker image looks into `/docker-entrypoint-initdb.d` directory on startup for initializing shell scripts and/or sql scripts.

To be precise, it only looks for scripts only when `/var/lib/mysql` does not exist.

So we need to delete the volume and start over again which is a bit time consuming, but it works so I just put the sql script under `./webapp/sql` since it's already mounted to `/docker-entrypoint-initdb.d`.

(TODO: Find a better way to run shell/sql scripts against MySQL container on the fly.)

```bash
cd webapp
docker compose down --volume
docker compose up # it takes 2~3 mins to load dump.sql.bz2
```

## analyze nginx access log w/ alp

in `./webapp/alp_analyzed_access.log`

```
+-------+-----+-------+-----+-----+-----+--------+-----------------------------+-------+-------+---------+-------+-------+-------+-------+--------+-----------+-------------+----------------+------------+
| COUNT | 1XX |  2XX  | 3XX | 4XX | 5XX | METHOD |             URI             |  MIN  |  MAX  |   SUM   |  AVG  |  P90  |  P95  |  P99  | STDDEV | MIN(BODY) |  MAX(BODY)  |   SUM(BODY)    | AVG(BODY)  |
+-------+-----+-------+-----+-----+-----+--------+-----------------------------+-------+-------+---------+-------+-------+-------+-------+--------+-----------+-------------+----------------+------------+
| 984   | 0   | 984   | 0   | 0   | 0   | GET    | /                           | 0.045 | 0.461 | 189.478 | 0.193 | 0.268 | 0.301 | 0.359 | 0.058  | 4007.000  | 36356.000   | 19480777.000   | 19797.538  |
| 14535 | 0   | 14535 | 0   | 0   | 0   | GET    | /image/[0-9]+.(jpg|png|gif) | 0.000 | 0.128 | 153.097 | 0.011 | 0.023 | 0.030 | 0.047 | 0.010  | 34400.000 | 1134143.000 | 4372291853.000 | 300811.273 |
| 200   | 0   | 200   | 0   | 0   | 0   | GET    | /posts                      | 0.044 | 0.586 | 57.258  | 0.286 | 0.405 | 0.453 | 0.515 | 0.088  | 33905.000 | 35013.000   | 6889805.000    | 34449.025  |
| 1427  | 0   | 1427  | 0   | 0   | 0   | GET    | /posts/[0-9]+               | 0.003 | 0.170 | 47.192  | 0.033 | 0.062 | 0.074 | 0.105 | 0.022  | 1639.000  | 6592.000    | 5378202.000    | 3768.887   |
| 245   | 0   | 245   | 0   | 0   | 0   | GET    | /@[a-zA-Z]+                 | 0.039 | 0.453 | 42.941  | 0.175 | 0.262 | 0.302 | 0.413 | 0.069  | 6206.000  | 35296.000   | 4526118.000    | 18473.951  |
| 731   | 0   | 0     | 731 | 0   | 0   | POST   | /login                      | 0.001 | 0.116 | 28.176  | 0.039 | 0.068 | 0.078 | 0.096 | 0.021  | 0.000     | 0.000       | 0.000          | 0.000      |
| 206   | 0   | 0     | 103 | 103 | 0   | POST   | /                           | 0.001 | 0.219 | 6.875   | 0.033 | 0.084 | 0.114 | 0.153 | 0.037  | 0.000     | 0.000       | 0.000          | 0.000      |
| 124   | 0   | 0     | 124 | 0   | 0   | POST   | /register                   | 0.009 | 0.107 | 6.056   | 0.049 | 0.074 | 0.085 | 0.095 | 0.018  | 0.000     | 0.000       | 0.000          | 0.000      |
| 1715  | 0   | 1715  | 0   | 0   | 0   | GET    | /favicon.ico                | 0.001 | 0.047 | 4.050   | 0.002 | 0.005 | 0.009 | 0.024 | 0.004  | 43.000    | 43.000      | 73745.000      | 43.000     |
| 1715  | 0   | 1715  | 0   | 0   | 0   | GET    | /css/style.css              | 0.000 | 0.044 | 3.436   | 0.002 | 0.005 | 0.007 | 0.023 | 0.004  | 1549.000  | 1549.000    | 2656535.000    | 1549.000   |
| 1715  | 0   | 1715  | 0   | 0   | 0   | GET    | /js/timeago.min.js          | 0.000 | 0.044 | 3.248   | 0.002 | 0.004 | 0.007 | 0.019 | 0.004  | 1915.000  | 1915.000    | 3284225.000    | 1915.000   |
| 1715  | 0   | 1715  | 0   | 0   | 0   | GET    | /js/main.js                 | 0.000 | 0.043 | 3.247   | 0.002 | 0.004 | 0.006 | 0.020 | 0.003  | 1824.000  | 1824.000    | 3128160.000    | 1824.000   |
| 128   | 0   | 0     | 128 | 0   | 0   | POST   | /comment                    | 0.002 | 0.060 | 1.979   | 0.015 | 0.028 | 0.031 | 0.041 | 0.009  | 0.000     | 0.000       | 0.000          | 0.000      |
| 182   | 0   | 182   | 0   | 0   | 0   | GET    | /login                      | 0.001 | 0.048 | 0.950   | 0.005 | 0.011 | 0.015 | 0.036 | 0.006  | 1290.000  | 1290.000    | 234780.000     | 1290.000   |
| 124   | 0   | 0     | 0   | 124 | 0   | GET    | /admin/banned               | 0.001 | 0.037 | 0.800   | 0.006 | 0.014 | 0.018 | 0.031 | 0.006  | 0.000     | 0.000       | 0.000          | 0.000      |
| 91    | 0   | 0     | 91  | 0   | 0   | GET    | /logout                     | 0.001 | 0.023 | 0.406   | 0.004 | 0.010 | 0.015 | 0.023 | 0.005  | 24.000    | 24.000      | 2184.000       | 24.000     |
| 1     | 0   | 1     | 0   | 0   | 0   | GET    | /initialize                 | 0.331 | 0.331 | 0.331   | 0.331 | 0.331 | 0.331 | 0.331 | 0.000  | 0.000     | 0.000       | 0.000          | 0.000      |
+-------+-----+-------+-----+-----+-----+--------+-----------------------------+-------+-------+---------+-------+-------+-------+-------+--------+-----------+-------------+----------------+------------+
```

static file serving is kinda slow. Let's use nginx to serve static files.

to be continued.
