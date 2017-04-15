defmodule ICS.Event do
  defstruct [:description, :dtstart, :dtend, :summary, :location]

  def encode(event) do
    import ICS.PropValueType

    [
      ["BEGIN:VEVENT\r\n"],
      ["DESCRIPTION:", text(event.description), "\r\n"],
      ["DTSTART:", date_time(event.dtstart), "\r\n"],
      ["DTEND:", date_time(event.dtend), "\r\n"],
      ["SUMMARY:", text(event.summary), "\r\n"],
      ["LOCATION:", text(event.location), "\r\n"],
      ["END:VEVENT\r\n"],
    ]
  end
end
