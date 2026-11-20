FROM ruby:3.4.13

RUN bundle config --global frozen 1

ENV DOCKER_BUILD true

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN gem install bundler -v '2.6.9' --no-document && \
    bundle config set --local without 'development test' && \
    bundle install

COPY . /usr/src/app
