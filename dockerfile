FROM ubuntu:16.04

RUN dpkg --add-architecture i386
RUN apt update


RUN apt install libgtk-3-0:i386 -y

RUN apt install  xvfb -y



ENV NODE_VERSION=16.13.0
RUN apt install -y curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"



WORKDIR /app


copy app/build/linux/x64/release/bundle ./flutter/

copy server ./server/

WORKDIR /app/server

run npm install

WORKDIR /app


COPY startup.sh .
RUN chmod a+x startup.sh

EXPOSE 8000


CMD [ "./startup.sh" ]



