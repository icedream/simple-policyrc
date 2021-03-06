#!/bin/sh -e

# TODO - Implement runlevel filtering.

if [ "$(id -u)" -eq 0 ]
then
	sudo() {
		"$@"
	}
fi

sudo install -m 755 ../policy-rc.d /usr/sbin/policy-rc.d
sudo cp -a policy-rc.d /etc/
mkdir -p actual-output

compare_output() {
	name="$1"
	shift 1
	"$@" > actual-output/"$name".txt
	echo "** Testing: $*"
	diff -uB --strip-trailing-cr expected-output/"$name".txt actual-output/"$name".txt || (
		echo "ERROR: Differences in output."
		exit 1
	)
}

check_policy() {
	name="$1"
	action="$2"
	expected_code="$3"
	expected_output_path="$(mktemp)"
	echo "$4" > "$expected_output_path"
	echo "** Testing: /usr/sbin/policy-rc.d $name $action (should return $expected_code, output \"$(cat "$expected_output_path")\")"
	set +e
	actual_output_path="$(mktemp)"
	/usr/sbin/policy-rc.d "$name" "$action" > "$actual_output_path"
	actual_code="$?"
	set -e
	[ "$actual_code" -eq "$expected_code" ] || (
		echo "ERROR: Actual code: $actual_code"
		exit 1
	)
	diff -uB --strip-trailing-cr "$expected_output_path" "$actual_output_path" || (
		echo "ERROR: Differences in output."
		exit 1
	)
	rm -f "$expected_output_path" "$actual_output_path"
}

###

compare_output list /usr/sbin/policy-rc.d --list
compare_output list-test /usr/sbin/policy-rc.d --list test
compare_output list-test2 /usr/sbin/policy-rc.d --list test2

check_policy test this-should-be-allowed 0
check_policy test this-should-also-be-allowed 0
check_policy test this-should-be-fallbacked 106 "fallback1 fallback2"
check_policy test this-should-be-denied 101
check_policy test this-should-also-be-denied 101

check_policy test2 this-should-be-allowed 0
check_policy test2 this-should-also-be-allowed 0
check_policy test2 abc 101
