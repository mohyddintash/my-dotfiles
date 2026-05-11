#!/usr/bin/env bun
// @bun

// src/index.ts
import { exec } from "child_process";
import { promisify } from "util";
import { readFileSync } from "fs";
import { join } from "path";
import { homedir } from "os";
var execAsync = promisify(exec);

class Wifi4Wofi {
  config = {
    FIELDS: "SSID,SECURITY",
    POSITION: 0,
    YOFF: 0,
    XOFF: 0
  };
  WIFI_IFACE = null;
  constructor() {
    this.loadConfig();
  }
  loadConfig() {
    const configPaths = [
      join(process.cwd(), "config"),
      join(homedir(), ".config", "wofi", "wifi")
    ];
    console.log("Looking for config in:", configPaths);
    for (const path of configPaths) {
      try {
        console.log("Trying to read config from:", path);
        const configContent = readFileSync(path, "utf-8");
        const configLines = configContent.split(`
`);
        for (const line of configLines) {
          if (line.trim().startsWith("#"))
            continue;
          const [key, value] = line.split("=");
          if (key && value) {
            const trimmedKey = key.trim();
            const trimmedValue = value.trim();
            if (["POSITION", "XOFF", "YOFF"].includes(trimmedKey)) {
              this.config[trimmedKey] = parseInt(trimmedValue, 10);
              console.log(`Set ${trimmedKey} to ${this.config[trimmedKey]} (numeric)`);
            } else {
              this.config[trimmedKey] = trimmedValue;
              console.log(`Set ${trimmedKey} to ${this.config[trimmedKey]} (string)`);
            }
          }
        }
        console.log("Final config:", this.config);
        break;
      } catch (error) {
        console.log("Error reading config from", path, error);
        continue;
      }
    }
  }
  async initializeWifiInterface() {
    try {
      const { stdout } = await execAsync(`nmcli device status | grep "wifi" | awk '{print $1}' | head -n 1`);
      this.WIFI_IFACE = stdout.trim();
      if (!this.WIFI_IFACE) {
        console.error("No Wi-Fi interface found by nmcli!");
        await execAsync('notify-send "Wi-Fi Error" "No Wi-Fi interface found! Check nmcli device status."');
      } else {
        console.log(`Detected Wi-Fi interface: ${this.WIFI_IFACE}`);
      }
    } catch (error) {
      console.error("Error detecting Wi-Fi interface:", error);
      await execAsync('notify-send "Wi-Fi Error" "Failed to detect Wi-Fi interface."');
    }
  }
  async getScreenDimensions() {
    try {
      const { stdout } = await execAsync('swaymsg -t get_outputs | jq -r ".[0].current_mode"');
      const [width, height] = stdout.trim().split("x").map(Number);
      return { width, height };
    } catch (error) {
      console.warn("Could not get screen dimensions via swaymsg. Defaulting. Error:", error);
      return { width: 1920, height: 1080 };
    }
  }
  async getWifiList() {
    const { stdout } = await execAsync(`nmcli --terse --fields "SSID,SECURITY,SIGNAL" device wifi list --rescan yes`);
    return stdout;
  }
  async getCurrentSSID() {
    const { stdout } = await execAsync("nmcli -t -f active,ssid dev wifi | awk -F: '$1 ~ /^yes/ {print $2}'");
    return stdout.trim();
  }
  async getWifiState() {
    const { stdout } = await execAsync("nmcli -t -f WIFI g");
    return stdout.trim();
  }
  async showWofiPrompt(prompt, default_value = "", isPassword = false) {
    let wofiCmd = `echo "${default_value}" | wofi -i -d --prompt "${prompt}" --lines 1 --location center --width 500 --height 100`;
    if (isPassword) {
      wofiCmd += ` --pass-display`;
    }
    console.log("Wofi prompt command:", wofiCmd);
    try {
      const { stdout } = await execAsync(wofiCmd);
      return stdout.trim();
    } catch (error) {
      if (error.code === 1) {
        console.log("Wofi prompt cancelled by user.");
        return "";
      }
      console.error("Error in showWofiPrompt:", error);
      throw error;
    }
  }
  async showWofiMenu(options, prompt = "Select Wi-Fi Network:") {
    const input = options.join(`
`);
    const menuWidth = 500;
    const menuHeight = Math.max(options.length * 30, 100);
    const positionMap = {
      0: "center",
      1: "top_left",
      2: "top",
      3: "top_right",
      4: "right",
      5: "bottom_right",
      6: "bottom",
      7: "bottom_left",
      8: "left"
    };
    const position = positionMap[this.config.POSITION || 0] || "center";
    console.log("Using position:", position, "from config POSITION:", this.config.POSITION);
    const cmd = `echo "${input}" | wofi -i -d --prompt "${prompt}" --lines ${options.length} --location ${position} --width ${menuWidth} --height ${menuHeight}`;
    console.log("Wofi menu command:", cmd);
    try {
      const { stdout } = await execAsync(cmd);
      return stdout.trim();
    } catch (error) {
      if (error.code === 1) {
        console.log("Wofi menu cancelled by user.");
        return "";
      }
      console.error("Error in showWofiMenu:", error);
      throw error;
    }
  }
  async connectToWifi(ssid, password) {
    let actualConnectionName = `wifi-${ssid}`;
    try {
      const { stdout: connectionsList } = await execAsync("nmcli -t connection show");
      const existingSsidConnection = connectionsList.split(`
`).find((line) => line.startsWith(`${ssid}:`));
      if (existingSsidConnection) {
        actualConnectionName = ssid;
        console.log(`Found existing connection profile named "${ssid}". Using it.`);
      } else {
        console.log(`No existing connection profile found named "${ssid}". Will use "${actualConnectionName}".`);
      }
    } catch (error) {
      console.warn("Could not check for existing connection profile by SSID:", error);
    }
    if (!password) {
      const cmd = `nmcli dev wifi con "${ssid}"`;
      console.log("Connecting (open network) with command:", cmd);
      await execAsync(cmd);
      return;
    }
    try {
      const modifyCmd = `nmcli connection modify "${actualConnectionName}" wifi.ssid "${ssid}" wifi-sec.key-mgmt wpa-psk 802-11-wireless-security.psk "${password}"`;
      console.log(`Attempting to modify/create connection "${actualConnectionName}" with command:`, modifyCmd);
      await execAsync(modifyCmd);
    } catch (error) {
      console.warn(`Modify connection failed for "${actualConnectionName}", trying to add new. Error: ${error.message}`);
      const addNewConnectionName = `wifi-${ssid}`;
      if (!this.WIFI_IFACE) {
        throw new Error("Cannot add new connection: Wi-Fi interface not detected.");
      }
      const addCmd = `nmcli connection add type wifi con-name "${addNewConnectionName}" ifname "${this.WIFI_IFACE}" ssid "${ssid}" wifi-sec.key-mgmt wpa-psk 802-11-wireless-security.psk "${password}"`;
      console.log(`Attempting to add new connection with command "${addNewConnectionName}":`, addCmd);
      await execAsync(addCmd);
      actualConnectionName = addNewConnectionName;
    }
    const upCmd = `nmcli connection up "${actualConnectionName}"`;
    console.log(`Bringing connection "${actualConnectionName}" up with command:`, upCmd);
    await execAsync(upCmd);
  }
  async toggleWifi(state) {
    await execAsync(`nmcli radio wifi ${state}`);
  }
  async run() {
    await this.initializeWifiInterface();
    if (!this.WIFI_IFACE) {
      return;
    }
    try {
      const currentSSID = await this.getCurrentSSID();
      const wifiState = await this.getWifiState();
      const isEnabled = wifiState.includes("enabled");
      const toggleOption = isEnabled ? "Toggle Wi-Fi Off" : "Toggle Wi-Fi On";
      const rawWifiList = await execAsync(`nmcli --terse --fields "SSID,SECURITY,SIGNAL" device wifi list --rescan no`);
      const wifiNetworks = rawWifiList.stdout.trim().split(`
`).map((line) => {
        const parts = line.split(":");
        const ssid = parts[0];
        const security = parts[1] || "None";
        const signal = parts[2] || "0";
        return { ssid, security, signal: parseInt(signal, 10) };
      }).filter((net) => net.ssid && net.ssid !== "--");
      const displayedNetworkOptions = [];
      const ssidMap = new Map;
      const uniqueNetworks = new Map;
      for (const net of wifiNetworks) {
        if (!uniqueNetworks.has(net.ssid) || net.signal > (uniqueNetworks.get(net.ssid)?.signal || 0)) {
          uniqueNetworks.set(net.ssid, net);
        }
      }
      for (const [ssid, net] of uniqueNetworks.entries()) {
        let displayString = `${net.ssid} (${net.signal}%)`;
        if (net.security && net.security !== "None") {
          displayString += ` [${net.security}]`;
        }
        if (net.ssid === currentSSID) {
          displayString += " [Connected]";
        }
        displayedNetworkOptions.push(displayString);
        ssidMap.set(displayString, net.ssid);
      }
      displayedNetworkOptions.sort((a, b) => {
        const aConnected = a.includes("[Connected]");
        const bConnected = b.includes("[Connected]");
        if (aConnected && !bConnected)
          return -1;
        if (!aConnected && bConnected)
          return 1;
        const aSignalMatch = a.match(/\((\d+)%\)/);
        const bSignalMatch = b.match(/\((\d+)%\)/);
        const aSignal = aSignalMatch ? parseInt(aSignalMatch[1]) : 0;
        const bSignal = bSignalMatch ? parseInt(bSignalMatch[1]) : 0;
        if (aSignal !== bSignal)
          return bSignal - aSignal;
        return a.localeCompare(b);
      });
      const menuOptions = [toggleOption, "Enter SSID Manually", "Disconnect", ...displayedNetworkOptions];
      const selection = await this.showWofiMenu(menuOptions);
      if (!selection) {
        console.log("Main Wofi menu cancelled.");
        return;
      }
      if (selection === "Toggle Wi-Fi On") {
        await this.toggleWifi("on");
        await execAsync('notify-send "Wi-Fi" "Wi-Fi enabled."');
      } else if (selection === "Toggle Wi-Fi Off") {
        await this.toggleWifi("off");
        await execAsync('notify-send "Wi-Fi" "Wi-Fi disabled."');
      } else if (selection === "Disconnect") {
        if (currentSSID) {
          await execAsync(`nmcli device disconnect ${this.WIFI_IFACE}`);
          await execAsync(`notify-send "Wi-Fi" "Disconnected from ${currentSSID}."`);
        } else {
          await execAsync('notify-send "Wi-Fi" "Not connected to any network."');
        }
      } else if (selection === "Enter SSID Manually") {
        const manualSSID = await this.showWofiPrompt("Enter SSID:");
        if (!manualSSID) {
          await execAsync('notify-send "Wi-Fi" "Manual SSID entry cancelled."');
          return;
        }
        const password = await this.showWofiPrompt(`Enter password for ${manualSSID}:`, "", true);
        if (!password) {
          await execAsync('notify-send "Wi-Fi" "Password entry cancelled for manual SSID."');
          return;
        }
        try {
          await this.connectToWifi(manualSSID, password);
          await execAsync(`notify-send "Wi-Fi" "Attempting to connect to ${manualSSID}..."`);
        } catch (connectError) {
          console.error(`Error connecting to ${manualSSID} via nmcli:`, connectError);
          await execAsync(`notify-send "Wi-Fi Error" "Failed to connect to ${manualSSID}. Manual configuration may be required. Launching Network Manager Editor."`);
          await execAsync("nm-connection-editor &");
        }
      } else {
        const ssidToConnect = ssidMap.get(selection);
        if (!ssidToConnect) {
          await execAsync('notify-send "Error" "Invalid Wi-Fi network selected."');
          console.error("Failed to map selected option to SSID:", selection);
          return;
        }
        const { stdout: connectionsList } = await execAsync("nmcli -t connection show");
        const connectionExists = connectionsList.split(`
`).some((line) => line.startsWith(`${ssidToConnect}:`));
        if (false) {
          try {} catch (connUpError) {
            if (password) {
              try {} catch (reconnectError) {}
            } else {}
          }
        } else {
          await execAsync(`notify-send "Wi-Fi" "Connecting to new network: ${ssidToConnect}. Enter password..."`);
          const password = await this.showWofiPrompt(`Password for ${ssidToConnect}:`, "", true);
          if (password) {
            try {
              await this.connectToWifi(ssidToConnect, password);
              await execAsync(`notify-send "Wi-Fi" "Connection attempt completed for ${ssidToConnect}."`);
            } catch (connectError) {
              console.error(`Error connecting to ${ssidToConnect} via nmcli:`, connectError);
              await execAsync(`notify-send "Wi-Fi Error" "Failed to connect to ${ssidToConnect}. Manual configuration may be required. Launching Network Manager Editor."`);
              await execAsync("nm-connection-editor &");
            }
          } else {
            await execAsync(`notify-send "Wi-Fi" "Connection cancelled: No password provided for ${ssidToConnect}."`);
          }
        }
      }
    } catch (error) {
      console.error("Error in Wifi4Wofi:", error);
      await execAsync(`notify-send "Wi-Fi Error" "An unhandled error occurred: ${error}"`);
    }
  }
}
var app = new Wifi4Wofi;
app.run();
