#!/bin/bash -e
#
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# support for prometheus-exporter 
( sleep 14; /prometheus-exporter/elasticsearch_exporter )  &

# Add elasticsearch as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- elasticsearch "$@"
fi

# Drop root privileges if we are running elasticsearch
# allow the container to be started with `--user`
if [ "$1" = 'elasticsearch' -a "$(id -u)" = '0' ]; then
	# Change the ownership of user-mutable directories to elasticsearch
	for path in \
		/usr/share/elasticsearch/data \
		/usr/share/elasticsearch/logs \
	; do
		chown -R elasticsearch:elasticsearch "$path"
	done
	set -- gosu elasticsearch "$@"
fi

# Parse all enviroment variables with .(dot), as option for Elasticsearch.
declare -a opts

while IFS='=' read -r key value; do
	if [[ "$key" =~ ^[a-z0-9_]+\.[a-z0-9_]+ ]]; then
		if [[ ! -z $value ]]; then
			opts+=("-E${key}=${value}")
		fi
	fi
done < <(env)

exec "$@" "${opts[@]}"
