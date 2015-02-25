## Jenkins-Github authorization script

This project allows to add a [Github deploy key](https://developer.github.com/guides/managing-deploy-keys/#deploy-keys) and [Jenkins Webhook](https://developer.github.com/webhooks/) to a github repository for a certain organization.

## Environment Configuration ##

### Ruby###

- Dowload and install [Rbenv](https://github.com/sstephenson/rbenv).
- This project is currently using Ruby version `2.2.0`, set your rbenv local to match this version. You can do this by setting the version in the `.ruby-version` file.
- Download and install [Ruby-Build](https://github.com/sstephenson/ruby-build).
- Install the Ruby version by running `rbenv install 2.2.0`

### Sinatra ###

- Clone the repository.
- Install [Bundler](http://bundler.io/).
- Install all the gem included in the project.

 ```bash
  > git clone https://github.com/Wolox/wolox-jenkins-github-authorize.git
  > gem install bundler
  > rbenv rehash
  > bundle
 ```
 
### How to use it ###

Access to `http://your-server/authorize?project=github-project` where `github-project` is the github repository name you want to authorize. You will have to enter the username and password explained in `Environment Configuration`

### Environment configuration ###

You should have a `.credentials.yml` in the project root with the following information:

- access_token: Github access token
- uri: https://api.github.com/repos/your-organization
- jenkins_hook_url: http://your-server/github-webhook/
- username: authentication user
- password: authentication password
 
## Contributing ##

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Maintainers ##

This project is maintained by [Esteban Pintos](https://github.com/epintos).
