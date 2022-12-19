defmodule DawnChorusFeed do
  @domain "https://chorus.mohiohio.com/"

  def main(args) do
    IO.puts(args |> Enum.take(1) |> create_feed())
  end

  # @spec create_feed(String.t()) :: String.t()
  def create_feed(directory) do
    alias Atomex.Feed

    Feed.new(@domain, DateTime.utc_now(), "Leith Valley Dawn Chorus")
    |> Feed.author("Tim Field", email: "tim@mohiohio.com")
    |> Feed.add_field(
      :description,
      nil,
      "Bird song field recordings from Leith Valley, Dunedin, New Zealand"
    )
    |> Feed.add_field(XmlBuilder.generate({:image, nil, [{:url, nil, @domain <> "feed.jpg"}]}))
    |> Feed.add_field("itunes:image", nil, @domain <> "feed.jpg")
    |> Feed.add_field("itunes:category", nil, "Nature")
    |> Feed.add_field(:language, nil, "en-us")
    |> Feed.add_field("itunes:explicit", nil, "False")
    |> Feed.add_field("itunes:author", nil, "tim@mohiohio.com")
    |> Feed.link(@domain <> "feed.xml", rel: "self")
    |> Feed.entries(
      directory
      |> File.ls!()
      |> Enum.sort(:desc)
      |> Enum.filter(fn fileName -> !String.starts_with?(fileName, ".") end)
      |> Enum.map(fn fileName ->
        get_entry(directory, fileName)
      end)
    )
    |> Feed.build(%{"xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd"})
    |> Atomex.generate_document()
  end

  defp get_entry(directory, fileName) do
    alias Atomex.Entry
    date = fileName |> parseDate()
    url = @domain <> "audio/" <> fileName
    fileSize = File.stat!(Path.join([directory, fileName])).size

    Entry.new(
      url,
      date,
      "Leith valley at " <> Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")
    )
    |> Entry.add_field(
      :enclosure,
      %{
        url: url,
        rel: "enclosure",
        type: "audio/ogg",
        length: fileSize
      },
      nil
    )
    |> Entry.summary(
      "A field recording of birdsong in Leith valley. Recorded at " <>
        Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")
    )
    |> Entry.build()
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
