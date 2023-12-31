properties([
        parameters([
                gitParameter(
                        description: 'Which branch do you build with?',
                        name: 'BRANCH',
                        branchFilter: 'origin/(.*)',
                        defaultValue: 'main',
                        type: 'PT_BRANCH_TAG',
                        selectedValue: 'DEFAULT',
                        sortMode: 'DESCENDING_SMART',
                        quickFilterEnabled: true,
                        tagFilter: '*'
                )
        ])
])

environment {
    BRANCH = "$params.BRANCH"
}

def GIT_REPO = 'https://github.com/EvanFor/spring-boot-gradle.git'
def DOCKER_REPO = 'localhost:9000'

def label = "slave-${env.BUILD_NUMBER}"

podTemplate(
        label: label,
        cloud: 'kubernetes',
        containers: [
                containerTemplate(name: 'gradle', image: 'gradle:jdk17-alpine', command: 'cat', ttyEnabled: true),
                containerTemplate(name: 'docker', image: 'docker', command: 'cat', ttyEnabled: true),
                containerTemplate(name: 'kubectl', image: 'cnych/kubectl', command: 'cat', ttyEnabled: true)
        ],
        volumes: [
                hostPathVolume(hostPath: '/Users/evan/.gradle', mountPath: '/root/.gradle'),
                hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')
        ]) {

    node(label) {

        stage('Echo Params') {
            echo "流水线名称：          ${env.JOB_NAME}"
            echo "BRANCH        信息为: ${env.BRANCH}"
        }

        stage('Git Clone') {
            echo "-----> Git start <-----"
            git branch: "${env.BRANCH}", changelog: true, credentialsId: "github", url: "${GIT_REPO}"

            env.GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
            env.APP_NAME = "spring-boot-gradle"
            env.NAMESPACE = "dev"
            echo "GIT_COMMIT     信息为：${env.GIT_COMMIT}"
            echo "-----> Git end   <-----"
        }

        stage('Gradle Build') {
          echo "-----> Gradle start <-----"
           sh 'apk add nodejs=18.17.0-r0'
           sh 'apk add npm=9.6.6-r0'
           sh 'node -v'
           sh 'npm -v'
          container('gradle') {
              sh 'gradle build --stacktrace'
          }
          echo "-----> Gradle end <-----"
        }

        stage('Docker Build') {
            echo "-----> Docker start <-----"
            container('docker') {
                docker.withRegistry("https://${DOCKER_REPO}", 'docker-credentials') {
                    image = docker.build("spring-boot-gradle:${env.GIT_COMMIT}")
                    image.push("${env.GIT_COMMIT}")
                }
            }
            echo "-----> Docker end <-----"
        }

        stage("Prepare K8S") {
            sh "sed -e 's#{{APP_NAME}}#${env.APP_NAME}#g;s#{{NAMESPACE}}#${env.NAMESPACE}#g;s#{{IMAGE_URL}}#${DOCKER_REPO}/${env.APP_NAME}#g;s#{{IMAGE_TAG}}#${env.GIT_COMMIT}#g' k8s.tpl > k8s.yaml"
            stash name: "k8s.yaml", includes: "k8s.yaml"
            sh "cat k8s.yaml"
        }

        stage('K8S Deploy') {
            echo "-----> Kubectl start <-----"
            container('kubectl') {
                withKubeConfig([credentialsId: "k8s-credentials", serverUrl: "https://kubernetes.default.svc.cluster.local"]) {
                    unstash("k8s.yaml")
                    sh 'kubectl apply -f k8s.yaml'
                }
            }
            echo "-----> Kubectl end <-----"
        }
    }
}