FROM base/archlinux
MAINTAINER Chris Lucas

ENV MIX_ENV prod

RUN pacman -Syu --noconfirm && pacman -S --noconfirm sed elixir nodejs npm grep awk
RUN npm i -g brunch

EXPOSE 8080

ADD . /tvdb

WORKDIR /tvdb
RUN chmod +x build.sh
CMD ./build.sh
