# LFTP4WIN Legacy Installer

This is a modified version of the original LFTP4WIN installer ([userdocs/LFTP4WIN](https://github.com/userdocs/LFTP4WIN)) with the only purpose being supporting older 32-bit operating systems. **For modern 64-bit systems, use the original installer.**

What's changed:
- fixed support for 32-bit Windows due to cygwin sunsetting their 32-bit Windows support, removed support for 64-bit Windows

What's planned to change:
- option to use curl instead of bitsadmin, which struggles with HTTPS transfers on older systems (or is outright non-functional/removed on modified versions of Windows)
