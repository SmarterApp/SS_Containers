# Redis Sentinel Cluster Image
This docker image definition provides a Redis Server and Sentinel for use in Kubernetes.  It is based off of the 
Kubernetes example work at:
https://github.com/kubernetes/kubernetes/tree/master/examples/storage/redis
This image is designed to be used with a leader-elector side-car to simplify deployments and increase availability in 
the case of catastrophic failure.

## Details
A deployment environment will generally want at least 3 Sentinel instances running as well as 3 Server instances to 
provide a highly-available cluster.  The general process for determining the master is:
1. Request master from Sentinels
2. Request master from Servers 
3. Request master from localhost elector side-car

If #1 cannot provide a master server, #2 will be queried, then number #3.

The benefit of including the elector side-car is that deployment is a single-step process that does not require 
intervention rather than a two-step process from the example above.

## Usage Example
Sample Kubernetes YAML:
```yaml
#Add a redis server deployment with 3 nodes and a leader-election sidecar
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: redis-server
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: redis-server
    spec:
      terminationGracePeriodSeconds: 60
      containers:
        - name: redis-server
          image: fwsbac/redis-image:latest
          imagePullPolicy: Always
          ports:
          - containerPort: 6379
          resources:
            limits:
              cpu: 100m
          volumeMounts:
          - mountPath: /redis-master-data
            name: data
          livenessProbe:
            exec:
              command:
              - /live_check.sh
            initialDelaySeconds: 60
            periodSeconds: 60
            failureThreshold: 4
          readinessProbe:
            exec:
              command:
              - /live_check.sh
            initialDelaySeconds: 30
            periodSeconds: 30
            failureThreshold: 3
          env:
          - name: REDIS_SENTINEL_SERVICE_HOST
            value: "redis-sentinel-service"
          - name: REDIS_SENTINEL_SERVICE_PORT
            value: "26379"
          - name: REDIS_SERVER_SERVICE_HOST
            value: "redis-server-service"

        #Add an elector side-car that will elect one of the registered redis-server pods as the master.
        - name: elector
          image: fwsbac/leader-elector:0.0.1
          ports:
          - containerPort: 4040
          command:
          - /bin/sh
          args:
          - -c
          - /server --election=redis-master --http=0.0.0.0:4040 --id=$(hostname -i)

      volumes:
        - name: data
          emptyDir: {}

---
#Wrap the redis-servers in a Service
apiVersion: v1
kind: Service
metadata:
  name: redis-server-service
spec:
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: 6379
    name: redis-port
  - port: 4040
    targetPort: 4040
    name: elector-port
  selector:
    app: redis-server

---
#Add a redis sentinel deployment with 3 sentinels
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: redis-sentinel
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: redis-sentinel
    spec:
      containers:
        - name: sentinel
          image: fwsbac/redis-image:latest
          imagePullPolicy: Always
          ports:
          - containerPort: 26379
          resources:
            limits:
              cpu: 100m
          livenessProbe:
            exec:
              command:
              - /sentinel_check.sh
            initialDelaySeconds: 60
            periodSeconds: 60
            failureThreshold: 4
          env:
          - name: REDIS_SENTINEL_SERVICE_HOST
            value: "redis-sentinel-service"
          - name: REDIS_SENTINEL_SERVICE_PORT
            value: "26379"
          - name: REDIS_SERVER_SERVICE_HOST
            value: "redis-server-service"
          - name: SENTINEL
            value: "true"

---
#Wrap the redis sentinel pods in a service
apiVersion: v1
kind: Service
metadata:
  name: redis-sentinel-service
spec:
  ports:
    - port: 26379
      targetPort: 26379
  selector:
    app: redis-sentinel
```