FROM espressif/idf:release-v5.3

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ccache \
    && rm -rf /var/lib/apt/lists/*

ENV IDF_CCACHE_ENABLE=1
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

WORKDIR /workspace

CMD ["/bin/bash"]