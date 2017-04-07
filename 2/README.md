# <a name="about"></a>About

This image contains an installation Elasticsearch 2.4.4.

For more information, see the [Official Image Launcher Page](https://console.cloud.google.com/launcher/details/google/elasticsearch).

Pull command:
```shell
gcloud docker -- pull launcher.gcr.io/google/elasticsearch2
```

Dockerfile for this image can be found [here](https://github.com/GoogleCloudPlatform/elasticsearch-docker/tree/master/2.4.4).

# <a name="table-of-contents"></a>Table of Contents
* [Using Kubernetes](#using-kubernetes)
  * [Running Elasticsearch](#running-elasticsearch-kubernetes)
    * [Start a Elasticsearch Instance](#start-a-elasticsearch-instance-kubernetes)
  * [Using Elasticsearch](#using-elasticsearch-kubernetes)
    * [Connect and start using elasticsearch.](#connect-and-start-using-elasticsearch-kubernetes)
  * [Adding persistence](#adding-persistence-kubernetes)
    * [Use a persistent data volume](#use-a-persistent-data-volume-kubernetes)
  * [Configurations](#configurations-kubernetes)
    * [Using configuration volume](#using-configuration-volume-kubernetes)
* [Using Docker](#using-docker)
  * [Running Elasticsearch](#running-elasticsearch-docker)
    * [Start a Elasticsearch Instance](#start-a-elasticsearch-instance-docker)
  * [Using Elasticsearch](#using-elasticsearch-docker)
    * [Connect and start using elasticsearch.](#connect-and-start-using-elasticsearch-docker)
  * [Adding persistence](#adding-persistence-docker)
    * [Use a persistent data volume](#use-a-persistent-data-volume-docker)
  * [Configurations](#configurations-docker)
    * [Using configuration volume](#using-configuration-volume-docker)
* [References](#references)
  * [Ports](#references-ports)
  * [Volumes](#references-volumes)

# <a name="using-kubernetes"></a>Using Kubernetes

## <a name="running-elasticsearch-kubernetes"></a>Running Elasticsearch

### <a name="start-a-elasticsearch-instance-kubernetes"></a>Start a Elasticsearch Instance

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
    - image: launcher.gcr.io/google/elasticsearch2
      name: elasticsearch
```

Run the following to expose the port:
```shell
kubectl expose pod some-elasticsearch --name some-elasticsearch-9200 \
  --type LoadBalancer --port 9200 --protocol TCP
```

## <a name="using-elasticsearch-kubernetes"></a>Using Elasticsearch

### <a name="connect-and-start-using-elasticsearch-kubernetes"></a>Connect and start using elasticsearch.

Attach to the container.

```shell
kubectl exec -it some-elasticsearch -- bash
```

To get data into elasticsearch we use the `curl` command. We must install curl as it's not installed by default.
```
apt-get update && apt-get install -y curl
```

Now we have curl installed, we can get test data into elasticsearch using a HTTP PUT request. This will populate elasticsearch with test data.
```
curl -XPUT http://localhost:9200/estest/test/1 -d \
'{
   "name" : "Elasticsearch Test",
   "Description": "This is just a test"
 }'
```

Now the data is in elasticsearch, we can search for it using `curl`.
```
curl http://localhost:9200/estest/_search?q=Test
```

## <a name="adding-persistence-kubernetes"></a>Adding persistence

The container is built with a default VOLUME of `/use/share/elasticsearch/data`. The data will survive a reboot but if the container is moved then the data will be lost.

To ensure the data is retained, we create a persistent data volume.

### <a name="use-a-persistent-data-volume-kubernetes"></a>Use a persistent data volume

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
    - image: launcher.gcr.io/google/elasticsearch2
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

Run the following to expose the port:
```shell
kubectl expose pod some-elasticsearch --name some-elasticsearch-9200 \
  --type LoadBalancer --port 9200 --protocol TCP
```

## <a name="configurations-kubernetes"></a>Configurations

### <a name="using-configuration-volume-kubernetes"></a>Using configuration volume

Elasticsearch gets configuration from `/usr/share/elasticsearch/config/elasticsearch.yml`. We can customize and tweak elasticsearch by creating a configuration VOLUME which will be read on container startup.

Create the following `configmap`:
```shell
kubectl create configmap elasticsearchconfig \
  --from-file=/path/to/your/elasticsearch/config/elasticsearch.yml
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
    - image: launcher.gcr.io/google/elasticsearch2
      name: elasticsearch
      volumeMounts:
        - name: elasticsearchconfig
          mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
  volumes:
    - name: elasticsearchconfig
      configMap:
        name: elasticsearchconfig
```

Run the following to expose the port:
```shell
kubectl expose pod some-elasticsearch --name some-elasticsearch-9200 \
  --type LoadBalancer --port 9200 --protocol TCP
```

See [Volume reference](#references-volumes) for more details.

# <a name="using-docker"></a>Using Docker

## <a name="running-elasticsearch-docker"></a>Running Elasticsearch

### <a name="start-a-elasticsearch-instance-docker"></a>Start a Elasticsearch Instance

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.
```yaml
version: '2'
services:
  elasticsearch:
    image: launcher.gcr.io/google/elasticsearch2
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-elasticsearch \
  -d \
  launcher.gcr.io/google/elasticsearch2
```

## <a name="using-elasticsearch-docker"></a>Using Elasticsearch

### <a name="connect-and-start-using-elasticsearch-docker"></a>Connect and start using elasticsearch.

Attach to the container.

```shell
docker exec -it some-elasticsearch bash
```

To get data into elasticsearch we use the `curl` command. We must install curl as it's not installed by default.
```
apt-get update && apt-get install -y curl
```

Now we have curl installed, we can get test data into elasticsearch using a HTTP PUT request. This will populate elasticsearch with test data.
```
curl -XPUT http://localhost:9200/estest/test/1 -d \
'{
   "name" : "Elasticsearch Test",
   "Description": "This is just a test"
 }'
```

Now the data is in elasticsearch, we can search for it using `curl`.
```
curl http://localhost:9200/estest/_search?q=Test
```

## <a name="adding-persistence-docker"></a>Adding persistence

The container is built with a default VOLUME of `/use/share/elasticsearch/data`. The data will survive a reboot but if the container is moved then the data will be lost.

To ensure the data is retained, we create a persistent data volume.

### <a name="use-a-persistent-data-volume-docker"></a>Use a persistent data volume

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.
```yaml
version: '2'
services:
  elasticsearch:
    image: launcher.gcr.io/google/elasticsearch2
    volumes:
      - /path/to/your/elasticsearch/data/directory:/usr/share/elasticsearch/data
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-elasticsearch \
  -v /path/to/your/elasticsearch/data/directory:/usr/share/elasticsearch/data \
  -d \
  launcher.gcr.io/google/elasticsearch2
```

## <a name="configurations-docker"></a>Configurations

### <a name="using-configuration-volume-docker"></a>Using configuration volume

Elasticsearch gets configuration from `/usr/share/elasticsearch/config/elasticsearch.yml`. We can customize and tweak elasticsearch by creating a configuration VOLUME which will be read on container startup.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.
```yaml
version: '2'
services:
  elasticsearch:
    image: launcher.gcr.io/google/elasticsearch2
    volumes:
      - /path/to/your/elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-elasticsearch \
  -v /path/to/your/elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
  -d \
  launcher.gcr.io/google/elasticsearch2
```

See [Volume reference](#references-volumes) for more details.

# <a name="references"></a>References

## <a name="references-ports"></a>Ports

These are the ports exposed by the container image.

| **Port** | **Description** |
|:---------|:----------------|
| TCP 9200 | Elasticsearch HTTP port. |
| TCP 9300 | Elasticsearch default communication port. |

## <a name="references-volumes"></a>Volumes

These are the filesystem paths used by the container image.

| **Path** | **Description** |
|:---------|:----------------|
| /usr/share/elasticsearch/data | Location to the VOLUME where the elasticsearch data lives. |
| /usr/share/elasticsearch/config/elasticsearch.yml | Location to the VOLUME where elasticsearch reads its configuration settings. |
