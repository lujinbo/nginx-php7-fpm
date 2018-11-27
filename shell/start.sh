#!/bin/bash
# 启动nginx
nginx
# 启动php-fpm
php-fpm7 -R

tail -f /dev/null

