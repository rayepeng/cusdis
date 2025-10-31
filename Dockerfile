FROM node:18-alpine3.18 as builder

VOLUME [ "/data" ]

ARG DB_TYPE=sqlite
ENV DB_TYPE=$DB_TYPE

RUN apk add --no-cache python3 py3-pip make gcc g++ openssl1.1-compat

WORKDIR /app

# 先复制依赖文件以利用Docker缓存
COPY package.json yarn.lock ./

# 配置yarn使用淘宝镜像源并安装依赖
RUN yarn config set registry https://registry.npmmirror.com/ && \
    yarn install --network-timeout 100000 && \
    npx browserslist@latest --update-db

# 复制所有源代码
COPY . .

# 构建应用
RUN npm run build:without-migrate

FROM node:18-alpine3.18 as runner

# 安装 OpenSSL 以支持 Prisma
RUN apk add --no-cache openssl1.1-compat

ENV NODE_ENV=production
ARG DB_TYPE=sqlite
ENV DB_TYPE=$DB_TYPE

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY . /app

EXPOSE 3000/tcp

CMD ["npm", "run", "start:with-migrate"]
