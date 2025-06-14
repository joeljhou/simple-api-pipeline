# 使用 Eclipse Temurin JRE 17 作为基础镜像，体积较小
FROM eclipse-temurin:17-jre
# 设置工作目录
WORKDIR /app
# 复制构建好的 JAR 文件到容器中
COPY target/*.jar app.jar
# 暴露 Spring Boot 默认端口
EXPOSE 8080
# 运行 Spring Boot 应用
ENTRYPOINT ["java", "-jar", "app.jar"]