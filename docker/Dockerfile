FROM python

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --yes patchelf python3-dev python3.7-dev && \
    rm -rf /var/lib/apt/lists/* && \
    pip install virtualenv
COPY build-venvs.sh build-wheels.sh /
RUN /build-venvs.sh

CMD ["/build-wheels.sh"]
