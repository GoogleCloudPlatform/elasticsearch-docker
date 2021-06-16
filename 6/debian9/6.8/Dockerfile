FROM gcr.io/google-appengine/openjdk

RUN set -ex; \
	if ! command -v gpg > /dev/null; then \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			gnupg \
			dirmngr \
		; \
		rm -rf /var/lib/apt/lists/*; \
	fi

# add gosu for easy step-down from root
ENV GOSU_VERSION 1.11

# prometheus exporter
ENV EXPORTER_VERSION 1.1.0

RUN set -x \
	&& wget -q -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -q -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
# copy source code
	&& wget -q -O /usr/local/src/gosu.tar.gz "https://github.com/tianon/gosu/archive/$GOSU_VERSION.tar.gz" \
# extract gosu binary and check signature
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found='' \
	&& for server in \
		pool.sks-keyservers.net \
		ha.pool.sks-keyservers.net \
		pgp.mit.edu \
		na.pool.sks-keyservers.net \
		eu.pool.sks-keyservers.net \
		oc.pool.sks-keyservers.net \
		ha.pool.sks-keyservers.net \
		hkp://p80.pool.sks-keyservers.net:80 \
		hkp://keyserver.ubuntu.com:80 \
	; do \
		gpg --no-tty --keyserver $server --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
		&& found="yes" && break; \
	done; test -n "$found" \
	&& gpg --no-tty --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

# Install Elastic Search
RUN set -ex; \
# https://artifacts.elastic.co/GPG-KEY-elasticsearch
	key='46095ACC8548582C1A2699A9D27D666CD88E42B4'; \
	export GNUPGHOME="$(mktemp -d)"; \
	found=''; \
	for server in \
		pool.sks-keyservers.net \
		ha.pool.sks-keyservers.net \
		pgp.mit.edu \
		na.pool.sks-keyservers.net \
		eu.pool.sks-keyservers.net \
		oc.pool.sks-keyservers.net \
		ha.pool.sks-keyservers.net \
		hkp://p80.pool.sks-keyservers.net:80 \
		hkp://keyserver.ubuntu.com:80 \
	; do \
		gpg --keyserver $server --recv-keys "$key" \
			&& found="yes" && break; \
	done; test -n "$found"; \
	gpg --export "$key" > /etc/apt/trusted.gpg.d/elastic.gpg; \
	rm -rf "$GNUPGHOME"; \
	apt-key list

# https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-repositories.html
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends apt-transport-https && rm -rf /var/lib/apt/lists/* \
	&& echo 'deb https://artifacts.elastic.co/packages/6.x/apt stable main' > /etc/apt/sources.list.d/elasticsearch.list

ENV ELASTICSEARCH_VERSION 6.8.15
ENV ELASTICSEARCH_DEB_VERSION 6.8.15

ENV C2D_RELEASE=${ELASTICSEARCH_VERSION}

# copy source code
RUN wget -q https://github.com/elastic/elasticsearch/archive/v6.8.15.tar.gz -O /usr/local/src/elasticsearch-source-v6.8.15.tar.gz

RUN set -x \
# don't allow the package to install its sysctl file (causes the install to fail)
# Failed to write '262144' to '/proc/sys/vm/max_map_count': Read-only file system
	&& dpkg-divert --rename /usr/lib/sysctl.d/elasticsearch.conf \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends "elasticsearch=$ELASTICSEARCH_DEB_VERSION" \
	&& rm -rf /var/lib/apt/lists/*

RUN set -ex \
        && wget -q -O elasticsearch_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz https://github.com/justwatchcom/elasticsearch_exporter/releases/download/v${EXPORTER_VERSION}/elasticsearch_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz \
        && wget -q -O /usr/src/elasticsearch_exporter-v$EXPORTER_VERSION.tar.gz https://github.com/justwatchcom/elasticsearch_exporter/archive/v${EXPORTER_VERSION}.tar.gz \
        && tar -xzf elasticsearch_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz \
        && mv elasticsearch_exporter-${EXPORTER_VERSION}.linux-amd64 prometheus-exporter \
        && rm -f elasticsearch_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz \
        && mkdir -p /usr/share/doc/elasticsearch_exporter \
        && cp /prometheus-exporter/LICENSE /usr/share/doc/elasticsearch_exporter/LICENSE

COPY licenses-sha256 /
RUN /bin/bash -c 'set -ex \
	OLDPWD=$(pwd) && \
	dir_prefix='/usr/share/doc' && \
	url_prefix='https://raw.githubusercontent.com/justwatchcom/elasticsearch_exporter/master/vendor/github.com' && \
	url_suffix=('prometheus/procfs/LICENSE' \
           'prometheus/common/internal/bitbucket.org/ww/goautoneg/README.txt' 'prometheus/client_model/LICENSE' \
           'prometheus/client_golang/LICENSE' 'matttproud/golang_protobuf_extensions/LICENSE' \
           'kr/logfmt/Readme' 'imdario/mergo/LICENSE' 'golang/protobuf/LICENSE' \
           'go-stack/stack/LICENSE.md' 'go-logfmt/logfmt/LICENSE' 'go-kit/kit/LICENSE' 'blang/semver/LICENSE' \
           'beorn7/perks/LICENSE' 'alecthomas/units/COPYING' 'alecthomas/template/LICENSE') && \
	license_volume=${#url_suffix[@]} && \
	license_dir=('alecthomas/template' 'alecthomas/units' \
           'beorn7/perks' 'blang/semver' \
           'go-kit/kit' 'golang/protobuf' 'go-logfmt/logfmt' \
           'go-stack/stack' 'imdario/mergo' 'kr/logfmt' \
           'matttproud/golang_protobuf_extensions' \
           'prometheus/client_golang' 'prometheus/client_model' \
           'prometheus/common/internal/bitbucket.org/ww/goautoneg' \
           'prometheus/procfs') && \
	mkdir -pv "$dir_prefix/kingpin.v2" && \
	cd $dir_prefix/kingpin.v2 && \
	wget -q https://gopkg.in/alecthomas/kingpin.v2/COPYING && \
	cd - && \
	mkdir -p $dir_prefix/prometheus/common && \
	cd $dir_prefix/prometheus/common && \
	wget -q https://github.com/prometheus/common/blob/main/LICENSE && \
	cd - && \
	for d in ${license_dir[@]}; do \
	  mkdir -p $dir_prefix/$d && \
	  if [[ $license_volume -ge 0 ]]; then \
	     for s in ${url_suffix[@]}; do \
	         if [[ $s =~ $d ]]; then \
	            cd $dir_prefix/$d && \
	            wget -q ${url_prefix}/${s} && \
	            cd - && \
	            break ; \
	         fi ; \
	     done \
	  fi && \
	  ((license_volume--)) ; \
	done && \
        sha256sum -c /licenses-sha256'

ENV PATH /usr/share/elasticsearch/bin:$PATH

WORKDIR /usr/share/elasticsearch

COPY config /etc/elasticsearch

RUN set -ex \
	&& for path in \
		./data \
		./logs \
		/etc/elasticsearch \
		/etc/elasticsearch/scripts \
		/usr/share/elasticsearch \
	; do \
		mkdir -p "$path"; \
		chown -R elasticsearch:elasticsearch "$path"; \
	done

RUN test ${C2D_RELEASE} = $(elasticsearch --version | cut -d' ' -f 2 | grep -o -E '([0-9]+\.)([0-9]+\.)([0-9]+)') \
         || { echo "Version check failed"; exit 1; }

VOLUME /usr/share/elasticsearch/data

COPY docker-entrypoint.sh /

# 9114 prometheus exporter port
EXPOSE 9114 9200 9300
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["elasticsearch"]
