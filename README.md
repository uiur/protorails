# protorails

`protorails` is a toolkit to build type-safe API on Rails with Protocol Buffers (protobuf).
It's built on twitch's battle-tested [Twirp protocol](https://github.com/twitchtv/twirp). 

Write API schema in protobuf, and it can generate API client for [TypeScript, Ruby or Java etc](https://github.com/twitchtv/twirp#implementations-in-other-languages).

The deployment is easy. [Twirp protocol](https://github.com/twitchtv/twirp/blob/master/PROTOCOL.md) is over HTTP 1.1. The server is just an ordinary Rails application.
You can integrate it easily onto an existing Rails application.

## Features
- Generators to generate protobuf definitions from models
- Auto-reloading protobuf definitions in development
- Zeitwerk support (Rails 6)

## Usage

How to use my plugin.

## Status
alpha: prototype for proof of concept

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'protorails'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install protorails
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
