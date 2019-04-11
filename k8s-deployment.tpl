apiVersion: apps/v1
kind: Deployment
metadata:
  name: {APP_NAME}-deployment
  labels:
    app: {APP_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {APP_NAME}
  template:
    metadata:
      labels:
        app: {APP_NAME}
    spec:
      containers:
      - name: {APP_NAME}
        image: {HARBOR_HOST}/{IMAGE_URL}:{IMAGE_TAG}
        ports:
        - containerPort: 65530
        env:
          - name: SPRING_PROFILES_ACTIVE
            value: {SPRING_PROFILE}
      imagePullSecrets:
        - name: login