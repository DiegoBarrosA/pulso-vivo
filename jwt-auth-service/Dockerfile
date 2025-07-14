FROM openjdk:17-jdk-slim

WORKDIR /app

COPY target/jwt-auth-service-*.jar app.jar

EXPOSE 8099

CMD ["java", "-jar", "app.jar"]
