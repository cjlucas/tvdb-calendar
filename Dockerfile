FROM ubuntu:18.04
MAINTAINER Chris Lucas

ENV MIX_ENV prod

RUN apt-get update && apt-get install -y gnupg wget locales npm

RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
    dpkg -i erlang-solutions_1.0_all.deb && \
        apt-get update && \
            apt-get install -y esl-erlang=1:21.1 elixir=1.8.2-1


RUN npm i -g brunch

RUN locale-gen en_US.UTF-8
ENV LANG en_US.utf8
ENV LC_ALL en_US.utf8

ADD . /tvdb

WORKDIR /tvdb
RUN chmod +x build.sh
CMD ./build.sh
