#!/bin/bash

# Prompt for inputs
read -p "Enter VM ID (e.g., 8000): " VMID
read -p "Enter VM Name (e.g., ubuntu-cloud): " VMNAME
read -p "Enter Memory size (in MB, e.g., 2048): " MEMORY
read -p "Enter number of CPU cores (e.g., 2): " CORES
read -p "Enter network bridge (e.g., vmbr0): " BRIDGE
read -p "Enter storage name (e.g., local, TNS_L, etc.): " STORAGE
read -p "Enter the path to Ubuntu cloud image (e.g., URL or local path): " UBUNTU_IMAGE

# Check if the UBUNTU_IMAGE is a URL or a local path
if [[ "$UBUNTU_IMAGE" =~ ^https?:// ]]; then
  # Extract the filename from the URL
  IMAGE_FILENAME=$(basename "$UBUNTU_IMAGE")
  echo "Downloading Ubuntu image as $IMAGE_FILENAME..."
  wget "$UBUNTU_IMAGE" -O "$IMAGE_FILENAME"
  UBUNTU_IMAGE="$IMAGE_FILENAME"
elif [ ! -f "$UBUNTU_IMAGE" ]; then
  echo "Ubuntu image not found at $UBUNTU_IMAGE. Exiting."
  exit 1
else
  # Extract the file name if a local path is given
  IMAGE_FILENAME=$(basename "$UBUNTU_IMAGE")
fi

# Create a VM
qm create "$VMID" --memory "$MEMORY" --cores "$CORES" --name "$VMNAME" --net0 virtio,bridge="$BRIDGE"

# Import the downloaded Ubuntu disk to the specified storage
qm disk import "$VMID" "$UBUNTU_IMAGE" "$STORAGE"

# Attach the new disk to the VM as a SCSI drive
qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE:vm-$VMID-disk-0"

# Add a cloud-init drive to the VM
qm set "$VMID" --ide2 "$STORAGE":cloudinit

# Make the cloud-init drive bootable and restrict BIOS to boot from disk only
qm set "$VMID" --boot c --bootdisk scsi0

# Add a serial console
qm set "$VMID" --serial0 socket --vga serial0

# Convert VM to template
qm template "$VMID"

# Delete image file
rm ./"$IMAGE_FILENAME"

echo "VM $VMNAME with ID $VMID has been created and configured."

# Provide troubleshooting instructions for resetting machine-id
echo "To troubleshoot, you can reset the machine-id using the following commands inside the VM:"
echo "sudo rm -f /etc/machine-id"
echo "sudo rm -f /var/lib/dbus/machine-id"
echo "sudo systemd-machine-id-setup"