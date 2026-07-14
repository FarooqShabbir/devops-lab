# NOTE: build context for this Dockerfile is the REPO ROOT (see docker-compose.yml),
# not apps/java-app/, so it can also pull servers/tomcat-java/server.xml.

# --- build stage: compile WAR with Maven ---
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /build
COPY apps/java-app/pom.xml .
RUN mvn -B dependency:go-offline
COPY apps/java-app/src ./src
RUN mvn -B clean package -DskipTests

# --- runtime stage: this IS the "Tomcat server" from servers/tomcat-java ---
FROM tomcat:10.1-jdk17-temurin
LABEL role="app-server" server="tomcat" stack="java"

# Remove default Tomcat sample apps (security hardening, smaller image)
RUN rm -rf /usr/local/tomcat/webapps/ROOT \
           /usr/local/tomcat/webapps/examples \
           /usr/local/tomcat/webapps/docs \
           /usr/local/tomcat/webapps/manager \
           /usr/local/tomcat/webapps/host-manager

# Deploy our WAR as ROOT so the app answers at /
COPY --from=builder /build/target/java-app.war /usr/local/tomcat/webapps/ROOT.war

# Tomcat server tuning (connection limits, access logs, header hardening)
COPY servers/tomcat-java/server.xml /usr/local/tomcat/conf/server.xml

EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --retries=5 --start-period=30s \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["catalina.sh", "run"]
