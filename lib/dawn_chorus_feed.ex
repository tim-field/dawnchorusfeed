defmodule DawnChorusFeed do
  @domain "https://chorus.mohiohio.com"

  def main(args) do
    IO.puts(args |> Enum.take(1) |> create_feed())
  end

  # @spec create_feed(String.t()) :: String.t()
  def create_feed(directory) do
    alias Atomex.Feed

    Feed.new(@domain, DateTime.utc_now(), "Leith Valley Dawn Chorus")
    |> Feed.author("Tim Field", email: "tim@mohiohio.com")
    |> Feed.link(@domain <> "feed.xml", rel: "self")
    |> Feed.entries(
      directory
      |> File.ls!()
      |> Enum.map(fn fileName ->
        get_entry(directory, fileName)
      end)
    )
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(directory, fileName) do
    alias Atomex.Entry
    date = fileName |> parseDate()

    Entry.new(
      fileName,
      date,
      "Leith valley at " <> Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")
    )
    |> Entry.link(@domain <> "/audio/" <> fileName,
      rel: "enclosure",
      type: "audio/ogg",
      length: File.stat!(Path.join([directory, fileName])).size
    )
  end

  @spec parseDate(String.t()) :: DateTime.t()
  defp parseDate(fileName) do
    parsed =
      Regex.named_captures(
        ~r/(?<year>[0-9]{4})-(?<month>[0-9]{2})-(?<day>[0-9]{2})T(?<hour>[0-9]{2})-(?<minute>[0-9]{2})-(?<second>[0-9]{2})/,
        fileName
      )

    date =
      Date.new!(
        String.to_integer(parsed["year"]),
        String.to_integer(parsed["month"]),
        String.to_integer(parsed["day"])
      )

    time =
      Time.new!(
        String.to_integer(parsed["hour"]),
        String.to_integer(parsed["minute"]),
        String.to_integer(parsed["second"])
      )

    DateTime.new!(date, time, "Pacific/Auckland", Tz.TimeZoneDatabase)
  end
end
