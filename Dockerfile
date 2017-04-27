FROM base/archlinux
MAINTAINER Chris Lucas

ENV MIX_ENV prod

RUN pacman -Syu --noconfirm && pacman -S --noconfirm sed elixir nodejs npm grep awk
RUN npm i -g brunch

EXPOSE 8080

ADD . /tvdb

WORKDIR /tvdb
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN npm i
RUN brunch build --production
RUN mix phx.digest
RUN mix release

RUN mkdir /artifacts
RUN cp _build/prod/rel/tvdb_calendar/releases/$APP_VERSION/tvdb_calendar.tar.gz /artifacts/tvdb_calendar-$APP_VERSION.tar.gz
VOLUME /artifacts
