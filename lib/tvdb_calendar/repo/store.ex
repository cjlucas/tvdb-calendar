defmodule TVDBCalendar.Repo.Store do
  use GenServer

  @vsn 1

  @default_table :repo_store

  @type record :: %{id: binary, username: binary, key: binary}

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

  def handle_call(:all_users, _from, state) do
    %{table: table} = state

    users =
      :dets.match_object(table, :"$1")
      |> Enum.map(fn {username, record} ->
        Keyword.put(record, :username, username) |> Enum.into(%{})
      end)
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

  defp lookup_user(table, user) do
    case :dets.lookup(table, user) do
      [] ->
        {:error, :no_user_found}
      [record] ->
        record =
          record
          |> elem(1)
          |> Keyword.put(:username, user)
          |> Enum.into(%{})

        {:ok, record}
    end
  end

  def terminate(_reason, table) do
    :dets.close(table)
  end
end
