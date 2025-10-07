FROM arm64v8/ruby:3.1.3
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/
WORKDIR /srv/jekyll
# Copy Gemfile for dependency installation
COPY Gemfile Gemfile.lock ./
RUN bundle install
EXPOSE 4000
