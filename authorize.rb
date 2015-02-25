require 'sinatra'
require 'sinatra/config_file'
require 'net/http'
require 'uri'
require 'pry'
require 'rest_client'
require 'httparty'

config_file '.credentials.yml'

use Rack::Auth::Basic do |username, password|
  username == settings.username and password == settings.password
end

# GET /authorize?project=example
get '/authorize' do
  project = params[:project]

  # Generate deploy key
  ssh_path = File.expand_path("~/.ssh/#{project}")
  system("ssh-keygen -t rsa -N '' -f #{ssh_path}")

  # Added deploy key
  body = "{
    \"title\":\"Jenkins\",
    \"key\": \"#{File.open("#{ssh_path}.pub").read.gsub("\n", '')}\"
  }"
  options = {
    body: body,
    headers: {'Content-Type' => 'application/json', 'User-Agent' => project}
  }
  response = HTTParty.post(
    "#{settings.uri}/#{project}/keys?access_token=#{settings.access_token}",
    options
  )
  return puts "Error generating deploy key #{response.body}" if response.code != 201

  # Added Jenkins Service
  body = "{
    \"name\": \"jenkins\",
    \"active\":\"true\",
    \"events\":\[\"push\"\],
    \"config\": \{\"jenkins_hook_url\": \"#{settings.jenkins_hook_url}\"\}
  }"

  options = {
    body: body,
    headers: {'Content-Type' => 'application/json', 'User-Agent' => project}
  }
  response = HTTParty.post(
    "#{settings.uri}/#{project}/hooks?access_token=#{settings.access_token}",
    options
  )
  return puts "Error adding Jenkins service #{response.body}" if response.code != 201
  puts 'Project authorized with Github!'
end


