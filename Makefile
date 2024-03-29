# Globals
LOCAL_DEV_ENV=local-dev-env
LOCAL_CACHE=.cache
SRV_DEV_ENV="$(LOCAL_DEV_ENV)"/server
NPM_DEV_ENV="$(LOCAL_DEV_ENV)"/webapp

# Package Details
PACKAGE_NAME=localdev
PACKAGE_DESC=Running application locally
PACKAGE_AUTHOR=geld.tech
PACKAGE_VERSION=0.0.1
PACKAGE_DATE=01-01-1970

# Tasks
TASK_ID=12345678-abcd-cdef-abef-ba0987654321

# UI Tests
PROTO=http
HOST=0.0.0.0
PORT=5000
WAIT=10

# Conditional Processing
NPM_AUDIT=true

# MQ Variables
export MQ_USER:=mquser
export MQ_PASS:=mqsecret
export MQ_HOST:=localhost
export MQ_VAPP:=$(PACKAGE_NAME)


## Start local development environment
start: all mq-start worker-start webapp-start

## Stop local development environment
stop: worker-stop webapp-stop mq-stop

## Stop all local development environment
stop-all: worker-stop webapp-stop mq-stop db-stop tsdb-stop clean-all

## Run all targets locally
all: check-prereq show-versions stop save-cache clean isort lint test local-dev-env vue-dev-tools npm-install npm-lint npm-audit npm-build webapp-setup webapp-settings
	@echo "Build completed successfully!"

## Remove all local build artifacts
clean: stop clean-pyc
	$(call echo_title, "LOCAL DEV ENV CLEANUP")
	rm -rf $(LOCAL_DEV_ENV)

## Clean all files including cache for NPM
clean-all: clean
	$(call echo_title, "CACHE FILES CLEANUP")
	-rm -rf $(LOCAL_CACHE)
	-rm -f `pwd`/sources/server/config/secret.uti
	-rm -f `pwd`/sources/server/data/metrics.sqlite3

## Remove python artifacts
clean-pyc:
	$(call echo_title, "PYTHON FILES CLEANUP")
	find . -name '*.pyc' -exec rm --force {} +
	find . -name '*.pyo' -exec rm --force {} +

## Save NPM cache
save-cache:
	$(call echo_title, "SAVE CACHE")
	@echo "== NPM =="
	@if [ -d "$(LOCAL_DEV_ENV)/webapp/node_modules/" ]; then \
	    rm -rf $(LOCAL_CACHE)/node_modules/; \
	    mkdir -p $(LOCAL_CACHE); \
	    mv $(LOCAL_DEV_ENV)/webapp/node_modules/ $(LOCAL_CACHE) ||: ; \
	fi

## Check pre-requisites are installed
check-prereq:
	$(call echo_title, "CHECK PRE-REQUISITES")
	@if [ ! -f "/usr/bin/isort" ]  && [ ! -f "/usr/local/bin/isort" ]; then echo "Python Isort not found.. Install and try again"; exit 127; fi
	@if [ ! -f "/usr/bin/flake8" ] && [ ! -f "/usr/local/bin/flake8" ]; then echo "Python Flake8 not found.. Install and try again"; exit 127; fi
	@if [ ! -f "/usr/bin/npm" ]    && [ ! -f "/usr/local/bin/npm" ]; then echo "Node.js NPM not found.. Install and try again"; exit 127; fi
	@if [ ! -f "/usr/bin/celery" ] && [ ! -f "/usr/local/bin/celery" ]; then echo "Python Celery found.. Install and try again"; exit 127; fi

## Display installed versions of tools
show-versions:
	$(call echo_title, "INSTALLED VERSIONS")
	python --version
	flake8 --version
	npm --version
	node --version 
	jfrog --version

## Sort Python import statements
isort:
	$(call echo_title, "PYTHON ISORT")
	sh -c "isort --skip-glob=.tox --recursive sources/server/ "

## Check coding style of Flask application, enforce no syntax errors or undefined names, and flags other issues
lint:
	$(call echo_title, "PYTHON LINTER")
	flake8 sources/server/ --show-source --max-line-length=239 --max-complexity=10 --statistics --count

## Run all tests (unit tests and UI tests)
tests: test test-ui

## Run unit tests
test:
	$(call echo_title, "PYTHON UNIT TESTS")
	@python -c  "import os; print(os.urandom(24));" > `pwd`/sources/server/config/secret.uti
	python -m unittest discover -s tests/unit_test
	@rm -f `pwd`/sources/server/config/secret.uti
	@rm -f `pwd`/sources/server/data/metrics.sqlite3

## Run UI Tests (CLI overridable parameters: PROTO, HOST, PORT, WAIT)
test-ui:
	$(call echo_title, "PYTHON SELENIUM UI TESTS")
	@echo "Executing UI tests on $(PROTO)://$(HOST):$(PORT) (delay of $(WAIT) seconds)"
	ls tests/ui_test/*.py | xargs -i python {} --proto=$(PROTO) --host=$(HOST) --port=$(PORT) --delay=$(WAIT)

## Prepare local development environment
local-dev-env: clean
	$(call echo_title, "LOCAL DEV ENV")
	@echo "== Prepare folders =="
	mkdir -p $(LOCAL_DEV_ENV)
	cp -r sources/server/ $(LOCAL_DEV_ENV)
	cp -r sources/webapp/ $(LOCAL_DEV_ENV)
	@echo "== Replace place holders =="
	find $(LOCAL_DEV_ENV) -type f -not -path "$(LOCAL_DEV_ENV)/webapp/node_modules/*" | xargs sed -i "s/__PACKAGE_NAME__/$(PACKAGE_NAME)/g"
	find $(LOCAL_DEV_ENV) -type f -not -path "$(LOCAL_DEV_ENV)/webapp/node_modules/*" | xargs sed -i "s/__PACKAGE_DESC__/$(PACKAGE_DESC)/g"
	find $(LOCAL_DEV_ENV) -type f -not -path "$(LOCAL_DEV_ENV)/webapp/node_modules/*" | xargs sed -i "s/__PACKAGE_AUTHOR__/$(PACKAGE_AUTHOR)/g"
	find $(LOCAL_DEV_ENV) -type f -not -path "$(LOCAL_DEV_ENV)/webapp/node_modules/*" | xargs sed -i "s/__VERSION__/$(PACKAGE_VERSION)/g"
	find $(LOCAL_DEV_ENV) -type f -not -path "$(LOCAL_DEV_ENV)/webapp/node_modules/*" | xargs sed -i "s/__DATE__/$(PACKAGE_DATE)/g"
	@if [ -d "$(LOCAL_CACHE)/node_modules/" ]; then \
		echo "== Restore NPM cache =="; \
		set -x; \
		mv $(LOCAL_CACHE)/node_modules/ $(LOCAL_DEV_ENV)/webapp/ ||: ; \
		set +x; \
	fi
	@echo "== Prepare H5 model =="
	@echo "TODO"

## Ensure Vue application is built with DevTools enabled (requires Firefox or Chrome plugin)
vue-dev-tools:
	$(call echo_title, "VUE DEVTOOLS")
	sed -i '/Vue.config.productionTip = false/a Vue.config.devtools = true' $(LOCAL_DEV_ENV)/webapp/src/main.js
	sed -i '/Vue.config.productionTip = false/a Vue.config.devtools = true' $(LOCAL_DEV_ENV)/webapp/src/store/store.js

## Install NPM Modules in local dev environment
npm-install: local-dev-env
	$(call echo_title, "NPM INSTALL")
	cd $(NPM_DEV_ENV) ; npm install

## Runs linter on Vue web application files
npm-lint: npm-install
	$(call echo_title, "NPM LINT")
	cd $(NPM_DEV_ENV) ; npm run lint

## Runs NPM audit to flag security issues (disable with make NPM_AUDIT=false)
npm-audit: npm-install
	# To run conditionally, as not installed on all systems, or to ignore some known failures or (yet) unresolved vulnerabilities, use true:
	# e.g. failures will be ignored on local development, but be enforced on Travis before distribution
	#
	#	cd $(NPM_DEV_ENV) ; npm audit || true; \
	#
	# Or, upgrade nodejs/npm such as the following on CentOS/EL 7 systems via repository:
	#	/usr/bin/yum remove -y nodejs
	#	/usr/bin/yum clean all
	#	/bin/rm -rf /var/cache/yum
	#	/bin/rm /etc/yum.repos.d/nodesource*
	#	/usr/bin/curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
	#
	$(call echo_title, "NPM AUDIT")
	@if [ "$(NPM_AUDIT)" == "true" ]; then \
		cd $(NPM_DEV_ENV) ; npm audit; \
	else \
		echo "Bypassing NPM AUDIT as specified with NPM_AUDIT=$(NPM_AUDIT) .." ; \
	fi

## Runs a full build using NPM
npm-build: npm-install
	$(call echo_title, "NPM BUILD")
	cd $(NPM_DEV_ENV) ; npm run build

## Prepare application
webapp-setup: npm-build
	$(call echo_title, "PREPARE")
	mkdir $(SRV_DEV_ENV)/static/
	cp -r $(NPM_DEV_ENV)/static/* $(SRV_DEV_ENV)/static/
	cp -r $(NPM_DEV_ENV)/dist/css/ $(SRV_DEV_ENV)/static/
	cp -r $(NPM_DEV_ENV)/dist/js/ $(SRV_DEV_ENV)/static/
	mkdir $(SRV_DEV_ENV)/templates/
	cp $(NPM_DEV_ENV)/dist/*.html $(SRV_DEV_ENV)/templates/

## Create a stub settings.cfg file
webapp-settings:
	$(call echo_title, "CREATE STUB SETTINGS")
	@touch $(SRV_DEV_ENV)/config/settings.cfg.dev
	@echo "[admin]" >> $(SRV_DEV_ENV)/config/settings.cfg.dev
	@echo "password = Y25mZmpiZXExMjM=" >> $(SRV_DEV_ENV)/config/settings.cfg.dev
	@echo "" >> $(SRV_DEV_ENV)/config/settings.cfg.dev
	@echo "[ganalytics]" >> $(SRV_DEV_ENV)/config/settings.cfg.dev
	@echo "ua_id = 1234567" >> $(SRV_DEV_ENV)/config/settings.cfg.dev
	@echo "" >> $(SRV_DEV_ENV)/config/settings.cfg.dev
	@echo "[model]" >> $(SRV_DEV_ENV)/config/settings.cfg.dev
	@echo "file = tl_trained_weights.h5" >> $(SRV_DEV_ENV)/config/settings.cfg.dev

## Configure stub settings.cfg
webapp-config: webapp-settings
	cp -f $(SRV_DEV_ENV)/config/settings.cfg.dev $(SRV_DEV_ENV)/config/settings.cfg

## Upload file to Web App
upload:
	$(call echo_title, "UPLOAD")
	@curl -v -H "Content-Type: multipart/form-data" -X POST -F "files=@tests/wolf_01.jpg" http://0.0.0.0:5000/upload

## Check status of a task with ID provided via CLI (e.g. make task-status TASK_ID=<task_id>)
task-status:
	$(call echo_title, "TASK ID STATUS: $(TASK_ID)")
	@echo "NOTE: Provide task ID via command line"
	@echo ""
	@echo "        make task-status TASK_ID=<task_id>"
	@echo ""
	@curl -v -H "Content-Type: multipart/form-data" -X GET http://0.0.0.0:5000/tasks?task_id=$(TASK_ID)

## Start metrics worker
worker-start:
	$(call echo_title, "START WORKER DAEMON")
	@echo "Starting background worker daemon locally, use 'make worker-stop' to terminate.."
	@echo ""
	cd $(SRV_DEV_ENV); celery multi start worker -A worker -Q $(PACKAGE_NAME) -c 3 -f "celery-%n.log" -l INFO --pidfile="celery-%n.pid" --without-gossip
	@echo ""
	@sleep 3

## Stop metrics worker
worker-stop:
	$(call echo_title, "STOP WORKER DAEMON")
	@if [ -d "$(SRV_DEV_ENV)" ]; then \
		set -x; \
		cd $(SRV_DEV_ENV); \
		celery multi stopwait worker --pidfile="celery-%n.pid"; \
		set +x; \
	fi

## Check worker status
worker-status:
	$(call echo_title, "STATUS WORKER DAEMON")
	@if [ -f "$(SRV_DEV_ENV)/celery-worker.pid" ]; then \
		celery status; \
		echo ""; \
		cd $(SRV_DEV_ENV); celery report -A worker; \
	else \
		echo "No worker daemon running.."; \
	fi

## Start web application
webapp-start:
	$(call echo_title, "START WEB APPLICATION")
	@python -c  "import os; print(os.urandom(24));" > $(SRV_DEV_ENV)/config/secret.uti
	@echo "Starting web application locally, use 'make webapp-stop' to terminate.."
	@echo ""
	python $(SRV_DEV_ENV)/application.py &
	@echo ""
	@sleep 3

## Stop web application
webapp-stop:
	$(call echo_title, "STOP WEB APPLICATION")
	-pkill -f $(SRV_DEV_ENV)/application.py

## Start background Message Queue
mq-start:
	$(call echo_title, "START MESSAGE QUEUE")
	@echo ""
	@if [ -f "$(LOCAL_DEV_ENV)/rabbitmq.pid" ]; then \
		echo "Message queue running"; \
		docker ps -af "name=rabbitmq"; \
	else \
		docker run -d --hostname rabbitmq --name rabbitmq -p 5672:5672 rabbitmq:3; \
		sleep 3; \
		docker ps -qf "name=rabbitmq" > $(LOCAL_DEV_ENV)/rabbitmq.pid; \
	fi

## Check Message Queue Status
mq-status:
	$(call echo_title, "STATUS MESSAGE QUEUE")
	@if [ -f "$(LOCAL_DEV_ENV)/rabbitmq.pid" ]; then \
		docker ps -af "name=rabbitmq"; \
		echo ""; \
		docker exec -it `docker ps -f "name=rabbitmq"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'` /bin/bash -c "rabbitmqctl list_vhosts"; \
		echo ""; \
		docker exec -it `docker ps -f "name=rabbitmq"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'` /bin/bash -c "rabbitmqctl list_connections"; \
		echo ""; \
		docker exec -it `docker ps -f "name=rabbitmq"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'` /bin/bash -c "rabbitmqctl list_channels"; \
		echo ""; \
		docker exec -it `docker ps -f "name=rabbitmq"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'` /bin/bash -c "rabbitmqctl list_queues"; \
	else \
		echo "No message queue running.."; \
	fi

## Stop background Message Queue
mq-stop:
	$(call echo_title, "STOP MESSAGE QUEUE")
	@if [ -f "$(LOCAL_DEV_ENV)/rabbitmq.pid" ]; then \
		docker rm -f `cat $(LOCAL_DEV_ENV)/rabbitmq.pid`; \
		rm -f $(LOCAL_DEV_ENV)/rabbitmq.pid; \
	elif [ -n "`docker ps -a -f 'name=rabbitmq'|grep -iv 'CONTAINER ID'|awk -e '{print $$1}'`" ]; then \
		docker rm -f `docker ps -a -f "name=rabbitmq"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'`; \
	fi

## Start background Database
db-start:
	$(call echo_title, "START DATABASE")
	@echo ""
	@if [ -f "$(LOCAL_DEV_ENV)/influxdb.pid" ]; then \
		echo "Message queue running"; \
		docker ps -af "name=influxdb"; \
	else \
		docker run -d --hostname influxdb --name influxdb -p 8086:8086 -v influxdb:/var/lib/influxdb influxdb:1.8; \
		sleep 3; \
		mkdir -p $(LOCAL_DEV_ENV); \
		docker ps -qf "name=influxdb" > $(LOCAL_DEV_ENV)/influxdb.pid; \
	fi

## Check Database
db-status:
	$(call echo_title, "STATUS DATABASE")
	@if [ -f "$(LOCAL_DEV_ENV)/influxdb.pid" ]; then \
		docker ps -af "name=influxdb"; \
		echo ""; \
		docker exec -it `docker ps -f "name=influxdb"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'` /bin/bash -c "influxd"; \
		echo ""; \
		docker exec -it `docker ps -f "name=influxdb"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'` /bin/bash -c "influx -version"; \
		echo ""; \
		docker exec -it `docker ps -f "name=influxdb"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'` /bin/bash -c "influx -execute 'SHOW DATABASES'"; \
	else \
		echo "No InfluxDB running.."; \
	fi

## Stop Database
db-stop:
	$(call echo_title, "STOP DATABASE")
	@if [ -f "$(LOCAL_DEV_ENV)/influxdb.pid" ]; then \
		docker rm -f `cat $(LOCAL_DEV_ENV)/influxdb.pid`; \
		rm -f $(LOCAL_DEV_ENV)/influxdb.pid; \
	elif [ -n "`docker ps -a -f 'name=influxdb'|grep -iv 'CONTAINER ID'|awk -e '{print $$1}'`" ]; then \
		docker rm -f `docker ps -a -f "name=influxdb"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'`; \
	fi

## Start background TS Database
tsdb-start:
	$(call echo_title, "START TIME SERIES DATABASE")
	@echo ""
	@if [ -f "$(LOCAL_DEV_ENV)/prometheus.pid" ]; then \
		echo "Message queue running"; \
		docker ps -af "name=prometheusdb"; \
	else \
		docker run -d --hostname prometheusdb --name prometheusdb -p 9090:9090 -v prometheus:/prometheus prom/prometheus:v2.19.2; \
		sleep 3; \
		mkdir -p $(LOCAL_DEV_ENV); \
		docker ps -qf "name=prometheusdb" > $(LOCAL_DEV_ENV)/prometheusdb.pid; \
	fi

## Check TS Database
tsdb-status:
	$(call echo_title, "STATUS TIME SERIES DATABASE")
	@if [ -f "$(LOCAL_DEV_ENV)/prometheusdb.pid" ]; then \
		docker ps -af "name=prometheusdb"; \
		echo ""; \
		docker exec -it `docker ps -f "name=prometheusdb"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'` /bin/sh -c "promtool --version"; \
	else \
		echo "No Prometheus running.."; \
	fi

## Stop TS Database
tsdb-stop:
	$(call echo_title, "STOP TIME SERIES DATABASE")
	@if [ -f "$(LOCAL_DEV_ENV)/prometheusdb.pid" ]; then \
		docker rm -f `cat $(LOCAL_DEV_ENV)/prometheusdb.pid`; \
		rm -f $(LOCAL_DEV_ENV)/prometheusdb.pid; \
	elif [ -n "`docker ps -a -f 'name=prometheusdb'|grep -iv 'CONTAINER ID'|awk -e '{print $$1}'`" ]; then \
		docker rm -f `docker ps -a -f "name=prometheusdb"|grep -iv "CONTAINER ID"|awk -e '{print $$1}'`; \
	fi

## Validate latest .deb package on a local Ubuntu image with Docker
docker-run-deb:
	$(call echo_title, "DOCKER RUN DEB")
	docker run -i -t -p 8005:8005 --rm ubuntu:xenial /bin/bash -c ' apt clean all && apt update ; \
		apt install -y python wget vim ; \
		wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py ; \
		cp /usr/bin/systemctl /usr/bin/systemctl.bak ; \
		yes | cp -f systemctl.py /usr/bin/systemctl ; \
		chmod a+x /usr/bin/systemctl ; \
		test -L /bin/systemctl || ln -sf /usr/bin/systemctl /bin/systemctl ; \
		echo "deb http://dl.bintray.com/geldtech/debian /" |  tee -a /etc/apt/sources.list.d/geld-tech.list ; \
		apt-key adv --recv-keys --keyserver keyserver.ubuntu.com EA3E6BAEB37CF5E4 ; \
		apt clean all ; \
		apt update ; \
		apt install -y synthetic-monitoring-service ; \
		systemctl status synthetic-monitoring-service ; \
		systemctl status synthetic-monitoring-service-worker ; \
		$$SHELL '

## Validate latest .rpm package on a local CentOS image with Docker
docker-run-rpm:
	$(call echo_title, "DOCKER RUN RPM")
	docker run -i -t -p 8005:8005 --rm centos:7 /bin/bash -c ' yum clean all ; \
		yum install -y python wget vim ; \
		yum install -y epel-release ; \
		wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py ; \
		cp /usr/bin/systemctl /usr/bin/systemctl.bak ; \
		yes | cp -f systemctl.py /usr/bin/systemctl ; \
		chmod a+x /usr/bin/systemctl ; \
		test -L /bin/systemctl || ln -sf /usr/bin/systemctl /bin/systemctl ; \
		useradd -MU www-data && usermod -L www-data ; \
		echo -e "[geld.tech]\nname=geld.tech\nbaseurl=http://dl.bintray.com/geldtech/rpm\ngpgcheck=0\nrepo_gpgcheck=0\nenabled=1" | \
			tee -a /etc/yum.repos.d/geld.tech.repo ; \
		yum install -y synthetic-monitoring-service ; \
		systemctl status synthetic-monitoring-service ; \
		systemctl status synthetic-monitoring-service-worker ; \
		$$SHELL '


# PHONYs
.PHONY: clean isort lint test local-dev-env
.PHONY: vue-dev-tools npm-install npm-lint npm-audit npm-build
.PHONY: webapp-setup webapp-settings webapp-config
.PHONY: daemon-start daemon-stop webapp-start webapp-stop
.PHONY: mq-start mq-stop mq-status
.PHONY: start stop stop-all


# Functions
define echo_title
	@echo ""
	@echo ""
	@echo "$$(tput bold)### $(1) ###$$(tput sgr0)"
	@echo ""
endef


# Self-documented makefile (DO NOT EDIT PAST THIS LINE)
.DEFAULT_GOAL := show-help
.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) == Darwin && echo '--no-init --raw-control-chars')
