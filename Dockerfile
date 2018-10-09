FROM frolvlad/alpine-glibc

RUN apk add --no-cache ansible ca-certificates git \
    && ln -s /usr/bin/pip3 /usr/bin/pip \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && pip install --upgrade pip \
    && pip install boto boto3

ENV OC_VERSION "v3.9.0"
ENV OC_RELEASE "openshift-origin-client-tools-v3.9.0-191fece-linux-64bit"
ENV KONTEMPLATE_VERSION "v1.6.0"
ENV KONTEMPLATE_RELEASE "kontemplate-1.6.0-97bef90-linux-amd64"

RUN mkdir -p /opt/oc && \
    mkdir -p /opt/kontemplate && \
    wget https://github.com/openshift/origin/releases/download/${OC_VERSION}/${OC_RELEASE}.tar.gz -O /opt/oc/release.tar.gz && \
    wget https://github.com/tazjin/kontemplate/releases/download/${KONTEMPLATE_VERSION}/${KONTEMPLATE_RELEASE}.tar.gz -O /opt/kontemplate/release.tar.gz && \
    tar --strip-components=1 -xzvf /opt/oc/release.tar.gz -C /opt/oc/ && \
    mv /opt/oc/oc /usr/bin/ && \
    tar -xzvf /opt/kontemplate/release.tar.gz -C /opt/kontemplate/ && \
    mv /opt/kontemplate/kontemplate /usr/bin/ && \
    rm -rf /opt/* && \
    mkdir -p /opt/shiftigrade

WORKDIR /opt/shiftigrade
COPY ./ansible/ /opt/shiftigrade/ansible/
COPY ./ocp/ /opt/shiftigrade/ocp/
