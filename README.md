# Deploy a URL shortener

This is a proof-of-concept on using the Heroku [Platform API][api] to deploy an
app with zero user interaction. You run the script, it spits out a URL, and it's
live.

[api]: https://devcenter.heroku.com/tags/api

## Requirements

You need zsh and [jq]. On OS X you can do `brew install jq`.

[jq]: http://stedolan.github.io/jq/

## Instructions

Find your Heroku token by running `heroku auth:token`.

Let's say your token is `abc123`. Then run the script like this:

```
HEROKU_TOKEN=abc123 APP_NAME=whatever-you-want ./deploy-a-url-shortener.zsh
```

It will create an app named `$APP_NAME` and deploy
https://github.com/gabebw/crumple (a URL shortener) to it.
