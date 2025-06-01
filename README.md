
# Open5GS and UERANSIM Integration Guide

This guide documents the installation process of a 5G core simulation environment using Open5GS, MongoDB, and Node.js on a Virtual Machine running Ubuntu. The setup is a part of a research project focused on **Authentication Mechanisms in 5G Networks**.

---

## System Requirements

- Virtual Machine (tested on VMware Workstation)
- Ubuntu  22.04-JammyJellyfish

---

##  Components

| Tool        | Description                                |
|-------------|--------------------------------------------|
| Open5GS     | Open-source 5G core network implementation |
| UERANSIM    | Simulates 5G gNB and UE                    |
| MongoDB     | Core database used by Open5GS              |
| Node.js     | Required for Open5GS WebUI                 |
| Wireshark   | Used for protocol analysis                 |


---

## Step-by-Step Installation Process

### Step 1: Update System Packages

Update your system to ensure all packages are current.

```bash
sudo apt-get update
sudo apt-get upgrade
```

> This ensures you're starting from a clean, up-to-date environment.

---

### Step 2: Install Essential Tools

Install `curl`, `wget`, and `gnupg`, which are required for fetching repositories and setting up secure keys.

```bash
sudo apt-get install -y gnupg wget curl
```

> These tools are used to securely download and verify third-party repositories.

---

## MongoDB Installation

Open5GS uses MongoDB to store subscriber and session data.

---

### Step 3: Import MongoDB GPG Key

Download and add MongoDB's public key to authenticate package downloads.

```bash
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
```

---

### Step 4: Add MongoDB Repository

Add the MongoDB 8.0 package source to your system's list.

```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

---

### Step 5: Update Package List

Refresh your package list to include the new MongoDB source.

```bash
sudo apt-get update
```

---

### Step 6: Install MongoDB

Now install MongoDB along with all necessary tools.

```bash
sudo apt install -y mongodb-org
```

---

### Step 7: Start and Enable MongoDB

Start the MongoDB service and make sure it starts automatically on boot.

```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

Check if MongoDB is running properly:

```bash
sudo systemctl status mongod
```

> If everything is set up correctly, the status should show as `active (running)`.

---

## Node.js Installation

Node.js is a runtime used by Open5GS web UI and other scripts.

---

### Step 8: Add NodeSource Repository

Install the setup script for Node.js 18.x:

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
```

---

### Step 9: Install Node.js

Install Node.js and its package manager (npm):

```bash
sudo apt install -y nodejs
```

Check the versions (optional):

```bash
node -v
npm -v
```

---

##  Open5GS Installation

Open5GS provides the 5G Core Network implementation (AMF, SMF, UPF, etc.).

---

### Step 10: Add Open5GS PPA Repository

```bash
sudo add-apt-repository ppa:open5gs/latest
```

> This adds the official PPA repository maintained by the Open5GS team. After adding this, you'll be able to install Open5GS packages like `open5gs-amf`, `open5gs-smf`, etc.

---

## Open5GS Core Network Installation

Open5GS provides the essential core network functions for 4G/5G such as AMF, SMF, UPF, etc.

---

### Step 11: Install Open5GS Core Components

This command installs all major 4G/5G NFs: AMF, AUSF, SMF, UPF, PCF, UDM, UDR, etc.
```bash
sudo apt install -y open5gs
```

---

### Step 12: Start and Verify Open5GS Services

Ensures all NF services are running. You can check logs/status for each NF.
```bash
sudo service open5gs-mmed status
sudo service open5gs-pcrfd status
sudo systemctl restart open5gs-*
```

---

### Step 13: Install and Configure Net Tools

ifconfig helps verify local IP addresses used for UE/gNB communication.
```bash
sudo apt install net-tools
ifconfig
```

---

## 🌐 Open5GS WebUI Setup

A graphical web interface for managing subscribers and viewing logs.

---

### Step 14: Install WebUI Automatically

Automatically sets up Node.js project for Open5GS WebUI.
```bash
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
```

---

### Step 15: Build WebUI from Source (Optional / If Needed)

For manual control or editing WebUI code. May be required if auto-install fails or needs patching.
```bash
curl -sL https://github.com/open5gs/open5gs/archive/v2.7.0.tar.gz | tar xzf -
cd open5gs-2.7.0/webui
npm ci
npm run build
```

---

### Step 16: Enable and Start WebUI Service

Makes the dashboard available on every boot and verifies service status.
```bash
sudo systemctl daemon-reexec
sudo systemctl enable open5gs-webui
sudo systemctl start open5gs-webui
```

```bash
sudo systemctl status open5gs-webui
```

---

### Step 17: Access Open5GS WebUI

Open your browser and go to:

```
http://localhost:9999
```

Default login credentials:
- **Username**: `admin`
- **Password**: `1423`

---

#  UERANSIM Setup and Integration with Open5GS

`UERANSIM` is a high-fidelity 5G UE and gNB (base station) simulator. It is used to emulate real-world interactions between the Radio Access Network (RAN) and the 5G Core (Open5GS) without needing physical hardware like 5G modems or radios.

This makes it a perfect tool for simulating and analyzing **authentication procedures** and **network behavior** in a controlled virtual environment.

---

### Step 18: Install Build Tools and Dependencies

```bash
sudo apt install make gcc g++ libsctp-dev lksctp-tools iproute2 git
```

 **Explanation**:
- `make`, `gcc`, `g++`: Needed to compile the C++ source code of UERANSIM.
- `libsctp-dev`, `lksctp-tools`: Required for SCTP protocol support, used in 5G NGAP signaling between gNB and AMF.
- `iproute2`: Provides tools like `ip` used in interface and routing management.
- `git`: To clone the UERANSIM repository from GitHub.

---

### Step 19: Install CMake

```bash
sudo snap install cmake --classic
```

**Explanation**:
CMake is a build-system generator. It creates platform-independent makefiles from configuration scripts, enabling flexible project builds.

---

### Step 20: Download UERANSIM Source Code

```bash
mkdir ueransim && cd ueransim
git clone https://github.com/aligungr/UERANSIM
cd UERANSIM
```

**Explanation**:
- Organize source files in a dedicated folder.
- Clone the latest version of UERANSIM for stability and up-to-date compatibility with Open5GS.

---

### Step 21: Compile UERANSIM from Source

```bash
make
```

**Explanation**:
This will:
- Run `cmake` to generate build files
- Compile all components (gNB, UE, library modules)
- Output final binaries in the `build/` directory

You should see `UERANSIM successfully built.` at the end.

---

### Step 22: Configure gNB and UE Profiles

UERANSIM includes config samples:
- `config/open5gs-gnb.yaml`
- `config/open5gs-ue.yaml`

Edit them to match your Open5GS IP addresses and PLMN (e.g. `imsi-208930000000001`).

**Explanation**:
These YAML files define:
- gNB ID, IP, port, MCC/MNC
- UE IMSI, keys, slices, PDU session requests
Ensure they align with Open5GS settings (`/etc/open5gs/*.yaml`).

---

### 🚦 Step 23: Start gNB Simulator

```bash
./build/nr-gnb -c config/open5gs-gnb.yaml
```

**Explanation**:
- Starts SCTP communication with Open5GS AMF on localhost.
- You’ll see logs indicating:
  - SCTP established
  - NG Setup Request/Response
  - Connection success

This simulates a live RAN node.

---

### 📡 Step 24: Start UE Simulator (After Adding Subscriber in WebUI)

```bash
./build/nr-ue -c config/open5gs-ue.yaml
```

 **Explanation**:
- Simulates a real 5G device registering to the network.
- Triggers authentication (AKA), security mode, session establishment
- Open5GS logs will show NAS message flows and authentication details

---

### Step 25: View AMF Logs for Confirmation

```bash
sudo service open5gs-amfd status
```

**Explanation**:
You’ll see:
- Setup from gNB
- UE registration events
- NAS and authentication message traces

---

### Step 26: Confirm Address Bindings in YAML Files

```bash
cd /etc/open5gs
grep -i "addr" *.yaml
```

**Explanation**:
Verifies IP addresses for NFs like `amf.yaml`, `ausf.yaml`, etc., ensuring localhost or private IPs match what UERANSIM expects.

---


---

### Step 27: Configure gNodeB and UE

- Navigate to UERANSIM config directory:
  ```bash
  cd ~/ueransim/config
  ```

- Edit `gnb1.yaml` and `ue1.yaml` using a text editor (e.g., `gedit`):
  ```bash
  gedit gnb1.yaml &
  gedit ue1.yaml &
  ```

#### Example `gnb1.yaml`
```yaml
mcc: '999'         # Mobile Country Code
mnc: '70'          # Mobile Network Code
nci: 0x000000010   # NR Cell Identity
tac: 1             # Tracking Area Code
linkIp: 127.0.0.1
ngapIp: 127.0.0.1
gtpIp: 127.0.0.1
amfConfigs:
  - address: 127.0.0.5
    port: 38412
slices:
  - sst: 1
ignoreStreamIds: true
```

#### Example `ue1.yaml`
```yaml
supi: 'imsi-999700000000001'
mcc: '999'
mnc: '70'
key: '000102030405060708090a0b0c0d0e0f'
opc: 'c9e8763286b5b9ffbdf56e1297d0887b'
type: 'OPC'
amf: '8000'
imei: '356938035643803'
imeiSv: '4370816125816150'
gnbSearchList:
  - 127.0.0.1
```

---

### Step 28: Run gNodeB and UE Simulations

- Run gNB:
  ```bash
  ./build/nr-gnb -c gnb1.yaml
  ```

- Run UE:
  ```bash
  ./build/nr-ue -c ue1.yaml
  ```

You should see messages indicating successful SCTP association and NG Setup:
```
[ngap] NG Setup Request
[ngap] NG Setup Response
[ngap] NG Setup procedure is successful
```

---

### Step 29: Verify AMF Receives Connection

- Check AMF logs:
  ```bash
  sudo service open5gs-amfd status
  ```

- Look for logs confirming UE connection, gNB registration, and stream setup.

---

### Step 30: Install and Use Wireshark for Packet Analysis

- Clone the NR dissector:
  ```bash
  git clone https://github.com/louisroyer-deb/rls-wireshark-dissector
  ```

- Copy to Wireshark plugins folder:
  ```bash
  sudo cp -R ~/ueransim/rls-wireshark-dissector/* /usr/lib/x86_64-linux-gnu/wireshark/plugins/
  ```

- Launch Wireshark with:
  ```bash
  sudo wireshark
  ```

- Start packet capture and apply filters like:
  ```
  ngap || nas-5gs
  ```

This allows you to visualize authentication exchanges and NGAP procedures.

---

### Step 31: Confirm End-to-End Connectivity

- Monitor successful UE attach procedure.
- Confirm registration accept and session setup messages.
- Ensure AMF logs match Wireshark captures.

---

### Final Directory Snapshot

Key directories should include:
- `/etc/open5gs/*.yaml` – Core network configs
- `~/ueransim/config/*.yaml` – gNB/UE simulation configs
- `~/ueransim/build/` – Compiled binaries
- `~/ueransim/rls-wireshark-dissector/` – Wireshark plugin

---

## Step 32: Create a Subscriber in Open5GS WebUI

1. Open a browser and go to [http://localhost:9999](http://localhost:9999).
2. Click the **`+` (plus)** button to create a new subscriber.

**Fill in the following details:**
- **IMSI**: `999700000000001`
- **Key (K)**: `465B5CE8 B199B49F AA5F0A2E E238A6BC`
- **OPc**: `E8ED289D EBA952E4 283B54E8 86E1B3CA`
- **AMF**: `8000`
- **Downlink & Uplink AMBR**: `1 Gbps`

Click **SAVE** after filling in the fields.

---

## Step 33: Verify the Subscriber Entry

After saving, search for the IMSI (`999700000000001`) in the **Subscriber** section. You should see the subscriber listed there.

---

## Step 34: Confirm UE Configuration

Edit `ue1.yaml` in `UERANSIM/config` directory to match the newly created subscriber:

```yaml
imsi: '999700000000001'
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
opType: 'OPc'
op: 'E8ED289DEBA952E4283B54E8861B3CA'
amf: '8000'
imei: '356938035643803'
imeiSv: '437081612581451'
gnbSearchList:
  - 127.0.0.1
```
Ensure the imsi, key, op, and amf match the WebUI entry.

---

## Step 35: Run UE Simulator

Run the UE with proper permissions:

```
sudo ./build/nr-ue -c ue1.yaml
```

If run without sudo, you may encounter:
TUN interface could not be setup. Permission denied.


## Step 36: Successful UE Registration
When run with sudo, you should see:

```
[info] Registration is successful
[info] Connection setup for PDU session(s) is successful
```
TUN interface like 10.45.0.3 will be up and assigned.

Step 37: Packet Capture via Wireshark

Launch Wireshark:

```
sudo wireshark
```

Filter by protocol NR RRC or IP loopback if needed.

You will see packets such as:
  - RRC Setup Request
  - RRC Setup
  - Authentication Request
  - Security Mode Command
  - PDU Session Establishment Accept
  - Information Transfer packets

## References
 - Open5GS Releases - https://github.com/open5gs/open5gs
 - UERANSIM GitHub - https://github.com/aligungr/UERANSIM
 - Wireshark RLS Dissector Plugin - https://github.com/louisroyer-deb/rls-wireshark-dissector
