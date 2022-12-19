defmodule DawnChorusFeed do
  @domain "https://chorus.mohiohio.com/"

  def main(args) do
    IO.puts(args |> Enum.take(1) |> create_feed())
  end

  # @spec create_feed(String.t()) :: String.t()
  def create_feed(directory) do
    import XmlBuilder

    generate({
      :rss,
      [version: 2, "xmlns:itunes": "http://www.itunes.com/dtds/podcast-1.0.dtd"],
      [
        {
          :channel,
          nil,
          [
            {:title, nil, "Dawn Chorus"},
            {:link, nil, @domain},
            {:language, nil, "en-us"},
            {"itunes:author", nil, "Tim Field"},
            {:description, nil,
             "Bird song field recordings from Leith Valley, Dunedin, New Zealand"},
            {"itunes:owner", nil,
             [{"itunes:name", nil, "Tim Field"}, {"itunes:email", nil, "tim@mohiohoi.com"}]},
            {"itunes:image", %{href: @domain <> "feed.jpg"}, nil},
            {"itunes:category", %{text: "Science"},
             [{"itunes:category", %{text: "Nature"}, nil}]},
            {"itunes:explicit", nil, "false"},
            directory
            |> File.ls!()
            |> Enum.sort(:desc)
            |> Enum.filter(fn fileName -> !String.starts_with?(fileName, ".") end)
            |> Enum.map(fn fileName ->
              get_entry(directory, fileName)
            end)
          ]
        }
      ]
    })
  end

  defp get_entry(directory, fileName) do
    import XmlBuilder

    date = fileName |> parseDate()
    url = @domain <> "audio/" <> fileName
    fileSize = File.stat!(Path.join([directory, fileName])).size

    element(:item, nil, [
      {:title, nil, "Leith valley at " <> Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")},
      {:description, nil,
       "A field recording of birdsong in Leith valley. Recorded at " <>
         Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")},
      {:enclosure, %{length: fileSize, type: "audio/ogg", url: url}}
    ])
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
