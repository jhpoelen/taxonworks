# image based on local Dockerfile.base
FROM jhpoelen/taxonworks:base
MAINTAINER Matt Yoder
ENV LAST_FULL_REBUILD 2018-08-10

CMD ["/sbin/my_init"]
