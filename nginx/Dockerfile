FROM nginx:1.15.1

RUN set -x \
	&& apt-get update \
	&& apt-get install -y openssl

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY setup-and-run.sh /setup-and-run.sh

CMD ["bash", "/setup-and-run.sh"]
