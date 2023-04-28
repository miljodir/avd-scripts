# avd-scripts
Installation scripts for software to be installed on AVD - Azure Virtual Desktop

Scripts in this repo will be used to install and update software on AVD hosts.

## Logic

Core logic:
- Ensure winget is installed on the underlying host
- Create a `<hostpoolname>-choco.jsonc` file in the programs folder, one per hostpool
- Find packages you wish to update/install, add to file
- Use chocolatey if there are packages you cannot find in winget
- Call the Install.ps1 script from whatever works (e.g. CustomScriptExtension on virtual machine, Github Actions workflow)
  - Implementation not decided yet.
- Use software.

## Future

Future ideas:

- Github actions to validate software lists in [programs](./programs)
- Test installation scripts via Github Actions
- Default profiles for PowerShell, bash
- AKS: Add default color theme / current cluster visible in context.

Ideas and contributions are welcome.