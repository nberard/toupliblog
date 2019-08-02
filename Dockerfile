FROM nginx
MAINTAINER Nicolas Berard "berard.nicolas@gmail.com"

ADD docker/nginx.conf /etc/nginx/conf.d/default.conf

ENV HEXO_VERSION 3.1.1

RUN apt-get update && apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get update && apt-get install -y curl git nodejs
RUN npm install -g hexo@${HEXO_VERSION}

WORKDIR /tmp/build

COPY . ./

RUN npm install
RUN hexo deploy
WORKDIR /usr/share/nginx/html
RUN mv /tmp/build/public  ./
COPY favicon.ico ./public/

CMD nginx -g "daemon off;"
