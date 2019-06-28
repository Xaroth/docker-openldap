FROM osixia/openldap:1.2.5-dev
LABEL author="https://github.com/Xaroth"

RUN apt-get -y update \
    && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends inotify-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD wait-for-file /wait-for-file
ADD process.sh /container/service/slapd/process.sh
ADD ldif /container/service/slapd/assets/config/bootstrap/ldif
ADD environment /container/environment/01-custom

RUN chmod +x /wait-for-file /container/service/slapd/process.sh

ENTRYPOINT ["/wait-for-file", "/container/tool/run"]
