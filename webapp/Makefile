pt-query-digest:
	cat ./logs/mysql/slow.log | docker run -i --rm matsuu/pt-query-digest > analyzed-slow.log

alp:
	alp json --file ./logs/nginx/access.log --reverse --sort=sum -m "/image/[0-9]+.(jpg|png|gif), /@[a-zA-Z]+, /posts/[0-9]+" > alp_analyzed_access.log
