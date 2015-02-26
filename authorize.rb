require 'sinatra'
require 'sinatra/config_file'
require 'net/http'
require 'uri'
require 'pry'
require 'httparty'
require 'jenkins_api_client'

config_file '.credentials.yml'

class BlogAuth < Rack::Auth::Basic

  def call(env)
    request = Rack::Request.new(env)
    case request.path
    when '/authorize'
      super
    else
      @app.call(env)  # skip auth
    end
  end

end

use BlogAuth do |username, password|
  username == settings.username and password == settings.password
end

def generate_ssh_keys(project)
  ssh_path = File.expand_path("~/.ssh/#{project}")
  system("echo -e  'y\n'|ssh-keygen -q -t rsa -N '' -f #{ssh_path}")
  ssh_path
end

def add_deploy_key(ssh_path, project)
  make_request(
    "#{settings.uri}/#{project}/keys?access_token=#{settings.access_token}",
    generate_request_options(deploy_key_body(ssh_path), project)
  )
end

def add_jenkins_service(project)
  make_request(
    "#{settings.uri}/#{project}/hooks?access_token=#{settings.access_token}",
    generate_request_options(jenkins_service_body, project)
  )
end

def generate_request_options(body, project)
  {
    body: body,
    headers: {'Content-Type' => 'application/json', 'User-Agent' => project}
  }
end

def deploy_key_body(ssh_path)
  "{
    \"title\":\"Jenkins\",
    \"key\": \"#{File.open("#{ssh_path}.pub").read.gsub("\n", '')}\"
  }"
end

def jenkins_service_body
  "{
    \"name\": \"jenkins\",
    \"active\":\"true\",
    \"events\":\[\"push\"\],
    \"config\": \{\"jenkins_hook_url\": \"#{settings.jenkins_hook_url}\"\}
  }"
end

def make_request(url, options)
  HTTParty.post(url, options)
end

# GET /authorize?project=github-repo
get '/authorize' do
  project = params[:project]

  # Added deploy key
  ssh_path = generate_ssh_keys(project)
  deploy_keys_response = add_deploy_key(ssh_path, project)
  if deploy_keys_response.code != 201
    return "<p>Error generating deploy key:</p>"\
           "<p><strong>#{deploy_keys_response.body}</p></strong>"
  end

  # Added Jenkins Service
  jenkins_service_response = add_jenkins_service(project)
  if jenkins_service_response.code != 201
    return "<p>Error adding Jenkins service:</p>"\
           "<p><strong>#{jenkins_service_response.body}</p></strong>"
  end
  return "<h2>#{project.capitalize} authorized with Github!.</h2>"\
         "<p>Add the following private key to the Jenkins credentials:</p>"\
         "<p><strong>#{File.open("#{ssh_path}").read.gsub("\n", '')}</p></strong>"
end
