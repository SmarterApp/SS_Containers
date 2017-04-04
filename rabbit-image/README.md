# RabbitMQ Cluster Image
This docker image definition provides a RabbitMQ Server cluster for use in Kubernetes.  It is designed to be used in a
Kubernetes [StatefulSet](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/) which will 
persist the backing "Mnesia" filestore and provide consistent pod names for clustering.  This image and it's associated
deployment are designed to be fault-tolerant.  If a single node goes down, there will be no service interruption while
Kubernetes stands the replacement node back up.

NOTE that this image is also configured to provide [High-Availability mirrored Queues](https://www.rabbitmq.com/ha.html)
with all queues being mirrored across 2 nodes by default.

NOTE that this image is using the [RabbitMQ Autocluster plugin](https://github.com/rabbitmq/rabbitmq-autocluster) to
provide clustering with a version built off of commit 1e7f9710e8802ef51d23692c344f64b051a8c331 due to the latest release
missing some bug fixes and being bound to an old version of RabbitMQ.

## Details
A deployment environment will generally want at least 3 RabbitMQ instances running.  We will also need an ETCD service 
running to provide cluster coordination.

The deployment should not require direct intervention.

## Usage Example
Sample Kubernetes YAML:
```yaml
# Create a shared secret used by rabbit-mq cluster nodes to authenticate with each other
apiVersion: v1
kind: Secret
metadata:
  name: rabbit-secret
type: Opaque
data:
  erlang-cookie: ZXhhbXBsZSBzZWNyZXQ=
---

# Create a service wrapping the Rabbit ETCD pod
apiVersion: v1
kind: Service
metadata:
  name: rabbit-etcd
spec:
  type: ClusterIP
  selector:
    app: rabbit-etcd
  ports:
  - name: server-port
    port: 2379
    targetPort: 2379
  - name: client-port
    port: 4001
    targetPort: 4001
---

# Create an ETCD deployment for coordinating the cluster
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: rabbit-etcd-deployment
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: rabbit-etcd
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: etcd-rabbit
        image: microbox/etcd:2.1.1
        command:
        - etcd
        args:
        - --name
        - 'rabbit-etcd'
        - --listen-client-urls
        - 'http://0.0.0.0:2379,http://0.0.0.0:4001'
        - --advertise-client-urls
        - 'http://rabbit-etcd:2379,http://rabbit-etcd:4001'
        env:
        - name: GET_HOSTS_FROM
          value: dns
        ports:
        - name: client-port
          containerPort: 4001
        - name: server-port
          containerPort: 2379
        resources:
          requests:
            cpu: 100m
            memory: 100M
          limits:
            cpu: 100m
            memory: 200M

---
# Create a service for providing DNS to rabbit stateful set
apiVersion: v1
kind: Service
metadata:
  name: rabbit-service
spec:
  clusterIP: None
  selector:
    app: rabbit-server
  ports:
    - port: 5672
      targetPort: 5672
      name: amqp
    - port: 25672
      targetPort: 25672
      name: dist

---
# Stand up our rabbit cluster as a stateful set with persistent domain names
# and filesystem mounts
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: rabbit-server
spec:
  serviceName: "rabbit-service"
  replicas: 3
  template:
    metadata:
      labels:
        app: rabbit-server
    spec:
      terminationGracePeriodSeconds: 90
      containers:
      - name: rabbit-server
        image: fwsbac/rabbit-image:latest
        imagePullPolicy: Always
        env:
        - name: GET_HOSTS_FROM
          value: dns
        - name: RABBITMQ_MEMORY_LIMIT
          value: "{absolute, \"650MiB\"}"
        - name: RABBITMQ_DISK_LIMIT
          value: "\"650MB\""
        - name: AUTOCLUSTER_TYPE
          value: "etcd"
        - name: AUTOCLUSTER_DELAY
          value: "0"
        - name: ETCD_HOST
          value: "rabbit-etcd"
        - name: ETCD_TTL
          value: "15"
        - name: RABBITMQ_ERLANG_COOKIE
          valueFrom:
            secretKeyRef:
              name: rabbit-secret
              key: erlang-cookie
        - name: RABBITMQ_MNESIA_BASE
          value: "/data"
        readinessProbe:
          exec:
            command:
            - /live_check.sh
          periodSeconds: 30
          timeoutSeconds: 10
        lifecycle:
          preStop:
            exec:
              # SIGTERM triggers a quick exit; gracefully terminate instead
              command:
              - /shutdown.sh
        ports:
        - containerPort: 5672
          name: amqp
        - containerPort: 25672
          name: dist
        resources:
          requests:
            cpu: 100m
            memory: 250M
          limits:
            cpu: 200m
            memory: 1G
        volumeMounts:
        - name: rabbit-data
          mountPath: /data
  volumeClaimTemplates:
    - metadata:
        name: rabbit-data
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 5Gi
```