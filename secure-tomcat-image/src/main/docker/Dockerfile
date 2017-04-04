################
# Docker file to build a secure Apache Tomcat 7 image on JRE 7
################

FROM tomcat:7-jre7

#Put more secured server.xml
# Removed server banner
# Changed SHUTDOWN port and Command
# Increased maxHttpHeaderSize to 65536
# Set URIEncoding to UTF-8
ADD server.xml /usr/local/tomcat/conf/

#Put more secured web.xml
# Replaced default 404, 403, 500 pages
# Will not show server version info up on errors and exceptions
# Added .vtt extension and mime-type
ADD web.xml /usr/local/tomcat/conf/

#Remove version string from HTTP error messages
#override ServerInfo.properties in catalina.jar
RUN mkdir -p /usr/local/tomcat/lib/org/apache/catalina/util
ADD ServerInfo.properties /usr/local/tomcat/lib/org/apache/catalina/util/ServerInfo.properties

#remove redundant apps and unsecure configurations
RUN rm -rf /usr/local/tomcat/webapps/* ; \
    rm -rf /usr/local/tomcat/work/Catalina/localhost/* ; \
    rm -rf /usr/local/tomcat/conf/Catalina/localhost/*

#make tomcat conf dir read only
RUN chmod -R 400 /usr/local/tomcat/conf

EXPOSE 8080
CMD ["catalina.sh", "run"]