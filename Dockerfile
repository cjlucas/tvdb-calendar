FROM gentoo/stage3-amd64
MAINTAINER Chris Lucas

ENV MIX_ENV prod

RUN echo "dev-lang/elixir ~amd64" >> /etc/portage/package.accept_keywords
RUN emerge-webrsync && emerge elixir nodejs
RUN npm i -g brunch

EXPOSE 8080

ADD . /tvdb

WORKDIR /tvdb
RUN chmod +x build.sh
CMD ./build.sh
