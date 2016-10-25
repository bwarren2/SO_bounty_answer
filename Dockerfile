# start with a base image
FROM python:3.4-slim

EXPOSE 5000

# install dependencies
RUN apt-get update && apt-get install -y \
apt-utils \
nginx \
supervisor \
python3-pip \
&& rm -rf /var/lib/apt/lists/*

RUN echo "America/New_York" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# update working directories
ADD ./app /app
ADD ./config /config
ADD requirements.txt /

# install dependencies
RUN pip install --upgrade pip
RUN pip3 install -r requirements.txt

# setup config
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default

RUN ln -s /config/nginx.conf /etc/nginx/sites-enabled/
RUN ln -s /config/supervisor.conf /etc/supervisor/conf.d/

EXPOSE 80
CMD ["supervisord", "-n"]
