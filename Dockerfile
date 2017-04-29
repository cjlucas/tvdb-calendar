FROM gentoo/stage3-amd64
MAINTAINER Chris Lucas

ENV MIX_ENV prod

RUN echo "dev-lang/elixir ~amd64" >> /etc/portage/package.accept_keywords
# Required by nodejs-6.9.4
RUN echo "dev-libs/openssl -bindist" >> /etc/portage/package.use/nodejs
RUN emerge-webrsync && emerge --unmerge openssh && emerge --jobs=4 elixir nodejs && rm -rf /usr/portage /var/tmp/portage
RUN npm i -g brunch

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
ENV LANG en_US.utf8
ENV LC_ALL en_US.utf8

ADD . /tvdb

WORKDIR /tvdb
RUN chmod +x build.sh
CMD ./build.sh
