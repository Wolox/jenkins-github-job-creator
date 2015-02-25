require 'sinatra'
require 'sinatra/config_file'
require 'net/http'
require 'uri'
require 'pry'
require 'rest_client'

config_file '.credentials.yml'

use Rack::Auth::Basic do |username, password|
  username == settings.username and password == settings.password
end

# GET /authorize?project=example
get '/authorize' do
  project = params[:project]

  # Generate deploy key
  ssh_path = File.expand_path("~/.ssh/#{project}")
  # system("ssh-keygen -t rsa -N '' -f #{ssh_path}")
  # Added deploy key
  # uri = URI.parse("#{settings.uri}/#{project}/keys?access_token=#{settings.access_token}")
  # http = Net::HTTP.new(uri.host, uri.port)
  # http.use_ssl = true
  # request = Net::HTTP::Post.new(uri.request_uri)

  # request.set_form_data({
  #   'title' => 'Wolox Jenkins',
  #   'key' => File.open("#{ssh_path}.pub").read.gsub("\n", '')
  # })
  # request['Content-Type'] = 'application/json'
  # response = http.request(request)


  begin
    res = RestClient.post(
      "#{settings.uri}/#{project}/keys?access_token=#{settings.access_token}",
      {
        "title": "Wolox Jenkins",
        "key": File.open("#{ssh_path}.pub").read.gsub("\n", '')
      },
      content_type: :json,
      accept: :json
    )
  rescue => e
    puts "Error adding deploy key: #{e.response.body}"
    return
  end

  # Added Jenkins service
  # uri = URI.parse("#{settings.uri}/#{project}/hooks?access_token=#{settings.access_token}")
  # http = Net::HTTP.new(uri.host, uri.port)
  # http.use_ssl = true
  # request = Net::HTTP::Post.new(uri.request_uri)
  # request.set_form_data({
  #   'name': 'jenkins',
  #   'active': true,
  #   'events': [
  #       'push'
  #   ],
  #   'config': {
  #     'jenkins_hook_url': settings.jenkins_hook_url
  #   }
  # })
  # request['Content-Type'] = 'application/json'
  # response = http.request(request)

  begin
    res = RestClient.post(
      "#{settings.uri}/#{project}/hooks?access_token=#{settings.access_token}",
      {
        'name': 'jenkins',
        'active': true,
        'events': [
            'push'
        ],
        'config': {
          'jenkins_hook_url': settings.jenkins_hook_url
        }
      },
      content_type: :json,
      accept: :json
    )
    puts 'Project authorized with Github'
  rescue => e
    puts "Error adding Jenkins service #{e.response.body}"
  end
end


