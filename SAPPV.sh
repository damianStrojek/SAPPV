#!/bin/bash
#
# SAP Parameter Validator
# Copyright (C) 2024 Damian Strojek
#

# Define colors for output
GREEN='\033[0;32m'      # Green
RED='\033[0;31m'        # Red
YELLOW='\033[0;33m'     # Yellow
BOLD='\033[1m'          # Bold
NC='\033[0m'            # No Color

# Define namespace URI
NAMESPACE_URI="urn:schemas-microsoft-com:office:spreadsheet"

# List of parameters and their expected values
declare -A PARAMETERS
PARAMETERS=(
  ["auth/object_disabling_active"]="Y"
  ["auth/rfc_authority_check"]="<2"
  ["auth/no_check_in_some_cases"]="Y"
  ["bdc/bdel_auth_check"]="FALSE"
  ["gw/reg_no_conn_info"]="<255"
  ["icm/security_log"]="2"
  ["icm/server_port_0"]=""
  ["icm/server_port_1"]=""
  ["icm/server_port_2"]=""
  ["login/password_compliance_to_current_policy"]="0"
  ["login/no_automatic_user_sapstar"]="0"
  ["login/min_password_specials"]="0"
  ["login/min_password_lng"]="<8"
  ["login/min_password_lowercase"]="0"
  ["login/min_password_uppercase"]="0"
  ["login/min_password_digits"]="0"
  ["login/min_password_letters"]="1"
  ["login/fails_to_user_lock"]="<5"
  ["login/password_expiration_time"]=">90"
  ["login/password_max_idle_initial"]="<14"
  ["login/password_max_idle_productive"]="<180"
  ["login/password_downwards_compatibility"]="0"
  ["rfc/reject_expired_passwd"]="0"
  ["rsau/enable"]="0"
  ["rdisp/gui_auto_logout"]="<5"
  ["service/protectedwebmethods"]="SDEFAULT"
  ["snc/enable"]="0"
  ["ucon/rfc/active"]="0"
)

# Order of parameters for display
PARAM_ORDER=(
  "auth/no_check_in_some_cases"
  "auth/object_disabling_active"
  "auth/rfc_authority_check"
  "bdc/bdel_auth_check"
  "gw/reg_no_conn_info"
  "icm/security_log"
  "icm/server_port_0"
  "icm/server_port_1"
  "icm/server_port_2"
  "login/fails_to_user_lock"
  "login/min_password_digits"
  "login/min_password_letters"
  "login/min_password_lng"
  "login/min_password_lowercase"
  "login/min_password_specials"
  "login/min_password_uppercase"
  "login/no_automatic_user_sapstar"
  "login/password_compliance_to_current_policy"
  "login/password_downwards_compatibility"
  "login/password_expiration_time"
  "login/password_max_idle_initial"
  "login/password_max_idle_productive"
  "rdisp/gui_auto_logout"
  "rfc/reject_expired_passwd"
  "rsau/enable"
  "service/protectedwebmethods"
  "snc/enable"
  "ucon/rfc/active"
)

# Function to determine color based on parameter value
get_color() {
  local param="$1"
  local user_defined="$2"
  local system_default="$3"
  local expected_value="$4"

  # Choose value to compare
  if [ "$user_defined" == "No data" ]; then
    value="$system_default"
  else
    value="$user_defined"
  fi

  # Remove trailing and leading spaces and uppercase letters from the value for comparison
  value=$(echo "$value" | tr -d '[:space:]' | tr -d 'H')

  case "$param" in
    "auth/object_disabling_active"|"auth/no_check_in_some_cases"|"bdc/bdel_auth_check"|"icm/security_log"|"login/password_compliance_to_current_policy"|"login/no_automatic_user_sapstar"|"service/protectedwebmethods"|"snc/enable"|"rfc/reject_expired_passwd"|"rsau/enable"|"ucon/rfc/active"|"login/min_password_specials"|"login/min_password_lowercase"|"login/min_password_uppercase"|"login/min_password_digits"|"login/min_password_letters"|"login/password_downwards_compatibility")
      if [ "$value" == "$expected_value" ]; then
        echo "$RED"
      else
        echo "$GREEN"
      fi
      ;;
    "auth/rfc_authority_check"|"gw/reg_no_conn_info"|"rdisp/gui_auto_logout"|"login/min_password_lng"|"login/fails_to_user_lock"|"login/password_max_idle_initial"|"login/password_max_idle_productive")
      if [ "$(echo "$value" | tr -d '[:space:]')" -lt "${expected_value//<}" ]; then
        echo "$RED"
      else
        echo "$GREEN"
      fi
      ;;
    "login/password_expiration_time")
      if [ "$(echo "$value" | tr -d '[:space:]')" -gt "${expected_value//>/}" ]; then
        echo "$RED"
      else
        echo "$GREEN"
      fi
      ;;
    "icm/server_port_0"|"icm/server_port_1"|"icm/server_port_2")
      echo "$YELLOW"
      ;;
    *)
      echo "$NC"
      ;;
  esac
}

# Function to extract and print parameter details
extract_parameters() {
  local xml_file="$1"
  local search_param="$2"
  local expected_value="$3"

  # Construct XPath query to get the matching row
  local xpath_query="//*[local-name()='Row'][*[local-name()='Cell'][1]/*[local-name()='Data'][text()='$search_param']]"

  # Execute xmllint and capture output
  local row=$(xmllint --xpath "$xpath_query" "$xml_file" 2>/dev/null)

  if [ -z "$row" ]; then
    echo -e "${RED}No matching parameter found for ${search_param}.${NC}"
    return
  fi

  # Extract values using XPath
  local user_defined=$(echo "$row" | xmllint --xpath "//*[local-name()='Cell'][2]/*[local-name()='Data']/text()" - 2>/dev/null)
  local system_default=$(echo "$row" | xmllint --xpath "//*[local-name()='Cell'][3]/*[local-name()='Data']/text()" - 2>/dev/null)
  local comment=$(echo "$row" | xmllint --xpath "//*[local-name()='Cell'][5]/*[local-name()='Data']/text()" - 2>/dev/null)

  # Default to empty string if not found
  user_defined=${user_defined:-"No data"}
  system_default=${system_default:-"No data"}
  comment=${comment:-"No comment"}

  # Get color based on the parameter value
  local color=$(get_color "$search_param" "$user_defined" "$system_default" "$expected_value")

  echo -e "${color}${BOLD}Parameter: ${search_param}${NC}"
  echo -e "${color}User-Defined Value: ${user_defined}${NC}"
  echo -e "${color}System Default Value: ${system_default}${NC}"
  echo -e "${color}Comment: ${comment}${NC}"
}

# Main function to handle input and output
main() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <xml-file>"
    exit 1
  fi

  xml_file="$1"
  
  if [ ! -f "$xml_file" ]; then
    echo "File $xml_file does not exist."
    exit 1
  fi

  echo ""

  # Process parameters with expected values
  for param in "${PARAM_ORDER[@]}"; do
    extract_parameters "$xml_file" "$param" "${PARAMETERS[$param]}"
    echo
  done
}

main "$@"
