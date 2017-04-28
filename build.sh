mix local.hex --force
mix local.rebar --force
mix deps.get
npm i
brunch build --production
mix phx.digest
mix release

#mkdir /artifacts
echo hithere
ls /artifacts
cp -v _build/prod/rel/tvdb_calendar/releases/$APP_VERSION/tvdb_calendar.tar.gz /artifacts/tvdb_calendar-$APP_VERSION.tar.gz
