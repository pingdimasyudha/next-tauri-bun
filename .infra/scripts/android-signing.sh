#!/usr/bin/env bash
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │   Author  : Dimas Yudha Pratama                                         │
# │   Email   : pingdimasyudha@icloud.com                                   │
# │   Created : January 11th, 2025                                          │
# │   Version : 1.0.0                                                       │
# │                                                                         │
# │   Description:                                                          │
# │   This script automates the process of Android code signing for a       │
# │   Tauri-based project, ensuring that a keystore and its associated      │
# │   password are properly set up. It also modifies the existing           │
# │   build.gradle.kts file to configure release signing.                   │
# └─────────────────────────────────────────────────────────────────────────┘

set -euo pipefail
IFS=$'\n\t'

###############################################################################
# ┏━📘━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ log()                                                                     ┃
# ┃   Purpose:                                                                ┃
# ┃     Provides a single, flexible logging function for all levels.          ┃
# ┃   Usage:                                                                  ┃
# ┃     log "INFO" "Starting script..."                                       ┃
# ┃     log "WARN" "Potential issue..."                                       ┃
# ┃     log "SUCCESS" "Operation successful."                                 ┃
# ┃     log "ERROR" "Fatal error encountered!"                                ┃
# ┃   Parameters:                                                             ┃
# ┃     $1 -> Log level: INFO, WARN, SUCCESS, or ERROR                        ┃
# ┃     $2 -> Log message                                                     ┃
# ┃   Returns:                                                                ┃
# ┃     Outputs the message to stdout or stderr. Exits if level is ERROR.     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
###############################################################################
log() {
  local level="$1"
  local message="$2"
  local icon
  local timestamp
  timestamp="$(date +'%Y-%m-%d %H:%M:%S')"

  case "${level}" in
    INFO)     icon="ℹ️ ";;
    WARN)     icon="⚠️";;
    SUCCESS)  icon="✅";;
    ERROR)    icon="❌";;
    *)        icon="🔖";;
  esac

  if [[ "${level}" == "ERROR" ]]; then
    echo -e "[${timestamp}] [${level}] ${icon} ${message}" >&2

    exit 1
  else
    echo -e "[${timestamp}] [${level}] ${icon} ${message}"
  fi
}

###############################################################################
# ┏━📘━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ check_os()                                                                ┃
# ┃   Purpose:                                                                ┃
# ┃     Detects the operating system (Linux or macOS).                        ┃
# ┃   Usage:                                                                  ┃
# ┃     check_os                                                              ┃
# ┃   Returns:                                                                ┃
# ┃     Sets global variable CURRENT_OS to "Linux" or "macOS". Exits if       ┃
# ┃     unsupported OS is detected.                                           ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
###############################################################################
check_os() {
  local uname_out
  uname_out="$(uname -s)"

  case "${uname_out}" in
    Linux*)   CURRENT_OS="Linux" ;;
    Darwin*)  CURRENT_OS="macOS" ;;
    *)        log "ERROR" "Unsupported OS detected: ${uname_out}. Exiting..." ;;
  esac

  log "INFO" "Detected OS: ${CURRENT_OS}"
}

###############################################################################
# ┏━📘━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ check_keystore_file()                                                     ┃
# ┃   Purpose:                                                                ┃
# ┃     Ensures that /home/nonroot/nayud.jks exists.                          ┃
# ┃   Usage:                                                                  ┃
# ┃     check_keystore_file                                                   ┃
# ┃   Returns:                                                                ┃
# ┃     Exits if the file does not exist.                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
###############################################################################
check_keystore_file() {
  if [[ ! -f "/home/nonroot/nayud.jks" ]]; then
    log "ERROR" "nayud.jks not found in /home/nonroot. Script will terminate."
  fi

  log "SUCCESS" "nayud.jks file is present in /home/nonroot."
}

###############################################################################
# ┏━📘━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ check_tauri_keystore_password()                                           ┃
# ┃   Purpose:                                                                ┃
# ┃     Checks if the TAURI_KEYSTORE_PASSWORD environment variable is set.    ┃
# ┃   Usage:                                                                  ┃
# ┃     check_tauri_keystore_password                                         ┃
# ┃   Returns:                                                                ┃
# ┃     Exits if TAURI_KEYSTORE_PASSWORD is unset.                            ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
###############################################################################
check_tauri_keystore_password() {
  if [[ -z "${TAURI_KEYSTORE_PASSWORD:-}" ]]; then
    log "ERROR" "TAURI_KEYSTORE_PASSWORD environment variable is not set. Script will terminate."
  fi

  log "SUCCESS" "TAURI_KEYSTORE_PASSWORD is exported."
}

###############################################################################
# ┏━📘━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ check_src_tauri_gen()                                                     ┃
# ┃   Purpose:                                                                ┃
# ┃     Ensures that the src-tauri/gen folder exists, or creates it using     ┃
# ┃     'bun init:android' if Bun is installed.                               ┃
# ┃   Usage:                                                                  ┃
# ┃     check_src_tauri_gen                                                   ┃
# ┃   Returns:                                                                ┃
# ┃     Exits if the folder cannot be created.                                ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
###############################################################################
check_src_tauri_gen() {
  if [[ ! -d "src-tauri/gen" ]]; then
    log "WARN" "src-tauri/gen folder does not exist. Attempting to create with bun init:android..."

    if ! command -v bun &>/dev/null; then
      log "ERROR" "Bun is not installed. Cannot run 'bun init:android'. Please install Bun first."
    fi

    if ! bun init:android; then
      log "ERROR" "Failed to create src-tauri/gen folder using 'bun init:android'."
    fi

    log "SUCCESS" "src-tauri/gen folder created successfully."
  else
    log "SUCCESS" "src-tauri/gen folder already exists."
  fi
}

###############################################################################
# ┏━📘━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ create_keystore_properties()                                              ┃
# ┃   Purpose:                                                                ┃
# ┃     Creates/overwrites a keystore.properties file for Android signing,    ┃
# ┃     storing password, alias, and store file path.                         ┃
# ┃   Usage:                                                                  ┃
# ┃     create_keystore_properties                                            ┃
# ┃   Returns:                                                                ┃
# ┃     Exits if file I/O fails, otherwise creates file at                    ┃
# ┃     src-tauri/gen/android/keystore.properties.                            ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
###############################################################################
create_keystore_properties() {
  local keystore_file_path="src-tauri/gen/android/keystore.properties"

  {
    echo "password=${TAURI_KEYSTORE_PASSWORD}"
    echo "keyAlias=upload"
    echo "storeFile=/home/nonroot/nayud.jks"
  } > "${keystore_file_path}"

  if [[ ! -f "${keystore_file_path}" ]]; then
    log "ERROR" "Failed to create keystore.properties at ${keystore_file_path}"
  fi

  log "SUCCESS" "keystore.properties created successfully at ${keystore_file_path}"
}

###############################################################################
# ┏━📘━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ modify_build_gradle()                                                     ┃
# ┃   Purpose:                                                                ┃
# ┃     Modifies build.gradle.kts in src-tauri/gen/android/app                ┃
# ┃     to insert signing configuration.                                      ┃
# ┃   Usage:                                                                  ┃
# ┃     modify_build_gradle                                                   ┃
# ┃   Details:                                                                ┃
# ┃     1. Insert `import java.io.FileInputStream` after `import`             ┃
# ┃     2. Insert signingConfigs block after `namespace`.                     ┃
# ┃     3. Insert `signingConfig = signingConfigs.getByName("release")`       ┃
# ┃        after `release`.                                                   ┃
# ┃   Returns:                                                                ┃
# ┃     Exits if the file cannot be modified.                                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
###############################################################################
modify_build_gradle() {
  local gradle_file="src-tauri/gen/android/app/build.gradle.kts"

  if [[ ! -f "${gradle_file}" ]]; then
    log "ERROR" "Cannot find build.gradle.kts at ${gradle_file}"
  fi

  log "INFO" "Modifying build.gradle.kts at ${gradle_file}..."

  local tmp_file
  tmp_file="$(mktemp)"

  awk '
    /import/ {
      print
      print "import java.io.FileInputStream"
      next
    }
    /release/ {
      print
      print "            signingConfig = signingConfigs.getByName(\"release\")"
      next
    }
    /namespace/ {
      print
      print "    signingConfigs {"
      print "        create(\"release\") {"
      print "            val keystorePropertiesFile = rootProject.file(\"keystore.properties\")"
      print "            val keystoreProperties = Properties()"
      print ""
      print "            if (keystorePropertiesFile.exists()) {"
      print "                keystoreProperties.load(FileInputStream(keystorePropertiesFile))"
      print "            }"
      print ""
      print "            keyAlias = keystoreProperties[\"keyAlias\"] as String"
      print "            keyPassword = keystoreProperties[\"password\"] as String"
      print "            storeFile = file(keystoreProperties[\"storeFile\"] as String)"
      print "            storePassword = keystoreProperties[\"password\"] as String"
      print "        }"
      print "    }"
      next
    }
    { print }
  ' "${gradle_file}" > "${tmp_file}"

  mv "${tmp_file}" "${gradle_file}"

  log "SUCCESS" "Successfully modified build.gradle.kts."
}

###############################################################################
# ┏━📘━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ main()                                                                    ┃
# ┃   Purpose:                                                                ┃
# ┃     The main driver function that sequentially performs the OS check,     ┃
# ┃     environment checks, keystore setup, and Gradle file modifications.    ┃
# ┃   Usage:                                                                  ┃
# ┃     main                                                                  ┃
# ┃   Returns:                                                                ┃
# ┃     Orchestrates the entire script flow and logs the final outcome.       ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
###############################################################################
main() {
  check_os
  check_keystore_file
  check_tauri_keystore_password
  check_src_tauri_gen
  create_keystore_properties
  modify_build_gradle

  log "SUCCESS" "Android code signing setup is complete! 🚀"
}

main