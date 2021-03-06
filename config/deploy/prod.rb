server 'sul-stacks-prod-a.stanford.edu', user: 'stacks', roles: %w{web app}
server 'sul-stacks-prod-b.stanford.edu', user: 'stacks', roles: %w{web app}
server 'sul-stacks-prod-c.stanford.edu', user: 'stacks', roles: %w{web app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'

set :bundle_without, %w{deployment development test}.join(' ')
