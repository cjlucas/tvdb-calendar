defmodule TVDBCalendar.Repo.StoreTest do
  alias TVDBCalendar.Repo.Store

  use ExUnit.Case

  setup do
    {:ok, pid} = Store.start_link(:test_repo_table)
    :ok

    on_exit fn ->
      if Process.alive?(pid) do
        GenServer.stop(pid)
      end

      File.rm!("test_repo_table")
    end
  end

  test "add_user/2 and lookup_user/1" do
    assert {:ok, record} = Store.add_user("foo", "bar")
    id = Map.get(record, :id)
    assert is_binary(id)
    assert Map.get(record, :username) == "foo"
    assert Map.get(record, :key) == "bar"
    assert Store.add_user("foo", "bar") == {:error, :user_exists}

    assert Store.lookup_user(id) == {:ok, %{id: id, username: "foo", key: "bar"}}
  end

  test "all_users/0" do
    {:ok, _} = Store.add_user("foo", "bar")
    {:ok, _} = Store.add_user("bar", "baz")

    users = Store.all_users
    assert is_list(users)
    assert length(users) == 2
  end
end
