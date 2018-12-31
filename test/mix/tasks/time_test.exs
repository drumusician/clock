
defmodule Mix.Tasks.TimeTest do
  use ExUnit.Case, async: true

  describe "run/1" do
    test "it outputs the current time" do
      Mix.Tasks.Time.run([])

      assert_received {:mix_shell, :info, [time]}

      current_time =
      :calendar.local_time
      |> NaiveDateTime.from_erl!
      |> NaiveDateTime.to_time
      |> to_string

      assert time == current_time
    end

    test "it accepts a timezone as an argument" do
      Mix.Tasks.Time.run(["Europe/Amsterdam"])

      assert_received {:mix_shell, :info, [time]}

      {:ok, current_date_time_in_time_zone} = DateTime.now("Europe/Amsterdam")

      current_time =
        current_date_time_in_time_zone
        |> DateTime.truncate(:second)
        |> DateTime.to_time
        |> to_string()


      assert time == "time in Amsterdam: #{current_time}"
    end

    test "it shows if the new year has arrived" do
      Mix.Tasks.Time.run(["Australia/Sydney"])

      assert_received {:mix_shell, :info, [time]}

      {:ok, current_date_time_in_time_zone} = DateTime.now("Australia/Sydney")

      current_time =
        current_date_time_in_time_zone
        |> DateTime.truncate(:second)
        |> DateTime.to_time
        |> to_string()


      assert time == current_time <> " Happy New Year Sydney!"
    end
  end
end
