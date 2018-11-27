# ucse php_test
FROM alpine:edge
LABEL author=duanxuqiang@ucse.net

# base 镜像
ENV TIMEZONE Asia/Shanghai
# 一些工作目录准备
RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/tmp/client_body_temp && \
    mkdir -p /var/lib/nginx && \
    mkdir -p /ucse/web && \
    # 修改镜像源为国内ustc.edu.cn(中科大)／aliyun.com(阿里云)／tuna.tsinghua.edu.cn（清华）
    # 近期阿里云不稳定，更换镜像为清华
    # main官方仓库，community社区仓库
    echo http://mirrors.aliyun.com/alpine/edge/main > /etc/apk/repositories && \
    echo http://mirrors.aliyun.com/alpine/edge/community >> /etc/apk/repositories && \
    # 更新系统和修改时区以及一些扩展apk update && apk upgrade -a &&  busybox-extras libc6-compat
    apk update && apk upgrade -a && apk add --no-cache tzdata curl wget bash git vim && \
    # 配置ll alias 命令
    echo "alias ll='ls -l --color=tty'" >> /etc/profile && \
    echo "source /etc/profile " >> ~/.bashrc && \
    # -X获取指定仓库的包
    apk add --no-cache -X http://mirrors.aliyun.com/alpine/edge/community neofetch && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone


# nginx 镜像
RUN apk add --no-cache nginx-mod-http-echo

# redis 镜像
RUN apk add --no-cache redis && \
    # 去掉安全模式
    sed -i "s|protected-mode yes|protected-mode no|" /etc/redis.conf && \
    # 支持远端连接
    sed -i "s|bind 127.0.0.1|# bind 127.0.0.1|" /etc/redis.conf

# PHP 镜像
RUN apk add --no-cache php7-fpm php7-common php7-pdo php7-pdo_mysql  php7-curl php7-redis php7-gd php7-openssl php7-json php7-pear php7-phar  php7-zip php7-zlib php7-iconv php-xml php-mbstring php7-mcrypt php7-tokenizer php7-ctype php7-fileinfo php7-sockets php7-dom php-xmlwriter  && \
# composer 中国镜像
    php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer && \
    # 设置中国镜像源
    composer config -g repo.packagist composer https://packagist.phpcomposer.com
#日志输出
RUN apk add --no-cache -X http://mirrors.aliyun.com/alpine/edge/testing filebeat
#开放端口
EXPOSE 8886 80 443 9000
#外部配置
COPY nginx_config /etc/nginx/
COPY php_config/conf /etc/php7/
COPY web_code /ucse/web/
COPY shell /shell
RUN cd /shell && chmod -R 777 /shell
COPY filebeat_config /etc/filebeat/

# 健康检查 --interval检查的间隔 超时timeout retries失败次数
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl --fail http://localhost || exit 1
# 启动
CMD ["/shell/start.sh"]
