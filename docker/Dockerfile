FROM ubuntu:18.04

# build 
# docker build -t helmfile-infra .
#
# to get a shell and run commands directly
#docker run --rm -it -v ~/.kube:/app/.kube -v ~/.gnupg:/app/.gnupg -v $(pwd):/app/helmfile-infra --network host helmfile-infra /bin/sh
#
# depending on the state of your PGP, you might have to:
# docker run --rm -it -v ~/.kube:/app/.kube -v ~/.gnupg:/app/.gnupg -v $(pwd):/app/helmfile-infra --network host helmfile-infra gpg --export-secret-keys >~/.gnupg/secring.gpg
#
# depeding on your gcloud state, you might have to:
# docker run --rm -it -v ~/.kube:/app/.kube -v ~/.gnupg:/app/.gnupg -v $(pwd):/app/helmfile-infra --network host helmfile-infra gcloud init
# docker run --rm -it -v ~/.kube:/app/.kube -v ~/.gnupg:/app/.gnupg -v $(pwd):/app/helmfile-infra --network host helmfile-infra gcloud container clusters get-credentials gcp --region=us-central1
#
# docker run --rm -it -v ~/.kube:/app/.kube -v ~/.gnupg:/app/.gnupg -v $(pwd):/app/helmfile-infra --network host helmfile-infra helmfile -e gcp diff
#
# apply
# docker run --rm -it -v ~/.kube:/app/.kube -v ~/.gnupg:/app/.gnupg -v $(pwd):/app/helmfile-infra --network host helmfile-infra helmfile -e gcp apply
#

# handle apt 
RUN apt-get update && apt-get upgrade -y && apt-get install curl gcc git libffi-dev libssl-dev libyaml-dev make lsb-release openssl python-dev python-pip cl-getopt -y

# gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y

RUN useradd --home /app app
RUN mkdir /home/.config 
RUN mkdir -p /app/.helm/plugins
RUN chown -R app /app

# install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
RUN chmod +x /kubectl && mv kubectl ./bin/kubectl

# install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod +x ./get_helm.sh && ./get_helm.sh
RUN rm -f /get-helm.sh

# install helmfile
RUN curl -fsSL -o helmfile https://github.com/roboll/helmfile/releases/download/v0.116.0/helmfile_linux_amd64
RUN chmod +x ./helmfile && mv ./helmfile /usr/local/bin/helmfile

RUN pip install pyyml
#RUN curl -s https://packagecloud.io/install/repositories/gasolwu/jsonnet/script.deb.sh | bash
# no snpa on docker
#RUN apt-get install snapd -y 
#RUN snap install jsonnet
RUN curl -fsSL https://github.com/google/jsonnet/releases/download/v0.15.0/jsonnet-bin-v0.15.0-linux.tar.gz -o jsonnet.tgz && tar -xzvf jsonnet.tgz && mv jsonnet /usr/local/bin && mv jsonnetfmt /usr/local/bin && chmod +x /usr/local/bin/jsonnet* && rm jsonnet.tgz

RUN curl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl
RUN curl https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson
RUN chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson

RUN curl -fsSL https://github.com/mozilla/sops/releases/download/v3.5.0/sops-v3.5.0.linux -o /usr/local/bin/sops
RUN chmod +x /usr/local/bin/sops

RUN apt-get install unzip
RUN curl -fsSL https://releases.hashicorp.com/terraform/0.12.25/terraform_0.12.25_linux_amd64.zip -o terraform_0.12.25_linux_amd64.zip && unzip terraform_0.12.25_linux_amd64.zip && mv terraform /usr/local/bin/&& chmod +x /usr/local/bin/terraform && rm terraform_0.12.25_linux_amd64.zip

# cleanup
#RUN apt-get remove --purge -y $BUILD_PACKAGES $(apt-mark showauto) && rm -rf /var/lib/apt/lists/*

USER app

#ENV HELM_PLUGIN_DIR /app/.helm/plugins
#ENV XDG_CONFIG_HOME /app/.helm/plugins

ENV HELM_PLUGIN_DIR /app/.local/share/helm/plugins/
RUN helm plugin install https://github.com/databus23/helm-diff --version v3.1.1 
RUN helm plugin install https://github.com/futuresimple/helm-secrets 

#RUN curl -L $TARBALL_URL | tar -C /app/.helm/plugins -xzv
#RUN helm plugin install https://github.com/databus23/helm-diff --version v3.1.1 
#RUN helm plugin install https://github.com/viglesiasce/helm-gcs.git
#RUN helm plugin install https://github.com/databus23/helm-diff
#RUN helm plugin install https://github.com/helm/helm-2to3

WORKDIR /app/helmfile-infra
