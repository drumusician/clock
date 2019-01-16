
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


      assert time == "time in Amsterdam: #{current_time} "
    end

    test "the output contains a New Year greeting on the first day of the year" do
      time = ~T[02:00:00.005]
      date = ~D[2019-01-01]
      {:ok, date_time} = NaiveDateTime.new(date, time)

      output = Mix.Tasks.Time.format_output(date_time, "Australia/Sydney")
      truncated_time = time |> Time.truncate(:second) |> to_string()

      assert output == truncated_time <> " Happy New Year Sydney!"
    end

    test "the time is updated when it is pm" do
      time = ~T[13:00:00.005]
      date = ~D[2019-01-02]
      {:ok, date_time} = NaiveDateTime.new(date, time)

      output = Mix.Tasks.Time.format_output(date_time, "Europe/Amsterdam", [am_pm: true])

      assert output == "time in Amsterdam: 01:00:00 pm"
    end

    test "the output can be switched to 12-hour format with a flag" do
      Mix.Tasks.Time.run(["Europe/Amsterdam","--am-pm"])

      assert_received {:mix_shell, :info, [time]}

      {:ok, current_date_time_in_time_zone} = DateTime.now("Europe/Amsterdam")

      current_time =
        current_date_time_in_time_zone
        |> DateTime.truncate(:second)
        |> DateTime.to_time
        |> to_string()

      hour = String.split(current_time, ":") |> List.first |> String.to_integer

      assert time == "time in Amsterdam: #{current_time}" <> " #{suffix(hour)}"
    end

    defp suffix(hour) when hour < 12, do: "am"
    defp suffix(_), do: "pm"
  end
end
