# Things you could do with mix
## Let's play

For the `time` being this will be the last post of me exploring `Mix`, but as there is so much more to discover, I will definitely pick this up in the future. During my talk [@ CodeBeam Lite in Amsterdam](https://www.pscp.tv/acscherp/1ynJOOeLbLlJR?t=1h31m34s) last November, I explored some crazy things you could do with Mix and would like to share some of those ideas in this post. First, let's start by exploring two things that might actually be very useful.

### Creating a task to create a task

After you get your feet wet with your first few Mix tasks, you'll probably have an urge to automate more stuff and create more mix tasks. So, why not make the creation of a mix task easier by creating a task to create a task... ;) Are you still with me?

So only this first time we'll need to create the content by hand:

```elixir
defmodule Mix.Tasks.Generate.Task do
  @moduledoc """
  Generate boilerplate for a new mix task
  """

  @shortdoc "Create a new mix task"

  use Mix.Task
  alias Mix.Shell.IO

  def run(_argv) do
    ...
  end
end
```

This is basically just the standard boilerplate we have used before. You'll notice I have added an additional alias we have not used before:
```elixir
alias Mix.Shell.IO
```
This gives us some nice interface features to gather user input. Commandline interfaces should be simple and straightforward, so we'll make invoking our mix task creator as easy as possible.

We'll ask for some user input to create our Mix task file:

```elixir
...
  IO.info("Let's create a new mix task!")
  taskname = IO.prompt("What should we call this new task?")
  modulename = IO.prompt("Please provide the module name to use for this task:")
  description = IO.prompt("Please describe what your task does.")
...
```

And then use the [`Mix.Generator.create_file/3`](https://hexdocs.pm/mix/Mix.Generator.html#create_file/3) function to create our module file.

```elixir
...
Mix.Generator.create_file(
  "lib/mix/tasks/#{String.trim(taskname)}.ex",
  """
  defmodule Mix.Tasks.#{String.trim(modulename)} do
    @moduledoc \"""
    #{description}
    \"""
    use Mix.Task
    alias Mix.Shell.IO
    def run(_argv) do
      IO.info "Nothing implemented yet...\n Add your implementation in lib/mix/tasks/#{taskname}.ex"
    end
  end
  """
)
...
```

Notice the `"""`. This is basically the way to add multiline strings(heredocs) in Elixir. So the content between those triple parentheses gets injected into the file we are creating. We also need to escape those if we want to add these to the content of the file we are creating. That is what I do for the @moduledoc:

```elixir
...
@moduledoc \"""
#{description}
\"""
...
```

### Creating a task that creates an API endpoint

Great so now we have a task to help us create a task. In my talk I explored some API endpoints and so adding those API endpoints get's cumbersome after having done that for a couple of times. So let's see if we can actually create a task to generate the boilerplate for an API endpoint.

Calling an external API from your Elixir app is very easy using HTTPoison. So we'll use that in our new task. Let's create that task first. And here is where our new task creator comes in handy rightaway!

So we'll invoke that:
```shell
  $ mix generate.task
    Let's create a new mix task!
    What should we call this new task? generate_api
    PLease describe what your task does. Generates boilerplate for an API endpoint
    * creating lib/mix/tasks/generate_api.ex
    Task: generate_api created.
    Add your implementation in lib/mix/tasks/generate_api.ex

```

Now, let's open up that file and add our implementation for this new task.

First we'll need some input from the user:

```elixir
def run(_argv) do
  IO.info("Great! Let's create a new API endpoint.")
  base_url = IO.prompt("Please provide the base_url for the api endpoint: ")
  api_module = IO.prompt("Please provide the module name to use for this new API:")
  
  answer = IO.yes?("You have entered #{api_module}. Is that correct?")
  ...
end
```

Here I'm using another nice method from Mix.Shell.IO, the `yes?` function. Basically that handles the y/n flow on the commandline.

We'll handle the answer for that by exiting if the user answers no like this:

```elixir
...
case answer do
  false ->
    IO.info("You have entered no!\nSee you later!")
    exit(:normal)

  _ ->
    ""
end
...
```

And now we can create our API endpoint:

```elixir
...
Mix.Generator.create_file(
  "lib/api/#{filename}.ex",
  """
  defmodule MixHelp.Api.#{String.trim(api_module)} do
    @moduledoc false
    use HTTPoison.Base

    def process_url(url) do
      "#{String.trim(base_url)}" <> url
    end

    def process_response_body(body) do
      body
      |> Poison.decode!()
    end
  end
  """
)
...
```

This is really all you need in Elixir to have a basic endpoint to connect to an external API. Pretty cool, right? 


### Let's play Bruno Mars!

For my talk I really wanted to be able to play music using Mix. And let's make that happen!

Spotify provides a great API with awesome [documentation](https://developer.spotify.com/documentation/web-api/), so be sure to check that out and let it inspire you to create cool things with the music on Spotify!

We'll use our newly created mix task to start off our little Spotify play project:

```shell
  $ mix generate.task
  Let's create a new mix task!
  What should we call this new task? play
  PLease describe what your task does. Play music from an artist on Spotify
  * creating lib/mix/tasks/play.ex
  Task: play created.
  Add your implementation in lib/mix/tasks/play.ex

```

That will generate our basic play task, but won't do anything. Before implementing our task we should make sure we are able to connect to Spotify, so let's work on that first. 

The gist of what we want to accomplish is entering an artist on the commandline and searching Spotify for that artist name and grabbing that artists top tracks when we find the artist. 

Spotify provides an API endpoint to search for an artist: [https://developer.spotify.com/documentation/web-api/reference/search/search/](https://developer.spotify.com/documentation/web-api/reference/search/search/) which let's you search by type. In our case we are interested in the `artist` type.

The second endpoint we need is the endpoint that retrieves the top-tracks for an artist and you can find that here: [https://developer.spotify.com/documentation/web-api/reference/artists/get-artists-top-tracks/](https://developer.spotify.com/documentation/web-api/reference/artists/get-artists-top-tracks/). If you look closely at the return format for that endpoint you'll notice it has a `preview_url` in there. We are going to make use of this in our implementation!

Spotify supports unauthenticated access to parts of their API, but they have slimmed down the parts that you can use unauthenticated the last couple of years. The benefit of using an access token is also a higher rate limit available. Getting the token is actually not that hard if we use the [Client Credentials flow](https://developer.spotify.com/documentation/general/guides/authorization-guide/#client-credentials-flow), so we'll add that to our API endpoint.

But we'll need some boilerplate first...

```shell
  $ mix generate.api
  Great! Let's create a new API endpoint.
  Please provide the base_url for the api endpoint: https://api.spotify.com/v1/
  Please provide the module name to use for this new API: Api.Spotify
  You have entered Api.Spotify. Is that correct? y
```

Cool, that's a start, but as we need to authenticate with a token some more HTTPoison boilerplate is needed. Luckily HTTPoison comes with some nice macros that make this a breeze.

First we need to make sure we send our token on every request. So we add this method to our Api endpoint module to modify the headers to use our token.

```elixir
def process_request_headers(headers) do
  headers ++ [{"Authorization", "Bearer #{access_token()}"}]
end
```

Now to get an actual token we are going to add the folloding private function. We need to make sure we add the `client_id` and `client_secret` to our config file. My application/project is called `spotiplay` in this instance, just so you know where that name comes from. And I have added the secrets to my ENV variables.

```elixir
config :spotiplay,
  spotify_client_id: System.get_env("SPOTIFY_CLIENT_ID"),
  spotify_client_secret: System.get_env("SPOTIFY_CLIENT_SECRET")
```

And here is the function to get the `access_token`:

```elixir
def access_token do
  client_id = Application.get_env(:spotiplay, :spotify_client_id)
  client_secret = Application.get_env(:spotiplay, :spotify_client_secret)

  headers = [
    {"Authorization", "Basic #{Base.encode64("#{client_id}:#{client_secret}")}"}
  ]

  body = {:form, [grant_type: "client_credentials"]}

  HTTPoison.post!("https://accounts.spotify.com/api/token", body, headers).body
  |> Poison.decode!()
  |> Map.get("access_token")
end
```

Ok, so now we need to get some data from Spotify. We are going to assume that our Spotify Api module receives an artist name as a string and with that we'll need to return a track to be played. 

The first step is to find the artist:
```elixir
  query_string = URI.encode_query(%{q: artist, type: "artist"})
  result = __MODULE__.get!("search?#{query_string}").body["artists"]["items"]
```

And the second part is getting the top tracks from this artist and take a random track to play:
```elixir
def get_top_tracks(artist_id) do
  __MODULE__.get!("artists/#{artist_id}/top-tracks?country=NL").body["tracks"]
end
```

Of course we need to take into account when we don't find anything etc. 

Here is the full function that gets a random track:
```elixir
def get_random_track(artist) do
  query_string = URI.encode_query(%{q: artist, type: "artist"})
  result = __MODULE__.get!("search?#{query_string}").body["artists"]["items"]

  top_tracks =
    case result do
      [] ->
        nil

      _ ->
        result
        |> List.first()
        |> Map.get("id")
        |> get_top_tracks
    end

  case top_tracks do
    [] ->
      nil

    _ ->
      top_tracks
      |> Enum.random()
  end
end
```

And our final step is to get our mix task to send a name to our Api module and process the json that comes back:

```elixir
def run(argv) do
  artist = Enum.join(argv, " ")
  IO.puts("Let me find some music by #{artist}")
  HTTPoison.start()

  artist
  |> Spotify.get_random_track()
  |> play_track
end
```

And by now you either fell asleep, because this post is getting pretty long, or you are very curious as to what the `play_track` above actually does... ;) 

Thanks to the lovely `curl` and `mplayer` this is actually not very hard to accomplish. I have two definitions of `play track/1` using pattern matching to also catch the case where there are actually no tracks available. In that case I play some great dutch `smartlap` music.
```elixir
defp play_track(nil) do
  IO.puts("searching...")
  :timer.sleep(2000)
  IO.puts("hmmm that artist doesn't have any preview tracks available.\n")
  :timer.sleep(1500)
  IO.puts("How about some music by Frans Duits... ?\n")
  :timer.sleep(1000)

  run(['Frans', 'Duits'])
end

defp play_track(track) do
  case track["preview_url"] do
    nil ->
      play_track(nil)

    _ ->
      System.cmd("curl", ["-o", "file.mp3", track["preview_url"]], stderr_to_stdout: true)
      IO.puts("Ok, playing #{track["name"]} by #{artist(track)}")
      System.cmd("mplayer", ["file.mp3"], stderr_to_stdout: true)
      File.rm("file.mp3")
  end
end
```


It involved some trickery, but in the end it worked and was really fun to build. Playing music using a mix task is probably not something you should use Mix for, but I learned a lot by fuguring out if I could `pull it off` and hope you had some fun following my mix adventure?

You can try it out yourself by installing this:
```shell
mix escript.install https://github.com/drumusician/spotiplay/raw/master/spotiplay
```

And you can play some music using this command:
```shell
  spotiplay bruno mars
```

Do make sure you have mplayer and curl installed on your system. :) 

If you look at the github repo for spotiplay, you'll notice that this spotify preview track player is not a mix task anymore. It turns out that a global player like this is actually much better implemented as an `escript`. We'll explore escripts and the reasoning behind this in another post!

Hope you learned something new!

Until next `time`!


