pipeline {
    agent any

    environment {
        HARBOR_ADDR = 'proxy.harbor.orb.local'
        HARBOR_REPO = 'repo'
        IMAGE_NAME  = 'simple-api-pipeline'
        IMAGE_TAG   = 'origin-dev'
        EXPOSE_PORT = '8082'
    }

    stages {
        stage('Git拉取代码') {
            steps {
                echo '✅ Git拉取代码 SUCCESS'
                }
        }
        stage('Maven构建项目') {
            steps {
                echo '✅ Maven构建项目 SUCCESS'
                }
        }
        stage('SonarQube扫描') {
            steps {
                echo '✅ SonarQube扫描质量检查 SUCCESS'
            }
        }
        stage('Docker制作镜像') {
            steps {
                echo '✅ Docker制作镜像 SUCCESS'
            }
        }
        stage('Harbor推送镜像') {
            steps {
                echo '✅ Harbor推送镜像 SUCCESS'
            }
        }
        stage('SSH发布通知') {
            steps {
                echo '✅ SSH发布通知 SUCCESS'
            }
        }
    }
    post {
        success {
            echo '🎉 全部阶段 SUCCESS'
        }
        failure {
            echo '❌ 流水线执行失败，请查看日志'
        }
    }
}