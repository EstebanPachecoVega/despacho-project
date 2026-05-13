#Multi-stage
#Stage 1
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

#Stage 2
#la etapa 1 esta por morir
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
COPY entrypoint.sh /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
