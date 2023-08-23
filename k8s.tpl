apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}
  namespace: {{NAMESPACE}}
spec:
  selector:
    matchLabels:
      app: {{APP_NAME}}
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: {{APP_NAME}}
    spec:
      imagePullSecrets:
        - name: my-registry-admin
      containers:
        - name: {{APP_NAME}}
          image: {{IMAGE_URL}}:{{IMAGE_TAG}}
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
              name: port
              protocol: TCP
          command: [ "/bin/sh" ]
          args: [ "-c", "set -e && java -Dspring.profiles.active={{NAMESPACE}} -Dserver.port=8080 -jar app.jar" ]
---
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}
  namespace: {{NAMESPACE}}
spec:
  type: ClusterIP
  selector:
      app: {{APP_NAME}}
  ports:
    - port: 8080
      protocol: TCP
      targetPort: 8080