FROM python:3-alpine3.7

LABEL maintainer="cerebus2@gmail.com" \
      description="Baseline for distributed computation with python3"

# Builds a baseline image for python-based distributed computation.
# Used for both master and worker containers.  This image is loaded
# with core Python3; applicaton dependencies will be loaded by
# build triggers when this image is inherited.

# You can rebuild this baseline image to customize the following:

# REQUIRE: Packages to install.  Currently sudo (for user
# 	    convenience), ssh client/server (for master image login,
# 	    and inter-image communications), and build-base (in case a
# 	    python library need compilation). Keep this list small.
# USER: default user
# WORKDIR: Where your application will reside
# USER_HOME: default user home directory
# USER_SSH: default user SSH directory

ARG REQUIRE="sudo openssh build-base"
ARG USER=worker
ARG WORKDIR=/project
ARG USER_HOME=/home/${USER}
ARG USER_SSH=${USER_HOME}/.ssh

ENV USER ${USER}
ENV USER_HOME ${USER_HOME}
ENV USER_SSH ${USER_SSH}
ENV WORKDIR ${WORKDIR}

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

# 'get_hosts' is a script that discovers workers; lists of hosts are
# usually required for distributed computation libraries.
COPY get_hosts /usr/local/bin/get_hosts

# This baseline image is used to build your application image (master and
# worker), which will be deployed via docker swarm, so we use ONBUILD
# triggers to load the project.
#
# A project should have the following structure:
# - toplevel
# +-- Dockerfile (for your app image, see example)
# +-- docker-compose.yml
# +-- build.sh
# +-- project/
#     +-- requirements.txt (for pip)
#     +-- (application code)
# +-- ssh/
#     +-- id_rsa (chmod 0600)
#     +-- id_rsa.pub
#     +-- config (provided)

ONBUILD COPY project/ ${WORKDIR}/
ONBUILD COPY ssh/ ${USER_SSH}/

ONBUILD RUN chown -R ${USER}:${USER} ${USER_HOME} \
	&& pip install --no-cache-dir -r /project/requirements.txt

WORKDIR ${WORKDIR}

CMD ["/usr/sbin/sshd", "-D"]
