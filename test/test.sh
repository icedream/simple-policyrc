#!/bin/sh -ex

# TODO - Implement runlevel filtering.

sudo install -m 755 ../policy-rc.d /usr/sbin/policy-rc.d
sudo cp -a policy-rc.d /etc/
mkdir -p actual-output

compare_output() {
	name="$1"
	shift 1
	"$@" > actual-output/"$name".txt
	diff -uB --strip-trailing-cr expected-output/"$name".txt actual-output/"$name".txt
}

check_policy() {
	name="$1"
	action="$2"
	expected_code="$3"
	expected_output_path="$(mktemp)"
	printf "%s" "$4" > "$expected_output_path"
	set +e
	actual_output_path="$(mktemp)"
	/usr/sbin/policy-rc.d "$name" "$action" > "$actual_output_path"
	set -e
	actual_code="$?"
	[ "$actual_code" -eq "$expected_code" ]
	diff -uB --strip-trailing-cr "$expected_output_path" "$actual_output_path"
}

###

compare_output list /usr/sbin/policy-rc.d --list

check_policy test this-should-be-allowed 0
check_policy test this-should-also-be-allowed 0
check_policy test this-should-be-fallbacked 106 "fallback1 fallback2"
check_policy test this-should-be-denied 101
check_policy test this-should-also-be-denied 101

check_policy test2 this-should-be-allowed 0
check_policy test2 this-should-also-be-allowed 0
check_policy test2 abc 101
