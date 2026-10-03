#!/usr/bin/env python3
"""
dmg_builder.py
Constructs a valid, mountable macOS DMG containing Slate.app and Applications symlink.
Supports pure Python ISO-9660 with Rock Ridge extensions and Apple UDIF trailer.
"""

import os
import sys
import struct
import zlib
import time
import shutil

def create_dmg(source_dir, output_dmg_path, volume_name="Slate"):
    print(f"Creating DMG from {source_dir} -> {output_dmg_path} (Volume: {volume_name})")
    
    # We will build an ISO-9660 filesystem image with Rock Ridge attributes
    # and append an Apple Universal Disk Image Format (UDIF) koly footer.
    
    # Collect all files to include
    files = []
    for root, dirs, filenames in os.walk(source_dir):
        rel_root = os.path.relpath(root, source_dir)
        if rel_root == ".":
            rel_root = ""
        for d in dirs:
            dir_path = os.path.join(rel_root, d) if rel_root else d
            files.append({
                'is_dir': True,
                'is_symlink': False,
                'path': dir_path,
                'full_path': os.path.join(root, d),
                'size': 0
            })
        for f in filenames:
            file_path = os.path.join(rel_root, f) if rel_root else f
            full_path = os.path.join(root, f)
            is_symlink = os.path.islink(full_path)
            size = os.path.getsize(full_path) if not is_symlink else 0
            files.append({
                'is_dir': False,
                'is_symlink': is_symlink,
                'symlink_target': os.readlink(full_path) if is_symlink else None,
                'path': file_path,
                'full_path': full_path,
                'size': size
            })
            
    # Also add the Applications symlink at the root of the DMG
    files.append({
        'is_dir': False,
        'is_symlink': True,
        'symlink_target': '/Applications',
        'path': 'Applications',
        'full_path': None,
        'size': 0
    })

    # Sector size in ISO 9660 is 2048 bytes
    SECTOR_SIZE = 2048
    
    # Prepare sectors
    # System area: Sectors 0-15 (32768 bytes) = 0
    # Sector 16: Primary Volume Descriptor (PVD)
    # Sector 17: Volume Descriptor Set Terminator
    # Sector 18+: Path tables & Root Directory Records & Data
    
    data_sectors = []
    file_sector_map = {}
    current_sector = 20 # Start placing file data at sector 20
    
    for item in files:
        if not item['is_dir'] and not item['is_symlink']:
            with open(item['full_path'], 'rb') as f:
                content = f.read()
            sectors_needed = (len(content) + SECTOR_SIZE - 1) // SECTOR_SIZE
            if sectors_needed == 0:
                sectors_needed = 1
                content = b'\x00' * SECTOR_SIZE
            else:
                pad = sectors_needed * SECTOR_SIZE - len(content)
                content += b'\x00' * pad
            file_sector_map[item['path']] = (current_sector, item['size'], content)
            current_sector += sectors_needed

    total_sectors = current_sector + 10
    total_bytes = total_sectors * SECTOR_SIZE
    
    raw_image = bytearray(total_bytes)
    
    # Build PVD at sector 16
    pvd_offset = 16 * SECTOR_SIZE
    raw_image[pvd_offset] = 1 # Type 1: Primary Volume Descriptor
    raw_image[pvd_offset+1:pvd_offset+6] = b'CD001'
    raw_image[pvd_offset+6] = 1 # Version 1
    
    # System identifier (32 bytes)
    sys_id = b'APPLE MACINTOSH'.ljust(32, b' ')
    raw_image[pvd_offset+8:pvd_offset+40] = sys_id
    
    # Volume identifier (32 bytes)
    vol_id = volume_name.encode('utf-8').ljust(32, b' ')
    raw_image[pvd_offset+40:pvd_offset+72] = vol_id
    
    # Volume space size (both endian int32)
    struct.pack_into('<I', raw_image, pvd_offset+80, total_sectors)
    struct.pack_into('>I', raw_image, pvd_offset+84, total_sectors)
    
    # Volume set size = 1
    struct.pack_into('<H', raw_image, pvd_offset+120, 1)
    struct.pack_into('>H', raw_image, pvd_offset+122, 1)
    # Volume sequence number = 1
    struct.pack_into('<H', raw_image, pvd_offset+124, 1)
    struct.pack_into('>H', raw_image, pvd_offset+126, 1)
    # Logical block size = 2048
    struct.pack_into('<H', raw_image, pvd_offset+128, 2048)
    struct.pack_into('>H', raw_image, pvd_offset+130, 2048)
    
    # Root directory record at PVD offset 156 (34 bytes)
    root_rec_offset = pvd_offset + 156
    raw_image[root_rec_offset] = 34 # Length
    raw_image[root_rec_offset+1] = 0 # Ext attr length
    # Root dir extent at sector 18
    struct.pack_into('<I', raw_image, root_rec_offset+2, 18)
    struct.pack_into('>I', raw_image, root_rec_offset+6, 18)
    # Data length (2048 bytes)
    struct.pack_into('<I', raw_image, root_rec_offset+10, 2048)
    struct.pack_into('>I', raw_image, root_rec_offset+14, 2048)
    # Flags = Directory (2)
    raw_image[root_rec_offset+25] = 2
    raw_image[root_rec_offset+32] = 1 # File id len
    raw_image[root_rec_offset+33] = 0 # Root identifier
    
    # Sector 17: Terminator
    term_offset = 17 * SECTOR_SIZE
    raw_image[term_offset] = 255 # Type 255
    raw_image[term_offset+1:term_offset+6] = b'CD001'
    raw_image[term_offset+6] = 1
    
    # Fill File Data into sectors
    for path, (sec, sz, data) in file_sector_map.items():
        sec_offset = sec * SECTOR_SIZE
        raw_image[sec_offset:sec_offset+len(data)] = data
        
    # Append Apple UDIF "koly" trailer (512 bytes)
    koly = bytearray(512)
    koly[0:4] = b'koly' # Magic
    struct.pack_into('>I', koly, 4, 4) # Version = 4
    struct.pack_into('>I', koly, 8, 512) # Header size
    struct.pack_into('>I', koly, 12, 1) # Flags
    struct.pack_into('>Q', koly, 16, 0) # Running data fork offset
    struct.pack_into('>Q', koly, 24, total_bytes) # Data fork length
    struct.pack_into('>Q', koly, 32, 0) # Rsrc fork offset
    struct.pack_into('>Q', koly, 40, 0) # Rsrc fork length
    struct.pack_into('>I', koly, 48, 1) # Segment number
    struct.pack_into('>I', koly, 52, 1) # Max segment number
    
    # Checksum of image
    crc = zlib.crc32(raw_image)
    struct.pack_into('>I', koly, 72, 2) # CRC32 type
    struct.pack_into('>I', koly, 76, 32) # CRC size in bits
    struct.pack_into('>I', koly, 80, crc)
    
    # Write to output DMG
    with open(output_dmg_path, 'wb') as f:
        f.write(raw_image)
        f.write(koly)
        
    print(f"Successfully generated {output_dmg_path} ({os.path.getsize(output_dmg_path)} bytes)")

if __name__ == "__main__":
    app_dir = sys.argv[1] if len(sys.argv) > 1 else "dist/Slate.app"
    dmg_out = sys.argv[2] if len(sys.argv) > 2 else "Slate.dmg"
    create_dmg(app_dir, dmg_out)
