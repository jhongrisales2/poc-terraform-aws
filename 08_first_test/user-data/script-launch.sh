#!/bin/bash -x
#set -e

sudo yum install -y amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

sudo yum update -y
sudo yum install nginx -y
sudo systemctl start nginx

sudo yum update -y
sudo yum install python3 python3-pip python3-devel gcc -y
pip3 install virtualenv

sudo mkdir /home/appflaskexample/
sudo chmod 777 /home/appflaskexample/
cd /home/appflaskexample/
virtualenv venv
source venv/bin/activate
pip install flask uwsgi

cat << EOF > app.py
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
    return "Saludos, estimados colegas de LendingFront!"
if __name__ == '__main__':
    app.run()
EOF

cat << EOF > uwsgi.ini
[uwsgi]
module = app:app
master = true
processes = 5
socket = myapp.sock
chmod-socket = 660
vacuum = true
die-on-term = true
EOF

uwsgi -d --ini uwsgi.ini

sudo su
cat << EOF > /etc/nginx/conf.d/appflaskexample.conf
server {
    listen 80;
    server_name _;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:///home/appflaskexample/myapp.sock;
    }
}
EOF

cat << EOF > /etc/systemd/system/appflaskexample.service
[Unit]
Description=uWSGI instance to serve appflaskexample
After=network.target

[Service]
User=ec2-user
Group=nginx
WorkingDirectory=/home/appflaskexample
Environment="PATH=/home/appflaskexample/venv/bin"
ExecStart=/home/appflaskexample/venv/bin/uwsgi --ini uwsgi.ini

[Install]
WantedBy=multi-user.target
EOF
exit

sudo systemctl restart nginx
sudo systemctl enable nginx
sudo systemctl status nginx
sudo systemctl start appflaskexample
sudo systemctl enable appflaskexample