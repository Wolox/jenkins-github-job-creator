## Jenkins Github Job Creator

This Sinatra project creates jobs in a Jenkins instance with some basic configuration. It does the following:

  - Add deploy key to Github repository and a Credential to Jenkins
  - Adds Jenkins Service as a Github webhook to allow Pull Requests integration
  - Creates the two basic jobs needed for every technology.

This script is used at [Wolox](https://wolox.co), so many things in the script could suit Wolox way or working. Fill free to propose changes.

## Environment Configuration

### Installing Ruby

- Download and install [Rbenv](https://github.com/sstephenson/rbenv).
- Download and install [Ruby-Build](https://github.com/sstephenson/ruby-build).
- Install the appropriate Ruby version by running `rbenv install [version]` where `version` is the one located in [.ruby-version](.ruby-version)

### Installing Gems

- Clone the repository.
- Install [Bundler](http://bundler.io/).
- Install all the gems included in the project.

  ```bash
    git clone https://github.com/Wolox/jenkins-github-job-creator.git
    gem install bundler
    rbenv rehash
    bundle
  ```

### How to use it

Access to `http://your-server/authorize?project=github-repo-name&tech=project-technology` where `github-repo-name` is the github repository name you want to authorize and `project-technology` is either `rails`, `angular` or `android`.

### Environment configuration

You must have a `.credentials.yml` in the project root with the following information:

- jenkins_url: Jenkins domain url. Eg: `https://some-domain.com`
- access_token: Github access token
- uri: https://api.github.com/repos/your-organization
- jenkins_hook_url: https://your-server/github-webhook/
- username: authentication user
- password: authentication password
- jenkins_api_user: A Github username
- jenkins_api_token: The api token of the Github username username chosen.

## Deploy

Then you need to access the EC2 instance by `ssh` and run:

```bash
  sudo su - jenkins
  git clone https://github.com/Wolox/jenkins-github-job-creator.git
  cd jenkins-github-job-creator
  nohup irb authorize.rb&
```

You can kill the process by running `ps ax | grep nohup` and killing it with `kill -9 PID`. If you can't see the process pid and you know its running you can get the pid by running `netstat -l -p | grep 4567`.

## Logs

You can see the logs by running `tail -f nohup.out` under the `jenkins-github-job-creator` folder.

## Nginx configuration

In order to run this Sinatra app with jenkins, you need to configure nginx (/etc/nginx/sites-available/jenkins) like this:

```bash
  upstream app_server {
    server 127.0.0.1:8080 fail_timeout=0;
  }

  upstream sinatra {
    server 127.0.0.1:4567;
  }
  server {
    listen 80;
    listen [::]:80 default ipv6only=on;
    server_name your-server-url;

    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;

        if (!-f $request_filename) {
            proxy_pass http://app_server;
            break;
        }
    }

    location /authorize {
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;

      if (!-f $request_filename) {
          proxy_pass http://sinatra;
          break;
      }
    }
  }
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Maintainers

This project is maintained by [Esteban Pintos](https://github.com/epintos) and it is written by [Wolox](http://www.wolox.com.ar).

![Wolox](https://raw.githubusercontent.com/Wolox/press-kit/master/logos/logo_banner.png)
