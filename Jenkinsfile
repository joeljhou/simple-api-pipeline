pipeline {
    agent any

    environment {
        TAG = "${BRANCH_OR_TAG.replaceAll('/', '-')}"
    }

    stages {
        stage('Git拉取代码') {
            steps {
                checkout scmGit(
                    branches: [[name: "${BRANCH_OR_TAG}"]],
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: 'ff5a1807-5c7d-487c-bfc9-e4817ef59ff2',
                        url: 'http://gitlab.orb.local/joeljhou/simple-api-pipeline.git'
                    ]]
                )
            }
        }
        stage('Maven构建项目') {
            steps {
                withEnv(["PATH+MAVEN=${tool 'maven-3.8.8'}/bin"]) {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }
        stage('SonarQube扫描') {
            steps {
               withCredentials([string(credentialsId: '2fdcc713-2421-4296-9873-fb8df6ae4d20', variable: 'SONAR_TOKEN')]) {
                    withEnv(["PATH+SONAR=${tool 'sonar-scanner-7.1'}/bin"]) {
                         sh """
                            sonar-scanner \
                                -Dsonar.host.url=http://sonarqube.orb.local \
                                -Dsonar.projectKey=com.geekyspace:simple-api-pipeline \
                                -Dsonar.projectName="${env.JOB_NAME}" \
                                -Dsonar.projectVersion="${env.BRANCH_OR_TAG}" \
                                -Dsonar.sources=./ \
                                -Dsonar.java.binaries=target
                        """
                    }
               }
            }
        }
        stage('构建并推送Harbor镜像') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(configName: 'Mac主机',
                    transfers: [sshTransfer(
                        sourceFiles: 'target/*.jar docker/ Dockerfile',
                        removePrefix: '',
                        remoteDirectory: 'simple-api-pipeline',
                        execCommand: '''
                            # 提取标签名（替换分支中的斜杠为破折号）
                            TAG=$(echo "$BRANCH_OR_TAG" | sed 's|/|-|g')
                            # 临时将 /usr/local/bin 加入 PATH，确保脚本中能直接调用 docker 命令
                            export PATH=/usr/local/bin:$PATH

                            # 1. 进入项目根目录（Dockerfile 所在位置）
                            cd /Users/joeljhou/CodeHub/joeljhou/jenkins-deploy/simple-api-pipeline/
                            # 2. 构建 Docker 镜像，使用环境变量 TAG 作为镜像标签
                            docker build -t simple-api-pipeline:$TAG .
                            # 3. 给本地镜像打标签，指向 Harbor 私有仓库的对应版本标签，准备推送
                            docker tag simple-api-pipeline:$TAG proxy.harbor.orb.local/repo/simple-api-pipeline:$TAG
                            # 4. 临时移除 macOS Docker 配置文件中的 credsStore 配置，避免登录时 Keychain 报错
                            sed -i '' '/"credsStore":/d' ~/.docker/config.json
                            # 5. 无交互登录 Harbor 私有仓库，使用密码或 token 认证
                            echo "Harbor12345" | docker login proxy.harbor.orb.local -u admin --password-stdin
                            # 6. 推送带版本标签的镜像到 Harbor 私有仓库
                            docker push proxy.harbor.orb.local/repo/simple-api-pipeline:$TAG
                            # 7. 恢复 macOS Docker 配置文件中的 credsStore 配置，重新启用 Keychain 功能
                            sed -i '' '/"currentContext":/i\\
                                "credsStore": "osxkeychain",
                            ' ~/.docker/config.json
                        '''
                    )]
                )])
            }
        }
        stage('SSH发布通知') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(configName: 'Mac主机',
                    transfers: [sshTransfer(
                        sourceFiles: 'deploy.sh',
                        removePrefix: '',
                        remoteDirectory: 'simple-api-pipeline',
                        execCommand: '''
                            cd /Users/joeljhou/CodeHub/joeljhou/jenkins-deploy/simple-api-pipeline
                            sh deploy.sh proxy.harbor.orb.local repo simple-api-pipeline "$BRANCH_OR_TAG" "$PORT"
                        '''
                    )]
                )])
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