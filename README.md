# Unicorn::Standby

Unicorn standby is on standby until it accepts the request.
If you use many rack applications (such as microservices) in development environments, Unicorn Standby saves memory consumption of your computer.

For example of simple Rails app RSS:
```
# 1 master and 1 worker
master  77288kb
worker 108112kb
sum    185400kb

# 1 standby master
standby 20648kb
```

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

unicorn-standby master process starts.
```
$ ps aux | grep unicorn
name 1000  11.0  0.2  2477948  20648   ??  S    10:00AM   0:00.69 unicorn-standby master (standby) -c config/unicorn.rb -D
```

When the app is accessed, master and worker processed start.
```
$ ps aux | grep unicorn
name 1001   0.0  1.3  2574060 105072   ??  S    10:02AM   0:00.96 unicorn-standby worker[0] -c config/unicorn.rb -D
name 1000   0.0  1.0  2548444  81392   ??  S    10:00AM   0:03.96 unicorn-standby master -c config/unicorn.rb -D
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

