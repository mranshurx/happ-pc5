package pc5core

import "testing"

func TestVersionNotEmpty(t *testing.T) {
	if Version() == "" {
		t.Fatal("core version is empty — the xray import graph did not link")
	}
}

func TestRunRejectsBadInput(t *testing.T) {
	if err := Run("{not json", 0, 1500); err == nil {
		t.Fatal("expected error for invalid config and fd")
	}
}
