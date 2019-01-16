defmodule Mix.Tasks.Time do
  use Mix.Task

  @shortdoc "A mix clock that can tell time. ;)"

  def run([]) do
    time =
      :calendar.local_time()
      |> NaiveDateTime.from_erl!()
      |> NaiveDateTime.to_time()
      |> to_string

    Mix.shell().info(time)
  end

  def run(args) do
    Mix.Task.run "app.start"

    {opts, [time_zone], _} = OptionParser.parse(args, strict: [am_pm: :boolean])
    {:ok, current_date_time_in_time_zone} = DateTime.now(time_zone)

    output = format_output(current_date_time_in_time_zone, time_zone, opts)

    Mix.shell().info(output)
  end

  def format_output(date_time, time_zone, opts \\ []) do
    time = time(date_time)
    {time, suffix} = suffix(time, opts)
    city = city(time_zone)

    case day_of_the_year(date_time) do
      1 ->
        time <> suffix <> " Happy New Year #{city}!"

      _ ->
        "time in #{city}: #{time} " <> suffix
    end
  end

  defp suffix(time, [am_pm: am_pm]) when am_pm do
    hour = String.split(time, ":") |> List.first |> String.to_integer
    {convert_pm(time), suffix(hour)}
  end

  defp suffix(time, _), do: {time, ""}
  defp suffix(hour) when hour < 12, do: "am"
  defp suffix(hour) when hour > 12, do: "pm"

  defp city(time_zone) do
    String.split(time_zone, "/")
    |> Enum.drop(1)
    |> to_string()
  end

  defp day_of_the_year(date_time) do
    date_time
    |> DateTime.to_date()
    |> Date.day_of_year()
  end

  defp time(date_time) do
    date_time
    |> DateTime.to_naive
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_time()
    |> to_string()
  end

  defp convert_pm(time) do
    case hour(time) > 12 do
      true ->
        [h, m, s] = time |> String.split(":") |> Enum.map(&String.to_integer/1)
        {:ok, time} = Time.new(h, m, s)

        time
        |> Time.add(43200, :second)
        |> Time.truncate(:second)
        |> to_string
      _ ->
        time
    end
  end

  defp hour(time) do
    time
    |> to_string()
    |> String.split(":")
    |> List.first
    |> String.to_integer
  end
end
