#! /usr/bin/env sh

# Saner defaults for noninteractive APT / DPKG

# Idempotency check
if ! grep -q -- "DEBIAN_FRONTEND" /etc/environment; then
  # Stop Debconf from doing anything
  echo "DEBIAN_FRONTEND=noninteractive" >> /etc/environment
fi

# 1. Default to keeping default/old settings, so apt doesn't ask a noninteractive jobmanager
#    for user input in those cases.
# 2. If dpkg/apt is already running wait 15 minutes for it to release its lock
#    15 minutes is because that's the current default jobmanager timeout value, so...
#    Higher would be better though, in rare cases.
cat <<- EOF > /etc/apt/apt.conf.d/local
	Dpkg::Options {
	   "--force-confdef";
	   "--force-confold";
	}

	Dpkg::Lock {
	  "Timeout 900";
	}
EOF
