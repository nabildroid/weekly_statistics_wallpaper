FROM ubuntu:18.04


# Prerequisites
RUN apt update && apt install -y curl git unzip xz-utils zip libglu1-mesa  wget

# Setup new user
RUN useradd -ms /bin/bash developer
USER developer
WORKDIR /home/developer

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git
ENV PATH "$PATH:/home/developer/flutter/bin"

USER root
RUN apt -y install  ninja-build pkg-config libgtk-3-dev clang snapd

RUN  apt-get -y install cmake protobuf-compiler



user developer
# Run basic check to download Dark SDK
RUN flutter doctor
RUN flutter devices

user root

run flutter
cmd ["flutter"]
