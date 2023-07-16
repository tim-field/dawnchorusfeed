defmodule DawnChorusFeed do
  @domain "https://chorus.mohiohio.com/"

  def main(args) do
    [audioDir, imageDir] = args
    IO.puts(create_feed(audioDir, imageDir))
  end

  # @spec create_feed(String.t()) :: String.t()
  def create_feed(audioDirectory, imageDirectory) do
    import XmlBuilder

    images = get_images(imageDirectory)
    findImage = &get_image_for_date(images, &1)

    generate({
      :rss,
      [
        version: "2.0",
        "xmlns:itunes": "http://www.itunes.com/dtds/podcast-1.0.dtd",
        "xmlns:atom": "http://www.w3.org/2005/Atom",
        "xmlns:mohiohio": "https://mohiohio.com/rss"
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
            {:description, nil, "New Zealand bird song recorded at sunrise each day"},
            {"itunes:owner", nil,
             [{"itunes:name", nil, "Tim Field"}, {"itunes:email", nil, "tim@mohiohio.com"}]},
            {"itunes:image",
             %{
               href:
                 @domain <>
                   "images/" <> findImage.(DateTime.now!("Pacific/Auckland", Tz.TimeZoneDatabase))
             }, nil},
            {"itunes:category", %{text: "Science"},
             [{"itunes:category", %{text: "Nature"}, nil}]},
            {"itunes:explicit", nil, "clean"},
            {"atom:link",
             %{href: @domain <> "feed.xml", rel: "self", type: "application/rss+xml"}, nil},
            audioDirectory
            |> File.ls!()
            |> Enum.sort(:desc)
            |> Enum.filter(fn fileName ->
              !String.starts_with?(fileName, ".")
            end)
            |> Enum.map(fn fileName ->
              get_entry(audioDirectory, fileName, findImage, images)
            end)
            |> Enum.filter(fn entry -> entry !== nil end)
          ]
        }
      ]
    })
  end

  defp get_image_for_date(images, compareDate) do
    imageDate =
      images
      |> Map.keys()
      |> Enum.reduce(nil, fn imageDate, min ->
        cond do
          min === nil ->
            imageDate

          abs(DateTime.diff(min, compareDate)) > abs(DateTime.diff(imageDate, compareDate)) ->
            imageDate

          true ->
            min
        end
      end)

    images[imageDate]
  end

  defp get_all_images_for_date(images, compareDate) do
    day =
      DateTime.to_string(compareDate)
      |> String.slice(1..9)

    images
    |> Map.filter(fn {date, _} ->
      DateTime.to_string(date)
      |> String.slice(1..9) == day
    end)
  end

  defp get_entry(directory, fileName, findImage, images) do
    import XmlBuilder

    date = fileName |> parseDate()

    if(date) do
      url = @domain <> "audio/" <> fileName
      fileSize = File.stat!(Path.join([directory, fileName])).size
      imageUrl = @domain <> "images/" <> findImage.(date)

      element(:item, nil, [
        {:title, nil, "Upper Waitati at " <> Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")},
        {:description, nil,
         "New Zealand birdsong recorded at " <>
           Calendar.strftime(date, "%I:%M%P on %B %-d, %Y")},
        {:enclosure, %{length: fileSize, type: "audio/ogg", url: url}},
        {:pubDate, nil, Calendar.strftime(date, "%a, %d %b %Y %H:%M:%S %z")},
        {"itunes:image", %{href: imageUrl}, nil},
        {:guid, nil, url},
        get_all_images_for_date(images, date)
        |> Enum.map(fn {date, fileName} ->
          {"mohiohio:image",
           %{href: @domain <> "images/" <> fileName, date: DateTime.to_iso8601(date)}, nil}
        end)
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
