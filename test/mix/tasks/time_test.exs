
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
  end
end
