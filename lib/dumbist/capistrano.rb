namespace :load do
  task :defaults do
    set :dumbist_default_hooks, -> { true }
    set :dumbist_pid, -> { File.join(shared_path, 'tmp', 'pids', 'dumbist.pid') }
    set :dumbist_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
    set :dumbist_log, -> { File.join(shared_path, 'log', 'dumbist.log') }
    set :dumbist_role, -> { :app }
    set :dumbist_timeout, -> { 10 }
  end
end

namespace :deploy do
  before :starting, :check_dumbist_hooks do
    invoke 'dumbist:add_default_hooks' if fetch(:dumbist_default_hooks)
  end

  after :publishing, :restart_dumbist do
    invoke 'dumbist:restart' if fetch(:dumbist_default_hooks)
  end
end

namespace :dumbist do

  def pid_file
    fetch(:dumbist_pid)
  end

  def pid_process_exists?
    pid_file_exists? && test(*("kill -0 $( cat #{pid_file} )").split(' '))
  end

  def pid_file_exists?
    test(*("[ -f #{pid_file} ]").split(' '))
  end

  def start_dumbist
    args = []
    args.push "--environment #{fetch(:dumbist_env)}"
    args.push "--logfile #{fetch(:dumbist_log)}" if fetch(:dumbist_log)
    args.push "--pidfile #{fetch(:dumbist_pid)}" if fetch(:dumbist_pid)

    if defined?(JRUBY_VERSION)
      args.push '>/dev/null 2>&1 &'
      warn 'Since JRuby doesn\'t support Process.daemon, Dumbist will not be running as daemon.'
    else
      args.push '--daemon'
    end

    execute :bundle, :exec, :dumbist, args.compact.join(' ')
  end

  def stop_dumbist
    execute :bundle, :exec, :dumbist_ctl, 'stop', pid_file, fetch(:dumbist_timeout)
  end

  task :add_default_hooks do
    after 'deploy:updated', 'dumbist:stop'
    after 'deploy:reverted', 'dumbist:stop'
    after 'deploy:published', 'dumbist:start'
  end

  desc 'Start Dumbist'
  task :start do
    on roles fetch(:dumbist_role) do
      within release_path do
        start_dumbist unless pid_process_exists?
      end
    end
  end

  desc 'Stop Dumbist'
  task :stop do
    on roles fetch(:dumbist_role) do
      if test("[ -d #{release_path} ]")
        within release_path do
          stop_dumbist if pid_process_exists?
        end
      end
    end
  end

  desc 'Restart Dumbist'
  task :restart do
    invoke 'dumbist:stop'
    invoke 'dumbist:start'
  end
end