defmodule TVDBCalendar.PageView do
  use TVDBCalendar.Web, :view

  @before_opts [
    {"a month ago", 31},
    {"a week ago", 7},
    {"today", 0}
  ]

  @after_opts [
    {"one week from now", 7},
    {"one month from now", 31},
    {"forever", :infinity}
  ]

  def airs_before_select(cur_setting, attrs \\ []) do
    _select(:days_before, @before_opts, cur_setting, attrs)
  end

  def airs_after_select(cur_setting, attrs \\ []) do
    _select(:days_after, @after_opts, cur_setting, attrs)
  end

  defp _select(name, options, selected_value, attrs \\ []) do
    IO.puts ("in _select #{inspect options} #{inspect selected_value}")
    attrs = Keyword.put(attrs, :name, name)
    content_tag :select, attrs do
      Enum.map(options, fn {text, value} ->
        content_tag(:option, text, [selected: value == selected_value, value: value])
      end)
    end
  end
end
