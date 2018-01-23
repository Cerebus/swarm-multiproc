FROM python:3-alpine3.7

LABEL maintainer="cerebus2@gmail.com" \
      description="Base for distributed computation with python3"

ARG REQUIRE="sudo openssh"
ARG USER=worker
ARG WORKDIR=/project
ARG USER_HOME=/home/${USER}
ARG USER_SSH=${USER_HOME}/.ssh

USER root

RUN apk update \
    && apk upgrade \
    && apk add --no-cache ${REQUIRE} \
    && adduser -D ${USER} -s /bin/ash \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p ${USER_SSH} \
    && passwd -u ${USER} \
    && mkdir -p ${WORKDIR} \
    && chown -R ${USER}:${USER} ${WORKDIR} \
    && echo "cd ${WORKDIR}" >> ${USER_HOME}/.profile \
    && cd /etc/ssh/ && ssh-keygen -A -N '' \
    && sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config \
    && sed -i "s/#PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config \
    && sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config \
    && sed -i "s/#AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config 

COPY get_hosts /usr/local/bin/get_hosts
COPY ssh/ ${USER_SSH}/

RUN chown -R ${USER}:${USER} ${USER_HOME} 

WORKDIR ${WORKDIR}

USER root

CMD ["/usr/sbin/sshd", "-D"]
