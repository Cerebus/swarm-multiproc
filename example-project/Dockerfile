## -*- docker-image-name: "cerebus2/multiproc-example" -*-
# Build from the baseline; ONBUILD triggers will copy project/ and ssh/
# directories into the image, and run pip installs.

FROM cerebus2/swarm-multiproc:base

LABEL maintainer="" \
      description=""

ARG REQUIRE=""

WORKDIR ${WORKDIR}

RUN apk update \
    && apk upgrade \
    && apk add --no-cache ${REQUIRE} \
    && pip install --no-cache -r /project/requirements.txt

