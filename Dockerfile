FROM openjdk:17-ea-oracle
ARG JAR_FILE=build/libs/spring-boot-gradle-0.0.1.jar
ADD ${JAR_FILE} app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]