#!/usr/bin/env bash
set -euo pipefail

base_url="${CANARY_BASE_URL:?Set CANARY_BASE_URL to the canary HTTPS origin}"
credentials_file="${CANARY_CREDENTIALS_FILE:?Set CANARY_CREDENTIALS_FILE to the two-user credentials file}"

for command_name in curl jq; do
    command -v "${command_name}" >/dev/null
done

user_a="$(sed -n '1s/:.*//p' "${credentials_file}")"
password_a="$(sed -n '1s/^[^:]*://p' "${credentials_file}")"
user_b="$(sed -n '2s/:.*//p' "${credentials_file}")"
password_b="$(sed -n '2s/^[^:]*://p' "${credentials_file}")"

if [[ -z "${user_a}" || -z "${password_a}" || -z "${user_b}" || -z "${password_b}" ]]; then
    echo "Test credentials are empty" >&2
    exit 1
fi

response_file="$(mktemp)"
token_a=""
token_b=""

cleanup() {
    set +e
    if [[ -n "${token_b}" ]]; then
        curl --silent --output /dev/null --request POST --header "X-Emby-Token: ${token_b}" "${base_url}/SyncPlay/Leave"
    fi
    if [[ -n "${token_a}" ]]; then
        curl --silent --output /dev/null --request POST --header "X-Emby-Token: ${token_a}" "${base_url}/SyncPlay/Leave"
    fi
    if [[ -n "${token_b}" ]]; then
        curl --silent --output /dev/null --request POST --header "X-Emby-Token: ${token_b}" "${base_url}/Sessions/Logout"
    fi
    if [[ -n "${token_a}" ]]; then
        curl --silent --output /dev/null --request POST --header "X-Emby-Token: ${token_a}" "${base_url}/Sessions/Logout"
    fi
    rm -f -- "${response_file}"
    unset password_a password_b token_a token_b
}
trap cleanup EXIT

authenticate() {
    local username="$1"
    local password="$2"
    local device_id="$3"
    local payload

    payload="$(jq -nc --arg Username "${username}" --arg Pw "${password}" '{Username: $Username, Pw: $Pw}')"
    curl --fail --silent --show-error \
        --header "Authorization: MediaBrowser Client=\"SyncPlay Capability Smoke\", Device=\"canary\", DeviceId=\"${device_id}\", Version=\"1.0\"" \
        --header "Content-Type: application/json" \
        --data "${payload}" \
        "${base_url}/Users/AuthenticateByName" \
        | jq -er '.AccessToken'
}

expect_status() {
    local expected="$1"
    local label="$2"
    local method="$3"
    local token="$4"
    local path="$5"
    local payload="${6:-}"
    local status
    local -a args

    args=(
        --silent
        --show-error
        --output "${response_file}"
        --write-out '%{http_code}'
        --request "${method}"
        --header "X-Emby-Token: ${token}"
    )
    if [[ -n "${payload}" ]]; then
        args+=(--header "Content-Type: application/json" --data "${payload}")
    fi

    status="$(curl "${args[@]}" "${base_url}${path}")"
    if [[ "${status}" != "${expected}" ]]; then
        echo "${label}: expected HTTP ${expected}, received ${status}" >&2
        jq -c . "${response_file}" >&2 2>/dev/null || true
        exit 1
    fi
    echo "${label}: HTTP ${status}"
}

token_a="$(authenticate "${user_a}" "${password_a}" "syncplay-capability-a")"
token_b="$(authenticate "${user_b}" "${password_b}" "syncplay-capability-b")"

capable_payload='{"PlayableMediaTypes":["Video"],"SupportedCommands":[],"SupportsMediaControl":true,"SupportsPersistentIdentifier":true,"SupportsSyncPlayPlaybackRate":true}'
legacy_payload='{"PlayableMediaTypes":["Video"],"SupportedCommands":[],"SupportsMediaControl":true,"SupportsPersistentIdentifier":true}'
expect_status 204 "capable client declaration" POST "${token_a}" "/Sessions/Capabilities/Full" "${capable_payload}"
expect_status 204 "legacy payload without new field" POST "${token_b}" "/Sessions/Capabilities/Full" "${legacy_payload}"

group_payload="$(jq -nc --arg GroupName "capability-smoke-$(date +%s)" '{GroupName: $GroupName}')"
group_response="$(curl --fail --silent --show-error \
    --header "X-Emby-Token: ${token_a}" \
    --header "Content-Type: application/json" \
    --data "${group_payload}" \
    "${base_url}/SyncPlay/New")"
group_id="$(jq -er '.GroupId' <<<"${group_response}")"
join_payload="$(jq -nc --arg GroupId "${group_id}" '{GroupId: $GroupId}')"

expect_status 204 "legacy join at 1x" POST "${token_b}" "/SyncPlay/Join" "${join_payload}"
expect_status 409 "legacy participant blocks 1.25x" POST "${token_a}" "/SyncPlay/SetPlaybackRate" '{"PlaybackRate":1.25}'
jq -e '.code == "SyncPlayPlaybackRateNotSupported" and .unsupportedParticipants == 1' "${response_file}" >/dev/null

expect_status 204 "legacy leave after rejected change" POST "${token_b}" "/SyncPlay/Leave"
expect_status 204 "legacy rejoin proves state stayed at 1x" POST "${token_b}" "/SyncPlay/Join" "${join_payload}"
expect_status 204 "legacy leave before acceleration" POST "${token_b}" "/SyncPlay/Leave"

expect_status 204 "capable group changes to 1.25x" POST "${token_a}" "/SyncPlay/SetPlaybackRate" '{"PlaybackRate":1.25}'
expect_status 409 "legacy join blocked at 1.25x" POST "${token_b}" "/SyncPlay/Join" "${join_payload}"
jq -e '.code == "SyncPlayPlaybackRateNotSupported" and .unsupportedParticipants == 1' "${response_file}" >/dev/null

expect_status 204 "capable group changes to 1.5x" POST "${token_a}" "/SyncPlay/SetPlaybackRate" '{"PlaybackRate":1.5}'
expect_status 400 "invalid 0.1x rejected" POST "${token_a}" "/SyncPlay/SetPlaybackRate" '{"PlaybackRate":0.1}'
expect_status 204 "group returns to 1x" POST "${token_a}" "/SyncPlay/SetPlaybackRate" '{"PlaybackRate":1.0}'
expect_status 204 "legacy join allowed again at 1x" POST "${token_b}" "/SyncPlay/Join" "${join_payload}"

expect_status 204 "legacy cleanup leave" POST "${token_b}" "/SyncPlay/Leave"
expect_status 204 "capable cleanup leave" POST "${token_a}" "/SyncPlay/Leave"
groups_after_cleanup="$(curl --fail --silent --show-error --header "X-Emby-Token: ${token_a}" "${base_url}/SyncPlay/List")"
jq -e --arg GroupId "${group_id}" 'all(.[]; .GroupId != $GroupId)' <<<"${groups_after_cleanup}" >/dev/null
echo "test group cleanup: verified"
expect_status 204 "legacy session logout" POST "${token_b}" "/Sessions/Logout"
token_b=""
expect_status 204 "capable session logout" POST "${token_a}" "/Sessions/Logout"
token_a=""

echo "SyncPlay playback-rate capability smoke passed"
