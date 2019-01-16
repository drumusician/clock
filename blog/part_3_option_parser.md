## Things you could do with mix

### Part 3: OptionParser

Hello again! This is part 3 of my blog post exploring things you could do with mix. If you haven't read the first two you can find those and [here](https://www.theguild.nl/things-you-could-do-with-mix/) and [here](https://www.theguild.nl/thing-you-could-do-with-mix-2/). Last time we explored some new DateTime features in Elixir 1.8.0 and changed our output based on when the new year had arrived. The test we wrote for that was very brittle as it relied on the actual time. So let's start by making sure our full test suite is green again.

This is the test we wrote, checking if the new year had arrived.

```elixir
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
```

Now we could think about testing this by travelling in time or creating a mock of the current time, or something else that sounds way to complex. But let's tackle this from a different perspective. First let's take a closer look at our implementation of the `run/1` function that takes in the timezone.

```elixir
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
```

Now our failing test fails because the output doesn't match the new year greeting we got on the 31st of december. We can make this very testable by exctracting just that part out in a different function and testing that in isolation.

Let's create a new test for the new function we would like to see.

```elixir
test "the output contains a new years greeting on the first day of the year" do
  time = ~T[02:00:00.005]
  date = ~D[2019-01-01]
  {:ok, date_time} = NaiveDateTime.new(date, time)

  output = Mix.Tasks.Time.format_output(date_time, "Australia/Sydney")
  truncated_time = time |> Time.truncate(:second) |> to_string()

  assert output == truncated_time <> " Happy New Year Sydney!"
end
```

I have hardcoded the timezone here for now, but that is good enough for now.
We can make this test pass by creating the function extracting the output from the run function. We'll go ahead and extract the other conversions as private functions as well ending with the implementation below:

```elixir
def format_output(date_time, time_zone) do
  time = time(date_time)
  city = city(time_zone)

  case day_of_the_year(date_time) do
    1 ->
      "#{time} Happy New Year #{city}!"

    _ ->
      "time in #{city}: #{time}"
  end
end

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
```

Now that was a lot more refactoring than I initially thought I would do, but we pulled this out into separate functions very nicely!

As promised in the title of this post, let's talk about [OptionParser](https://hexdocs.pm/elixir/OptionParser.html). Basically `OptionParser` brings us some nice and convenient ways to add aliases and convert our arguments into options and switches.

As always let's test our way into our implementation. We want to be able to add a flag to our clock that will output the time in either 12- or 24-hour format. The current output uses 24 hour time, so we need to convert that to am / pm.

Here is our test. I have created a helpser function to create the am or pm in our test.

```elixir
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

  assert time == "time in Amsterdam: #{current_time}" <> suffix(hour)
end

defp suffix(hour) when hour < 12, do: "am"
defp suffix(_), do: "pm"
```

This test immediately fails hard because it expects only a timezone as an argument. That is where `OptionParser` comes in. OptionParser has a [`parse/2`](https://hexdocs.pm/elixir/OptionParser.html#parse/2) function that takes the arguments from the commandline with a list of options and returns a 3 element tuple containing { parsed_switches, remaining arguments, invalid_options }. I highly recommend using `:strict` mode which let's you define exactly what switches you allow along with the types you expect.

Here is our changed `run/1` function using `OptionParser`.

```elixir
def run(args) do
  Mix.Task.run "app.start"

  {opts, [time_zone], _} = OptionParser.parse(args, strict: [am_pm: :boolean])
  {:ok, current_date_time_in_time_zone} = DateTime.now(time_zone)

  output = format_output(current_date_time_in_time_zone, time_zone, opts)

  Mix.shell().info(output)
end
```

As you can see we are now passing the options from OptionParser into the format function as well. We update that so we can change the output accordingly. Below you see the new implementation adding a suffix function to handle our am/pm output when the flag is passed.

```elixir
def format_output(date_time, time_zone, opts \\ []) do
  time = time(date_time)
  city = city(time_zone)
  suffix = suffix(time, opts)

  case day_of_the_year(date_time) do
    1 ->
      time <> suffix <> " Happy New Year #{city}!"

    _ ->
      "time in #{city}: #{time}" <> suffix
  end
end

defp suffix(time, [am_pm: am_pm]) when am_pm do
  hour = String.split(time, ":") |> List.first |> String.to_integer
  suffix(hour)
end

defp suffix(_, _), do: ""
defp suffix(hour) when hour < 12, do: "am"
defp suffix(hour) when hour > 12, do: "pm"
```

For those of you paying extra attention will probably have spotted that the output still isn't correct... right? Are you with me? Of course, 13:00:00 pm isn't a thing. :)

I'll leave that part for you to explore on github: [https://github.com/drumusician/clock](https://github.com/drumusician/clock)

Ok, that's all the `time` I have for now. Next post we'll continue our exploration in the world of `Mix` and discover some crazy stuff we could do with Mix, but probably shouldn't...

Until nex time!
