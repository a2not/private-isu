start:
	docker compose up --build

start-from-scratch:
	docker compose down --volumes --remove-orphans
	docker compose up --build

clear-log:
	sudo chmod 777 -R ./logs
	> ./logs/mysql/slow.log
	> ./logs/nginx/access.log
	> ./logs/nginx/error.log

pt-query-digest:
	cat ./logs/mysql/slow.log | docker run -i --rm matsuu/pt-query-digest > analyzed-slow.log

alp:
	alp json --file ./logs/nginx/access.log --reverse --sort=sum -m "/image/[0-9]+.(jpg|png|gif), /@[a-zA-Z]+, /posts/[0-9]+" > alp_analyzed_access.log

pprof:
	pprof -proto -seconds 60 -output profile.pb.gz http://localhost:6060/debug/pprof/profile
