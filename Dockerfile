# 第一阶段：构建静态文件
# 建议加上 -alpine，镜像体积会从 900MB 缩减到 100MB 左右，构建更快
FROM node:20-alpine AS base
WORKDIR /app

# 启用 corepack 并准备 pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# 只有在 Alpine 系统下，sharp 可能需要额外的 libc 兼容库（可选但稳妥）
RUN apk add --no-cache libc6-compat

# 复制依赖描述文件
COPY package.json pnpm-lock.yaml* ./

# 安装依赖
# 注意：这里会触发你 package.json 里的 onlyBuiltDependencies
RUN pnpm install --frozen-lockfile

# 复制源码并构建
COPY . .
RUN pnpm run build

# 第二阶段：运行环境
# 使用 mainline-alpine-slim 是极佳的选择，非常轻量
FROM nginx:mainline-alpine-slim AS runtime

# 拷贝构建好的静态文件到 Nginx 目录
COPY --from=base /app/dist /usr/share/nginx/html

# 映射 80 端口
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
