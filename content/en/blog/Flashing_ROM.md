---
title: "Rebellion via MDM Prison Break with Odin (Part I)"
date: 2025-12-05
tags: ["custom-ROM", "mdm", "odin","heimdall"]
---

This is the first part of my blog where I attempt to flash a new OS into a tablet, that has been carrying a firmware, locked down with heavy restrictions.


For context, I've got my hands on a government-provided Samsung tablet (won't be disclosing model or the provider for paranoia-reasons) which has been "locked" for general usage, and allows only 8 applications that can be used (restricted using a third party MDM software), strictly for academic purposes (including instagram for whatever reasons?).

Now, older versions of these kind of third-party MDM launchers can be disabled by simply:

- Rebooting into safe mode.
- Changing default launcher from third party restrictive software to system launcher.

That should work fine... in older tablets (Similar to the Byju's ones). But the one I have, has even restricted the option to reboot into safe mode. I've tried to perform a factory reset, but even the stock recovery menu (which appears holding on vol. up + power button when it's switched-off) was hidden! Talk about government control!

Now, the most impulsive (and fun) choice would be to flash a whole new ROM (Custom OS) and take over the bootloader, and make the tablet a pet gadget which I'd use however I want. Now, for


## Getting Started


I went on to search for different tools to flash firmware into the tablet, and found [Odin](https://odindownload.com/), a ROM Flashing tool for SAMSUNG Android devices. But it works for windows (ew), so I found a linux alternative, i.e, [Heimdall](https://glassechidna.com.au/heimdall/) to get the job done.

I went to [SamFw](https://samfw.com/) obviously, for financial reasons, and got the exact firmware for my device. Remember to keep an eye and NOT to download the whole factory version (that ends with `_fac`). You need the CHILD files instead. Specifically,
1. `AP_*_user_low_ship_MULTI_CERT_meta*.zip`
2. `BL_*_user_low_ship*.zip`
3. `CSC_ODM_*_user_low_ship_*.zip`

Save these and extract with `tar -xvf <filename>`. There'll be multiple images in each tar file, we'll be mapping them with PIT. 

After trying some painful stuff out, I found something depressing about the Tablet. It WAS NOT using Samsung/Odin's partitions, it was using a MediaTek PIT layout. What this means, is that heimdall CANNOT flash these onto my device(heimdall can work with older exynos based firmware). The depressing part of the problem is that I have to go to windows, and use Odin to do the job.

Now, these are the steps to follow to flash the firmware with odin:

1. Go into the download mode on tablet, and connect it with your PC. You should see "<DEVICE ID> Added!!" in it immediately.
2. Now, load the firmware files into Odin. (You'll see buttons for each image)
3. And for a security check, go to options and ensure only `Auto Reboot` and `Reset Time` have been checked.
4. Now click `START` and wait until Odin displays `welcome!` with a start button.

## Congratulations. 

We've now flashed new firmware, and CAN use it as a normal Samsung tablet. BUT we're only halfway done. I've been writing this since a week and now I've realised the blog *may* need a third part, but We'll get to it later.

### NOTE!

This is NOT our final goal. We need to install a custom OS in the tablet, which requires OEM Unlock from the device. In most of the devices, the option appears in `Developer Options` in a week or so. We'll be doing rest of that after it appears.

Until then, Enjoy your brand new Samsung Tablet(Well, new on atleast the software part).
