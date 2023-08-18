FROM arm64v8/ruby:3.1.3
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/
RUN gem install jekyll \
  bundler \
  github-pages \
  html-proofer \
  jekyll-reload \
  jekyll-mentions \
  jekyll-coffeescript \
  jekyll-sass-converter \
  jekyll-commonmark \
  jekyll-paginate \
  jekyll-compose \
  jekyll-assets \
  RedCloth \
  kramdown \
  jemoji \
  jekyll-default-layout \
  jekyll-gist \
  jekyll-github-metadata \
  jekyll-optional-front-matter \
  jekyll-readme-index \
  jekyll-titles-from-headings \
  jekyll-relative-links
WORKDIR /srv/jekyll
EXPOSE 4000
