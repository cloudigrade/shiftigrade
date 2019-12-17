PYTHON		= $(shell which python)

TOPDIR		= $(shell pwd)
PYDIR		= cloudigrade

OC_VERSION	= v3.11.43

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
	@echo "  oc-up-dev                     to start the local OpenShift cluster and deploy the db."
	@echo "  oc-up-all                     to start the cluster and deploy supporting services along with cloudigrade."
	@echo "  oc-check-cluster              to check the cluster status."
	@echo "  oc-down                       to stop the local OpenShift cluster."
	@echo "  oc-clean                      to stop the local OpenShift cluster and delete configuration."
	@echo "==[OpenShift/Deployment Shortcuts]==================================="
	@echo "  oc-deploy-db                  to create and deploy the DB."
	@echo "  oc-create-cloudigrade-api     to create and deploy the cloudigrade. "
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
	minishift start \
		--openshift-version=$(OC_VERSION)
ifeq ($(OS),Linux)
	make oc-login-developer
endif

oc-deploy-db:
	oc process openshift//postgresql-persistent \
		-p NAMESPACE=openshift \
		-p POSTGRESQL_USER=postgres \
		-p POSTGRESQL_PASSWORD=postgres \
		-p POSTGRESQL_DATABASE=postgres \
		-p POSTGRESQL_VERSION=9.6 \
	| oc create -f -
	oc rollout status dc/postgresql

oc-create-cloudigrade-api:
	API_ROUTE_HOST=cloudigrade.$$(minishift ip).nip.io \
	AUTH_ROUTE_HOST=cloudigrade.$$(minishift ip).nip.io \
	kontemplate template ocp/local.yaml	-i cloudigrade | oc apply -f -

oc-forward-ports:
	-make oc-stop-forwarding-ports 2>/dev/null
	oc port-forward $$(oc get pods -o jsonpath='{.items[*].metadata.name}' -l name=postgresql) 5432 &

oc-stop-forwarding-ports:
	kill -HUP $$(ps -eo pid,command | grep "oc port-forward" | grep -v grep | awk '{print $$1}')

oc-up-dev: oc-up oc-deploy-db

oc-up-all: oc-up oc-deploy-db oc-create-cloudigrade-api

oc-down:
	minishift stop

oc-clean: oc-down
	minishift delete -f

oc-user:
	oc rsh -c c-a $$(oc get pods -o jsonpath='{.items[*].metadata.name}' -l name=c-a  | awk '{print $$1}') python manage.py createsuperuser

oc-user-authenticate:
	@read -p "User name: " uname; \
	oc rsh -c c-a $$(oc get pods -o jsonpath='{.items[*].metadata.name}' -l name=c-a | awk '{print $$1}') python manage.py drf_create_token $$uname
