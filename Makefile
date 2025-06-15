DEVICES = rpi-zero.local
USERS = admin
SSH_KEYS = $(HOME)/.ssh/homelab
SSH_PORTS = 22 717

REMOTE_TMP = /tmp/homelab
REMOTE_TARGET = /root/homelab
LOCAL_DIR = $(CURDIR)/

copy:
	@for i in `seq 1 $(words $(DEVICES))`; do \
		DEVICES_LIST="$(DEVICES)"; \
		USERS_LIST="$(USERS)"; \
		KEYS="$(SSH_KEYS)"; \
		PORTS="$(SSH_PORTS)"; \
		\
		DEVICE=$$(echo $$DEVICES_LIST | cut -d' ' -f$$i); \
		USER=$$(echo $$USERS_LIST | cut -d' ' -f$$i); \
		\
		echo "Deploying to $$DEVICE as $$USER"; \
		\
		SUCCESS=0; \
		for KEY in $$KEYS; do \
			for PORT in $$PORTS; do \
				echo "Trying SSH key: $$KEY on port $$PORT"; \
				scp -o ConnectTimeout=5 -P $$PORT -i $$KEY -r $(LOCAL_DIR) $$USER@$$DEVICE:$(REMOTE_TMP) && \
				ssh -o ConnectTimeout=5 -p $$PORT -i $$KEY $$USER@$$DEVICE "sudo -S rm -rf $(REMOTE_TARGET) && sudo mv $(REMOTE_TMP) $(REMOTE_TARGET)" && \
				SUCCESS=1 && break 2; \
			done; \
		done; \
		if [ $$SUCCESS -eq 0 ]; then \
			echo "SSH keys failed, falling back to password..."; \
			scp -o ConnectTimeout=5 -r $(LOCAL_DIR) $$USER@$$DEVICE:$(REMOTE_TMP) && \
			ssh -o ConnectTimeout=5 $$USER@$$DEVICE "echo $$PW | sudo -S rm -rf $(REMOTE_TARGET) && sudo mv $(REMOTE_TMP) $(REMOTE_TARGET)"; \
		fi; \
	done

chmod:
	@echo "Making all .sh files executable..."
	@find $(LOCAL_DIR) -type f -name "*.sh" -exec chmod +x {} \;