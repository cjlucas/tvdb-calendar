defmodule ICS.PropValueType do

  @moduledoc false


  def boolean(val) do
    if val, do: "TRUE", else: "FALSE"
  end

  def text(val) when is_nil(val), do: []
  def text(val) do
    val
    |> String.to_charlist
    |> Enum.map(fn c ->
      cond do
        c in [92, ?;, ?,, 12] ->
          [92, c]
        c > 255 ->
          <<c::utf8>>
        true ->
          c
      end
    end)
  end

  @date_fmt ExPrintf.parse_printf("%d%02d%02d")
  @time_fmt ExPrintf.parse_printf("%02d%02d%02d")
  @date_time_fmt ExPrintf.parse_printf("%d%02d%02dT%02d%02d%02d")

  def date(%Date{year: year, month: month, day: day}) do
    :io_lib.format(@date_fmt, [year, month, day])
  end

  def time(%Time{hour: hour, minute: minute, second: second}) do
    :io_lib.format(@time_fmt, [hour, minute, second])
  end

  def date_time(%NaiveDateTime{year: y, month: mo, day: d, hour: h, minute: mi, second: s}) do
    :io_lib.format(@date_time_fmt, [y, mo, d, h, mi, s])
  end
  def date_time(%DateTime{year: y, month: mo, day: d, hour: h, minute: mi, second: s}) do
    :io_lib.format(@date_time_fmt, [y, mo, d, h, mi, s])
  end

  def integer(val) do
    Integer.to_string(val)
  end

  def float(val) do
    Float.to_string(val)
  end

  def binary(val) do
    Base.encode64(val)
  end
end
