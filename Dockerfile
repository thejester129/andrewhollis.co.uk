FROM ruby:3.4.4

WORKDIR /usr/src/app

COPY Gemfile ./

COPY Gemfile.lock ./

RUN bundle install

COPY . .

CMD ["bundle", "exec", "jekyll", "serve", "--port", "4129", "-H", "0.0.0.0", "--livereload", "--force_polling"]

