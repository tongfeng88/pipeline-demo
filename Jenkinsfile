// 需要在jenkins的Credentials设置中配置jenkins-harbor-creds、jenkins-k8s-config参数
pipeline {
    agent any
    environment {
        HARBOR_CREDS = credentials('jenkins-harbor-creds')
        K8S_CONFIG = credentials('jenkins-k8s-config')
        GIT_TAG = sh(returnStdout: true,script: 'git describe --tags').trim()
    }
    parameters {
        string(name: 'HARBOR_HOST', defaultValue: '192.168.2.10:8999', description: 'harbor仓库地址')
        string(name: 'DOCKER_IMAGE', defaultValue: 'tongfeng88/pipeline-demo', description: 'docker镜像名')
        string(name: 'APP_NAME', defaultValue: 'pipeline-demo', description: 'k8s中标签名')
        string(name: 'K8S_NAMESPACE', defaultValue: 'Default', description: 'k8s的namespace名称')
    }
    stages {
        stage('Maven Build') {
            when { expression { env.GIT_TAG != null } }
            agent {
                docker {
                    image 'maven:3-jdk-8-alpine'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh 'mvn clean package -Dfile.encoding=UTF-8 -DskipTests=true'
                stash includes: 'target/*.jar', name: 'app'
            }

        }
        stage('Docker Build') {
            when { 
                allOf {
                    expression { env.GIT_TAG != null }
                }
            }
            agent any
            steps {
                unstash 'app'
                sh "docker login -u ${HARBOR_CREDS_USR} -p ${HARBOR_CREDS_PSW} ${params.HARBOR_HOST}"
                sh "docker build --build-arg JAR_FILE=`ls target/*.jar |cut -d '/' -f2` -t ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG} ."
                sh "docker push ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}"
                sh "docker rmi ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}"
            }
            
        }
        stage('Deploy') {
            when { 
                allOf {
                    expression { env.GIT_TAG != null }
                }
            }
            agent {
                docker {
                    image 'lwolf/helm-kubectl-docker'
                }
            }
            steps {
                sh "cat >k8s-rc.yaml <<EFO"
                sh "apiVersion: v1
                    kind: ReplicationController
                    metadata:
                      name: pipeline-demo
                      labels:
                        name: pipeline-demo
                    spec:
                      replicas: 1
                      selector:
                        name: pipeline-demo
                      template:
                        metadata:
                          labels:
                            name: pipeline-demo
                        spec:
                          containers:
                          - name: pipeline-demo
                            image: ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}
                            ports:
                            - containerPort: 2002
                    EFO"
                sh "rancher kubectl delete -f k8s-rc.yaml --ignore-not-found=true"
                sh "sleep 5"
                sh "rancher kubectl create -f k8s-rc.yaml"
            }
            
        }
        
    }
}
