git clone https://github.com/jboss-openshift/cct_module.git
cd cct_module
git config core.eol lf
git config core.autocrlf false
git reset
git checkout-index --force --all
cd ..

docker build -t openj9-14-rhel7 .