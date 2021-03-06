defmodule TVDBCalendar.PageView do
  use TVDBCalendar.Web, :view

  @before_opts [
    {"a month ago", 31},
    {"a week ago", 7},
    {"today", 0}
  ]

  @after_opts [
    {"next week", 7},
    {"next month", 31},
    {"forever", :infinity}
  ]

  def airs_before_select(cur_setting, attrs \\ []) do
    _select(:days_before, @before_opts, cur_setting, attrs)
  end

  def airs_after_select(cur_setting, attrs \\ []) do
    _select(:days_after, @after_opts, cur_setting, attrs)
  end

  defp _select(name, options, selected_value, attrs) do
    attrs = Keyword.put(attrs, :name, name)
    content_tag :select, attrs do
      Enum.map(options, fn {text, value} ->
        content_tag(:option, text, [selected: value == selected_value, value: value])
      end)
    end
  end
end
