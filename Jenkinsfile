#!groovy

podTemplate(cloud: "kubernetes", containers: [
    containerTemplate(name: 'jnlp', image: 'jenkinsci/jnlp-slave:alpine', ttyEnabled: true, alwaysPullImage: true),
    containerTemplate(name: 'maven', image: 'maven:3.3.9-jdk-8-alpine', ttyEnabled: true, command: 'cat', alwaysPullImage: true),
    // containerTemplate(name: 'sonar', image: 'sonarqube:latest', ttyEnabled: true, command: 'cat', alwaysPullImage: true),
    containerTemplate(name: 'kaniko', image: 'gcr.io/kaniko-project/executor:debug', ttyEnabled: true, command: '/busybox/cat', alwaysPullImage: true)
]) {
    node(POD_LABEL) {
        //Vault Configuration
        def configuration = [vaultUrl: 'http://10.103.252.118:8200',
                            vaultCredentialId: 'vault-token', engineVersion: 1]
        //Define Required Secrets and Env Variables
        def secrets = [
            [path: 'kv/docker', secretValues: [
                [envVar: 'DOCKER_CONFIG_FILE', vaultKey: 'config']]]
        ]
        //Use the Credentials with the Build
        withVault([configuration: configuration, vaultSecrets: secrets]) {
            //Checkout code from GitHub
            stage ('Checkout') {
                try {
                    git credentialsId: 'github-key', branch: "$BRANCH_NAME", url: "git@github.com:bicatana/demo-java.git"
                }
                catch (exc) {
                    println "Failed the Git Checkout - ${currentBuild.fullDisplayName}"
                }

            }
            //Ensure that the Workspace is ready for the pipeline
            stage('Check Workspace') {
                container('maven'){
                    try {
                        sh "mvn -v"
                        sh "pwd"
                    }
                    catch (exc) {
                        println "Failed the Workspace Check - ${currentBuild.fullDisplayName}"
                        throw(exc)
                    }
                }
            }
            //Check Package with SonarQube
            // stage('SonarQube Check') {
            //     container('sonar') {
            //         try {
            //             sh "mvn clean verify sonar:sonar"
            //         }
            //         catch (exc) {
            //             println "Failed the Security Check - ${currentBuild.fullDisplayName}"
            //             throw(exc)
            //         }
            //     }
            // }
            //Run Maven Build Stage
            stage('Build Package') {
                container('terraform') {
                    try {
                        sh """
                            mvn -B clean package
                            mkdir -p pkg
                            mv target/demo.war pkg/demo.war
                        """
                    }
                    catch (exc) {
                        println "Package Build Step Failed - ${currentBuild.fullDisplayName}"
                        throw(exc)
                    }
                }
            }
            //Package up and ship via Kaniko
            stage('Kaniko - Build & Ship') {
                container('kaniko') {
                    try {
                        //Kaniko Build and Ship to Docker Hub
                        //Use --verbosity=debug for more detailed logs if necessary
                        env.DOCKER_CONFIG = "/kaniko/.docker"
                        sh """
                        set +x
                        echo '$DOCKER_CONFIG_FILE' > config.json
                        cp config.json /kaniko/.docker/config.json
                        /kaniko/executor --dockerfile=$WORKSPACE/Dockerfile --context=$WORKSPACE  --destination=bicatana/k8s:java --skip-tls-verify
                        """                  
                    }
                    catch (exc) {
                        println "Kaniko Steps Failed - ${currentBuild.fullDisplayName}"
                        throw(exc)
                    }
                }
            }
        }
    }
}