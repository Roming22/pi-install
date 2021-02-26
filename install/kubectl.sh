#!/bin/bash -e
# Install kubectl
set -o pipefail

install_kubectl(){
	LATEST_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
	ARCH="$(arch)"
	case "$ARCH" in
			x86_64) ARCH="amd64" ;;
	esac
	BIN="$(command -v kubectl; true)"
	BIN_VERSION="$(${BIN} version --client --short | sed "s:.* ::"; true)"

	if [[ -z "${BIN}" || "${BIN_VERSION}" != "${LATEST_VERSION}" ]]; then
		URL="https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/${ARCH}/kubectl"
		echo "Installing kubectl from '$URL'"
		curl -LO "${URL}"
		chmod a+x "kubectl"
		mkdir -p "${HOME}/.local/bin"
		mv "kubectl" "${HOME}/.local/bin/kubectl"
	fi
	kubectl version --client --short
	kubectl completion "$(basename "${SHELL}")" | sudo tee /etc/bash_completion.d/kubectl
}

install_kubectl
