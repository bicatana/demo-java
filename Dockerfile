FROM tomcat:latest

RUN apt-get update && \
  apt-get install -y \
    net-tools \
    tree \
    vim && \
  rm -rf /var/lib/apt/lists/* && apt-get clean && apt-get purge

RUN echo "export JAVA_OPTS=\"-javaagent:/data/exporter.jar=8088:/data/tomcat.yaml -Dapp.env=staging\"" > /usr/local/tomcat/bin/setenv.sh
COPY pkg/demo.war /usr/local/tomcat/webapps/demo.war

RUN mkdir /data
ADD exporter.jar /data/exporter.jar
ADD jmx/tomcat.yml /data/tomcat.yaml

EXPOSE 8080
EXPOSE 8088

CMD ["catalina.sh", "run"]
