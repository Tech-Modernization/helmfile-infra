FROM ubuntu:18.04

# 2. load strimzi repo

# run like: docker run --rm -it -v ~/.kube:/home/admin/.kube --network host strimzi-ops /bin/bash


# handle apt 
RUN apt-get update && apt-get upgrade -y
RUN apt-get install curl -y

# install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
RUN chmod +x /kubectl && mv kubectl ./bin/kubectl

# install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod +x ./get_helm.sh && ./get_helm.sh
RUN rm -fv ./get-helm.sh

# install helmfile
RUN curl -fsSL -o helmfile https://github.com/roboll/helmfile/releases/download/v0.116.0/helmfile_linux_amd64
RUN chmod +x ./helmfile && mv ./helmfile /usr/local/bin/helmfile

# install strimzi repo
RUN curl -fsSL -o strimzi-0.17.0.tar.gz https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.17.0/strimzi-0.17.0.tar.gz
RUN tar xvf strimzi-0.17.0.tar.gz
RUN mv strimzi-0.17.0 /root/strimzi-0.17.0
RUN ln -s /root/strimzi-0.17.0 /root/strimzi

# cleanup
RUN apt-get remove --purge -y $BUILD_PACKAGES $(apt-mark showauto) && rm -rf /var/lib/apt/lists/*


WORKDIR /root