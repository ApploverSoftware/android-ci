FROM phusion/baseimage:0.11
LABEL maintainer="Applover Software House <docker-hub@applover.pl>"

CMD ["/sbin/my_init"]
ENV DEBIAN_FRONTEND noninteractive

ENV LC_ALL "en_US.UTF-8"
ENV LANGUAGE "en_US.UTF-8"
ENV LANG "en_US.UTF-8"

ENV SDK_TOOLS "4333796"
ENV BUILD_TOOLS "29.0.2"
ENV TARGET_SDK "29"

ENV ANDROID_HOME "/sdk"

ENV PATH "$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"

RUN apt-add-repository ppa:brightbox/ruby-ng && \
    apt-get update --fix-missing && \
    apt-get -y install --no-install-recommends \
    wget \
    file \
    curl \
    zip \
    unzip \
    git \
    ssh \
    lcov \
    patch \
    ruby2.6 \
    ruby2.6-dev \
    build-essential \
    openjdk-8-jdk \
    libxml2-dev \
    zlib1g-dev \
    liblzma-dev \
    libxslt1-dev

# Download and extract Android Tools
RUN wget -q http://dl.google.com/android/repository/sdk-tools-linux-${SDK_TOOLS}.zip -O /tmp/tools.zip && \
    unzip -qq /tmp/tools.zip -d ${ANDROID_HOME} && \
    rm -v /tmp/tools.zip

RUN mkdir -p ~/.android && touch ~/.android/repositories.cfg

# Install SDK Packages
RUN yes | sdkmanager --licenses && \
    sdkmanager --update && \
    sdkmanager "platform-tools" "extras;android;m2repository" "extras;google;m2repository" "extras;google;google_play_services"

ADD Gemfile Gemfile
RUN gem install bundler && gem install nokogiri -- --use-system-libraries && bundle install && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN sdkmanager "build-tools;${BUILD_TOOLS}" "platforms;android-${TARGET_SDK}"
