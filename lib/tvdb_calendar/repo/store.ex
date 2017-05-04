defmodule TVDBCalendar.Repo.Store do
  use GenServer

  @vsn 1

  @default_table :repo_store

  @type setting :: :days_before | :days_after

  @type settings :: [
    days_before: number,
    days_after: number | :infinity
  ]

  @type record :: %{id: binary, username: binary, key: binary, settings: settings}

  @defaults [days_before: 30, days_after: :infinity]

  @settings Keyword.keys(@defaults)

  defmodule State do
    defstruct table: :repo_store, id_map: Map.new
  end

  def start_link(table \\ @default_table) do
    GenServer.start_link(__MODULE__, table, name: __MODULE__)
  end

  def init(table) do
    :dets.open_file(table, type: :set)
   
    id_map =
      :dets.match(table, :"$1")
      |> Enum.map(&List.first/1)
      |> Enum.reduce(Map.new, fn {user, vals}, acc ->
        id  = Keyword.get(vals, :id)
        Map.put(acc, id, user)
      end)

    {:ok, %State{table: table, id_map: id_map}}
  end

  def all_users do
    GenServer.call(__MODULE__, :all_users)
  end

	def add_user(username, user_key) do
    GenServer.call(__MODULE__, {:add_user, username, user_key})
  end

  def user_by_id(id) do
    GenServer.call(__MODULE__, {:user_by_id, id})
  end

  def user_by_name(name) do
    GenServer.call(__MODULE__, {:user_by_name, name})
  end

  def put_setting(id, setting, value) when setting in @settings do
    GenServer.call(__MODULE__, {:put_setting, id, setting, value})
  end
  def put_setting(_id, _setting, _value) do
    {:error, :unknown_setting}
  end

  def handle_call(:all_users, _from, state) do
    %{table: table, id_map: map} = state

    users =
      Map.values(map)
      |> Enum.map(&lookup_user(table, &1))
      |> Enum.filter(&elem(&1, 0) == :ok)
      |> Enum.map(&elem(&1, 1))

    {:reply, users, state}
  end
  
  def handle_call({:add_user, username, user_key}, _from, state) do
    %{id_map: map, table: table} = state

    id = UUID.uuid4()
    if :dets.insert_new(table, {username, [id: id, key: user_key]}) do
      ret = %{id: id, username: username, key: user_key}
      {:reply, {:ok, ret}, %{state | id_map: Map.put(map, id, username)}}
    else
      {:reply, {:error, :user_exists}, state}
    end
  end

  def handle_call({:user_by_id, id}, _from, state) do
    %{id_map: map, table: table} = state

    ret = case Map.get(map, id) do
      user when is_binary(user) ->
        lookup_user(table, user)
      _ ->
        {:error, :no_user_found}
    end

    {:reply, ret, state}
  end

  def handle_call({:user_by_name, name}, _from, state) do
    %{table: table} = state
    {:reply, lookup_user(table, name), state}
  end

  def handle_call({:put_setting, id, setting, value}, _from, state) do
    %{table: table, id_map: map} = state

    ret = 
      case Map.get(map, id) do
        user when is_binary(user) ->
          case lookup_user(table, user) do
          {:ok, record} ->
            record = 
              record
              |> Enum.into([])
              |> Keyword.update(:settings, [{setting, value}], &Keyword.put(&1, setting, value))

            :dets.insert(table, {user, record})
          {:error, reason} ->
            {:error, reason}
          end
        _ ->
          {:error, :no_user_found}
      end

    {:reply, ret, state}
  end

  defp lookup_user(table, user) do
    case :dets.lookup(table, user) do
      [] ->
        {:error, :no_user_found}
      [{user, record}] ->
        record =
          record
          |> Keyword.update(:settings, @defaults, &Keyword.merge(@defaults, &1))
          |> Keyword.put(:username, user)
          |> Enum.into(%{})

        {:ok, record}
    end
  end

  def terminate(_reason, table) do
    :dets.close(table)
  end
end
