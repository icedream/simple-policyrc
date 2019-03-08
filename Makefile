.PHONY: default test install

default: install

test:
	docker run --rm \
		-w $(CURDIR)/test -v $(CURDIR):$(CURDIR) \
		debian ./test.sh

install:
	install -m 644 policy-rc.d /usr/sbin/policy-rc.d
