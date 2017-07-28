################
# Docker file to build a python container hosting the wkhtmltopdf service.
################

#Based off of the ubuntu container
FROM ubuntu:xenial

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y \
    bash wget build-essential xorg libssl-dev libxrender-dev python-pip

RUN pip install werkzeug executor gunicorn

#Install wkhtmltopdf
RUN wget -O wkhtmltox.tar.xz https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
RUN tar xvfJ wkhtmltox.tar.xz && rm wkhtmltox.tar.xz
RUN ln -s /wkhtmltox/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf

ADD app.py /app.py
EXPOSE 80

ENTRYPOINT ["usr/local/bin/gunicorn"]

# Show the extended help
CMD ["-b", "0.0.0.0:80", "--log-file", "-", "app:WkHtmlToPdfServer()"]
