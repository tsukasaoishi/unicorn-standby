# Unicorn::Standby

Unicorn Standby to standby to reach the request.
If you use many rack applications (such as microservices) in development environments, Unicorn Standby saves memory consumption of your computer.

## Installation

Add this line to your application's Gemfile:

```ruby
group :development do
  gem 'unicorn-standby'
end
```

And then execute:

    $ bundle

## Usage

Use ```unicorn-stanby``` command insted of ```unicorn```.

```
bundle exec unicorn-standby -c config/unicorn.rb -D
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

