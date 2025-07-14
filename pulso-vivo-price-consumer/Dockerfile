# Dockerfile for pulso-vivo-price-consumer
# Build stage
FROM docker.io/maven:3.9.6-eclipse-temurin-17-alpine AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM docker.io/eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY --from=build /build/target/pulso-vivo-price-consumer-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
