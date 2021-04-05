FROM phusion/baseimage:0.11
LABEL maintainer="Applover Software House <docker-hub@applover.pl>"

CMD ["/sbin/my_init"]
ENV DEBIAN_FRONTEND noninteractive

ENV LC_ALL "en_US.UTF-8"
ENV LANGUAGE "en_US.UTF-8"
ENV LANG "en_US.UTF-8"

ENV CLI_TOOLS "6858069_latest"
ENV BUILD_TOOLS "29.0.3"
ENV TARGET_SDK "30"

ENV ANDROID_HOME "/android-sdk"

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
    libxslt1-dev \
    jq

# Download and extract Android Tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-${CLI_TOOLS}.zip -O android-commandline-tools.zip \
    && mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && unzip -q android-commandline-tools.zip -d /tmp/ \
    && mv /tmp/cmdline-tools/ ${ANDROID_HOME}/cmdline-tools/latest \
    && rm android-commandline-tools.zip && ls -la ${ANDROID_HOME}/cmdline-tools/latest/

ENV PATH "$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"

# Accept licenses before installing components, no need to echo y for each component
# License is valid for all the standard components in versions installed from this file
# Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and
# Android Google TV require separate licenses, not accepted there
RUN yes | sdkmanager --licenses

RUN touch /root/.android/repositories.cfg

# Emulator and Platform tools
RUN yes | sdkmanager "platform-tools"

# SDKs
# Please keep these in descending order!
# The `yes` is for accepting all non-standard tool licenses.

RUN yes | sdkmanager --update --channel=3
# Please keep all sections in descending order!
RUN yes | sdkmanager \
    "platforms;android-30" \
    "platforms;android-29" \
    "platforms;android-28" \
    "build-tools;30.0.3" \
    "build-tools;30.0.2" \
    "build-tools;30.0.0" \
    "build-tools;29.0.3" \
    "build-tools;29.0.2" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1"

# Install Gradle from PPA
ENV GRADLE_VERSION=6.8.3
ENV PATH "$PATH:gradle/gradle-$GRADLE_VERSION/bin/"
RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
    && unzip -d /gradle /tmp/gradle-*.zip \
    && chmod +775 /gradle \
    && gradle --version \
    && rm -rf /tmp/gradle*

ADD Gemfile Gemfile
RUN gem install bundler && gem install nokogiri -- --use-system-libraries && bundle install && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sdkmanager "build-tools;${BUILD_TOOLS}" "platforms;android-${TARGET_SDK}"
