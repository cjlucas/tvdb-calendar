mix local.hex --force
mix local.rebar --force
mix deps.get
npm i >> /dev/null
brunch build --production
mix phx.digest

if [[ $UP_FROM != "" ]]; then
    echo "Building release to upgrade from version $UP_FROM"
    mix release --upgrade --upfrom=$UP_FROM
else
    echo "$UP_FROM was not specified, won't specifying --upgrade"
    mix release
fi

cp -v _build/prod/rel/tvdb_calendar/releases/$APP_VERSION/tvdb_calendar.tar.gz /artifacts/tvdb_calendar-$APP_VERSION.tar.gz
