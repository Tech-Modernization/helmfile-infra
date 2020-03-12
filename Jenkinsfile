/**********************************************************************************
 *
 * This pipeline deploys Helm chart with helmfile
 *
 **********************************************************************************/

pipeline {
    agent { label 'jenkins-slave-alpine-base' }
    parameters {
        choice(
                choices: ['ldev' , 'lprod', 'gcp'],
                description: 'Kubernetes Environment',
                name: 'kubeEnvironment'
        )
    }
    environment {
        // Token
        KUBE_CREDENTIALS = "k8s-${params.kubeEnvironment}-jenkins-robot"
        KUBE_API_SERVER = "https://kubernetes-${params.kubeEnvironment}-api.contino.io
    }
    options { timestamps() }
    stages {
        stage("Helm Deployment") {
            agent {
                docker {
                    label 'jenkins-slave-alpine-base'
                    image 'contino.io/kub/helmfile:latest'
                    alwaysPull true
                }
            }
            stages {
                stage('Helm Lint') {
                    steps {
                        withKubeConfig([credentialsId: env.KUBE_CREDENTIALS, serverUrl: env.KUBE_API_SERVER]) {
                            sh "helmfile --environment ${params.kubeEnvironment} lint"
                        }
                    }
                }

                // The difference on k8s resources from as built to new state
                // TODO: move this to PR output and autodeploy
                // stage('Helm Diff') {
                //     steps {
                //         ansiColor('xterm') {
                //             withKubeConfig([credentialsId: env.KUBE_CREDENTIALS, serverUrl: env.KUBE_API_SERVER]) {
                //                 sh "helmfile --environment ${params.kubeEnvironment} diff"
                //             }
                //         }
                //     }
                // }

                // Apply the state changes
                stage('Helmfile Apply') {
                    steps {
                        ansiColor('xterm') {
                            withKubeConfig([credentialsId: env.KUBE_CREDENTIALS, serverUrl: env.KUBE_API_SERVER]) {
                                sh "helmfile --environment ${params.kubeEnvironment} apply"
                            }
                        }
                    }
                }

                // List the resources that are deployed
                stage('List Deployed Changes') {
                    steps {
                        withKubeConfig([credentialsId: env.KUBE_CREDENTIALS, serverUrl: env.KUBE_API_SERVER]) {
                            sh "helmfile --environment ${params.kubeEnvironment} status"
                        }
                    }
                }

                // TODO Create a stage to wait for the end state to be built.
            }
        }
    }
    post {
        cleanup {
            script {
                // Clean workspace to remove token from disk
                deleteDir()
            }
        }
    }
}
