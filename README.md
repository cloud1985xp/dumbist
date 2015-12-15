# Dumbist

Dumbist is a gem to daemonize you process with Sidekiq-style usage.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dumbist'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dumbist

## Usage

write your codes in *dumbist.rb* and run

`bundle exec dumbist`

Or you can determine the file of your codes by

`bundle exec dumbist --require my.rb`

After executing the command, dubmist will run a process, which requires your file in the launching process.
If you want to daemonize the process, just put the argument of *--daemone*, like

`bundle exec dumbist --daemon`

### An example of running FTP server with ftpd

Using the gem of [ftpd](https://github.com/wconrad/ftpd)

in dumbist.rb

```ruby
require 'ftpd'
require 'tmpdir'

class Driver

  def initialize(temp_dir)
    @temp_dir = temp_dir
  end

  def authenticate(user, password)
    true
  end

  def file_system(user)
    Ftpd::DiskFileSystem.new(@temp_dir)
  end

end

Dir.mktmpdir do |temp_dir|
  driver = Driver.new(temp_dir)
  server = Ftpd::FtpServer.new(driver)
  server.start
  puts "Server listening on port #{server.bound_port}"
  gets
end

```

Then execute

`bundle exec dumbist`



## Capistrano Deployment

Dumbist supports Recipe of Capistrano 3.x, you can deploy it like sidekiq

in Capfile

`require 'dumbist/capistrano'`

In you deploy scripts, and you can set configuration in your deploy scripts

- dumbist_default_hooks: whether to use default hooks on deployment, default is true
- dumbist_pid: the path of pidfile, default is tmp/pids/dumbist.pid
- dumbist_log: the path of logfile, default is log/dumbist.log
- dumbist_role: the server role of running dumbist, default is :app

### Tasks of Capistrano

Then you can use following capistrano task to control your remote process

- bundle exec cap dumbist:start
- bundle exec cap dumbist:stop
- bundle exec cap dumbist:restart

## Pending Features

- To support multiple threads
- Deployment recipe of Capistrano 2
- To support event hooks, such as callback when process terminated

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cloud1985xp/dumbist.

