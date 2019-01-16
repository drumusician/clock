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
    Mix.Task.run("app.start")

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
        to_string(time) <> suffix <> " Happy New Year #{city}!"

      _ ->
        "time in #{city}: #{to_string(time)} " <> suffix
    end
  end

  defp suffix(%Time{hour: hour} = time, am_pm: am_pm) when am_pm do
    {convert_pm(time), suffix(hour)}
  end

  defp suffix(time, _), do: {time, ""}
  defp suffix(hour) when hour < 12, do: "am"
  defp suffix(_hour), do: "pm"

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
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_time()
  end

  defp convert_pm(%Time{hour: hour} = time)
       when hour == 12 do
    time
  end

  defp convert_pm(%Time{hour: hour, minute: minute, second: second}) do
    {:ok, time} = Time.new(rem(hour, 12), minute, second)

    time
  end
end
