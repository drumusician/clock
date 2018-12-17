# Things you could do with Mix
## Part 1: Creating Tasks

Recently I gave my very first talk at a conference, Code Beam Lite Amsterdam, and had a very great time doing so. So why not share my thoughts in the form of a blog post as well… The subject, Mix, is something that everybody that uses Elixir has definitely used. But you might have not discovered the power (and fun!) this little tool can bring to your workflow. 

In this first part I’d like to start out simple. We’ll start by creating our very first mix task. Now, starting out with Hello World gets old pretty fast, so we’ll do something a little different. We’ll create a task that will show us the current time. I know, might also not be the greatest wonder in the world, because we could also just look at the time on our computer… But hey, do you want to learn how to create a mix task or not?

Ok, let’s get cracking! Most tutorials will show you to create the task itself as that is very straightforward, but let’s not do that. Let’s write a test first! 

In order to write our first test, let’s use one of Mix’s best known tasks, mix new, to create our project.

```
mix new clock
``` 

After that we can create our test file:

```
mkdir -p test/mix/tasks
vim  test/mix/tasks/time_test.exs
```

And let’s create the boilerplate for our test:

```
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
```

If we look at the docs for Mix Tasks it has all the info we need to write our test right at the top:

_A Mix task can be defined by simply using Mix.Task in a module starting with Mix.Tasks. and defining the [`run/1`](https://hexdocs.pm/mix/Mix.Task.html#c:run/1) function_

Here is the boilerplate for our first function:
```
defmodule Mix.Tasks.Time do
  use Mix.Task

  def run(_argv) do
  end
end
```

Now it’s time to actually create a test that we can use. So what do we expect from this task? At first let’s start by just outputting the current time as a string to stdout.

In our tests it is not very useful to have the task output to stdout. We could of course use capture_io to catch stdout and test the output if it is what we expect. But I recently came across a nice blogpost by Jesse Cooke that points out a much nicer way to test shell output of mix. 

So basically you can replace the shell that Mix uses with the current process with the [`Mix.shell/1`](https://hexdocs.pm/mix/Mix.html#shell/1) function. So we’ll do just that and put that at the top of our test_helper.exs

```
# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)

ExUnit.start()

``` 
Once we do that we can use assert_received to test what ended up in the process mailbox. Nice!

I know I know, we’re getting there. Just a little more.

Here is the updated test:
```
defmodule Mix.Tasks.TimeTest do
  use ExUnit.Case, async: true

  describe "run/1" do
    test "it outputs the current time" do
      Mix.Tasks.Time.run([])

      assert_received {:mix_shell, :info, [time]}

      assert time == # we need to define the output
    end
  end
end
```
So we use some nice pattern matching to catch the output of the command. Now the only thing we need is to define the output we expect. We don’t want to bring in any dependencies like Timex at this point, and getting the current local time is a little tricky with the current standard library. There is some nice stuff coming in 1.8, but that hasn’t landed just yet.

Luckily we can reach out to erlang to solve this problem for us and use the `:calendar.local_time` function. We can then use Elixir’s NaiveDateTime module to convert into a string very easily.

So this is our final test:
```
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
```
With that in place we can run our test and make it pass by adding this to our task.
Note that this test against current_time only works when using seconds granularity. :) For this example that is good enough.
```
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
```
And now inside your project you can run mix time to output the current time to stdout :).

Now the task does not show up in the list of tasks when you run mix help. In the next part of this series we’ll explore how to do just that and also see if we can add some more features to our awesome clock.

You can find the repository for this code on github: https://github.com/drumusician/clock

Until next time!




