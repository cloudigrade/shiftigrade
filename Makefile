PYTHON		= $(shell which python)

TOPDIR		= $(shell pwd)
PYDIR		= cloudigrade

OC_SOURCE	= registry.access.redhat.com/openshift3/ose
OC_VERSION	= v3.7.23
OC_DATA_DIR	= ${HOME}/.oc/openshift.local.data

OS := $(shell uname)
ifeq ($(OS),Darwin)
	PREFIX	=
else
	PREFIX	= sudo
endif

help:
	@echo "Please use \`make <target>' where <target> is one of:"
	@echo "==[Local Dev]========================================================"
	@echo "  help                          to show this message."
	@echo "  clean                         to clean the project directory of any scratch files, bytecode, logs, etc."
	@echo "==[OpenShift]========================================================"
	@echo "==[OpenShift/Administration]========================================="
	@echo "  oc-up                         to start the local OpenShift cluster."
	@echo "  oc-up-all                     to start the cluster and deploy supporting services along with cloudigrade."
	@echo "  oc-down                       to stop the local OpenShift cluster."
	@echo "  oc-clean                      to stop the local OpenShift cluster and delete configuration."
	@echo "==[OpenShift/Deployment Shortcuts]==================================="
	@echo "  oc-create-templates           to create the ImageStream and template objects."
	@echo "  oc-create-db                  to create and deploy the DB."
	@echo "  oc-create-cloudigrade-all     to create and deploy the cloudigrade and frontigrade."
	@echo "  oc-create-cloudigrade-api     to create and deploy the cloudigrade. "
	@echo "  oc-create-cloudigrade-ui      to create and deploy the frontigrade."
	@echo "==[OpenShift/Dev Shortcuts]=========================================="
	@echo "  oc-login-admin                to log into the local cluster as an admin."
	@echo "  oc-login-developer            to log into the local cluster as a developer."
	@echo "  oc-user                       to create a Django super user for cloudigrade running in a local OpenShift cluster."
	@echo "  oc-user-authenticate          to generate an auth token for a user for cloudigrade running in a local OpenShift cluster."
	@echo "  oc-forward-ports              to forward ports for PostgreSQL for local development."
	@echo "  oc-stop-forwarding-ports      to stop forwarding ports for PostgreSQL for local development."

clean:
	git clean -fdx -e .idea/ -e *env/

oc-login-admin:
	oc login -u system:admin

oc-login-developer:
	oc login -u developer -p developer --insecure-skip-tls-verify

oc-up:
	oc cluster up \
		--image=$(OC_SOURCE) \
		--version=$(OC_VERSION) \
		--host-data-dir=$(OC_DATA_DIR) \
		--use-existing-config
ifeq ($(OS),Linux)
	make oc-login-developer
endif

oc-create-templates:
	oc create istag postgresql:9.6 --from-image=centos/postgresql-96-centos7

oc-create-db:
	oc process openshift//postgresql-persistent \
		-p NAMESPACE=myproject \
		-p POSTGRESQL_USER=postgres \
		-p POSTGRESQL_PASSWORD=postgres \
		-p POSTGRESQL_DATABASE=postgres \
		-p POSTGRESQL_VERSION=9.6 \
	| oc create -f -

oc-create-cloudigrade-api:
	kontemplate template ocp/local.yaml	-i cloudigrade | oc apply -f -

oc-create-cloudigrade-ui:
	kontemplate template ocp/local.yaml	-i frontigrade | oc apply -f -

oc-create-cloudigrade-all:
	kontemplate template ocp/local.yaml	| oc apply -f -

oc-forward-ports:
	-make oc-stop-forwarding-ports 2>/dev/null
	oc port-forward $$(oc get pods -o jsonpath='{.items[*].metadata.name}' -l name=postgresql) 5432 &

oc-stop-forwarding-ports:
	kill -HUP $$(ps -eo pid,command | grep "oc port-forward" | grep -v grep | awk '{print $$1}')

oc-up-dev: oc-up sleep-60 oc-create-templates oc-create-db

oc-up-all: oc-up sleep-60 oc-create-templates oc-create-db sleep-30 oc-create-cloudigrade-all

oc-down:
	oc cluster down

oc-clean: oc-down
	$(PREFIX) rm -rf $(OC_DATA_DIR)

oc-user:
	oc rsh -c cloudigrade $$(oc get pods -o jsonpath='{.items[*].metadata.name}' -l name=cloudigrade) scl enable rh-postgresql96 rh-python36 -- python manage.py createsuperuser

oc-user-authenticate:
	@read -p "User name: " uname; \
	oc rsh -c cloudigrade $$(oc get pods -o jsonpath='{.items[*].metadata.name}' -l name=cloudigrade) scl enable rh-postgresql96 rh-python36 -- python manage.py drf_create_token $$uname

sleep-60:
	@echo "Allow the cluster to startup and set all internal services up."
	sleep 60

sleep-30:
	@echo "Allow the DB to start before deploying cloudigrade."
	sleep 30
