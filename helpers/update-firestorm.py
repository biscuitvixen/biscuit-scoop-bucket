#!/usr/bin/env python3

import argparse
import hashlib
import json
import sys
import subprocess
import os
from pathlib import Path

URL_TEMPLATE = "https://downloads.firestormviewer.org/preview/windows/Phoenix-Firestorm-Betax64_AVX2-{}_Setup.exe"


def setup_venv():
    """Create and setup virtual environment with required packages."""
    venv_path = Path(__file__).parent / "venv"
    
    if not venv_path.exists():
        print("🔧 Creating virtual environment...")
        subprocess.run([sys.executable, "-m", "venv", str(venv_path)], check=True)
    
    # Always check if requests is installed
    pip_path = venv_path / "Scripts" / "pip.exe"
    python_path = venv_path / "Scripts" / "python.exe"
    
    try:
        # Test if requests is available in venv
        result = subprocess.run([str(python_path), "-c", "import requests"], 
                              capture_output=True, check=False)
        if result.returncode != 0:
            print("📦 Installing requests in virtual environment...")
            subprocess.run([str(pip_path), "install", "requests"], check=True)
    except FileNotFoundError:
        print("❌ Virtual environment setup failed")
        sys.exit(1)
    
    return python_path


def run_with_venv():
    """Re-run this script using the virtual environment Python."""
    venv_python = setup_venv()
    print("🔄 Re-running script with virtual environment...")
    
    # Pass all original arguments to the venv Python
    cmd = [str(venv_python), __file__] + sys.argv[1:]
    result = subprocess.run(cmd)
    sys.exit(result.returncode)


def download_installer(hyphen_version: str, dest: Path) -> Path:
    """Download the Firestorm installer and return the path."""
    url = URL_TEMPLATE.format(hyphen_version)
    filename = dest / Path(url).name
    print(f"⬇️ Downloading {url} ...")
    
    try:
        import requests
        response = requests.get(url, stream=True)
        response.raise_for_status()
    except requests.HTTPError as e:
        if e.response.status_code == 404:
            print(f"❌ Error: Version not found at {url}")
            sys.exit(1)
        else:
            print(f"❌ HTTP error while downloading: {e}")
            sys.exit(1)
    except requests.RequestException as e:
        print(f"❌ Network error: {e}")
        sys.exit(1)

    with open(filename, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)

    return filename


def calculate_sha256(filepath: Path) -> str:
    """Calculate SHA256 hash of the file."""
    print("🔐 Calculating SHA256...")
    hash_sha256 = hashlib.sha256()
    with filepath.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            hash_sha256.update(chunk)
    return hash_sha256.hexdigest().upper()


def update_manifest(manifest_path: Path, dotted_version: str, hyphen_version: str, checksum: str):
    """Update the Scoop manifest with new version and hash."""
    print("📝 Updating manifest...")
    
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)
    
    # Update version
    manifest['version'] = dotted_version
    
    # Update URL and hash
    manifest['architecture']['64bit']['url'] = URL_TEMPLATE.format(hyphen_version)
    manifest['architecture']['64bit']['hash'] = f"sha256:{checksum}"
    
    # Write back to file with nice formatting
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)


def cleanup_temp_files(temp_files: list[Path]):
    """Remove temporary downloaded files."""
    print("🧹 Cleaning up temporary files...")
    for file_path in temp_files:
        if file_path.exists():
            file_path.unlink()
            print(f"   Removed {file_path.name}")


def main():
    # Check if requests is available, if not, set up venv and re-run
    try:
        import requests
    except ImportError:
        print("⚠️  requests not found, setting up virtual environment...")
        run_with_venv()
        return  # This won't be reached, but for clarity

    parser = argparse.ArgumentParser(description="Update Firestorm Beta Scoop manifest.")
    parser.add_argument("version", help="New Firestorm version (e.g. 7.2.0.78879)")
    parser.add_argument("--keep-temp", action="store_true", 
                       help="Keep temporary downloaded files (don't clean up)")
    args = parser.parse_args()

    dotted_version = args.version
    hyphen_version = dotted_version.replace(".", "-")

    workdir = Path(__file__).resolve().parent.parent  # Go up one level from helpers/
    manifest_path = workdir / "bucket" / "firestorm-beta.json"
    temp_dir = Path(__file__).resolve().parent / "temp"  # Keep temp in helpers/
    temp_dir.mkdir(exist_ok=True)

    if not manifest_path.exists():
        print(f"❌ Error: Manifest not found at {manifest_path}")
        sys.exit(1)

    try:
        # Download and verify the installer
        installer_path = download_installer(hyphen_version, temp_dir)
        checksum = calculate_sha256(installer_path)
        
        # Update the manifest
        update_manifest(manifest_path, dotted_version, hyphen_version, checksum)
        
        print(f"✅ Done. Updated firestorm-beta to version {dotted_version}.")
        print(f"📋 SHA256: {checksum}")
        print("💡 Next steps:")
        print("   git add bucket/firestorm-beta.json")
        print(f"   git commit -m \"Update firestorm-beta to {dotted_version}\"")
        print("   git push")
        print("   scoop update firestorm-beta")
        
    finally:
        # Clean up temporary files unless --keep-temp is specified
        if not args.keep_temp:
            cleanup_temp_files([installer_path] if 'installer_path' in locals() else [])


if __name__ == "__main__":
    main()