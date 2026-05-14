# SQL Server Reporting Services

To open an RPTPROJ file (SQL Server Reporting Services project) in Visual Studio 2022, you'll need to install the appropriate extension, because SSRS support is not included by default.

**Step 1. Install SQL Server Data Tools (SSDT)**

- Open Visual Studio 2022
- Go to Extensions → Manage Extensions
- Search for "Microsoft Reporting Services Projects"
- Install the extension and restart Visual Studio

**Step 2. Alternative: Install via Visual Studio Installer**

- Open Visual Studio Installer
- Modify your VS 2022 installation
- Under "Individual components," look for and select:
    - "SQL Server Data Tools"
    - "Microsoft Reporting Services Projects"

**Step 3. Open the project**

Once the extension is installed:

- File → Open → Project/Solution
- Navigate to your .rptproj file
- Select and open it

!!! note
    The Microsoft Reporting Services Projects extension is the official way to work with SSRS projects in VS 2022. Make sure you have the latest version of the extension for best compatibility. Some older RPTPROJ files may need to be upgraded when you open them in VS 2022.
