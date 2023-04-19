NAME=template-service
TAG=latest
REGISTRY=us-docker.pkg.dev/omg-img/ordermygear
IMAGE=$(REGISTRY)/$(NAME):$(TAG)
RELEASE_IMAGE=$(REGISTRY)/$(NAME):$(RELEASE_TAG)
NETRC_SECRET_FILE=~/.netrc
IMAGE_BUILDER="omg-image-builder"
IMAGE_PLATFORMS="linux/amd64,linux/arm64"
GO_BUILDER_IMG=$(REGISTRY)/go:v1.17.13-1

GO_ENV=docker run --rm -v $(PWD):/workspace -w /workspace $(GO_BUILDER_IMG) --
ifeq ($(ENV), jenkins)
    GO_ENV=docker run --rm --volumes-from jenkins -w $(PWD) $(GO_BUILDER_IMG) --
endif

GH_AUTH=--build-arg GH_TOKEN=$(GH_TOKEN)
DOCKER_BUILD=docker buildx build --platform $(IMAGE_PLATFORMS) -t $(IMAGE) $(GH_AUTH) . --push
ifeq ($(IS_RELEASE), 1)
	DOCKER_BUILD+=-t $(RELEASE_IMAGE)
endif

all: push

netrc:
	cp $(NETRC_SECRET_FILE) ./netrc

vendor: netrc
	$(GO_ENV) go mod vendor

.release:
	@if ! docker buildx ls | grep -q $(IMAGE_BUILDER); then\
		docker buildx create --platform $(IMAGE_PLATFORMS) --name $(IMAGE_BUILDER) --use;\
	fi
	$(DOCKER_BUILD)
	touch .multi-platform-build
	echo "$(IMAGE)" > .release
release: .release

push: .release

lint:
	docker build --target linter -t $(LINTER_IMAGE) $(GH_AUTH) .
	docker rmi $(LINTER_IMAGE)

test:
	docker build --target tester -t $(TESTER_IMAGE) $(GH_AUTH) .
	docker run --rm --entrypoint cat $(TESTER_IMAGE) c.out > c.out
	docker rmi $(TESTER_IMAGE)
	@if [ -e c.out ]; then \
		go tool cover -html=c.out; \
	fi

clean:
	- rm -rf .build netrc .release data vendor c.out .multi-platform-build
	- docker rmi $(IMAGE)

.PHONY: release push clean test lint