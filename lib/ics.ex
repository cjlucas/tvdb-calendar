defmodule ICS do
  def encode(events) do

    [
      "BEGIN:VCALENDAR\r\n",
      "VERSION:2.0\r\n",
      Enum.map(events, &ICS.Event.encode/1),
      "END:VCALENDAR\r\n",
    ]
  end
end
