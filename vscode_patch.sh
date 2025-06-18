#!/usr/bin/env bash
#
# This script downloads and installs a specific version of VS Code Server for CentOS 7.
# It includes error handling and follows best practices for Bash scripting.

# --- Script Configuration and Best Practices ---

# Exit immediately if a command exits with a non-zero status.
set -o errexit
# Exit if an unset variable is used.
set -o nounset
# If any command in a pipeline fails, the whole pipeline's return status is that of the rightmost command
# to exit with a non-zero status, or zero if all commands exit successfully.
set -o pipefail
# Enable tracing of commands (set +o xtrace to disable). Useful for debugging.
# To activate, run the script with TRACE=1 ./your_script.sh
if [[ "${TRACE-0}" == "1" ]]; then
  set -o xtrace
fi

# Ensure all variables are quoted for safety.
# Prefer lowercase for internal script variables, uppercase for environment variables.
# Don't use naked $ signs, always use double quotes "$VAR". [5]

# --- Global Variables ---
readonly VSCODE_SERVER_BASE_URL="https://github.com/MikeWang000000/vscode-server-centos7/releases/download"
readonly TMP_DIR="/tmp"
readonly VSCODE_INSTALL_DIR="$HOME/.vscode-server"

# --- Functions ---

# Function to display error messages and exit.
log_error() {
  printf "Error: %s\n" "$@" >&2
  exit 1
}

# Function to display informational messages.
log_info() {
  printf "Info: %s\n" "$@"
}

# Main installation logic.
install_vscode_server() {
  local version="$1" # Use local variables in functions. [5]

  if [[ -z "$version" ]]; then
    log_error "VS Code Server version not provided. Usage: $0 <VERSION>"
  fi

  local download_url="${VSCODE_SERVER_BASE_URL}/${version}/vscode-server_${version}_x64.tar.gz"
  local tarball_path="${TMP_DIR}/vscode-server_${version}_x64.tar.gz"

  log_info "Attempting to download VS Code Server version: ${version} from ${download_url}"

  # Use curl with options for safety and robust download.
  # -S: Show error if curl fails silently.
  # -L: Follow redirects.
  # --fail-with-body: Fail silently but include response body in output for debugging.
  # -o: Write output to a local file.
  if ! curl -sSL --fail-with-body "${download_url}" -o "${tarball_path}"; then
    log_error "Failed to download VS Code Server. Check the version or URL."
  fi

  log_info "Creating installation directory: ${VSCODE_INSTALL_DIR}"
  mkdir -p "${VSCODE_INSTALL_DIR}" || log_error "Failed to create installation directory."

  log_info "Extracting VS Code Server to ${VSCODE_INSTALL_DIR}"
  if ! tar xzf "${tarball_path}" -C "${VSCODE_INSTALL_DIR}" --strip-components 1; then
    log_error "Failed to extract VS Code Server archive."
  fi

  log_info "Cleaning up temporary file: ${tarball_path}"
  rm -f "${tarball_path}" || log_info "Failed to remove temporary file, continuing anyway." # Non-fatal cleanup

  log_info "VS Code Server installation complete. Patching now..."
  # Ensure the directory exists before attempting to run.
  if [[ -x "${VSCODE_INSTALL_DIR}/code-latest" ]]; then # Check if executable.
    "${VSCODE_INSTALL_DIR}/code-latest" --patch-now || log_error "Failed to patch VS Code Server."
  else
    log_error "VS Code Server executable not found or not executable at ${VSCODE_INSTALL_DIR}/code-latest"
  fi

  log_info "VS Code Server is ready!"
}

# --- Script Entry Point ---
# Call the main function with all provided arguments. [5]
install_vscode_server "$@"
