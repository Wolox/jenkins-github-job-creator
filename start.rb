require 'daemons'

pwd = Dir.pwd
Daemons.run_proc(
  'authorize.rb',
  {
    :dir_mode =&gt;
    :normal, :dir =&gt;
    '/opt/pids/sinatra'
  }
) do
  Dir.chdir(pwd)
  exec 'irb authorize.rb'
end
