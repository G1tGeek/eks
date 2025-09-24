FROM eclipse-temurin:17-jdk AS builder

WORKDIR /app

# Copy source code and webapp
COPY src ./src

# Copy servlet-api JAR from Tomcat image
COPY --from=tomcat:10.1.8-jdk17-temurin /usr/local/tomcat/lib/servlet-api.jar ./servlet-api.jar

# Compile Java servlet classes
RUN mkdir -p out/WEB-INF/classes && \
    javac -d out/WEB-INF/classes -cp src/main/webapp/WEB-INF/lib/gson-2.8.5.jar:servlet-api.jar $(find src/main/java -name "*.java")

# Copy webapp resources (JSP, HTML, CSS, JS, WEB-INF)
RUN cp -r src/main/webapp/* out/


FROM tomcat:10.1.8-jdk17-temurin

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the compiled webapp
COPY --from=builder /app/out /usr/local/tomcat/webapps/ROOT

# Expose Tomcat port
EXPOSE 8080

# Run Tomcat
CMD ["catalina.sh", "run"]
