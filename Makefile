.PHONY: default test install

default: install

test:
	docker run --rm \
		-w $(CURDIR)/test -v $(CURDIR):$(CURDIR) \
		debian ./test.sh

install:
	install -m 755 policy-rc.d /usr/sbin/policy-rc.d
