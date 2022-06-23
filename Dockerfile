FROM python:3.9-buster

WORKDIR /app

RUN pip install Cython		       
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    gcc \
    git \
    libatlas3-base \
    libavformat58 \
    portaudio19-dev \
    avahi-daemon \
    pulseaudio \
    build-essential \
    libasound2-dev \
    libvorbisidec-dev \
    libvorbis-dev \
    libflac-dev \
    alsa-utils \
    libavahi-client-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    
RUN pip install --upgrade pip wheel setuptools
RUN pip install git+https://github.com/LedFx/LedFx

RUN adduser root pulse-access

# https://gnanesh.me/avahi-docker-non-root.html
RUN apt-get install -y libnss-mdns
RUN echo '*' > /etc/mdns.allow \
	&& sed -i "s/hosts:.*/hosts:          files mdns4 dns/g" /etc/nsswitch.conf \
	&& printf "[server]\nenable-dbus=no\n" >> /etc/avahi/avahi-daemon.conf \
	&& chmod 777 /etc/avahi/avahi-daemon.conf \
	&& mkdir -p /var/run/avahi-daemon \
	&& chown avahi:avahi /var/run/avahi-daemon \
	&& chmod 777 /var/run/avahi-daemon

RUN apt-get install -y wget \
                       libavahi-client3 \
                       libavahi-common3 \
                       apt-utils

RUN apt-get install -y squeezelite 

COPY setup-files/ /app/
RUN chmod a+wrx /app/*

WORKDIR /code
RUN git clone --recursive https://github.com/badaix/snapcast.git src && \
    cd src && \
    make && \
    make installserver && \
    make installclient

RUN useradd --system --uid 666 -M --shell /usr/sbin/nologin snapcast && \
    mkdir -p /home/snapcast/.config && \
    chown snapcast:snapcast -R /home
USER snapcast

EXPOSE 1704

VOLUME /data
WORKDIR /data


ENTRYPOINT ./entrypoint.sh 
