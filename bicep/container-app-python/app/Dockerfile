# base image
FROM python:3.9.5-slim-buster
# set web server root as working dir
WORKDIR /usr/src/app
# install required packages
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# copy project
WORKDIR /usr/src/app
COPY . /usr/src/app/

# expose port 80
EXPOSE 80

# start flask app using Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:80", "app:app"]