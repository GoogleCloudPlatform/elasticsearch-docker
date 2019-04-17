# <a name="about"></a>About

This image contains an installation Elasticsearch 5.x.

For more information, see the [Official Image Launcher Page](https://console.cloud.google.com/launcher/details/google/elasticsearch5).

Pull command (first install [gcloud](https://cloud.google.com/sdk/downloads)):

```shell
gcloud docker -- pull launcher.gcr.io/google/elasticsearch5
```

Dockerfile for this image can be found [here](https://github.com/GoogleCloudPlatform/elasticsearch-docker/tree/master/5).

# <a name="table-of-contents"></a>Table of Contents
* [Using Kubernetes](#using-kubernetes)
  * [Run Elasticsearch](#run-elasticsearch-kubernetes)
    * [Start an Elasticsearch instance](#start-an-elasticsearch-instance-kubernetes)
    * [Use a persistent data volume](#use-a-persistent-data-volume-kubernetes)
  * [Using Elasticsearch](#using-elasticsearch-kubernetes)
    * [Connect and start using Elasticsearch](#connect-and-start-using-elasticsearch-kubernetes)
  * [Configurations](#configurations-kubernetes)
    * [Using configuration volume](#using-configuration-volume-kubernetes)
* [Using Docker](#using-docker)
  * [Run Elasticsearch](#run-elasticsearch-docker)
    * [Start an Elasticsearch instance](#start-an-elasticsearch-instance-docker)
    * [Use a persistent data volume](#use-a-persistent-data-volume-docker)
  * [Using Elasticsearch](#using-elasticsearch-docker)
    * [Connect and start using Elasticsearch](#connect-and-start-using-elasticsearch-docker)
  * [Configurations](#configurations-docker)
    * [Using configuration volume](#using-configuration-volume-docker)
  * [Clustering](#clustering-docker)
    * [Creating simple cluster](#creating-simple-cluster-docker)
* [References](#references)
  * [Ports](#references-ports)
  * [Volumes](#references-volumes)

# <a name="using-kubernetes"></a>Using Kubernetes

Consult [Launcher container documentation](https://cloud.google.com/launcher/docs/launcher-container)
for additional information about setting up your Kubernetes environment.

## <a name="run-elasticsearch-kubernetes"></a>Run Elasticsearch

### <a name="start-an-elasticsearch-instance-kubernetes"></a>Start an Elasticsearch instance

Copy the following content to `pod.yaml` file, and run `kubectl create -f pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: some-elasticsearch
  labels:
    name: some-elasticsearch
spec:
  containers:
    - image: launcher.gcr.io/google/elasticsearch5
      name: elasticsearch
```

Run the following to expose the port.
Depending on your cluster setup, this might expose your service to the
Internet with an external IP address. For more information, consult
[Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/).

```shell
kubectl expose pod some-elasticsearch --name some-elasticsearch-9200 \
  --type LoadBalancer --port 9200 --protocol TCP
```

Elasticsearch host requires configured enviroment. On Linux host please run `sysctl -w vm.max_map_count=262144`. For details please check [official documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html).

To retain Elasticsearch data across container restarts, see [Use a persistent data volume](#use-a-persistent-data-volume-kubernetes).

To configure your application, see [Configurations](#configurations-kubernetes).

### <a name="use-a-persistent-data-volume-kubernetes"></a>Use a persistent data volume

To retain Elasticsearch data across container restarts, we should use a persistent volume for `/usr/share/elasticsearch/data`.

Copy the following content to `pod.yaml` file, and run `kubectl create -f pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: some-elasticsearch
  labels:
    name: some-elasticsearch
spec:
  containers:
    - image: launcher.gcr.io/google/elasticsearch5
      name: elasticsearch
      volumeMounts:
        - name: elasticsearchdata
          mountPath: /usr/share/elasticsearch/data
  volumes:
    - name: elasticsearchdata
      persistentVolumeClaim:
        claimName: elasticsearchdata
---
# Request a persistent volume from the cluster using a Persistent Volume Claim.
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: elasticsearchdata
  annotations:
    volume.alpha.kubernetes.io/storage-class: default
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 5Gi
```

Run the following to expose the port.
Depending on your cluster setup, this might expose your service to the
Internet with an external IP address. For more information, consult
[Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/).

```shell
kubectl expose pod some-elasticsearch --name some-elasticsearch-9200 \
  --type LoadBalancer --port 9200 --protocol TCP
```

## <a name="using-elasticsearch-kubernetes"></a>Using Elasticsearch

### <a name="connect-and-start-using-elasticsearch-kubernetes"></a>Connect and start using Elasticsearch

Attach to the container.

```shell
kubectl exec -it some-elasticsearch -- bash
```

The following examples use `curl`. First we need to install it as it is not installed by default.

```
apt-get update && apt-get install -y curl
```

We can get test data into Elasticsearch using a HTTP PUT request. This will populate Elasticsearch with test data.

```
curl -XPUT http://localhost:9200/estest/test/1 -d \
'{
   "name" : "Elasticsearch Test",
   "Description": "This is just a test"
 }'
```

We can try searching for our test data using `curl`.

```
curl http://localhost:9200/estest/_search?q=Test
```

## <a name="configurations-kubernetes"></a>Configurations

### <a name="using-configuration-volume-kubernetes"></a>Using configuration volume

Assume `/path/to/your/elasticsearch.yml` is the configuration file on your localhost. We can mount this as volume at `/usr/share/elasticsearch/config/elasticsearch.yml` on the container for Elasticsearch to read from.

Create the following `configmap`:

```shell
kubectl create configmap elasticsearchconfig \
  --from-file=/path/to/your/elasticsearch.yml
```

Copy the following content to `pod.yaml` file, and run `kubectl create -f pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: some-elasticsearch
  labels:
    name: some-elasticsearch
spec:
  containers:
    - image: launcher.gcr.io/google/elasticsearch5
      name: elasticsearch
      volumeMounts:
        - name: elasticsearchconfig
          mountPath: /usr/share/elasticsearch/config
  volumes:
    - name: elasticsearchconfig
      configMap:
        name: elasticsearchconfig
```

Run the following to expose the port.
Depending on your cluster setup, this might expose your service to the
Internet with an external IP address. For more information, consult
[Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/).

```shell
kubectl expose pod some-elasticsearch --name some-elasticsearch-9200 \
  --type LoadBalancer --port 9200 --protocol TCP
```

See [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html) on available configuration options.

Also see [Volume reference](#references-volumes).

# <a name="using-docker"></a>Using Docker

Consult [Launcher container documentation](https://cloud.google.com/launcher/docs/launcher-container)
for additional information about setting up your Docker environment.

## <a name="run-elasticsearch-docker"></a>Run Elasticsearch

### <a name="start-an-elasticsearch-instance-docker"></a>Start an Elasticsearch instance

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.

```yaml
version: '2'
services:
  elasticsearch:
    container_name: some-elasticsearch
    image: launcher.gcr.io/google/elasticsearch5
    ports:
      - '9200:9200'
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-elasticsearch \
  -p 9200:9200 \
  -d \
  launcher.gcr.io/google/elasticsearch5
```

Elasticsearch host requires configured enviroment. On Linux host please run `sysctl -w vm.max_map_count=262144`. For details please check [official documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html).

To retain Elasticsearch data across container restarts, see [Use a persistent data volume](#use-a-persistent-data-volume-docker).

To configure your application, see [Configurations](#configurations-docker).

### <a name="use-a-persistent-data-volume-docker"></a>Use a persistent data volume

To retain Elasticsearch data across container restarts, we should use a persistent volume for `/usr/share/elasticsearch/data`.

Assume `/path/to/your/elasticsearch/data` is a persistent data folder on your host.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.

```yaml
version: '2'
services:
  elasticsearch:
    container_name: some-elasticsearch
    image: launcher.gcr.io/google/elasticsearch5
    ports:
      - '9200:9200'
    volumes:
      - /path/to/your/elasticsearch/data:/usr/share/elasticsearch/data
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-elasticsearch \
  -p 9200:9200 \
  -v /path/to/your/elasticsearch/data:/usr/share/elasticsearch/data \
  -d \
  launcher.gcr.io/google/elasticsearch5
```

## <a name="using-elasticsearch-docker"></a>Using Elasticsearch

### <a name="connect-and-start-using-elasticsearch-docker"></a>Connect and start using Elasticsearch

Attach to the container.

```shell
docker exec -it some-elasticsearch bash
```

The following examples use `curl`. First we need to install it as it is not installed by default.

```
apt-get update && apt-get install -y curl
```

We can get test data into Elasticsearch using a HTTP PUT request. This will populate Elasticsearch with test data.

```
curl -XPUT http://localhost:9200/estest/test/1 -d \
'{
   "name" : "Elasticsearch Test",
   "Description": "This is just a test"
 }'
```

We can try searching for our test data using `curl`.

```
curl http://localhost:9200/estest/_search?q=Test
```

## <a name="configurations-docker"></a>Configurations

### <a name="using-configuration-volume-docker"></a>Using configuration volume

Assume `/path/to/your/elasticsearch.yml` is the configuration file on your localhost. We can mount this as volume at `/usr/share/elasticsearch/config/elasticsearch.yml` on the container for Elasticsearch to read from.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.

```yaml
version: '2'
services:
  elasticsearch:
    container_name: some-elasticsearch
    image: launcher.gcr.io/google/elasticsearch5
    ports:
      - '9200:9200'
    volumes:
      - /path/to/your/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-elasticsearch \
  -p 9200:9200 \
  -v /path/to/your/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
  -d \
  launcher.gcr.io/google/elasticsearch5
```

See [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html) on available configuration options.

Also see [Volume reference](#references-volumes).

## <a name="clustering-docker"></a>Clustering

### <a name="creating-simple-cluster-docker"></a>Creating simple cluster

In the following guide you will learn how to create simple two-node Elasticsearch cluster. This is only an example how to configure and link together containers, not a production ready configuration. For production ready configuration please refer to official documentation.

We will need a master node, that will also serve as a gateway to our cluster. Single slave node will be attached to the master node.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.

```yaml
version: '2'
services:
  elasticsearch-master:
    container_name: some-elasticsearch-master
    image: launcher.gcr.io/google/elasticsearch5
    ports:
      - '9200:9200'
    command:
      - '-Enetwork.host=0.0.0.0'
      - '-Etransport.tcp.port=9300'
      - '-Ehttp.port=9200'
  elasticsearch-slave:
    container_name: some-elasticsearch-slave
    image: launcher.gcr.io/google/elasticsearch5
    command:
      - '-Enetwork.host=0.0.0.0'
      - '-Etransport.tcp.port=9300'
      - '-Ehttp.port=9200'
      - '-Ediscovery.zen.ping.unicast.hosts=some-elasticsearch-master'
    depends_on:
      - elasticsearch-master
```

Or you can use `docker run` directly:

```shell
# elasticsearch-master
docker run \
  --name some-elasticsearch-master \
  -p 9200:9200 \
  -d \
  launcher.gcr.io/google/elasticsearch5 \
  -Enetwork.host=0.0.0.0 \
  -Etransport.tcp.port=9300 \
  -Ehttp.port=9200

# elasticsearch-slave
docker run \
  --name some-elasticsearch-slave \
  --link some-elasticsearch-master \
  -d \
  launcher.gcr.io/google/elasticsearch5 \
  -Enetwork.host=0.0.0.0 \
  -Etransport.tcp.port=9300 \
  -Ehttp.port=9200 \
  -Ediscovery.zen.ping.unicast.hosts=some-elasticsearch-master
```

After few seconds, we can check that cluster is running invoking `http://localhost:9200/_cluster/health`.

# <a name="references"></a>References

## <a name="references-ports"></a>Ports

These are the ports exposed by the container image.

| **Port** | **Description** |
|:---------|:----------------|
| TCP 9114 | Prometheus exporter port |
| TCP 9200 | Elasticsearch HTTP port. |
| TCP 9300 | Elasticsearch default communication port. |

## <a name="references-volumes"></a>Volumes

These are the filesystem paths used by the container image.

| **Path** | **Description** |
|:---------|:----------------|
| /usr/share/elasticsearch/data | Stores Elasticsearch data. |
| /usr/share/elasticsearch/config/elasticsearch.yml | Stores configurations. |
| /usr/share/elasticsearch/config/log4j2.properties | Stores logging configurations. |
