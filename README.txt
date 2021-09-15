---------------------------------------------------------------------------------
-- 
-- Arcade: Xevious port to MiSTer by Sorgelig
-- 23 October 2017
-- 
---------------------------------------------------------------------------------
-- Xevious by Dar (darfpga@aol.fr) (01 May 2017)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- gen_ram.vhd
-------------------------------- 
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
---------------------------------------------------------------------------------
-- T80/T80se - Version : 0247
-----------------------------
-- Z80 compatible microprocessor core
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
---------------------------------------------------------------------------------
-- 
-- Support screen and controls rotation on HDMI output.
-- Only controls are rotated on VGA output.
-- 
-- 
-- Keyboard inputs :
--
--   F3          : Add coin
--   F2          : Start 2 players
--   F1          : Start 1 player
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--   SPACE       : Fire  
--   CTRL        : Bomb
--
-- Joystick support.
-- 
----------------------------------------------

Hiscore save/load:

Save and load of hiscores is supported for this core:

To save your hiscores manually, press the 'Save Settings' option in the OSD.  Hiscores will be automatically loaded when the core is started.

To enable automatic saving of hiscores, turn on the 'Autosave Hiscores' option, press the 'Save Settings' option in the OSD, and reload the core.  Hiscores will then be automatically saved (if they have changed) any time the OSD is opened.

Hiscore data is stored in /media/fat/config/nvram/ as ```<mra filename>.nvm```

---------------------------------------------------------------------------------

                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip
