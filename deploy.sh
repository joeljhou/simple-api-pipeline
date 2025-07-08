#!/bin/bash

# ========== 参数 ==========
HARBOR_ADDR=$1       # Harbor 地址，如 proxy.harbor.orb.local
HARBOR_REPO=$2       # Harbor 项目名，如 repo
IMAGE_NAME=$3        # 镜像名称，如 simple-api-pipeline
IMAGE_TAG_RAW=$4     # 原始镜像标签，如 origin/dev
EXPOSE_PORT=$5       # 宿主机端口，如 8082

# ========== 参数校验 ==========
if [ $# -ne 5 ]; then
  echo "❌ 参数错误：需要 5 个参数"
  echo "✅ 用法: sh deploy.sh <harbor地址> <项目名> <镜像名> <镜像标签> <宿主机端口>"
  echo "例如: sh deploy.sh proxy.harbor.orb.local repo simple-api-pipeline origin/dev 8082"
  exit 1
fi

# ========== 构建镜像标签 ==========
IMAGE_TAG=$(echo "$IMAGE_TAG_RAW" | sed 's|/|-|g')
LOCAL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
HARBOR_IMAGE="${HARBOR_ADDR}/${HARBOR_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"
CONTAINER_NAME="${IMAGE_NAME}"

# 确保 docker 命令可执行
export PATH=/usr/local/bin:$PATH

echo "🟢 Local 镜像地址: $LOCAL_IMAGE"
echo "🟢 Harbor 镜像地址: $HARBOR_IMAGE"
echo "🟢 容器端口映射: $EXPOSE_PORT -> 8080"

# ========== 停止并删除已有容器（by 容器名称） ==========
if docker ps -a --format '{{.Names}}' | grep -Fx "$CONTAINER_NAME" >/dev/null; then
  echo "🔄 停止并删除旧容器: $CONTAINER_NAME"
  docker stop "$CONTAINER_NAME"
  docker rm "$CONTAINER_NAME"
else
  echo "✅ 无旧容器运行"
fi

# ========== 删除本地及Harbor镜像（by 容器标签） ==========
for IMG in "$LOCAL_IMAGE" "$HARBOR_IMAGE"; do
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -Fx "$IMG" >/dev/null; then
    echo "🧹 删除本地旧镜像: $IMG"
    docker rmi "$IMG"
  fi
done

# ========== 拉取 Harbor 镜像（学习环境下拉取省略登录） ==========
echo "📥 拉取 Harbor 镜像: $HARBOR_IMAGE"
docker pull "$HARBOR_IMAGE"
if [ $? -ne 0 ]; then
  echo "❌ 镜像拉取失败，请检查 Harbor 仓库或网络连接"
  exit 1
fi

## ========== 启动容器 ==========
echo "🚀 启动新容器: $CONTAINER_NAME"
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "$EXPOSE_PORT":8080 \
  "$HARBOR_IMAGE"

if [ $? -eq 0 ]; then
  echo "✅ 部署成功，容器 $CONTAINER_NAME 正在运行在端口 $EXPOSE_PORT"
else
  echo "❌ 容器启动失败，请检查镜像或端口冲突"
  exit 1
fi