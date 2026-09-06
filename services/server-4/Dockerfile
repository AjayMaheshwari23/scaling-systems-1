
# --------- JDK = tools for BUILDING Java --------------


# Linux env that already has Maven and Java 17. (isme build is just name)
FROM maven:3.9-eclipse-temurin-17 as build


# Copy everything from my server-4 folder into /app inside the Docker build environment
# /app/
# ├── pom.xml
# ├── src/
# └── Dockerfile
COPY . /app 



# From now on Docker runs commands from /app
WORKDIR /app


# compiles the app
RUN mvn -DskipTests package





# --------- JRE = tools for RUNNING Java --------------

# new stage with just java runtime
FROM eclipse-temurin:17-jre-jammy



# Go back to the environment named build, find the JAR Maven created, and copy it into this smaller environment
COPY --from=build /app/target/*.jar /app/app.jar

# expose on this port
EXPOSE 8080 


# Whenever somebody starts this container, run this.
ENTRYPOINT ["java", "-jar", "/app/app.jar"]