package pc5core

import (
	"encoding/json"
	"errors"
	"os"
	"strconv"
	"sync"

	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf/serial"
	_ "github.com/xtls/xray-core/main/distro/all"
	_ "github.com/xtls/xray-core/proxy/tun"
)

var (
	mu       sync.Mutex
	instance *core.Instance
)

// Run takes the server-supplied config, replaces its inbounds with a TUN inbound
// bound to the fd the VpnService created, and starts the core.
func Run(configJSON string, tunFd int32, mtu int32) error {
	mu.Lock()
	defer mu.Unlock()

	if instance != nil {
		return errors.New("core already running")
	}
	if tunFd <= 0 {
		return errors.New("invalid tun fd")
	}

	var root map[string]interface{}
	if err := json.Unmarshal([]byte(configJSON), &root); err != nil {
		return err
	}

	if mtu <= 0 || mtu > 9000 {
		mtu = 1500
	}

	os.Setenv("XRAY_TUN_FD", strconv.Itoa(int(tunFd)))
	os.Setenv("xray.tun.fd", strconv.Itoa(int(tunFd)))

	root["inbounds"] = []interface{}{
		map[string]interface{}{
			"tag":      "tun-in",
			"protocol": "tun",
			"settings": map[string]interface{}{
				"name":                   "pc5tun",
				"mtu":                    mtu,
				"autoOutboundsInterface": "auto",
			},
			"sniffing": map[string]interface{}{
				"enabled":      true,
				"destOverride": []interface{}{"http", "tls", "quic"},
				"routeOnly":    true,
			},
		},
	}

	patched, err := json.Marshal(root)
	if err != nil {
		return err
	}

	pbConfig, err := serial.BuildConfig(patched)
	if err != nil {
		return err
	}

	inst, err := core.New(pbConfig)
	if err != nil {
		return err
	}

	if err := inst.Start(); err != nil {
		return err
	}

	instance = inst
	return nil
}

// Stop tears the core down and releases the tun fd.
func Stop() {
	mu.Lock()
	defer mu.Unlock()
	if instance == nil {
		return
	}
	_ = instance.Close()
	instance = nil
	os.Unsetenv("XRAY_TUN_FD")
	os.Unsetenv("xray.tun.fd")
}

// Running reports core state.
func Running() bool {
	mu.Lock()
	defer mu.Unlock()
	return instance != nil
}

// Version returns the embedded core version string.
func Version() string {
	return core.Version()
}
