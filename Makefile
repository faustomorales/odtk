# You can set these variables from the command line.
WORKDIR = /usr/src
NOTEBOOK_PORT = 5000
DOCUMENTATION_PORT = 5001
DOCKER_ARGS = $(VOLUMES) -w $(WORKDIR) --rm 
IMAGE_NAME = mira
VOLUME_NAME = $(IMAGE_NAME)_venv
EXTENSIONS_VOLUME_NAME = $(IMAGE_NAME)_extensions
VOLUMES = -v $(PWD):/usr/src -v $(VOLUME_NAME):/usr/src/.venv -v $(EXTENSIONS_VOLUME_NAME):/usr/src/mira/utils --rm
JUPYTER_OPTIONS := --ip=0.0.0.0 --port=$(NOTEBOOK_PORT) --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
TEST_SCOPE ?= tests/
IN_DOCKER = docker run -it $(DOCKER_ARGS)

.PHONY: build
build:
	docker build --rm --force-rm -t $(IMAGE_NAME) .
	@-docker volume rm $(VOLUME_NAME)
	@-docker volume rm $(EXTENSIONS_VOLUME_NAME)
init:
	@-mkdir .venv
	pipenv install --dev --skip-lock
lab-server:
	$(IN_DOCKER) -p $(NOTEBOOK_PORT):$(NOTEBOOK_PORT) $(IMAGE_NAME) pipenv run jupyter lab $(JUPYTER_OPTIONS)
documentation-server:
	$(IN_DOCKER) -p $(DOCUMENTATION_PORT):$(DOCUMENTATION_PORT) $(IMAGE_NAME) pipenv run sphinx-autobuild -b html "docs" "docs/_build/html" --host 0.0.0.0 --port $(DOCUMENTATION_PORT) $(O)
.PHONY: tests
test:
	$(IN_DOCKER) $(IMAGE_NAME) pipenv run pytest $(TEST_SCOPE)
.PHONY: docs
docs:
	$(IN_DOCKER) $(IMAGE_NAME) pipenv run sphinx-build -b html "docs" "docs/dist"
bash:
	$(IN_DOCKER) $(IMAGE_NAME) bash