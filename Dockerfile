FROM debian:stretch-slim
LABEL VERSION=0.0.7

RUN apt-get update && apt-get -y --no-install-recommends install gettext-base curl git ca-certificates && apt-get -y clean
RUN curl -LO https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
COPY variable-populator.sh /usr/local/bin/

ENTRYPOINT ["variable-populator.sh"]
