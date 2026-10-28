# Setting up an Ubuntu Server VM on Hyper-V (Windows 11 Pro)

This builds the always-on Ubuntu VM that the agent lives in. It takes about 30 minutes, mostly waiting for installs.

You need Windows 11 **Pro** (or Enterprise/Education). Windows Home doesn't include Hyper-V.

---

## 1. Check virtualization is on

Open **Task Manager → Performance → CPU**. Near the bottom it should say **Virtualization: Enabled**.

If it says Disabled, turn on Intel VT-x / AMD-V (sometimes called "SVM") in your PC's BIOS/UEFI settings, then come back.

## 2. Turn on Hyper-V

1. Start menu → search **"Turn Windows features on or off"**
2. Tick **Hyper-V** (both sub-items: Platform and Management Tools)
3. OK → **Restart**

Or in **PowerShell as Administrator**:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

## 3. Download Ubuntu Server

Download **Ubuntu Server 26.04 LTS** from <https://ubuntu.com/download/server>. Get the `.iso` (~2.5 GB) and note where it saves.

## 4. Create an External network switch

This puts the VM on your home network like any other device, so it has a stable address you can SSH to. Hyper-V's "Default Switch" changes the VM's address on every reboot.

1. Open **Hyper-V Manager** (Start menu)
2. Right pane → **Virtual Switch Manager…**
3. **New virtual network switch** → **External** → **Create Virtual Switch**
4. Name: `External`. Under "External network", pick your **Ethernet** adapter (Wi-Fi works but is less reliable)
5. Leave **"Allow management operating system to share this network adapter"** ticked → **OK**

Your PC's network drops for a few seconds while the switch is created. That's normal.

## 5. Create the VM

### Option A: PowerShell (fastest, all settings in one go)

Open **PowerShell as Administrator** and paste, editing the ISO path on the first line:

```powershell
$Iso  = "$HOME\Downloads\ubuntu-26.04.1-live-server-amd64.iso"   # <- your ISO's real filename
$Name = "agent-vm"
$Dir  = "C:\Hyper-V\$Name"
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

New-VM -Name $Name -Generation 2 -MemoryStartupBytes 4GB `
  -NewVHDPath "$Dir\$Name.vhdx" -NewVHDSizeBytes 40GB -SwitchName "External" -Path "C:\Hyper-V"
Set-VMProcessor -VMName $Name -Count 2
Set-VMMemory    -VMName $Name -DynamicMemoryEnabled $false
Set-VMFirmware  -VMName $Name -SecureBootTemplate MicrosoftUEFICertificateAuthority
Add-VMDvdDrive  -VMName $Name -Path $Iso
Set-VMFirmware  -VMName $Name -FirstBootDevice (Get-VMDvdDrive -VMName $Name)
Set-VM -Name $Name -AutomaticStartAction Start -AutomaticStartDelay 60 `
  -AutomaticStopAction ShutDown -CheckpointType Production
Enable-VMIntegrationService -VMName $Name -Name "Guest Service Interface"

Start-VM -Name $Name
vmconnect.exe localhost $Name
```

### Option B: Hyper-V Manager wizard

1. **Action → New → Virtual Machine…**
2. Name: `agent-vm`
3. **Generation 2**
4. Memory: **4096 MB**, untick "Use Dynamic Memory"
5. Networking: **External**
6. Create a virtual hard disk: **40 GB**
7. "Install an operating system from a bootable image file" → browse to the Ubuntu ISO → **Finish**
8. **Before starting it**, right-click the VM → **Settings**:
   - **Security** → Template: **Microsoft UEFI Certificate Authority** *(the default template won't boot Ubuntu)*
   - **Processor** → **2** virtual processors
   - **Automatic Start Action** → **Always start this virtual machine automatically**, delay 60 seconds
   - **Automatic Stop Action** → **Shut down the guest operating system**
9. Right-click → **Connect…** → **Start**

## 6. Install Ubuntu

In the VM window, accept the defaults except where noted:

| Screen | Choose |
|---|---|
| Language / keyboard | English (US) or yours |
| Type of install | **Ubuntu Server** (not minimized) |
| Network | Leave DHCP. **Write down the IPv4 address it shows** (e.g. 192.168.1.57) |
| Proxy / mirror | Leave blank / default |
| Storage | **Use an entire disk** (defaults are fine) → Done → Continue |
| Profile | Your name, server name `agent-vm`, a username (e.g. `matt`) and a strong password |
| Ubuntu Pro | Skip for now |
| SSH | ✅ **Install OpenSSH server** |
| Featured snaps | Select none |

When it says **Installation complete**, choose **Reboot now**. If it asks you to remove the installation medium, use the VM window's **Media → DVD Drive → Eject**, then press Enter.

## 7. First login and updates

Log in at the VM console, or (easier, since copy/paste works) from **Windows Terminal / PowerShell** on your PC:

```powershell
ssh matt@192.168.1.57      # your username and the VM's IP
```

Then on the VM:

```bash
sudo apt update && sudo apt full-upgrade -y
df -h /          # check the root disk shows ~38G
```

If `df` shows much less than the 40 GB disk (the installer sometimes leaves space unallocated), grow it:

```bash
sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
```

Then `sudo reboot`.

## 8. Give the VM a fixed address (recommended)

In your **router's admin page**, find the DHCP client list and create a **DHCP reservation** for `agent-vm` so it always gets the same IP. That's simpler and safer than configuring a static IP inside Ubuntu.

## 9. Take a checkpoint

In Hyper-V Manager, right-click **agent-vm → Checkpoint**, then rename it to `clean install`. If anything ever goes badly wrong, right-click the checkpoint → **Apply** to rewind.

## 10. Keep Windows from sleeping

If the PC sleeps, the agent sleeps with it.

**Settings → System → Power & battery → Screen, sleep & hibernate timeouts**: set **"Make my device sleep after"** (plugged in) to **Never**. The screen can still turn off.

Windows Update will occasionally restart the PC. That's fine: the VM starts automatically about a minute after Windows boots, and the agent service starts with it.

---

## Next

Back to the main [README](../README.md#2-get-the-files-onto-the-vm). On the VM, clone this repo and run the bootstrap script.

### Useful Hyper-V commands (PowerShell as Administrator)

```powershell
Get-VM                                  # list VMs and state
Start-VM agent-vm / Stop-VM agent-vm    # start / clean shutdown
Checkpoint-VM agent-vm -SnapshotName "before X"
(Get-VMNetworkAdapter agent-vm).IPAddresses   # find the VM's IP
```
