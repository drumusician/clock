## Things you could do with mix

### Part 2: Passing Arguments

This is the second post in my series exploring mix tasks. PLease find the first part [here]. In the first part we explored how to create a simple mix task using tests to drive our implementation. In this episode we'll see how to expand our task by passing in arguments on the commandline that will influence the output of our clock.

Currently we don't see our mix task yet when running mix help. So how do we get our mix task to show up in the list of tasks when invoking mix help? The only thing we have to do to get mix help to output our task is adding a `@shortdoc` module attribute to our task module. Yes, it's that simple. 

So we update our task module by adding in our shortdoc attribute.

```elixir
defmodule Mix.Tasks.Time do
  use Mix.Task

  @shortdoc "A mix clock that can tell time. ;)"
  ...
end

```

And when we invoke `mix help` we'll see our task in output.

```shell
...
  mix profile.fprof     # Profiles the given file or expression with fprof
  mix run               # Starts and runs the current application
  mix test              # Runs a project's tests
  mix time              # A mix clock that can tell time. ;)
  mix xref              # Performs cross reference checks
  iex -S mix            # Starts IEx and runs the default task
...
```

With that done let's see if we can add a feature to our mix clock. Currently the `mix time` task only outputs the current local time. Wouldn't it be nice if we could also pass in a timezone to get the time anywhere else in the world?

Last time I mentioned that the current Elixir DateTime modules didn't yet support timezone functionality. Luckily 1.8.0-rc0 has just landed, so let's take advantage of some new and shiny features coming up in Elixir 1.8. The DataTime module now includes a `now/2` function that takes in a timezone. By default it only supports "Etc/UTC" timezones but we can pretty easily add a new timezone database. We can add the TzData time zone database by adding this to our mix.exs file:

```elixir
...
defp deps do
  [
    {:tzdata, git: "https://github.com/lau/tzdata.git", tag: "master"}
  ]
end
...
```

Now update our dependencies:

```shell
mix deps.get
```

And configure elixir to use that time_zone_database in config.exs.

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Let's first see if we can get the arguments we pass in. Using a test.

We create our test to use the new features in the Standard Library like this:

```elixir
test "it accepts a timezone as an argument" do
    Mix.Tasks.Time.run(["Australia/Sydney"])

    assert_received {:mix_shell, :info, [time]}

    {:ok, current_date_time_in_time_zone} = DateTime.now("Australia/Sydney")

    current_time =
      current_date_time_in_time_zone
      |> DateTime.truncate(:second)
      |> DateTime.to_time
      |> to_string()


    assert time == current_time
  end
```

Our test now fails as we haven't changed any implementation just yet, so let's see how can get the argument passed in.
Currently we have only one `run/1` function that matches all function calls. We need to differentiate this call baswed on the number of arguments passed in. Basically we should return the current local time when the arguments list is empty and for now we'll assume the other option is a list of 1 timezone.
Pattern matching to the rescue!

We change our old `run/1` function to only invoke on an empty list like this:

```elixir
def run([]) do
  # implemetation details unchanged
end
```

Next we create our new implementation assuming one argument is passed in.

```elixir
def run([time_zone])  do

  {:ok, current_date_time_in_time_zone} = DateTime.now(time_zone)

  time =
      current_date_time_in_time_zone
      |> DateTime.truncate(:second)
      |> DateTime.to_time
      |> to_string()

  Mix.shell.info(time)
end
```

Once we add that our test passes. Yay!

Now since it is almost new year, let's add one more feature. Let's see if the new year has arrived in the time zone we specify!

We'll add a small test for this using Sydney as the time zone as the new year has already landed when writing this post... :) Of course a very brittle test, but for now it is just for fun... :)

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

Now for the implementation:

```elixir
def run([time_zone])  do
  Mix.Task.run "app.start" # we need this to make sure we have our dependencies loaded. More on that in a later blogpost...

  {:ok, current_date_time_in_time_zone} = DateTime.now(time_zone)

  day_of_year =
    current_date_time_in_time_zone
    |> DateTime.to_date
    |> Date.day_of_year

  city =
      String.split(time_zone, "/")
      |> Enum.drop(1)
      |> to_string()

  time =
      current_date_time_in_time_zone
      |> DateTime.truncate(:second)
      |> DateTime.to_time
      |> to_string()

  output =
    case day_of_year do
      1 ->
        "#{time} Happy New Year #{city}!"
      _ ->
        "Time in #{city}: time"
    end

  Mix.shell.info(output)
end
```

When I run this now it will fail with the following message:

```shell
1) test run/1 it shows if the new year has arrived (Mix.Tasks.TimeTest)
    test/mix/tasks/time_test.exs:37
    Assertion with == failed
    code:  assert time == current_time <> " Happy New Year Sydney!"
    left:  "time in Sydney: 23:53:11"
    right: "23:53:11 Happy New Year Sydney!"
    stacktrace:
      test/mix/tasks/time_test.exs:51: (test)
```

But when I wait 7 more minutes my test passes... :) We'll fix our brittle tests next time and see how we can use OptionParser to make our implementation a bit more solid.

Hope you enjoyed this post. There will be many more explorations of Elixir and Mix coming from me in the new year. So keep an eye out!

For now, Happy New Year!

Until next time!
