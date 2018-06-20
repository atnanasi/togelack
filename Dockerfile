FROM ruby:2.4.1
WORKDIR /usr/src/app
COPY Gemfile* ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD rake assets:precompile && bundle exec puma -C config/puma.rb