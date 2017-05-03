defmodule TVDBCalendar.UserController do
  use TVDBCalendar.Web, :controller

  @valid_params ["days_before", "days_after"]
  def update(conn, params) do
    id = get_session(conn, :uid)

    params
    |> Enum.filter(&Enum.member?(@valid_params, elem(&1, 0)))
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.map(fn {k, v} ->
      cond do
        v == "infinity" ->
          {k, :infinity}
        k in [:days_before, :days_after] ->
          {k, String.to_integer(v)}
        true ->
          {k, v}
      end
    end)
    |> Enum.each(fn {k, v} -> TVDBCalendar.Repo.Store.put_setting(id, k, v) end)

    send_resp(conn, 201, "")
  end
end
