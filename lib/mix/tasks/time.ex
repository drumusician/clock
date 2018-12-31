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

  def run([time_zone]) do
    Mix.Task.run "app.start"

    {:ok, current_date_time_in_time_zone} = DateTime.now(time_zone)

    day_of_year =
      current_date_time_in_time_zone
      |> DateTime.to_date()
      |> Date.day_of_year()

    city =
      String.split(time_zone, "/")
      |> Enum.drop(1)
      |> to_string()

    time =
      current_date_time_in_time_zone
      |> DateTime.truncate(:second)
      |> DateTime.to_time()
      |> to_string()

    output =
      case day_of_year do
        1 ->
          "#{time} Happy New Year #{city}!"

        _ ->
          "time in #{city}: #{time}"
      end

    Mix.shell().info(output)
  end
end
