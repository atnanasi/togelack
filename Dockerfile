FROM ruby:2.4.1
WORKDIR /usr/src/app
COPY Gemfile* ./
RUN bundle install
COPY . .
RUN rake assets:precompile
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]