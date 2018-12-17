defmodule Mix.Tasks.Time do
  use Mix.Task

  def run(_argv) do
    time =
    :calendar.local_time
    |> NaiveDateTime.from_erl!
    |> NaiveDateTime.to_time
    |> to_string

    Mix.shell.info(time)
  end
end
