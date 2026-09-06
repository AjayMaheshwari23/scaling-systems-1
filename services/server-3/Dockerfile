
FROM maven:3.9-eclipse-temurin-17 as build 


COPY . /app 


WORKDIR /app


RUN mvn -DskipTests package 

FROM eclipse-temurin:17-jre-jammy

COPY --from=build /app/target/*.jar /app/app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]