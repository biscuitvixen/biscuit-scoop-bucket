# Bucket Helper Scripts

This directory contains maintenance and update scripts for the Scoop bucket.

## Firestorm Beta Updater

### Files
- `update-firestorm.py` - Main update script
- `update-firestorm.bat` - Windows batch wrapper
- `venv/` - Auto-created virtual environment (contains dependencies)

### Usage

#### Update to a specific version:
```powershell
.\helpers\update-firestorm.bat 7.2.1.78900
```

#### Or run the Python script directly:
```powershell
python .\helpers\update-firestorm.py 7.2.1.78900
```

#### Keep temporary files for debugging:
```powershell
.\helpers\update-firestorm.bat 7.2.1.78900 --keep-temp
```

### What it does

1. **Downloads** the Firestorm installer from the official preview server
2. **Calculates** SHA256 hash automatically
3. **Updates** `bucket/firestorm-beta.json` with:
   - New version number
   - New download URL
   - New SHA256 hash
4. **Cleans up** temporary files automatically
5. **Shows** the git commands to run next

### Complete Update Workflow

1. **Run the updater:**
   ```powershell
   .\helpers\update-firestorm.bat 7.2.1.78900
   ```

2. **Review the changes:**
   ```powershell
   git diff bucket/firestorm-beta.json
   ```

3. **Commit and push:**
   ```powershell
   git add bucket/firestorm-beta.json
   git commit -m "Update firestorm-beta to 7.2.1.78900"
   git push
   ```

4. **Update locally:**
   ```powershell
   scoop update firestorm-beta
   ```

### Requirements

- Python 3.7+
- Internet connection
- The script automatically handles virtual environment setup and `requests` library installation

### First Run

The first time you run the script, it will:
- Create a `venv/` directory
- Install the `requests` library
- Re-run itself using the virtual environment

Subsequent runs will be faster as they use the existing virtual environment.

### Troubleshooting

**"Module not found" errors:** The script should handle this automatically by setting up a virtual environment. If issues persist, try deleting the `venv/` folder and running again.

**Network errors:** Ensure you have internet access and the Firestorm download servers are accessible.

**Permission errors:** Make sure you have write access to the bucket directory.
