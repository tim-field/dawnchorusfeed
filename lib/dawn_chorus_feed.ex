defmodule DawnChorusFeed do
  @domain "https://chorus.mohiohio.com/"

  def main(args) do
    [audioDir, imageDir] = args
    IO.puts(create_feed(audioDir, imageDir))
  end

  # @spec create_feed(String.t()) :: String.t()
  def create_feed(audioDirectory, imageDirectory) do
    import XmlBuilder

    findImage = &get_image_file(get_images(imageDirectory), &1)

    generate({
      :rss,
      [
        version: "2.0",
        "xmlns:itunes": "http://www.itunes.com/dtds/podcast-1.0.dtd",
        "xmlns:atom": "http://www.w3.org/2005/Atom"
      ],
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
             [{"itunes:name", nil, "Tim Field"}, {"itunes:email", nil, "tim@mohiohio.com"}]},
            {"itunes:image", %{href: @domain <> "feed.jpg"}, nil},
            {"itunes:category", %{text: "Science"},
             [{"itunes:category", %{text: "Nature"}, nil}]},
            {"itunes:explicit", nil, "clean"},
            {"atom:link",
             %{href: @domain <> "feed.xml", rel: "self", type: "application/rss+xml"}, nil},
            audioDirectory
            |> File.ls!()
            |> Enum.sort(:desc)
            |> Enum.filter(fn fileName -> !String.starts_with?(fileName, ".") end)
            |> Enum.map(fn fileName ->
              get_entry(audioDirectory, fileName, findImage)
            end)
            |> Enum.filter(fn entry -> entry !== nil end)
          ]
        }
      ]
    })
  end

  defp get_image_file(images, audioDate) do
    imageDate =
      images
      |> Map.keys()
      |> Enum.reduce(nil, fn imageDate, min ->
        cond do
          min === nil ->
            imageDate

          abs(DateTime.diff(min, audioDate)) > abs(DateTime.diff(imageDate, audioDate)) ->
            imageDate

          true ->
            min
        end
      end)

    images[imageDate]
  end

  defp get_entry(directory, fileName, findImage) do
    import XmlBuilder

    date = fileName |> parseDate()

    if(date) do
      url = @domain <> "audio/" <> fileName
      fileSize = File.stat!(Path.join([directory, fileName])).size
      imageUrl = @domain <> "images/" <> findImage.(date)

      element(:item, nil, [
        {:title, nil, "Leith valley at " <> Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")},
        {:description, nil,
         "A field recording of birdsong in Leith valley. Recorded at " <>
           Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")},
        {:enclosure, %{length: fileSize, type: "audio/ogg", url: url}},
        {:pubDate, nil, Calendar.strftime(date, "%a, %d %b %Y %H:%M:%S %z")},
        {"itunes:image", %{href: imageUrl}, nil},
        {:guid, nil, url}
      ])
    end
  end

  defp get_images(directory) do
    directory
    |> File.ls!()
    |> Enum.filter(fn fileName ->
      !String.starts_with?(fileName, ".") and String.ends_with?(fileName, ".jpg")
    end)
    # |> Enum.sort(:desc)
    |> Enum.reduce(%{}, fn fileName, acc ->
      date = parseDate(fileName)

      if(date) do
        Map.put(acc, parseDate(fileName), fileName)
      else
        acc
      end
    end)
  end

  defp parseDate(fileName) do
    parsed =
      Regex.named_captures(
        ~r/(?<year>[0-9]{4})-(?<month>[0-9]{2})-(?<day>[0-9]{2})T(?<hour>[0-9]{2})-(?<minute>[0-9]{2})-(?<second>[0-9]{2})/,
        fileName
      )

    if(parsed) do
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
end
