FROM jhpoelen/taxonworks-base
MAINTAINER Matt Yoder
ENV LAST_FULL_REBUILD 2018-05-10

ADD config/docker/nginx/gzip_max.conf /etc/nginx/conf.d/gzip_max.conf

ADD package.json /app/
ADD package-lock.json /app/
ADD Gemfile /app/
ADD Gemfile.lock /app/

WORKDIR /app

RUN bundle install --without=development test
RUN npm install 
# RUN npm run increase-memory-limit

COPY . /app

# See https://github.com/phusion/passenger-docker 
RUN mkdir -p /etc/my_init.d
ADD config/docker/nginx/init.sh /etc/my_init.d/init.sh
RUN chmod +x /etc/my_init.d/init.sh && \
    mkdir /app/tmp && \
    mkdir /app/log && \
    mkdir /app/public/packs && \
    mkdir /app/public/images/tmp && \
    chmod +x /app/public/images/tmp && \
    rm -f /etc/service/nginx/down



RUN chown 9999:9999 /app/public
RUN chown 9999:9999 /app/public/images/tmp
RUN chown 9999:9999 /app/public/packs
RUN chown 9999:9999 /app/log/

RUN touch /app/log/production.log
RUN chmod 0664 /app/log/production.log

CMD ["/sbin/my_init"]



