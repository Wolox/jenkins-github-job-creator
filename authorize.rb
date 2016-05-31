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

# use BlogAuth do |username, password|
#   username == settings.username and password == settings.password
# end

def generate_jenkins_credential(project, private_key)
  json = {
    credentials: {
      scope: 'GLOBAL',
      id: '',
      username: project,
      description: '',
      privateKeySource: {
        value: '0',
        privateKey: private_key,
        'stapler-class' => 'com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey$DirectEntryPrivateKeySource'
      },
      passphrase: '',
      'stapler-class' => 'com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey',
      '$class' => 'com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey'
    }
  }.to_json
  system("curl -X POST http://ci.wolox.com.ar/credentials/store/system/domain/_/createCredentials --user \"#{settings.jenkins_api_user}:#{settings.jenkins_api_token}\" --data-urlencode json='#{json}'")
end

def generate_ssh_keys(project)
  ssh_path = File.expand_path("~/.ssh/#{project}")
  system("rm #{ssh_path}")
  system("rm #{ssh_path}.pub")
  system("ssh-keygen -q -t rsa -N '' -f #{ssh_path}")
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
    \"active\":true,
    \"events\":\[\"push\"\],
    \"config\": \{\"jenkins_hook_url\": \"#{settings.jenkins_hook_url}\"\}
  }"
end

def generate_jobs(project, tech)
  if tech == 'rails'
    project_from = 'RoR-Example-Project'
    project_from_base = "#{project_from}-Base"
    project_name = project.split('-').map(&:capitalize).join('-')
    project_name_base = "#{project_name}-Base"
    create_jobs(project_from, project_from_base, project_name, project_name_base)
  elsif tech == 'angular'
    project_from = 'angular-example-project'
    project_from_base = "#{project_from}-base"
    project_name = project.split('-').map(&:downcase).join('-')
    project_name_base = "#{project_name}-base"
    create_jobs(project_from, project_from_base, project_name, project_name_base)
  elsif tech == 'android'
    project_from = 'Android-Example-Project'
    project_from_base = "#{project_from}-Base"
    project_name = project.split('-').map(&:capitalize).join('-')
    project_name_base = "#{project_name}-Base"
    create_jobs(project_from, project_from_base, project_name, project_name_base)
  end
end

def create_jobs(project_from, project_from_base, project_name, project_name_base)
  system("curl -X POST \"http://ci.wolox.com.ar/view/Actives%20Pull%20Requests/createItem?name=#{project_name}&mode=copy&from=#{project_from}\" --user \"#{settings.jenkins_api_user}:#{settings.jenkins_api_token}\"")
  system("curl -X POST \"http://ci.wolox.com.ar/view/Actives%20Base%20Branch/createItem?name=#{project_name_base}&mode=copy&from=#{project_from_base}\" --user \"#{settings.jenkins_api_user}:#{settings.jenkins_api_token}\"")
end

def make_request(url, options)
  HTTParty.post(url, options)
end

# GET /authorize?project=github-repo
get '/authorize' do
  project = params[:project]
  tech = params[:tech]

  # Adds deploy key
  ssh_path = generate_ssh_keys(project)
  private_key = File.open(ssh_path).read
  generate_jenkins_credential(project, private_key)
  if !generate_jobs(project, tech)
    return "<p>Error generating jobs</p>"\
  end
  deploy_keys_response = add_deploy_key(ssh_path, project)
  if deploy_keys_response.code != 201
    return "<p>Error generating deploy key:</p>"\
           "<p><strong>#{deploy_keys_response.body}</p></strong>"
  end

  # Adds Jenkins Service
  jenkins_service_response = add_jenkins_service(project)
  if jenkins_service_response.code != 201
    return "<p>Error adding Jenkins service:</p>"\
           "<p><strong>#{jenkins_service_response.body}</p></strong>"
  end
  return "<h2>#{project.capitalize} Wolox CI jobs created!.</h2>"\
         "<p>You can assign the <strong>#{project}</strong> credential and replace the jobs setup with your custom configuration</p>"
end
