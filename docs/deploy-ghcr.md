# GHCR 部署（推荐）

本仓库已配置 GitHub Actions：每次 `main` 更新会自动构建并推送镜像到 GHCR。

## 服务器部署

1. 安装 Docker + Docker Compose（v2）。
2. 克隆仓库并进入目录：

```bash
git clone https://github.com/XuF163/new-api.git
cd new-api
```

3. 创建 `.env`（建议至少设置 `SESSION_SECRET`）：

```bash
cat > .env <<'EOF'
NEW_API_PORT=6388
SESSION_SECRET=PLEASE_CHANGE_ME_TO_A_RANDOM_STRING
TZ=Asia/Shanghai
EOF
```

4. 启动（默认使用 GHCR 镜像）：

```bash
docker compose pull
docker compose up -d
```

访问：`http://<服务器IP>:6388`

## 可选：从源码构建

如果你不想用 GHCR 镜像，可以用 override compose 从本地源码构建：

```bash
docker compose -f docker-compose.yml -f docker-compose.build.yml up -d --build
```

