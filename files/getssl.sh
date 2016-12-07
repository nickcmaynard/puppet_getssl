#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# getssl - Obtain SSL certificates from the letsencrypt.org ACME server

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# For usage, run "getssl -h" or see https://github.com/srvrco/getssl

# Revision history:
# 2016-01-08 Created (v0.1)
# 2016-01-11 type correction and upload to github (v0.2)
# 2016-01-11 added import of any existing cert on -c  option (v0.3)
# 2016-01-12 corrected formatting of imported certificate (v0.4)
# 2016-01-12 corrected error on removal of token in some instances (v0.5)
# 2016-01-18 corrected issue with removing tmp if run as root with the -c option (v0.6)
# 2016-01-18 added option to upload a single PEN file ( used by cpanel) (v0.7)
# 2016-01-23 added dns challenge option (v0.8)
# 2016-01-24 create the ACL directory if it does not exist. (v0.9) - dstosberg
# 2016-01-26 correcting a couple of small bugs and allow curl to follow redirects (v0.10)
# 2016-01-27 add a very basic openssl.cnf file if it doesn't exist and tidy code slightly (v0.11)
# 2016-01-28 Typo corrections, quoted file variables and fix bug on DNS_DEL_COMMAND (v0.12)
# 2016-01-28 changed DNS checks to use nslookup and allow hyphen in domain names (v0.13)
# 2016-01-29 Fix ssh-reload-command, extra waiting for DNS-challenge,
# 2016-01-29 add error_exit and cleanup help message (v0.14)
# 2016-01-29 added -a|--all option to renew all configured certificates (v0.15)
# 2016-01-29 added option for elliptic curve keys (v0.16)
# 2016-01-29 added server-type option to use and check cert validity from website (v0.17)
# 2016-01-30 added --quiet option for running in cron (v0.18)
# 2016-01-31 removed usage of xxd to make script more compatible across versions (v0.19)
# 2016-01-31 removed usage of base64 to make script more compatible across platforms (v0.20)
# 2016-01-31 added option to safe a full chain certificate (v0.21)
# 2016-02-01 commented code and added option for copying concatenated certs to file (v0.22)
# 2016-02-01 re-arrange flow for DNS-challenge, to reduce time taken (v0.23)
# 2016-02-04 added options for other server types (ldaps, or any port) and check_remote (v0.24)
# 2016-02-04 added short sleep following service restart before checking certs (v0.25)
# 2016-02-12 fix challenge token location when directory doesn't exist (v0.26)
# 2016-02-17 fix sed -E issue, and reduce length of renew check to 365 days for older systems (v0.27)
# 2016-04-05 Ensure DNS cleanup on error exit. (0.28) - pecigonzalo
# 2016-04-15 Remove NS Lookup of A record when using dns validation (0.29) - pecigonzalo
# 2016-04-17 Improving the wording in a couple of comments and info statements. (0.30)
# 2016-05-04 Improve check for if DNS_DEL_COMMAND is blank. (0.31)
# 2016-05-06 Setting umask to 077 for security of private keys etc. (0.32)
# 2016-05-20 update to reflect changes in staging ACME server json (0.33)
# 2016-05-20 tidying up checking of json following AMCE changes. (0.34)
# 2016-05-21 added AUTH_DNS_SERVER to getssl.cfg as optional definition of authoritative DNS server (0.35)
# 2016-05-21 added DNS_WAIT to getssl.cfg as (default = 10 seconds as before) (0.36)
# 2016-05-21 added PUBLIC_DNS_SERVER option, for forcing use of an external DNS server (0.37)
# 2016-05-28 added FTP method of uploading tokens to remote server (blocked for certs as not secure) (0.38)
# 2016-05-28 added FTP method into the default config notes. (0.39)
# 2016-05-30 Add sftp with password to copy files (0.40)
# 2016-05-30 Add version check to see if there is a more recent version of getssl (0.41)
# 2016-05-30 Add [-u|--upgrade] option to automatically upgrade getssl (0.42)
# 2016-05-30 Added backup when auto-upgrading (0.43)
# 2016-05-30 Improvements to auto-upgrade (0.44)
# 2016-05-31 Improved comments - no structural changes
# 2016-05-31 After running for nearly 6 months, final testing prior to a 1.00 stable version. (0.90)
# 2016-06-01 Reorder functions alphabetically as part of code tidy. (0.91)
# 2016-06-03 Version 1.0 of code for release (1.00)
# 2016-06-09 bugfix of issue 44, and add success statement (ignoring quiet flag) (1.01)
# 2016-06-13 test return status of DNS_ADD_COMMAND and error_exit if a problem (hadleyrich) (1.02)
# 2016-06-13 bugfix of issue 45, problem with SERVER_TYPE when it's just a port number (1.03)
# 2016-06-13 bugfix issue 47 - DNS_DEL_COMMAND cleanup was run when not required. (1.04)
# 2016-06-15 add error checking on RELOAD_CMD (1.05)
# 2016-06-20 updated sed and date functions to run on MAC OS X (1.06)
# 2016-06-20 added CHALLENGE_CHECK_TYPE variable to allow checks direct on https rather than http (1.07)
# 2016-06-21 updated grep functions to run on MAC OS X (1.08)
# 2016-06-11 updated to enable running on windows with cygwin (1.09)
# 2016-07-02 Corrections to work with older slackware issue #56 (1.10)
# 2016-07-02 Updating help info re ACL in config file (1.11)
# 2016-07-04 adding DOMAIN_STORAGE as a variable to solve for issue #59 (1.12)
# 2016-07-05 updated order to better handle non-standard DOMAIN_STORAGE location (1.13)
# 2016-07-06 added additional comments about SANS in example template (1.14)
# 2016-07-07 check for duplicate domains in domain / SANS (1.15)
# 2016-07-08 modified to be used on older bash for issue #64 (1.16)
# 2016-07-11 added -w to -a option and comments in domain template (1.17)
# 2016-07-18 remove / regenerate csr when generating new private domain key (1.18)
# 2016-07-21 add output of combined private key and domain cert (1.19)
# 2016-07-21 updated typo (1.20)
# 2016-07-22 corrected issue in nslookup debug option - issue #74 (1.21)
# 2016-07-26 add more server-types based on openssl s_client (1.22)
# 2016-08-01 updated agreement for letsencrypt (1.23)
# 2016-08-02 updated agreement for letsencrypt to update automatically (1.24)
# 2016-08-03 improve messages on test of certificate installation (1.25)
# 2016-08-04 remove carriage return from agreement - issue #80 (1.26)
# 2016-08-04 set permissions for token folders - issue #81 (1.27)
# 2016-08-07 allow default chained file creation - issue #85 (1.28)
# 2016-08-07 use copy rather than move when archiving certs - issue #86 (1.29)
# 2016-08-07 enable use of a single ACL for all checks (if USE_SINGLE_ACL="true" (1.30)
# 2016-08-23 check for already validated domains (issue #93) - (1.31)
# 2016-08-23 updated already validated domains (1.32)
# 2016-08-23 included better force_renew and template for USE_SINGLE_ACL (1.33)
# 2016-08-23 enable insecure certificate on https token check #94 (1.34)
# 2016-08-23 export OPENSSL_CONF so it's used by all openssl commands (1.35)
# 2016-08-25 updated defaults for ACME agreement (1.36)
# 2016-09-04 correct issue #101 when some domains already validated (1.37)
# 2016-09-12 Checks if which is installed (1.38)
# 2016-09-13 Don't check for updates, if -U parameter has been given (1.39)
# 2016-09-17 Improved error messages from invalid certs (1.40)
# 2016-09-19 remove update check on recursive calls when using -a (1.41)
# 2016-09-21 changed shebang for portability (1.42)
# 2016-09-21 Included option to Deactivate an Authorization (1.43)
# 2016-09-22 retry on 500 error from ACME server (1.44)
# 2016-09-22 added additional checks and retry on 500 error from ACME server (1.45)
# 2016-09-24 merged in IPv6 support (1.46)
# 2016-09-27 added additional debug info issue #119 (1.47)
# 2016-09-27 removed IPv6 switch in favour of checking both IPv4 and IPv6 (1.48)
# 2016-09-28 Add -Q, or --mute, switch to mute notifications about successfully upgrading getssl (1.49)
# 2016-09-30 improved portability to work natively on FreeBSD, Slackware and OSX (1.50)
# 2016-09-30 comment out PRIVATE_KEY_ALG from the domain template Issue #125 (1.51)
# 2016-10-03 check remote certificate for right domain before saving to local (1.52)
# 2016-10-04 allow existing CSR with domain name in subject (1.53)
# 2016-10-05 improved the check for CSR with domain in subject (1.54)
# 2016-10-06 prints update info on what was included in latest updates (1.55)
# 2016-10-06 when using -a flag, ignore folders in working directory which aren't domains (1.56)
# 2016-10-12 alllow multiple tokens in DNS challenge (1.57)
# 2016-10-14 added CHECK_ALL_AUTH_DNS option to check all DNS servres, not just one primary server (1.58)
# 2016-10-14 added archive of chain and private key for each cert, and purge old archives (1.59)
# 2016-10-17 updated info comment on failed cert due to rate limits. (1.60)
# 2016-10-17 fix error messages when using 1.0.1e-fips  (1.61)
# 2016-10-20 set secure permissions when generating account key (1.62)
# 2016-10-20 set permsissions to 700 for getssl script during upgrade (1.63)
# 2016-10-20 add option to revoke a certificate (1.64)
# 2016-10-21 set revocation server default to acme-v01.api.letsencrypt.org (1.65)
# 2016-10-21 bug fix for revocation on different servers. (1.66)
# 2016-10-22 Tidy up archive code for certificates and reduce permissions for security
# 2016-10-22 Add EC signing for secp384r1 and secp521r1 (the latter not yet supported by Let's  Encrypt
# 2016-10-22 Add option to create a new private key for every cert (REUSE_PRIVATE_KEY="true" by default)
# 2016-10-22 Combine EC signing, Private key reuse and archive permissions (1.67)
# 2016-10-25 added CHECK_REMOTE_WAIT option ( to pause before final remote check)
# 2016-10-25 Added EC account key support ( prime256v1, secp384r1 ) (1.68)
# 2016-10-25 Ignore DNS_EXTRA_WAIT if all domains already validated (issue #146) (1.69)
# 2016-10-25 Add option for dual ESA / EDSA certs (1.70)
# 2016-10-25 bug fix Issue #141 challenge error 400 (1.71)
# 2016-10-26 check content of key files, not just recreate if missing.
# 2016-10-26 Improvements on portability (1.72)
# 2016-10-26 Date formatting for busybox (1.73)
# 2016-10-27 bug fix - issue #157 not recognising EC keys on some versions of openssl (1.74)
# 2016-10-31 generate EC account keys and tidy code.
# 2016-10-31 fix warning message if cert doesn't exist (1.75)
# 2016-10-31 remove only specified DNS token #161 (1.76)
# 2016-11-03 Reduce long lines, and remove echo from update (1.77)
# 2016-11-05 added TOKEN_USER_ID (to set ownership of token files )
# 2016-11-05 updated style to work with latest shellcheck (1.78)
# 2016-11-07 style updates
# 2016-11-07 bug fix DOMAIN_PEM_LOCATION starting with ./ #167
# 2016-11-08 Fix for openssl 1.1.0  #166 (1.79)
# 2016-11-08 Add and comment optional sshuserid for ssh ACL (1.80)
# 2016-11-09 Add SKIP_HTTP_TOKEN_CHECK option (Issue #170) (1.81)
# 2016-11-13 bug fix DOMAIN_KEY_CERT generation (1.82)
# 2016-11-17 add PREVENT_NON_INTERACTIVE_RENEWAL option (1.83)
# 2016-12-03 add HTTP_TOKEN_CHECK_WAIT option (1.84)
# ----------------------------------------------------------------------------------------

PROGNAME=${0##*/}
VERSION="1.84"

# defaults
CODE_LOCATION="https://raw.githubusercontent.com/srvrco/getssl/master/getssl"
CA="https://acme-staging.api.letsencrypt.org"
DEFAULT_REVOKE_CA="https://acme-v01.api.letsencrypt.org"
ACCOUNT_KEY_TYPE="rsa"
ACCOUNT_KEY_LENGTH=4096
WORKING_DIR=~/.getssl
DOMAIN_KEY_LENGTH=4096
SSLCONF="$(openssl version -d 2>/dev/null| cut -d\" -f2)/openssl.cnf"
VALIDATE_VIA_DNS=""
RELOAD_CMD=""
RENEW_ALLOW="30"
REUSE_PRIVATE_KEY="true"
PRIVATE_KEY_ALG="rsa"
SERVER_TYPE="https"
CHECK_REMOTE="true"
USE_SINGLE_ACL="false"
CHECK_ALL_AUTH_DNS="false"
DNS_WAIT=10
DNS_EXTRA_WAIT=""
CHECK_REMOTE_WAIT=0
PUBLIC_DNS_SERVER=""
CHALLENGE_CHECK_TYPE="http"
DEACTIVATE_AUTH="false"
PREVIOUSLY_VALIDATED="true"
DUAL_RSA_ECDSA="false"
SKIP_HTTP_TOKEN_CHECK="false"
HTTP_TOKEN_CHECK_WAIT=0
ORIG_UMASK=$(umask)
_USE_DEBUG=0
_CREATE_CONFIG=0
_CHECK_ALL=0
_FORCE_RENEW=0
_QUIET=0
_MUTE=0
_UPGRADE=0
_UPGRADE_CHECK=1
_RECREATE_CSR=0
_REVOKE=0

# store copy of original command in case of upgrading script and re-running
ORIGCMD="$0 $*"

# Define all functions (in alphabetical order)

cert_archive() {  # Archive certificate file by copying with dates at end.
  debug "creating an achive copy of current new certs"
  date_time=$(date +%Y_%m_%d_%H_%M)
  mkdir -p "${DOMAIN_DIR}/archive/${date_time}"
  umask 077
  cp "$CERT_FILE" "${DOMAIN_DIR}/archive/${date_time}/${DOMAIN}.crt"
  cp "$CERT_FILE" "${DOMAIN_DIR}/archive/${date_time}/${DOMAIN}.csr"
  cp "$DOMAIN_DIR/${DOMAIN}.key" "${DOMAIN_DIR}/archive/${date_time}/${DOMAIN}.key"
  cp "$CA_CERT" "${DOMAIN_DIR}/archive/${date_time}/chain.crt"
  if [[ "$DUAL_RSA_ECDSA" == "true" ]]; then
    cp "$CERT_FILE" "${DOMAIN_DIR}/archive/${date_time}/${DOMAIN}.ec.crt"
    cp "$CERT_FILE" "${DOMAIN_DIR}/archive/${date_time}/${DOMAIN}.ec.csr"
    cp "$DOMAIN_DIR/${DOMAIN}.key" "${DOMAIN_DIR}/archive/${date_time}/${DOMAIN}.ec.key"
    cp "$CA_CERT" "${DOMAIN_DIR}/archive/${date_time}/chain.ec.crt"
  fi
  umask "$ORIG_UMASK"
  debug "purging old GetSSL archives"
  purge_archive "$DOMAIN_DIR"
}

check_challenge_completion() { # checks with the ACME server if our challenge is OK
  uri=$1
  domain=$2
  keyauthorization=$3

  debug "sending request to ACME server saying we're ready for challenge"
  send_signed_request "$uri" "{\"resource\": \"challenge\", \"keyAuthorization\": \"$keyauthorization\"}"

  # check response from our request to perform challenge
  if [[ ! -z "$code" ]] && [[ ! "$code" == '202' ]] ; then
    error_exit "$domain:Challenge error: $code"
  fi

  # loop "forever" to keep checking for a response from the ACME server.
  while true ; do
    debug "checking"
    if ! get_cr "$uri" ; then
      error_exit "$domain:Verify error:$code"
    fi

    status=$(json_get "$response" status)

    # If ACME response is valid, then break out of loop
    if [[ "$status" == "valid" ]] ; then
      info "Verified $domain"
      break;
    fi

    # if ACME response is that their check gave an invalid response, error exit
    if [[ "$status" == "invalid" ]] ; then
      err_detail=$(json_get "$response" detail)
      error_exit "$domain:Verify error:$err_detail"
    fi

    # if ACME response is pending ( they haven't completed checks yet) then wait and try again.
    if [[ "$status" == "pending" ]] ; then
      info "Pending"
    else
      error_exit "$domain:Verify error:$response"
    fi
    debug "sleep 5 secs before testing verify again"
    sleep 5
  done

  if [[ "$DEACTIVATE_AUTH" == "true" ]]; then
    deactivate_url=$(echo "$responseHeaders" | grep "^Link" | awk -F"[<>]" '{print $2}')
    deactivate_url_list="$deactivate_url_list $deactivate_url"
    debug "adding url to deactivate list - $deactivate_url"
  fi
}

check_getssl_upgrade() { # check if a more recent version of code is available available
  temp_upgrade="$(mktemp)"
  curl --silent "$CODE_LOCATION" --output "$temp_upgrade"
  errcode=$?
  if [[ $errcode -eq 60 ]]; then
    error_exit "curl needs updating, your version does not support SNI (multiple SSL domains on a single IP)"
  elif [[ $errcode -gt 0 ]]; then
    error_exit "curl error : $errcode"
  fi
  latestversion=$(awk -F '"' '$1 == "VERSION=" {print $2}' "$temp_upgrade")
  latestvdec=$(echo "$latestversion"| tr -d '.')
  localvdec=$(echo "$VERSION"| tr -d '.' )
  debug "current code is version ${VERSION}"
  debug "Most recent version is  ${latestversion}"
  # use a default of 0 for cases where the latest code has not been obtained.
  if [[ "${latestvdec:-0}" -gt "$localvdec" ]]; then
    if [[ ${_UPGRADE} -eq 1 ]]; then
      install "$0" "${0}.v${VERSION}"
      install -m 700 "$temp_upgrade" "$0"
      if [[ ${_MUTE} -eq 0 ]]; then
        echo "Updated getssl from v${VERSION} to v${latestversion}"
        echo "these update notification can be turned off using the -Q option"
        echo ""
        echo "Updates are;"
        awk "/\(${VERSION}\)$/ {s=1} s; /\(${latestversion}\)$/ {s=0}" "$temp_upgrade" | awk '{if(NR>1)print}'
        echo ""
      fi
      eval "$ORIGCMD"
      graceful_exit
    else
      info ""
      info "A more recent version (v${latestversion}) of getssl is available, please update"
      info "the easiest way is to use the -u or --upgrade flag"
      info ""
    fi
  fi
  rm -f "$temp_upgrade"
}

clean_up() { # Perform pre-exit housekeeping
  umask "$ORIG_UMASK"
  if [[ $VALIDATE_VIA_DNS == "true" ]]; then
    # Tidy up DNS entries if things failed part way though.
    shopt -s nullglob
    for dnsfile in $TEMP_DIR/dns_verify/*; do
      # shellcheck source=/dev/null
      . "$dnsfile"
      debug "attempting to clean up DNS entry for $d"
      eval "$DNS_DEL_COMMAND" "$d" "$auth_key"
    done
    shopt -u nullglob
  fi
  if [[ ! -z "$DOMAIN_DIR" ]]; then
    rm -rf "${TEMP_DIR:?}"
  fi
}

copy_file_to_location() { # copies a file, using scp if required.
  cert=$1   # descriptive name, just used for display
  from=$2   # current file location
  to=$3     # location to move file to.
  if [[ ! -z "$to" ]]; then
    info "copying $cert to $to"
    debug "copying from $from to $to"
    if [[ "${to:0:4}" == "ssh:" ]] ; then
      debug "using scp scp -q $from ${to:4}"
      if ! scp -q "$from" "${to:4}" >/dev/null 2>&1 ; then
        error_exit "problem copying file to the server using scp.
        scp $from ${to:4}"
      fi
      debug "userid $TOKEN_USER_ID"
      if [[ ! -z "$TOKEN_USER_ID" ]]; then
        servername=$(echo "$to" | awk -F":" '{print $2}')
        tofile=$(echo "$to" | awk -F":" '{print $3}')
        debug "servername $servername"
        debug "file $tofile"
        # shellcheck disable=SC2029
        ssh "$servername" "chown $TOKEN_USER_ID $tofile"
      fi
    elif [[ "${to:0:4}" == "ftp:" ]] ; then
      if [[ "$cert" != "challenge token" ]] ; then
        error_exit "ftp is not a sercure method for copying certificates or keys"
      fi
      debug "using ftp to copy the file from $from"
      ftpuser=$(echo "$to"| awk -F: '{print $2}')
      ftppass=$(echo "$to"| awk -F: '{print $3}')
      ftphost=$(echo "$to"| awk -F: '{print $4}')
      ftplocn=$(echo "$to"| awk -F: '{print $5}')
      ftpdirn=$(dirname "$ftplocn")
      ftpfile=$(basename "$ftplocn")
      fromdir=$(dirname "$from")
      fromfile=$(basename "$from")
      debug "ftp user=$ftpuser - pass=$ftppass - host=$ftphost dir=$ftpdirn file=$ftpfile"
      debug "from dir=$fromdir  file=$fromfile"
      ftp -n <<- _EOF
			open $ftphost
			user $ftpuser $ftppass
			cd $ftpdirn
			lcd $fromdir
			put $fromfile
			_EOF
    elif [[ "${to:0:5}" == "sftp:" ]] ; then
      debug "using sftp to copy the file from $from"
      ftpuser=$(echo "$to"| awk -F: '{print $2}')
      ftppass=$(echo "$to"| awk -F: '{print $3}')
      ftphost=$(echo "$to"| awk -F: '{print $4}')
      ftplocn=$(echo "$to"| awk -F: '{print $5}')
      ftpdirn=$(dirname "$ftplocn")
      ftpfile=$(basename "$ftplocn")
      fromdir=$(dirname "$from")
      fromfile=$(basename "$from")
      debug "sftp user=$ftpuser - pass=$ftppass - host=$ftphost dir=$ftpdirn file=$ftpfile"
      debug "from dir=$fromdir  file=$fromfile"
      sshpass -p "$ftppass" sftp "$ftpuser@$ftphost" <<- _EOF
			cd $ftpdirn
			lcd $fromdir
			put $fromfile
			_EOF
    else
      if ! mkdir -p "$(dirname "$to")" ; then
        error_exit "cannot create ACL directory $(basename "$to")"
      fi
      if ! cp -p "$from" "$to" ; then
        error_exit "cannot copy $from to $to"
      fi
      if [[ ! -z "$TOKEN_USER_ID" ]]; then
        chown "$TOKEN_USER_ID" "$to"
      fi
    fi
    debug "copied $from to $to"
  fi
}

create_csr() { # create a csr using a given key (if it doesn't already exist)
  csr_file=$1
  csr_key=$2
  # check if domain csr exists - if not then create it
  if [[ -s "$csr_file" ]]; then
    debug "domain csr exists at - $csr_file"
    # check all domains in config are in csr
    alldomains=$(echo "$DOMAIN,$SANS" | sed -e 's/ //g; y/,/\n/' | sort -u)
    domains_in_csr=$(openssl req -text -noout -in "$csr_file" \
        | sed -n -e 's/^ *Subject: .* CN=\([A-Za-z0-9.-]*\).*$/\1/p; /^ *DNS:.../ { s/ *DNS://g; y/,/\n/; p; }' \
        | sort -u)
    for d in $alldomains; do
      if [[ "$(echo "${domains_in_csr}"| grep "^${d}$")" != "${d}" ]]; then
        info "existing csr at $csr_file does not contain ${d} - re-create-csr"\
             ".... $(echo "${domains_in_csr}"| grep "^${d}$")"
        _RECREATE_CSR=1
      fi
    done
    # check all domains in csr are in config
    if [[ "$alldomains" != "$domains_in_csr" ]]; then
      info "existing csr at $csr_file does not have the same domains as the config - re-create-csr"
      _RECREATE_CSR=1
    fi
  fi
  # end of ... check if domain csr exists - if not then create it

  # if CSR does not exist, or flag set to recreate, then create csr
  if [[ ! -s "$csr_file" ]] || [[ "$_RECREATE_CSR" == "1" ]]; then
    info "creating domain csr - $csr_file"
    # create a temporary config file, for portability.
    tmp_conf=$(mktemp)
    cat "$SSLCONF" > "$tmp_conf"
    printf "[SAN]\n%s" "$SANLIST" >> "$tmp_conf"
    openssl req -new -sha256 -key "$csr_key" -subj "/" -reqexts SAN -config "$tmp_conf" > "$csr_file"
    rm -f "$tmp_conf"
  fi
}

create_key() { # create a domain key (if it doesn't already exist)
  key_type=$1 # domain key type
  key_loc=$2  # domain key location
  key_len=$3  # domain key length - for rsa keys.
  # check if domain key exists, if not then create it.
  if [[ -s "$key_loc" ]]; then
    debug "domain key exists at $key_loc - skipping generation"
    # ideally need to check validity of domain key
  else
    umask 077
    info "creating domain key - $key_loc"
    case "$key_type" in
      rsa)
        openssl genrsa "$key_len" > "$key_loc";;
      prime256v1|secp384r1|secp521r1)
        openssl ecparam -genkey -name "$key_type" > "$key_loc";;
      *)
        error_exit "unknown private key algorithm type $key_loc";;
    esac
    umask "$ORIG_UMASK"
    # remove csr on generation of new domain key
    rm -f "${key_loc::-4}.csr"
  fi
}

date_epoc() { # convert the date into epoch time
  if [[ "$os" == "bsd" ]]; then
    date -j -f "%b %d %T %Y %Z" "$1" +%s
  elif [[ "$os" == "mac" ]]; then
    date -j -f "%b %d %T %Y %Z" "$1" +%s
  elif [[ "$os" == "busybox" ]]; then
    de_ld=$(echo "$1" | awk '{print $1 $2 $3 $4}')
    date -D "%b %d %T %Y" -d "$de_ld" +%s
  else
    date -d "$1" +%s
  fi

}

date_fmt() { # format date from epoc time to YYYY-MM-DD
  if [[ "$os" == "bsd" ]]; then #uses older style date function.
    date -j -f "%s" "$1" +%F
  elif [[ "$os" == "mac" ]]; then # MAC OSX uses older BSD style date.
    date -j -f "%s" "$1" +%F
  else
    date -d "@$1" +%F
  fi
}

date_renew() { # calculates the renewal time in epoch
  date_now_s=$( date +%s )
  echo "$((date_now_s + RENEW_ALLOW*24*60*60))"
}

debug() { # write out debug info if the debug flag has been set
  if [[ ${_USE_DEBUG} -eq 1 ]]; then
    echo " "
    echo "$@"
  fi
}

error_exit() { # give error message on error exit
  echo -e "${PROGNAME}: ${1:-"Unknown Error"}" >&2
  clean_up
  exit 1
}

get_auth_dns() { # get the authoritative dns server for a domain (sets primary_ns )
  gad_d="$1" # domain name
  gad_s="$PUBLIC_DNS_SERVER" # start with PUBLIC_DNS_SERVER

  if [[ "$os" == "cygwin" ]]; then
    all_auth_dns_servers=$(nslookup -type=soa "${d}" ${PUBLIC_DNS_SERVER} 2>/dev/null \
                          | grep "primary name server" \
                          | awk '{print $NF}')
    if [[ -z "$all_auth_dns_servers" ]]; then
      error_exit "couldn't find primary DNS server - please set AUTH_DNS_SERVER in config"
    fi
    primary_ns="$all_auth_dns_servers"
    return
  fi

  res=$(nslookup -debug=1 -type=soa -type=ns "$1" ${gad_s})

  if [[ "$(echo "$res" | grep -c "Non-authoritative")" -gt 0 ]]; then
    # this is a Non-authoritative server, need to check for an authoritative one.
    gad_s=$(echo "$res" | awk '$2 ~ "nameserver" {print $4; exit }' |sed 's/\.$//g')
    if [[ "$(echo "$res" | grep -c "an't find")" -gt 0 ]]; then
      # if domain name doesn't exist, then find auth servers for next level up
      gad_s=$(echo "$res" | awk '$1 ~ "origin" {print $3; exit }')
      gad_d=$(echo "$res" | awk '$1 ~ "->" {print $2; exit}')
    fi
  fi

  if [[ -z "$gad_s" ]]; then
    res=$(nslookup -debug=1 -type=soa -type=ns "$gad_d")
  else
    res=$(nslookup -debug=1 -type=soa -type=ns "$gad_d" "${gad_s}")
  fi

  if [[ "$(echo "$res" | grep -c "canonical name")" -gt 0 ]]; then
    gad_d=$(echo "$res" | awk ' $2 ~ "canonical" {print $5; exit }' |sed 's/\.$//g')
  elif [[ "$(echo "$res" | grep -c "an't find")" -gt 0 ]]; then
    gad_s=$(echo "$res" | awk ' $1 ~ "origin" {print $3; exit }')
    gad_d=$(echo "$res"| awk '$1 ~ "->" {print $2; exit}')
  fi

  all_auth_dns_servers=$(nslookup -type=soa -type=ns "$gad_d" "$gad_s" \
                        | awk ' $2 ~ "nameserver" {print $4}' \
                        | sed 's/\.$//g'| tr '\n' ' ')
  if [[ $CHECK_ALL_AUTH_DNS == "true" ]]; then
    primary_ns="$all_auth_dns_servers"
  else
    primary_ns=$(echo "$all_auth_dns_servers" | awk '{print $1}')
  fi
}

get_certificate() { # get certificate for csr, if all domains validated.
  gc_csr=$1         # the csr file
  gc_certfile=$2    # The filename for the certificate
  gc_cafile=$3      # The filename for the CA certificate

  der=$(openssl req -in "$gc_csr" -outform DER | urlbase64)
  debug "der $der"
  send_signed_request "$CA/acme/new-cert" "{\"resource\": \"new-cert\", \"csr\": \"$der\"}" "needbase64"

  # convert certificate information into correct format and save to file.
  CertData=$(awk ' $1 ~ "^Location" {print $2}' "$CURL_HEADER" |tr -d '\r')
  debug "certdata location = $CertData"
  if [[ "$CertData" ]] ; then
    echo -----BEGIN CERTIFICATE----- > "$gc_certfile"
    curl --silent "$CertData" | openssl base64 -e  >> "$gc_certfile"
    echo -----END CERTIFICATE-----  >> "$gc_certfile"
    info "Certificate saved in $CERT_FILE"
  fi

  # If certificate wasn't a valid certificate, error exit.
  if [[ -z "$CertData" ]] ; then
    response2=$(echo "$response" | fold -w64 |openssl base64 -d)
    debug "response was $response"
    error_exit "Sign failed: $(echo "$response2" | grep "detail")"
  fi

  # get a copy of the CA certificate.
  IssuerData=$(grep -i '^Link' "$CURL_HEADER" \
               | cut -d " " -f 2\
               | cut -d ';' -f 1 \
               | sed 's/<//g' \
               | sed 's/>//g')
  if [[ "$IssuerData" ]] ; then
    echo -----BEGIN CERTIFICATE----- > "$gc_cafile"
    curl --silent "$IssuerData" | openssl base64 -e  >> "$gc_cafile"
    echo -----END CERTIFICATE-----  >> "$gc_cafile"
    info "The intermediate CA cert is in $gc_cafile"
  fi
}

get_cr() { # get curl response
  url="$1"
  debug url "$url"
  response=$(curl --silent "$url")
  ret=$?
  debug response  "$response"
  code=$(json_get "$response" status)
  debug code "$code"
  debug "get_cr return code $ret"
  return $ret
}

get_os() { # function to get the current Operating System
  uname_res=$(uname -s)
  if [[ $(date -h 2>&1 | grep -ic busybox) -gt 0 ]]; then
    os="busybox"
  elif [[ ${uname_res} == "Linux" ]]; then
    os="linux"
  elif [[ ${uname_res} == "FreeBSD" ]]; then
    os="bsd"
  elif [[ ${uname_res} == "Darwin" ]]; then
    os="mac"
  elif [[ ${uname_res:0:6} == "CYGWIN" ]]; then
    os="cygwin"
  else
    os="unknown"
  fi
  debug "detected os type = $os"
}

get_signing_params() { # get signing parameters from key
  skey=$1
  if [[ "$(grep -c "RSA PRIVATE KEY" "$skey")" -gt 0 ]]; then # RSA key
    pub_exp64=$(openssl rsa -in "${skey}" -noout -text \
                | grep publicExponent \
                | grep -oE "0x[a-f0-9]+" \
                | cut -d'x' -f2 \
                | hex2bin \
                | urlbase64)
    pub_mod64=$(openssl rsa -in "${skey}" -noout -modulus \
                | cut -d'=' -f2 \
                | hex2bin \
                | urlbase64)

    jwk='{"e":"'"${pub_exp64}"'","kty":"RSA","n":"'"${pub_mod64}"'"}'
    jwkalg="RS256"
    signalg="sha256"
  elif [[ "$(grep -c "EC PRIVATE KEY" "$skey")" -gt 0 ]]; then # Elliptic curve key.
    crv="$(openssl ec -in  "$skey" -noout -text 2>/dev/null | awk '$2 ~ "CURVE:" {print $3}')"
    if [[ -z "$crv" ]]; then
      gsp_keytype="$(openssl ec -in  "$skey" -noout -text 2>/dev/null \
                     | grep "^ASN1 OID:" \
                     | awk '{print $3}')"
      case "$gsp_keytype" in
        prime256v1) crv="P-256" ;;
        secp384r1) crv="P-384" ;;
        secp521r1) crv="P-521" ;;
        *) error_exit "invalid curve algorithm type $gsp_keytype";;
      esac
    fi
    case "$crv" in
      P-256) jwkalg="ES256" ; signalg="sha256" ;;
      P-384) jwkalg="ES384" ; signalg="sha384" ;;
      P-521) jwkalg="ES512" ; signalg="sha512" ;;
      *) error_exit "invalid curve algorithm type $crv";;
    esac
    pubtext="$(openssl ec  -in "$skey"  -noout -text 2>/dev/null \
               | awk '/^pub:/{p=1;next}/^ASN1 OID:/{p=0}p' \
               | tr -d ": \n\r")"
    mid=$(( (${#pubtext} -2) / 2 + 2 ))
    debug "pubtext = $pubtext"
    x64=$(echo "$pubtext" | cut -b 3-$mid | hex2bin | urlbase64)
    y64=$(echo "$pubtext" | cut -b $((mid+1))-${#pubtext} | hex2bin | urlbase64)
    jwk='{"crv":"'"$crv"'","kty":"EC","x":"'"$x64"'","y":"'"$y64"'"}'
    debug "jwk $jwk"
  else
    error_exit "Invlid key file"
  fi
  thumbprint="$(printf "%s" "$jwk" | openssl dgst -sha256 -binary | urlbase64)"
  debug "jwk alg = $jwkalg"
  debug "jwk = $jwk"
  debug "thumbprint $thumbprint"
}

graceful_exit() { # normal exit function.
  clean_up
  exit
}

help_message() { # print out the help message
  cat <<- _EOF_
	$PROGNAME ver. $VERSION
	Obtain SSL certificates from the letsencrypt.org ACME server

	$(usage)

	Options:
	  -a, --all       Check all certificates
	  -d, --debug     Outputs debug information
	  -c, --create    Create default config files
	  -f, --force     Force renewal of cert (overrides expiry checks)
	  -h, --help      Display this help message and exit
	  -q, --quiet     Quiet mode (only outputs on error, success of new cert, or getssl was upgraded)
	  -Q, --mute      Like -q, but mutes notification about successful upgrade
	  -r, --revoke cert key  [CA_server] Revoke a certificate (the cert and key are required)
	  -u, --upgrade   Upgrade getssl if a more recent version is available
	  -U, --nocheck   Do not check if a more recent version is available
	  -w working_dir  Working directory

	_EOF_
}

hex2bin() { # Remove spaces, add leading zero, escape as hex string and parse with printf
#  printf -- "$(cat | os_esed -e 's/[[:space:]]//g' -e 's/^(.(.{2})*)$/0\1/' -e 's/(.{2})/\\x\1/g')"
  echo -e -n "$(cat | os_esed -e 's/[[:space:]]//g' -e 's/^(.(.{2})*)$/0\1/' -e 's/(.{2})/\\x\1/g')"
}

info() { # write out info as long as the quiet flag has not been set.
  if [[ ${_QUIET} -eq 0 ]]; then
    echo "$@"
  fi
}

json_get() { # get the value corresponding to $2 in the JSON passed as $1.
  # remove newlines, so it's a single chunk of JSON
  json_data=$( echo "$1" | tr '\n' ' ')
  # if $3 is defined, this is the section which the item is in.
  if [[ ! -z "$3" ]]; then
    jg_section=$(echo "$json_data" | awk -F"[}]" '{for(i=1;i<=NF;i++){if($i~/\"'"${3}"'\"/){print $i}}}')
    if [[ "$2" == "uri" ]]; then
      jg_subsect=$(echo "$jg_section" | awk -F"[,]" '{for(i=1;i<=NF;i++){if($i~/\"'"${2}"'\"/){print $(i)}}}')
      jg_result=$(echo "$jg_subsect" | awk -F'"' '{print $4}')
    else
      jg_result=$(echo "$jg_section" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\"'"${2}"'\"/){print $(i+1)}}}')
    fi
  else
    jg_result=$(echo "$json_data" |awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\"'"${2}"'\"/){print $(i+1)}}}')
  fi
  # check number of quotes
  jg_q=${jg_result//[^\"]/}
  # if 2 quotes, assume it's a quoted variable and just return the data within the quotes.
  if [[ ${#jg_q} -eq 2 ]]; then
    echo "$jg_result" | awk -F'"' '{print $2}'
  else
    echo "$jg_result"
  fi
}

os_esed() { # Use different sed version for different os types (extended regex)
  if [[ "$os" == "bsd" ]]; then # BSD requires -E flag for extended regex
    sed -E "${@}"
  elif [[ "$os" == "mac" ]]; then # MAC uses older BSD style sed.
    sed -E "${@}"
  else
    sed -r "${@}"
  fi
}

purge_archive() { # purge archive of old, invalid, certificates
  arcdir="$1/archive"
  debug "purging archives in ${arcdir}/"
  for padir in $arcdir/????_??_??_??_??; do
    # check each directory
    if [[ -d "$padir" ]]; then
      tstamp=$(basename "$padir"| awk -F"_" '{print $1"-"$2"-"$3" "$4":"$5}')
      if [[ "$os" == "bsd" ]]; then
        direpoc=$(date -j -f "%F %H:%M" "$tstamp" +%s)
      elif [[ "$os" == "mac" ]]; then
        direpoc=$(date -j -f "%F %H:%M" "$tstamp" +%s)
      else
        direpoc=$(date -d "$tstamp" +%s)
      fi
      current_epoc=$(date "+%s")
      # as certs currently valid for 90 days, purge anything older than 100
      purgedate=$((current_epoc - 60*60*24*100))
      if [[ "$direpoc" -lt "$purgedate" ]]; then
        echo "purge $padir"
        rm -rf "${padir:?}"
      fi
    fi
  done
}

reload_service() {  # Runs a command to reload services ( via ssh if needed)
  if [[ ! -z "$RELOAD_CMD" ]]; then
    info "reloading SSL services"
    if [[ "${RELOAD_CMD:0:4}" == "ssh:" ]] ; then
      sshhost=$(echo "$RELOAD_CMD"| awk -F: '{print $2}')
      command=${RELOAD_CMD:(( ${#sshhost} + 5))}
      debug "running following command to reload cert"
      debug "ssh $sshhost ${command}"
      # shellcheck disable=SC2029
      ssh "$sshhost" "${command}" 1>/dev/null 2>&1
      # allow 2 seconds for services to restart
      sleep 2
    else
      debug "running reload command $RELOAD_CMD"
      if ! eval "$RELOAD_CMD" ; then
        error_exit "error running $RELOAD_CMD"
      fi
    fi
  fi
}

revoke_certificate() { #revoke a certificate
  debug "revoking cert $REVOKE_CERT"
  debug "using key $REVOKE_KEY"
  ACCOUNT_KEY="$REVOKE_KEY"
  # need to set the revoke key as "account_key" since it's used in send_signed_request.
  get_signing_params "$REVOKE_KEY"
  TEMP_DIR=$(mktemp -d)
  debug "revoking from $CA"
  rcertdata=$(openssl x509 -in "$REVOKE_CERT" -inform PEM -outform DER | urlbase64)
  send_signed_request "$CA/acme/revoke-cert" "{\"resource\": \"revoke-cert\", \"certificate\": \"$rcertdata\"}"
  if [[ $code -eq "200" ]]; then
    info "certificate revoked"
  else
    error_exit "Revocation failed: $(echo "$response" | grep "detail")"
  fi
}

requires() { # check if required function is available
  result=$(which "$1" 2>/dev/null)
  debug "checking for required $1 ... $result"
  if [[ -z "$result" ]]; then
    error_exit "This script requires $1 installed"
  fi
}

send_signed_request() { # Sends a request to the ACME server, signed with your private key.
  url=$1
  payload=$2
  needbase64=$3

  debug url "$url"
  debug payload "$payload"

  CURL_HEADER="$TEMP_DIR/curl.header"
  dp="$TEMP_DIR/curl.dump"
  CURL="curl --silent --dump-header $CURL_HEADER "
  if [[ ${_USE_DEBUG} -eq 1 ]]; then
    CURL="$CURL --trace-ascii $dp "
  fi

  # convert payload to url base 64
  payload64="$(printf '%s' "${payload}" | urlbase64)"
  debug payload64 "$payload64"

  # get nonce from ACME server
  nonceurl="$CA/directory"
  nonce=$($CURL -I $nonceurl | grep "^Replay-Nonce:" | awk '{print $2}' | tr -d '\r\n ')

  debug nonce "$nonce"

  # Build header with just our public key and algorithm information
  header='{"alg": "'"$jwkalg"'", "jwk": '"$jwk"'}'

  # Build another header which also contains the previously received nonce and encode it as urlbase64
  protected='{"alg": "'"$jwkalg"'", "jwk": '"$jwk"', "nonce": "'"${nonce}"'", "url": "'"${url}"'"}'
  protected64="$(printf '%s' "${protected}" | urlbase64)"
  debug protected "$protected"

  # Sign header with nonce and our payload with our private key and encode signature as urlbase64
  sign_string "$(printf '%s' "${protected64}.${payload64}")"  "${ACCOUNT_KEY}" "$signalg"

  # Send header + extended header + payload + signature to the acme-server
  body="{\"header\": ${header},"
  body+="\"protected\": \"${protected64}\","
  body+="\"payload\": \"${payload64}\","
  body+="\"signature\": \"${signed64}\"}"
  debug "header, payload and signature = $body"

  code="500"
  loop_limit=5
  while [[ "$code" -eq 500 ]]; do
    if [[ "$needbase64" ]] ; then
      response=$($CURL -X POST --data "$body" "$url" | urlbase64)
    else
      response=$($CURL -X POST --data "$body" "$url")
    fi

    responseHeaders=$(cat "$CURL_HEADER")
    debug responseHeaders "$responseHeaders"
    debug response  "$response"
    code=$(awk ' $1 ~ "^HTTP" {print $2}' "$CURL_HEADER" | tail -1)
    debug code "$code"
    response_status=$(json_get "$response" status \
                      | head -1| awk -F'"' '{print $2}')
    debug "response status = $response_status"

    if [[ "$code" -eq 500 ]]; then
      info "error on acme server - trying again ...."
      sleep 2
      loop_limit=$((loop_limit - 1))
      if [[ $loop_limit -lt 1 ]]; then
        error_exit "500 error from ACME server:  $response"
      fi
    fi
  done
}

sign_string() { #sign a string with a given key and algorithm and return urlbase64
                # sets the result in variable signed64
  str=$1
  key=$2
  signalg=$3

  if [[ "$(grep -c "RSA PRIVATE KEY" "$key")" -gt 0 ]]; then # RSA key
    signed64="$(printf '%s' "${str}" | openssl dgst -"$signalg" -sign "$key" | urlbase64)"
  elif [[ "$(grep -c "EC PRIVATE KEY" "$key")" -gt 0 ]]; then # Elliptic curve key.
    signed=$(printf '%s' "${str}" | openssl dgst -"$signalg" -sign "$key" -hex | awk '{print $2}')
    debug "EC signature $signed"
    if [[ "${signed:4:4}" == "0220" ]]; then #sha256
      R=$(echo "$signed" | cut -c 9-72)
      part2=$(echo "$signed" | cut -c 73-)
    elif [[ "${signed:4:4}" == "0221" ]]; then #sha256
      R=$(echo "$signed" | cut -c 11-74)
      part2=$(echo "$signed" | cut -c 75-)
    elif [[ "${signed:4:4}" == "0230" ]]; then #sha384
      R=$(echo "$signed" | cut -c 9-104)
      part2=$(echo "$signed" | cut -c 105-)
    elif [[ "${signed:4:4}" == "0231" ]]; then #sha384
      R=$(echo "$signed" | cut -c 11-106)
      part2=$(echo "$signed" | cut -c 107-)
    elif [[ "${signed:6:4}" == "0241" ]]; then #sha512
      R=$(echo "$signed" | cut -c 11-140)
      part2=$(echo "$signed" | cut -c 141-)
    elif [[ "${signed:6:4}" == "0242" ]]; then #sha512
      R=$(echo "$signed" | cut -c 11-142)
      part2=$(echo "$signed" | cut -c 143-)
    else
      error_exit "error in EC signing couldn't get R from $signed"
    fi
    debug "R $R"

    if [[ "${part2:0:4}" == "0220" ]]; then #sha256
      S=$(echo "$part2" | cut -c 5-68)
    elif [[ "${part2:0:4}" == "0221" ]]; then #sha256
      S=$(echo "$part2" | cut -c 7-70)
    elif [[ "${part2:0:4}" == "0230" ]]; then #sha384
      S=$(echo "$part2" | cut -c 5-100)
    elif [[ "${part2:0:4}" == "0231" ]]; then #sha384
      S=$(echo "$part2" | cut -c 7-102)
    elif [[ "${part2:0:4}" == "0241" ]]; then #sha512
      S=$(echo "$part2" | cut -c 5-136)
    elif [[ "${part2:0:4}" == "0242" ]]; then #sha512
      S=$(echo "$part2" | cut -c 5-136)
    else
      error_exit "error in EC signing couldn't get S from $signed"
    fi

    debug "S $S"
    signed64=$(printf '%s' "${R}${S}" | hex2bin | urlbase64 )
    debug "encoded RS $signed64"
  fi
}

signal_exit() { # Handle trapped signals
  case $1 in
    INT)
      error_exit "Program interrupted by user" ;;
    TERM)
      echo -e "\n$PROGNAME: Program terminated" >&2
      graceful_exit ;;
    *)
      error_exit "$PROGNAME: Terminating on unknown signal" ;;
  esac
}

urlbase64() { # urlbase64: base64 encoded string with '+' replaced with '-' and '/' replaced with '_'
  openssl base64 -e | tr -d '\n\r' | os_esed -e 's:=*$::g' -e 'y:+/:-_:'
}

usage() { # program usage
  echo "Usage: $PROGNAME [-h|--help] [-d|--debug] [-c|--create] [-f|--force] [-a|--all] [-q|--quiet]"\
       "[-Q|--mute] [-u|--upgrade] [-U|--nocheck] [-r|--revoke cert key] [-w working_dir] domain"
}

write_domain_template() { # write out a template file for a domain.
  cat > "$1" <<- _EOF_domain_
	# Uncomment and modify any variables you need
	# see https://github.com/srvrco/getssl/wiki/Config-variables for details
	#
	# The staging server is best for testing
	#CA="https://acme-staging.api.letsencrypt.org"
	# This server issues full certificates, however has rate limits
	#CA="https://acme-v01.api.letsencrypt.org"

	#AGREEMENT="$AGREEMENT"

	# Set an email address associated with your account - generally set at account level rather than domain.
	#ACCOUNT_EMAIL="me@example.com"
	#ACCOUNT_KEY_LENGTH=4096
	#ACCOUNT_KEY="$WORKING_DIR/account.key"
	#PRIVATE_KEY_ALG="rsa"

	# Additional domains - this could be multiple domains / subdomains in a comma separated list
	# Note: this is Additional domains - so should not include the primary domain.
	SANS=${EX_SANS}

	# Acme Challenge Location. The first line for the domain, the following ones for each additional domain.
	# If these start with ssh: then the next variable is assumed to be the hostname and the rest the location.
	# An ssh key will be needed to provide you with access to the remote server.
	# Optionally, you can specify a different userid for ssh/scp to use on the remote server before the @ sign.
	# If left blank, the username on the local server will be used to authenticate against the remote server.
	# If these start with ftp: then the next variables are ftpuserid:ftppassword:servername:ACL_location
	# These should be of the form "/path/to/your/website/folder/.well-known/acme-challenge"
	# where "/path/to/your/website/folder/" is the path, on your web server, to the web root for your domain.
	#ACL=('/var/www/${DOMAIN}/web/.well-known/acme-challenge'
	#     'ssh:server5:/var/www/${DOMAIN}/web/.well-known/acme-challenge'
	#     'ssh:sshuserid@server5:/var/www/${DOMAIN}/web/.well-known/acme-challenge'
	#     'ftp:ftpuserid:ftppassword:${DOMAIN}:/web/.well-known/acme-challenge')

	#Enable use of a single ACL for all checks
	#USE_SINGLE_ACL="true"

	# Location for all your certs, these can either be on the server (full path name)
	# or using ssh /sftp as for the ACL
	#DOMAIN_CERT_LOCATION="ssh:server5:/etc/ssl/domain.crt"
	#DOMAIN_KEY_LOCATION="ssh:server5:/etc/ssl/domain.key"
	#CA_CERT_LOCATION="/etc/ssl/chain.crt"
	#DOMAIN_CHAIN_LOCATION="" # this is the domain cert and CA cert
	#DOMAIN_KEY_CERT_LOCATION="" # this is the domain_key and domain cert
	#DOMAIN_PEM_LOCATION="" # this is the domain_key. domain cert and CA cert

	# The command needed to reload apache / nginx or whatever you use
	#RELOAD_CMD=""
	# The time period within which you want to allow renewal of a certificate
	#  this prevents hitting some of the rate limits.
	RENEW_ALLOW="30"

	# Define the server type. This can be https, ftp, ftpi, imap, imaps, pop3, pop3s, smtp,
	# smtps_deprecated, smtps, smtp_submission, xmpp, xmpps, ldaps or a port number which
	# will be checked for certificate expiry and also will be checked after
	# an update to confirm correct certificate is running (if CHECK_REMOTE) is set to true
	#SERVER_TYPE="https"
	#CHECK_REMOTE="true"

	# Use the following 3 variables if you want to validate via DNS
	#VALIDATE_VIA_DNS="true"
	#DNS_ADD_COMMAND=
	#DNS_DEL_COMMAND=
	#AUTH_DNS_SERVER=""
	#DNS_WAIT=10
	#DNS_EXTRA_WAIT=60
	_EOF_domain_
}

write_getssl_template() { # write out the main template file
  cat > "$1" <<- _EOF_getssl_
	# Uncomment and modify any variables you need
	# see https://github.com/srvrco/getssl/wiki/Config-variables for details
	#
	# The staging server is best for testing (hence set as default)
	CA="https://acme-staging.api.letsencrypt.org"
	# This server issues full certificates, however has rate limits
	#CA="https://acme-v01.api.letsencrypt.org"

	#AGREEMENT="$AGREEMENT"

	# Set an email address associated with your account - generally set at account level rather than domain.
	#ACCOUNT_EMAIL="me@example.com"
	ACCOUNT_KEY_LENGTH=4096
	ACCOUNT_KEY="$WORKING_DIR/account.key"
	PRIVATE_KEY_ALG="rsa"
	#REUSE_PRIVATE_KEY="true"

	# The command needed to reload apache / nginx or whatever you use
	#RELOAD_CMD=""
	# The time period within which you want to allow renewal of a certificate
	#  this prevents hitting some of the rate limits.
	RENEW_ALLOW="30"

	# Define the server type. This can be https, ftp, ftpi, imap, imaps, pop3, pop3s, smtp,
	# smtps_deprecated, smtps, smtp_submission, xmpp, xmpps, ldaps or a port number which
	# will be checked for certificate expiry and also will be checked after
	# an update to confirm correct certificate is running (if CHECK_REMOTE) is set to true
	SERVER_TYPE="https"
	CHECK_REMOTE="true"

	# openssl config file.  The default should work in most cases.
	SSLCONF="$SSLCONF"

	# Use the following 3 variables if you want to validate via DNS
	#VALIDATE_VIA_DNS="true"
	#DNS_ADD_COMMAND=
	#DNS_DEL_COMMAND=
	#AUTH_DNS_SERVER=""
	#DNS_WAIT=10
	#DNS_EXTRA_WAIT=60
	_EOF_getssl_
}

write_openssl_conf() { # write out a minimal openssl conf
  cat > "$1" <<- _EOF_openssl_conf_
	# minimal openssl.cnf file
	distinguished_name  = req_distinguished_name
	[ req_distinguished_name ]
	[v3_req]
	[v3_ca]
	_EOF_openssl_conf_
}

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Parse command-line
while [[ -n $1 ]]; do
  case $1 in
    -h | --help)
      help_message; graceful_exit ;;
    -d | --debug)
     _USE_DEBUG=1 ;;
    -c | --create)
     _CREATE_CONFIG=1 ;;
    -f | --force)
     _FORCE_RENEW=1 ;;
    -a | --all)
     _CHECK_ALL=1 ;;
    -q | --quiet)
     _QUIET=1 ;;
    -Q | --mute)
     _QUIET=1
     _MUTE=1 ;;
    -r | --revoke)
     _REVOKE=1
     shift
     REVOKE_CERT="$1"
     shift
     REVOKE_KEY="$1"
     shift
     REVOKE_CA="$1" ;;
    -u | --upgrade)
     _UPGRADE=1 ;;
    -U | --nocheck)
      _UPGRADE_CHECK=0 ;;
    -w)
      shift; WORKING_DIR="$1" ;;
    -* | --*)
      usage
      error_exit "Unknown option $1" ;;
    *)
      DOMAIN="$1" ;;
  esac
  shift
done

# Main logic
############

# Get the current OS, so the correct functions can be used for that OS. (sets the variable os)
get_os

#check if required applications are included

requires which
requires openssl
requires curl
requires nslookup
requires awk
requires tr
requires date
requires grep
requires sed
requires sort

# Check if upgrades are available (unless they have specified -U to ignore Upgrade checks)
if [[ $_UPGRADE_CHECK -eq 1 ]]; then
  check_getssl_upgrade
fi

# Revoke a certificate
if [[ $_REVOKE -eq 1 ]]; then
  if [[ -z $REVOKE_CA ]]; then
    CA=$DEFAULT_REVOKE_CA
  elif [[ "$REVOKE_CA" == "-d" ]]; then
    _USE_DEBUG=1
    CA=$DEFAULT_REVOKE_CA
  else
    CA=$REVOKE_CA
  fi
  revoke_certificate
  graceful_exit
fi

# get latest agreement from CA (as default)
AGREEMENT=$(curl -I "${CA}/terms" 2>/dev/null | awk '$1 ~ "Location:" {print $2}'|tr -d '\r')

# if nothing in command line, print help and exit.
if [[ -z "$DOMAIN" ]] && [[ ${_CHECK_ALL} -ne 1 ]]; then
  help_message
  graceful_exit
fi

# if the "working directory" doesn't exist, then create it.
if [[ ! -d "$WORKING_DIR" ]]; then
  debug "Making working directory - $WORKING_DIR"
  mkdir -p "$WORKING_DIR"
fi

# read any variables from config in working directory
if [[ -s "$WORKING_DIR/getssl.cfg" ]]; then
  debug "reading config from $WORKING_DIR/getssl.cfg"
  # shellcheck source=/dev/null
  . "$WORKING_DIR/getssl.cfg"
fi

# Define defaults for variables unset in the main config.
ACCOUNT_KEY="${ACCOUNT_KEY:=$WORKING_DIR/account.key}"
DOMAIN_STORAGE="${DOMAIN_STORAGE:=$WORKING_DIR}"
DOMAIN_DIR="$DOMAIN_STORAGE/$DOMAIN"
CERT_FILE="$DOMAIN_DIR/${DOMAIN}.crt"
CA_CERT="$DOMAIN_DIR/chain.crt"
TEMP_DIR="$DOMAIN_DIR/tmp"

# Set the OPENSSL_CONF environment variable so openssl knows which config to use
export OPENSSL_CONF=$SSLCONF

# if "-a" option then check other parameters and create run for each domain.
if [[ ${_CHECK_ALL} -eq 1 ]]; then
  info "Check all certificates"

  if [[ ${_CREATE_CONFIG} -eq 1 ]]; then
    error_exit "cannot combine -c|--create with -a|--all"
  fi

  if [[ ${_FORCE_RENEW} -eq 1 ]]; then
    error_exit "cannot combine -f|--force with -a|--all because of rate limits"
  fi

  if [[ ! -d "$DOMAIN_STORAGE" ]]; then
    error_exit "DOMAIN_STORAGE not found  - $DOMAIN_STORAGE"
  fi

  for dir in ${DOMAIN_STORAGE}/*; do
    if [[ -d "$dir" ]]; then
      debug "Checking $dir"
      cmd="$0 -U" # No update checks when calling recursively
      if [[ ${_USE_DEBUG} -eq 1 ]]; then
        cmd="$cmd -d"
      fi
      if [[ ${_QUIET} -eq 1 ]]; then
        cmd="$cmd -q"
      fi
      # check if $dir looks like a domain name (contains a period)
      if [[ $(basename "$dir") == *.* ]]; then
        cmd="$cmd -w $WORKING_DIR $(basename "$dir")"
        debug "CMD: $cmd"
        eval "$cmd"
      fi
    fi
  done

  graceful_exit
fi
# end of "-a" option (looping through all domains)

# if "-c|--create" option used, then create config files.
if [[ ${_CREATE_CONFIG} -eq 1 ]]; then
  # If main config file does not exists then create it.
  if [[ ! -s "$WORKING_DIR/getssl.cfg" ]]; then
    info "creating main config file $WORKING_DIR/getssl.cfg"
    if [[ ! -s "$SSLCONF" ]]; then
      SSLCONF="$WORKING_DIR/openssl.cnf"
      write_openssl_conf "$SSLCONF"
    fi
    write_getssl_template "$WORKING_DIR/getssl.cfg"
  fi
  # If domain and domain config don't exist then create them.
  if [[ ! -d "$DOMAIN_DIR" ]]; then
    info "Making domain directory - $DOMAIN_DIR"
    mkdir -p "$DOMAIN_DIR"
  fi
  if [[ -s "$DOMAIN_DIR/getssl.cfg" ]]; then
    info "domain config already exists $DOMAIN_DIR/getssl.cfg"
  else
    info "creating domain config file in $DOMAIN_DIR/getssl.cfg"
    # if domain has an existing cert, copy from domain and use to create defaults.
    EX_CERT=$(echo \
      | openssl s_client -servername "${DOMAIN}" -connect "${DOMAIN}:443" 2>/dev/null \
      | openssl x509 2>/dev/null)
    EX_SANS="www.${DOMAIN}"
    if [[ ! -z "${EX_CERT}" ]]; then
      EX_SANS=$(echo "$EX_CERT" \
        | openssl x509 -noout -text 2>/dev/null| grep "Subject Alternative Name" -A2 \
        | grep -Eo "DNS:[a-zA-Z 0-9.-]*" | sed "s@DNS:$DOMAIN@@g" | grep -v '^$' | cut -c 5-)
      EX_SANS=${EX_SANS//$'\n'/','}
    fi
    write_domain_template "$DOMAIN_DIR/getssl.cfg"
  fi
  TEMP_DIR="$DOMAIN_DIR/tmp"
  # end of "-c|--create" option, so exit
  graceful_exit
fi
# end of "-c|--create" option to create config file.

# if domain directory doesn't exist, then create it.
if [[ ! -d "$DOMAIN_DIR" ]]; then
  debug "Making working directory - $DOMAIN_DIR"
  mkdir -p "$DOMAIN_DIR"
fi

# define a temporary directory, and if it doesn't exist, create it.
TEMP_DIR="$DOMAIN_DIR/tmp"
if [[ ! -d "${TEMP_DIR}" ]]; then
  debug "Making temp directory - ${TEMP_DIR}"
  mkdir -p "${TEMP_DIR}"
fi

# read any variables from config in domain directory
if [[ -s "$DOMAIN_DIR/getssl.cfg" ]]; then
  debug "reading config from $DOMAIN_DIR/getssl.cfg"
  # shellcheck source=/dev/null
  . "$DOMAIN_DIR/getssl.cfg"
fi

# from SERVER_TYPE convert names to port numbers and additional data.
if [[ ${SERVER_TYPE} == "https" ]] || [[ ${SERVER_TYPE} == "webserver" ]]; then
  REMOTE_PORT=443
elif [[ ${SERVER_TYPE} == "ftp" ]]; then
  REMOTE_PORT=21
  REMOTE_EXTRA="-starttls ftp"
elif [[ ${SERVER_TYPE} == "ftpi" ]]; then
  REMOTE_PORT=990
elif [[ ${SERVER_TYPE} == "imap" ]]; then
  REMOTE_PORT=143
  REMOTE_EXTRA="-starttls imap"
elif [[ ${SERVER_TYPE} == "imaps" ]]; then
  REMOTE_PORT=993
elif [[ ${SERVER_TYPE} == "pop3" ]]; then
  REMOTE_PORT=110
  REMOTE_EXTRA="-starttls pop3"
elif [[ ${SERVER_TYPE} == "pop3s" ]]; then
  REMOTE_PORT=995
elif [[ ${SERVER_TYPE} == "smtp" ]]; then
  REMOTE_PORT=25
  REMOTE_EXTRA="-starttls smtp"
elif [[ ${SERVER_TYPE} == "smtps_deprecated" ]]; then
  REMOTE_PORT=465
elif [[ ${SERVER_TYPE} == "smtps" ]] || [[ ${SERVER_TYPE} == "smtp_submission" ]]; then
  REMOTE_PORT=587
  REMOTE_EXTRA="-starttls smtp"
elif [[ ${SERVER_TYPE} == "xmpp" ]]; then
  REMOTE_PORT=5222
  REMOTE_EXTRA="-starttls xmpp"
elif [[ ${SERVER_TYPE} == "xmpps" ]]; then
  REMOTE_PORT=5269
elif [[ ${SERVER_TYPE} == "ldaps" ]]; then
  REMOTE_PORT=636
elif [[ ${SERVER_TYPE} =~ ^[0-9]+$ ]]; then
  REMOTE_PORT=${SERVER_TYPE}
else
  error_exit "unknown server type"
fi
# end of converting SERVER_TYPE names to port numbers and additional data.



# if check_remote is true then connect and obtain the current certificate (if not forcing renewal)
if [[ "${CHECK_REMOTE}" == "true" ]] && [[ $_FORCE_RENEW -eq 0 ]]; then
  debug "getting certificate for $DOMAIN from remote server"
  # shellcheck disable=SC2086
  EX_CERT=$(echo \
    | openssl s_client -servername "${DOMAIN}" -connect "${DOMAIN}:${REMOTE_PORT}" ${REMOTE_EXTRA} 2>/dev/null \
    | openssl x509 2>/dev/null)
  if [[ ! -z "$EX_CERT" ]]; then # if obtained a cert
    if [[ -s "$CERT_FILE" ]]; then # if local exists
      CERT_LOCAL=$(openssl x509 -noout -fingerprint < "$CERT_FILE" 2>/dev/null)
    else # since local doesn't exist leave empty so that the domain validation will happen
      CERT_LOCAL=""
    fi
    CERT_REMOTE=$(echo "$EX_CERT" | openssl x509 -noout -fingerprint 2>/dev/null)
    if [[ "$CERT_LOCAL" == "$CERT_REMOTE" ]]; then
      debug "certificate on server is same as the local cert"
    else
      # check if the certificate is for the right domain
      EX_CERT_DOMAIN=$(echo "$EX_CERT" | openssl x509 -text \
        | sed -n -e 's/^ *Subject: .* CN=\([A-Za-z0-9.-]*\).*$/\1/p; /^ *DNS:.../ { s/ *DNS://g; y/,/\n/; p; }' \
        | sort -u | grep "^$DOMAIN\$")
      if [[ "$EX_CERT_DOMAIN" == "$DOMAIN" ]]; then
        # check renew-date on ex_cert and compare to local ( if local exists)
        enddate_ex=$(echo "$EX_CERT" | openssl x509 -noout -enddate 2>/dev/null| cut -d= -f 2-)
        enddate_ex_s=$(date_epoc "$enddate_ex")
        debug "external cert has enddate $enddate_ex ( $enddate_ex_s ) "
        if [[ -s "$CERT_FILE" ]]; then # if local exists
          enddate_lc=$(openssl x509 -noout -enddate < "$CERT_FILE" 2>/dev/null| cut -d= -f 2-)
          enddate_lc_s=$(date_epoc "$enddate_lc")
          debug "local cert has enddate $enddate_lc ( $enddate_lc_s ) "
        else
          enddate_lc_s=0
          debug "local cert doesn't exist"
        fi
        if [[ "$enddate_ex_s" -eq "$enddate_lc_s" ]]; then
          debug "certificates expire at the same time"
        elif [[ "$enddate_ex_s" -gt "$enddate_lc_s" ]]; then
          # remote has longer to expiry date than local copy.
          debug "remote cert has longer to run than local cert - ignoring"
        else
          info "remote expires sooner than local for $DOMAIN, attempting to upload from local"
          copy_file_to_location "domain certificate" \
                                "$CERT_FILE" \
                                "$DOMAIN_CERT_LOCATION"
          copy_file_to_location "private key" \
                                "$DOMAIN_DIR/${DOMAIN}.key" \
                                "$DOMAIN_KEY_LOCATION"
          copy_file_to_location "CA certificate" "$CA_CERT" "$CA_CERT_LOCATION"
          cat "$CERT_FILE" "$CA_CERT" > "$TEMP_DIR/${DOMAIN}_chain.pem"
          copy_file_to_location "full pem" \
                                "$TEMP_DIR/${DOMAIN}_chain.pem" \
                                "$DOMAIN_CHAIN_LOCATION"
          cat "$DOMAIN_DIR/${DOMAIN}.key" "$CERT_FILE" > "$TEMP_DIR/${DOMAIN}_K_C.pem"
          copy_file_to_location "private key and domain cert pem" \
                                "$TEMP_DIR/${DOMAIN}_K_C.pem"  \
                                "$DOMAIN_KEY_CERT_LOCATION"
          cat "$DOMAIN_DIR/${DOMAIN}.key" "$CERT_FILE" "$CA_CERT" > "$TEMP_DIR/${DOMAIN}.pem"
          copy_file_to_location "full pem" \
                                "$TEMP_DIR/${DOMAIN}.pem"  \
                                "$DOMAIN_PEM_LOCATION"
          reload_service
        fi
      else
        info "Certificate on remote domain does not match domain, ignoring remote certificate"
      fi
    fi
  else
    info "no certificate obtained from host"
  fi
  # end of .... if obtained a cert
fi
# end of .... check_remote is true then connect and obtain the current certificate



# if there is an existing certificate file, check details.
if [[ -s "$CERT_FILE" ]]; then
  debug "certificate $CERT_FILE exists"
  enddate=$(openssl x509 -in "$CERT_FILE" -noout -enddate 2>/dev/null| cut -d= -f 2-)
  debug "local cert is valid until $enddate"
  if [[ "$enddate" != "-" ]]; then
    enddate_s=$(date_epoc "$enddate")
    if [[ $(date_renew) -lt "$enddate_s" ]] && [[ $_FORCE_RENEW -ne 1 ]]; then
      info "certificate for $DOMAIN is still valid for more than $RENEW_ALLOW days (until $enddate)"
      # everything is OK, so exit.
      graceful_exit
    else
      debug "certificate  for $DOMAIN needs renewal"
    fi
  fi
fi
# end of .... if there is an existing certificate file, check details.

if [[ ! -t 0 ]] && [[ "$PREVENT_NON_INTERACTIVE_RENEWAL" = "true" ]]; then
  errmsg="$DOMAIN due for renewal, "
  errmsg+="Did not not completed due to PREVENT_NON_INTERACTIVE_RENEWAL=true in config"
  error_exit "$errmsg"
fi

# create account key if it doesn't exist.
if [[ -s "$ACCOUNT_KEY" ]]; then
  debug "Account key exists at $ACCOUNT_KEY skipping generation"
else
  info "creating account key $ACCOUNT_KEY"
  create_key "$ACCOUNT_KEY_TYPE" "$ACCOUNT_KEY" "$ACCOUNT_KEY_LENGTH"
fi


# if not reusing priavte key, then remove the old keys
if [[ "$REUSE_PRIVATE_KEY" != "true" ]]; then
  if [[ -s "$DOMAIN_DIR/${DOMAIN}.key" ]]; then
   rm -f "$DOMAIN_DIR/${DOMAIN}.key"
  fi
  if [[ -s "$DOMAIN_DIR/${DOMAIN}.ec.key" ]]; then
   rm -f "$DOMAIN_DIR/${DOMAIN}.ecs.key"
  fi
fi
# create new domain keys if they don't already exist
if [[ "$DUAL_RSA_ECDSA" == "false" ]]; then
  create_key "${PRIVATE_KEY_ALG}" "$DOMAIN_DIR/${DOMAIN}.key" "$DOMAIN_KEY_LENGTH"
else
  create_key "rsa" "$DOMAIN_DIR/${DOMAIN}.key" "$DOMAIN_KEY_LENGTH"
  create_key "${PRIVATE_KEY_ALG}" "$DOMAIN_DIR/${DOMAIN}.ec.key" "$DOMAIN_KEY_LENGTH"
fi
# End of creating domain keys.



#create SAN
if [[ -z "$SANS" ]]; then
  SANLIST="subjectAltName=DNS:${DOMAIN}"
else
  SANLIST="subjectAltName=DNS:${DOMAIN},DNS:${SANS//,/,DNS:}"
fi
debug "created SAN list = $SANLIST"

# list of main domain and all domains in SAN
alldomains=$(echo "$DOMAIN,$SANS" | sed "s/,/ /g")

# check domain and san list for duplicates
echo "" > "$TEMP_DIR/sanlist"
for d in $alldomains; do
  if [[ "$(grep "^${d}$" "$TEMP_DIR/sanlist")" = "$d" ]]; then
    error_exit "$d appears to be duplicated in domain, SAN list"
  else
    echo "$d" >> "$TEMP_DIR/sanlist"
  fi
  # check nslookup for domains (ignore if using DNS check, as site may not be published yet)
  if [[ $VALIDATE_VIA_DNS != "true" ]]; then
    debug "checking nslookup for ${d}"
    if [[ "$(nslookup -query=AAAA "${d}"|grep -c "^${d}.*has AAAA address")" -ge 1 ]]; then
        debug "found IPv6 record for ${d}"
    elif [[ "$(nslookup "${d}"| grep -c ^Name)" -ge 1 ]]; then
        debug "found IPv4 record for ${d}"
    else
        error_exit "DNS lookup failed for $d"
    fi
  fi
done
# End of setting up SANS.




#create CSR's
if [[ "$DUAL_RSA_ECDSA" == "false" ]]; then
  create_csr "$DOMAIN_DIR/${DOMAIN}.csr" "$DOMAIN_DIR/${DOMAIN}.key"
else
  create_csr "$DOMAIN_DIR/${DOMAIN}.csr" "$DOMAIN_DIR/${DOMAIN}.key"
  create_csr "$DOMAIN_DIR/${DOMAIN}.ec.csr" "$DOMAIN_DIR/${DOMAIN}.ec.key"
fi


# use account key to register with CA
# currently the code registers every time, and gets an "already registered" back if it has been.
get_signing_params "$ACCOUNT_KEY"

if [[ "$ACCOUNT_EMAIL" ]] ; then
  regjson='{"resource": "new-reg", "contact": ["mailto: '$ACCOUNT_EMAIL'"], "agreement": "'$AGREEMENT'"}'
else
  regjson='{"resource": "new-reg", "agreement": "'$AGREEMENT'"}'
fi

info "Registering account"
# send the request to the ACME server.
send_signed_request   "$CA/acme/new-reg"  "$regjson"

if [[ "$code" == "" ]] || [[ "$code" == '201' ]] ; then
  info "Registered"
  echo "$response" > "$TEMP_DIR/account.json"
elif [[ "$code" == '409' ]] ; then
  debug "Already registered"
else
  error_exit "Error registering account ... $(json_get "$response" detail)"
fi
# end of registering account with CA




# verify each domain
info "Verify each domain"

# loop through domains for cert ( from SANS list)
alldomains=$(echo "$DOMAIN,$SANS" | sed "s/,/ /g")
dn=0
for d in $alldomains; do
  # $d is domain in current loop, which is number $dn for ACL
  info "Verifying $d"
  if [[ "$USE_SINGLE_ACL" == "true" ]]; then
    DOMAIN_ACL="${ACL[0]}"
  else
    DOMAIN_ACL="${ACL[$dn]}"
  fi

  # check if we have the information needed to place the challenge
  if [[ $VALIDATE_VIA_DNS == "true" ]]; then
    if [[ -z "$DNS_ADD_COMMAND" ]]; then
      error_exit "DNS_ADD_COMMAND not defined for domain $d"
    fi
    if [[ -z "$DNS_DEL_COMMAND" ]]; then
      error_exit "DNS_DEL_COMMAND not defined for domain $d"
    fi
  else
    if [[ -z "${DOMAIN_ACL}" ]]; then
      error_exit "ACL location not specified for domain $d in $DOMAIN_DIR/getssl.cfg"
    else
      debug "domain $d has ACL = ${DOMAIN_ACL}"
    fi
  fi

  # request a challenge token from ACME server
  request="{\"resource\":\"new-authz\",\"identifier\":{\"type\":\"dns\",\"value\":\"$d\"}}"
  send_signed_request "$CA/acme/new-authz" "$request"

  debug "completed send_signed_request"
  # check if we got a valid response and token, if not then error exit
  if [[ ! -z "$code" ]] && [[ ! "$code" == '201' ]] ; then
    error_exit "new-authz error: $response"
  fi

  if [[ $response_status == "valid" ]]; then
    info "$d is already validated"
    if [[ "$DEACTIVATE_AUTH" == "true" ]]; then
      deactivate_url="$(echo "$responseHeaders" | awk ' $1 ~ "^Location" {print $2}' | tr -d "\r")"
      deactivate_url_list+=" $deactivate_url "
      debug "url added to deactivate list ${deactivate_url}"
      debug "deactivate list is now $deactivate_url_list"
    fi
    # increment domain-counter
    ((dn++))
  else
    PREVIOUSLY_VALIDATED="false"
    if [[ $VALIDATE_VIA_DNS == "true" ]]; then # set up the correct DNS token for verification
      # get the dns component of the ACME response
      # get the token from the dns component
      token=$(json_get "$response" "token" "dns-01")
      debug token "$token"
      # get the uri from the dns component
      uri=$(json_get "$response" "uri" "dns-01")
      debug uri "$uri"

      keyauthorization="$token.$thumbprint"
      debug keyauthorization "$keyauthorization"

      #create signed authorization key from token.
      auth_key=$(printf '%s' "$keyauthorization" | openssl dgst -sha256 -binary \
                 | openssl base64 -e \
                 | tr -d '\n\r' \
                 | sed -e 's:=*$::g' -e 'y:+/:-_:')
      debug auth_key "$auth_key"

      debug "adding dns via command: $DNS_ADD_COMMAND $d $auth_key"
      if ! eval "$DNS_ADD_COMMAND" "$d" "$auth_key" ; then
        error_exit "DNS_ADD_COMMAND failed for domain $d"
      fi

      # find a primary / authoritative DNS server for the domain
      if [[ -z "$AUTH_DNS_SERVER" ]]; then
        get_auth_dns "$d"
      else
        primary_ns="$AUTH_DNS_SERVER"
      fi
      debug primary_ns "$primary_ns"

      # make a directory to hold pending dns-challenges
      if [[ ! -d "$TEMP_DIR/dns_verify" ]]; then
        mkdir "$TEMP_DIR/dns_verify"
      fi

      # generate a file with the current variables for the dns-challenge
      cat > "$TEMP_DIR/dns_verify/$d" <<- _EOF_
			token="${token}"
			uri="${uri}"
			keyauthorization="${keyauthorization}"
			d="${d}"
			primary_ns="${primary_ns}"
			auth_key="${auth_key}"
			_EOF_

    else      # set up the correct http token for verification
      # get the token from the http component
      token=$(json_get "$response" "token" "http-01")
      debug token "$token"
      # get the uri from the http component
      uri=$(json_get "$response" "uri" "http-01")
      debug uri "$uri"

      #create signed authorization key from token.
      keyauthorization="$token.$thumbprint"
      debug keyauthorization "$keyauthorization"

      # save variable into temporary file
      echo -n "$keyauthorization" > "$TEMP_DIR/$token"
      chmod 644 "$TEMP_DIR/$token"

      # copy to token to acme challenge location
      umask 0022
      debug "copying file from $TEMP_DIR/$token to ${DOMAIN_ACL}"
      copy_file_to_location "challenge token" \
                            "$TEMP_DIR/$token" \
                            "${DOMAIN_ACL}/$token"
      umask "$ORIG_UMASK"

      wellknown_url="${CHALLENGE_CHECK_TYPE}://$d/.well-known/acme-challenge/$token"
      debug wellknown_url "$wellknown_url"

      if [[ "$SKIP_HTTP_TOKEN_CHECK" == "true" ]]; then
        info "SKIP_HTTP_TOKEN_CHECK=true so not checking that token is working correctly"
      else
        sleep "$HTTP_TOKEN_CHECK_WAIT"
        # check that we can reach the challenge ourselves, if not, then error
        if [[ ! "$(curl -k --silent --location "$wellknown_url")" == "$keyauthorization" ]]; then
          error_exit "for some reason could not reach $wellknown_url - please check it manually"
        fi
      fi

      check_challenge_completion "$uri" "$d" "$keyauthorization"

      debug "remove token from ${DOMAIN_ACL}"
      if [[ "${DOMAIN_ACL:0:4}" == "ssh:" ]] ; then
        sshhost=$(echo "${DOMAIN_ACL}"| awk -F: '{print $2}')
        command="rm -f ${DOMAIN_ACL:(( ${#sshhost} + 5))}/${token:?}"
        debug "running following command to remove token"
        debug "ssh $sshhost ${command}"
        # shellcheck disable=SC2029
        ssh "$sshhost" "${command}" 1>/dev/null 2>&1
        rm -f "${TEMP_DIR:?}/${token:?}"
      elif [[ "${DOMAIN_ACL:0:4}" == "ftp:" ]] ; then
        debug "using ftp to remove token file"
        ftpuser=$(echo "${DOMAIN_ACL}"| awk -F: '{print $2}')
        ftppass=$(echo "${DOMAIN_ACL}"| awk -F: '{print $3}')
        ftphost=$(echo "${DOMAIN_ACL}"| awk -F: '{print $4}')
        ftplocn=$(echo "${DOMAIN_ACL}"| awk -F: '{print $5}')
        debug "ftp user=$ftpuser - pass=$ftppass - host=$ftphost location=$ftplocn"
        ftp -n <<- EOF
				open $ftphost
				user $ftpuser $ftppass
				cd $ftplocn
				delete ${token:?}
				EOF
      else
        rm -f "${DOMAIN_ACL:?}/${token:?}"
      fi
    fi
    # increment domain-counter
    ((dn++))
  fi
done # end of ... loop through domains for cert ( from SANS list)

# perform validation if via DNS challenge
if [[ $VALIDATE_VIA_DNS == "true" ]]; then
  # loop through dns-variable files to check if dns has been changed
  for dnsfile in $TEMP_DIR/dns_verify/*; do
    if [[ -e "$dnsfile" ]]; then
      debug "loading DNSfile: $dnsfile"
      # shellcheck source=/dev/null
      . "$dnsfile"

      # check for token at public dns server, waiting for a valid response.
      for ns in $primary_ns; do
        debug "checking dns at $ns"
        ntries=0
        check_dns="fail"
        while [[ "$check_dns" == "fail" ]]; do
          if [[ "$os" == "cygwin" ]]; then
            check_result=$(nslookup -type=txt "_acme-challenge.${d}" "${ns}" \
                           | grep ^_acme -A2\
                           | grep '"'|awk -F'"' '{ print $2}')
          else
            check_result=$(nslookup -type=txt "_acme-challenge.${d}" "${ns}" \
                           | grep ^_acme|awk -F'"' '{ print $2}')
          fi
          debug "expecting  $auth_key"
          debug "${ns} gave ... $check_result"

          if [[ "$check_result" == *"$auth_key"* ]]; then
            check_dns="success"
          else
            if [[ $ntries -lt 100 ]]; then
              ntries=$(( ntries + 1 ))
              info "checking DNS at ${ns} for ${d}. Attempt $ntries/100 gave wrong result, "\
                "waiting $DNS_WAIT secs before checking again"
              sleep $DNS_WAIT
            else
              debug "dns check failed - removing existing value"
              error_exit "checking _acme-challenge.$DOMAIN gave $check_result not $auth_key"
            fi
          fi
        done
      done
    fi
  done

  if [[ "$DNS_EXTRA_WAIT" -gt 0 && "$PREVIOUSLY_VALIDATED" != "true" ]]; then
    info "sleeping $DNS_EXTRA_WAIT seconds before asking the ACME-server to check the dns"
    sleep "$DNS_EXTRA_WAIT"
  fi

  # loop through dns-variable files to let the ACME server check the challenges
  for dnsfile in $TEMP_DIR/dns_verify/*; do
    if [[ -e "$dnsfile" ]]; then
      debug "loading DNSfile: $dnsfile"
      # shellcheck source=/dev/null
      . "$dnsfile"

      check_challenge_completion "$uri" "$d" "$keyauthorization"

      debug "remove DNS entry"
      eval "$DNS_DEL_COMMAND" "$d" "$auth_key"
      # remove $dnsfile after each loop.
      rm -f "$dnsfile"
    fi
  done
fi
# end of ... perform validation if via DNS challenge
#end of varify each domain.




# Verification has been completed for all SANS, so  request certificate.
info "Verification completed, obtaining certificate."

#obtain the certificate.
get_certificate "$DOMAIN_DIR/${DOMAIN}.csr" \
                "$CERT_FILE" \
                "$CA_CERT"
if [[ "$DUAL_RSA_ECDSA" == "true" ]]; then
  get_certificate "$DOMAIN_DIR/${DOMAIN}.ec.csr" \
                  "${CERT_FILE::-4}.ec.crt" \
                  "${CA_CERT::-4}.ec.crt"
fi

# create Archive of new certs and keys.
cert_archive

debug "Certificates obtained and archived locally, will now copy to specified locations"




# copy certs to the correct location (creating concatenated files as required)

copy_file_to_location "domain certificate" "$CERT_FILE" "$DOMAIN_CERT_LOCATION"
copy_file_to_location "private key" "$DOMAIN_DIR/${DOMAIN}.key" "$DOMAIN_KEY_LOCATION"
copy_file_to_location "CA certificate" "$CA_CERT" "$CA_CERT_LOCATION"
if [[ "$DUAL_RSA_ECDSA" == "true" ]]; then
  if [[ ! -z "$DOMAIN_CERT_LOCATION" ]]; then
    copy_file_to_location "ec domain certificate" \
                          "${CERT_FILE::-4}.ec.crt" \
                          "${DOMAIN_CERT_LOCATION::-4}.ec.crt"
  fi
  if [[ ! -z "$DOMAIN_KEY_LOCATION" ]]; then
  copy_file_to_location "ec private key" \
                        "$DOMAIN_DIR/${DOMAIN}.ec.key" \
                        "${DOMAIN_KEY_LOCATION::-4}.ec.key"
  fi
  if [[ ! -z "$CA_CERT_LOCATION" ]]; then
  copy_file_to_location "ec CA certificate" \
                        "${CA_CERT::-4}.ec.crt" \
                        "${CA_CERT_LOCATION::-4}.ec.crt"
  fi
fi

# if DOMAIN_CHAIN_LOCATION is not blank, then create and copy file.
if [[ ! -z "$DOMAIN_CHAIN_LOCATION" ]]; then
  if [[ "$(dirname "$DOMAIN_CHAIN_LOCATION")" == "." ]]; then
    to_location="${DOMAIN_DIR}/${DOMAIN_CHAIN_LOCATION}"
  else
    to_location="${DOMAIN_CHAIN_LOCATION}"
  fi
  cat "$CERT_FILE" "$CA_CERT" > "$TEMP_DIR/${DOMAIN}_chain.pem"
  copy_file_to_location "full chain" "$TEMP_DIR/${DOMAIN}_chain.pem"  "$to_location"
fi
# if DOMAIN_KEY_CERT_LOCATION is not blank, then create and copy file.
if [[ ! -z "$DOMAIN_KEY_CERT_LOCATION" ]]; then
  if [[ "$(dirname "$DOMAIN_KEY_CERT_LOCATION")" == "." ]]; then
    to_location="${DOMAIN_DIR}/${DOMAIN_KEY_CERT_LOCATION}"
  else
    to_location="${DOMAIN_KEY_CERT_LOCATION}"
  fi
  cat "$DOMAIN_DIR/${DOMAIN}.key" "$CERT_FILE" > "$TEMP_DIR/${DOMAIN}_K_C.pem"
  copy_file_to_location "private key and domain cert pem" "$TEMP_DIR/${DOMAIN}_K_C.pem"  "$to_location"
fi
# if DOMAIN_PEM_LOCATION is not blank, then create and copy file.
if [[ ! -z "$DOMAIN_PEM_LOCATION" ]]; then
  if [[ "$(dirname "$DOMAIN_PEM_LOCATION")" == "." ]]; then
    to_location="${DOMAIN_DIR}/${DOMAIN_PEM_LOCATION}"
  else
    to_location="${DOMAIN_PEM_LOCATION}"
  fi
  cat "$DOMAIN_DIR/${DOMAIN}.key" "$CERT_FILE" "$CA_CERT" > "$TEMP_DIR/${DOMAIN}.pem"
  copy_file_to_location "full key, cert and chain pem" "$TEMP_DIR/${DOMAIN}.pem"  "$to_location"
fi
# end of copying certs.




# Run reload command to restart apache / nginx or whatever system
reload_service




# deactivate authorizations
if [[ "$DEACTIVATE_AUTH" == "true" ]]; then
  debug "in deactivate list is $deactivate_url_list"
  for deactivate_url in $deactivate_url_list; do
    resp=$(curl "$deactivate_url" 2>/dev/null)
    d=$(json_get "$resp" "hostname")
    info "deactivating domain $d"
    debug "deactivating  $deactivate_url"
    send_signed_request "$deactivate_url" "{\"resource\": \"authz\", \"status\": \"deactivated\"}"
    # check response
    if [[ "$code" == "200" ]]; then
      debug "Authorization deactivated"
    else
      error_exit "$domain: Deactivation error: $code"
    fi
  done
fi
# end of deactivating authorizations


# Check if the certificate is installed correctly
if [[ ${CHECK_REMOTE} == "true" ]]; then
  sleep "$CHECK_REMOTE_WAIT"
  # shellcheck disable=SC2086
  CERT_REMOTE=$(echo \
    | openssl s_client -servername "${DOMAIN}" -connect "${DOMAIN}:${REMOTE_PORT}" ${REMOTE_EXTRA} 2>/dev/null \
    | openssl x509 -noout -fingerprint 2>/dev/null)
  CERT_LOCAL=$(openssl x509 -noout -fingerprint < "$CERT_FILE" 2>/dev/null)
  if [[ "$CERT_LOCAL" == "$CERT_REMOTE" ]]; then
    info "${DOMAIN} - certificate installed OK on server"
  else
    error_exit "${DOMAIN} - certificate obtained but certificate on server is different from the new certificate"
  fi
fi
# end of Check if the certificate is installed correctly



# To have reached here, a certificate should have been successfully obtained.
# Use echo rather than info so that 'quiet' is ignored.
echo "certificate obtained for ${DOMAIN}"


# gracefully exit ( tidying up temporary files etc).
graceful_exit
