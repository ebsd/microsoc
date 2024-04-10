FROM zeek/zeek:6.2
RUN apt update && apt -y upgrade && apt -y clean
COPY config/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
