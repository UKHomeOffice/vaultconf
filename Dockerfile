FROM quay.io/ukhomeofficedigital/centos-base
RUN yum install -y ruby rubygems ruby-devel gcc make libcurl-devel
RUN gem install bundler
ADD . /opt/bin/vaultconf
RUN bundle install --gemfile=/opt/bin/vaultconf/Gemfile
ENV BUNDLE_GEMFILE=/opt/bin/vaultconf/Gemfile
ENTRYPOINT ["bundle","exec","/opt/bin/vaultconf/bin/vaultconf"]
