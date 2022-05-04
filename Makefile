
build:
	cp /tmp/*.pem .
	docker build -t eloycoto/edgedevice .
