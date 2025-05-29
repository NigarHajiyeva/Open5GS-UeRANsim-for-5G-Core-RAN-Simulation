
# 5G Core Setup Using Open5GS + MongoDB + Node.js on Ubuntu VM

This guide documents the installation process of a 5G core simulation environment using Open5GS, MongoDB, and Node.js on a Virtual Machine running Ubuntu. The setup is a part of a research project focused on **Authentication Mechanisms in 5G Networks**.

---

## System Requirements

- Virtual Machine (tested on VMware Workstation)
- Ubuntu  22.04-JammyJellyfish
- Virtual Machine (tested on VMware Workstation)

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

