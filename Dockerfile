# ベースイメージ
ARG RUBY_VERSION=3.4.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim

# ワークディレクトリ
WORKDIR /rails

# 必要なパッケージインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 build-essential git libyaml-dev node-gyp pkg-config python-is-python3 libpq-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# nodeとyarnをインストール
ARG NODE_VERSION=22.14.0
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# gemモジュールインストール
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# nodeモジュールインストール
COPY package.json yarn.lock ./
RUN yarn install --immutable

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/


# DBをマイグレーション
ENTRYPOINT ["/rails/bin/dev-entrypoint"]

CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
