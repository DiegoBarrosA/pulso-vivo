# ---- Build Stage ----
FROM docker.io/maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .

RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests

# ---- Runtime Stage ----
FROM docker.io/eclipse-temurin:17-jre-jammy
WORKDIR /app

# Install required libraries
RUN apt-get update && \
    apt-get install -y libaio1 && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/wallet

COPY --from=build /app/target/*.jar app.jar
COPY src/main/resources/wallet/* /app/wallet/

RUN chmod 755 /app/wallet && \
    chmod 644 /app/wallet/* && \
    chmod 600 /app/wallet/ewallet.p12 /app/wallet/cwallet.sso || true

ENV TNS_ADMIN=/app/wallet \
    ORACLE_WALLET_LOCATION=/app/wallet \
    JAVA_OPTS="-Doracle.net.tns_admin=/app/wallet -Doracle.net.ssl_server_dn_match=false"

EXPOSE 8081
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
