# ⚔️ 三省六部 · Demo Dashboard
# docker run -p 8989:8989 cft0808/sansheng-demo
# Then open: http://localhost:8989

# Stage 1: 构建 React 前端
FROM --platform=${BUILDPLATFORM:-linux/amd64} node:20-alpine AS frontend-build
WORKDIR /build
COPY edict/frontend/package.json edict/frontend/package-lock.json ./
RUN npm ci --silent
COPY edict/frontend/ ./
# Build 输出到 /build/dist（vite.config 中 outDir 是相对路径，这里重写）
RUN npx vite build --outDir /build/dist

# Stage 2: 运行时 (支持双 A100 GPU)
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

# 避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# GPU 相关环境变量
ENV NVIDIA_VISIBLE_DEVICES=all
ENV CUDA_VISIBLE_DEVICES=0,1

WORKDIR /app

# 安装 Python 3.11 和系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3-pip \
    python3.11-venv \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 安装 Python 依赖
RUN pip3 install --no-cache-dir fastapi uvicorn websockets pyyaml aiohttp psutil nvidia-ml-py3 || true

# 复制看板核心文件
COPY dashboard/ ./dashboard/
COPY scripts/ ./scripts/

# 复制 React 构建产物
COPY --from=frontend-build /build/dist ./dashboard/dist/

# 注入演示数据
COPY docker/demo_data/ ./data/

# 创建数据目录挂载点 (用于挂载 /mnt/data)
RUN mkdir -p /mnt/data /root/.openclaw

# 非 root 用户运行 (保持原有权限设置)
RUN groupadd -r appuser && useradd -r -g appuser -d /app appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8989

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8989/healthz')" || exit 1

CMD ["python3", "dashboard/server.py", "--host", "0.0.0.0", "--port", "8989"]
