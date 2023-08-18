sudo apt-get update
sudo apt-get -y install git

git init
git config --local  user.name "PASS"
git config --local  user.email pass@example.com
git clone https://github.com/jlongo62/pass-python pass
cd pass

sudo bash ./1-bootstrap.sh