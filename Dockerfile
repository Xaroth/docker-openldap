FROM osixia/openldap:1.2.5-dev
LABEL author="https://github.com/Xaroth"

ADD ldif /container/service/slapd/assets/config/bootstrap/ldif
ADD environment /container/environment/01-custom

ENTRYPOINT ["/container/tool/run"]
