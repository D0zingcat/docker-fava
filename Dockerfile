ARG BEANCOUNT_VERSION=2.3.1
ARG NODE_BUILD_IMAGE=14.10.0-alpine3.12
ARG PYTHON_IMAGE=python:3.8.3-alpine
ARG FAVA_VERSION=1.15

FROM node:${NODE_BUILD_IMAGE} as node_build
MAINTAINER d0zingcat<autumnlo.v@gmail.com>


WORKDIR /tmp/build
RUN apk add --no-cache git make && git clone https://github.com/beancount/fava

WORKDIR /tmp/build/fava
RUN git checkout ${FAVA_VERSION}
RUN make && make mostlyclean


FROM ${PYTHON_IMAGE} as python_build
RUN apk update && apk add --no-cache curl python3 git gcc musl-dev
ENV PATH "/app/bin:$PATH"
RUN python3 -mvenv /app
RUN pip3 install -U pip setuptools
COPY --from=node_build /tmp/build/fava /tmp/build/fava

WORKDIR /tmp/build
RUN git clone https://github.com/beancount/beancount
WORKDIR /tmp/build/beancount
RUN git checkout ${BEANCOUNT_VERSION}
RUN CFLAGS=-s pip3 install -U /tmp/build/beancount
RUN pip3 install -U /tmp/build/fava
RUN pip3 uninstall -y pip
RUN find /app -name __pycache__ -exec rm -rf -v {} +

FROM ${PYTHON_IMAGE}
COPY --from=python_build /app /app
EXPOSE 5000
ENV BEANCOUNT_FILE ""
ENV LC_ALL "C.UTF-8"
ENV LANG "C.UTF-8"
ENV FAVA_HOST "0.0.0.0"
ENV PATH "/app/bin:$PATH"
ENTRYPOINT ["fava"]
