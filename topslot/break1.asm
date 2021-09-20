	;; Bootable Datapack for Top Slot Breakout
	;; Tests the hardware and provides framework for
	;; further hardware to be attached to breakout

	;; Header
	;; ======
	;; Comments from the technical manual

	
	;; A pack which is BOOTABLE must have the following header information in 
	;; the first six bytes of the pack:

	.ORG 0

	;; ADDRESS     DESCRIPTION

	;;    0        DATAPACK_CONTROL_BYTE
	;;    1        DATAPACK_SIZE_BYTE
	;;    2        DEVICE_OR_CODE_BYTE
	;;    3        DEVICE_NUMBER_BYTE
	;;    4        DEVICE_VERSION_BYTE
	;;    5        DEVICE_PRIORITY_BYTE
	;;    6        DEVICE_CODE_ADDRESS_WORD

	
	;; Control Byte
	;; ============
	
	;;     Bit NO.     BIT NAME        DESCRIPTION

        ;; 0       N/A             This is clear for a valid MKII
        ;;                         Organiser pack.
        ;; 1       EPROM           This is set if the pack is an eprom
        ;;                         pack (cleared if it is a ram pack).
        ;; 2       PGCPK           This is set if the pack is page counted.

        ;; 3       RDWRT           This is cleared if the pack is write
        ;;                         protected.
        ;; 4       NOBOOT          This is cleared if the pack is bootable.

        ;; 5       COPYPK          This is set if the pack is copyable.

        ;; 6       NYIMPL          This is normally set as it is reserved
        ;;                         for future expansion.

        ;; 7       MK1PAK          This is set if the pack is a MKI
        ;;                         Organiser pack.

	.BYTE  $6A

	;; DATAPACK_SIZE_BYTE
	;; ==================
	;;
	;;      This byte contains the number of 8K blocks in the datapack.   It  will
	;; have one of the following values:
	
	;;      1.    8K - 1
	;;      2.   16K - 2
	;;      3.   32K - 4
	;;      4.   64K - 8
	;;      5.  128K - 16

	.BYTE  $04

	;; DEVICE_OR_CODE_BYTE	
	;; ===================
	
	;;      This byte is used for descriptive purposes only.  It should be set  to
	;; 0  the  device  is  a  software  application  with  no additional hardware,
	;; otherwise it should be set to 1.

	.BYTE $01

	;; DEVICE_NUMBER_BYTE
	;; ==================
	
	;;      This byte contains the device number of the code extension or hardware
	;; device.
	
	;;      As more than one device can be "BOOTED" into the operating system,  it
	;; is  necessary to have a mechanism to identify each of the devices currently
	;; booted.  This is accomplished by having a unique  device  number  for  each
	;; device.
	
	;;      The device number is a value in the  range  $01  to  $FF.   However  a
	;; number of these are reserved by Psion and should not be used.  The reserved
	;; numbers are in the range $80 to $C0 and $01 to $40.  Psion already supplies
	;; a number of devices whose device numbers are as follows:
	
	;;      1.  RS232 INTERFACE - $C0
	
	;;      2.  BAR CODE INTERFACE - $BF
	
	;;      3.  SWIPE READER INTERFACE - $BE
	
	;;      4.  CONCISE OXFORD SPELLING CHECKER - $0A
	
	
	;; By convention devices which do not  have  an  hardware  interface  are
	;; allocated  device  numbers  in  the  range  $01  to  $40 and devices with a
	;; hardware interface are allocated device numbers in the range $80 to $C0.

	.BYTE $C0



	;; DEVICE_VERSION_BYTE
	;; ====================
	
	;;      This byte contains the release version number  of  the  device.   This
	;; byte  is  not  used  by  the  operating  system and is only for documentary
	;; purposes.
	
	;;      By convention version numbers are N.M and the byte is  formed  by  the
	;; following:
	
	;;      VERSION_BYTE = N*16+M
	
	;;      Thus for a version number of 2.3 the  byte  will  have  the  value  35
	;; ($23).

	.BYTE $25

	;; DEVICE_PRIORITY_BYTE
	;; ====================
	
	;;      This byte determines the  order  in  which  devices  are  booted  into
	;; memory.
	
	;;      The priority byte may have any value in the  range  $1  to  $FF.   The
	;; higher the value the higher the priority of the device.  Thus a device with
	;; priority $FF will be booted before a device with priority $FE.
	
	;;      The DV$BOOT service  scans  all  the  slots  and  builds  a  table  of
	;; priorities from all the bootable packs.  The priorities are then sorted and
	;; each device is loaded in turn.  In the event of a  tie  in  priorities  the
	;; devices will be loaded in the following order:
	
	;;      1.  SIDE SLOT B - SLOT 1
	
	;;      2.  SIDE SLOT C - SLOT 2
	
	;;      3.  TOP SLOT - SLOT 3
	
	
	;;      By convention priorities are the same as the device number.  Thus  the
	;; priorities of Psion's devices are as follows:
	
	;;      1.  RS232 INTERFACE - $C0
	
	;;      2.  BAR CODE INTERFACE - $BF
	
	;;      3.  SWIPE READER INTERFACE - $BE

	;;      4.  CONCISE OXFORD SPELLING CHECKER - $0A
	
	
	;;      By this convention hardware  devices  will  always  be  booted  before
	;; software-only applications such as the concise oxford spelling checker etc.

	.BYTE $c0



	;; DEVICE_CODE_ADDRESS_WORD
	
	;;      This word contains the address on the datapack of the device  code  to
	;; be booted into the operating system.
	
	;;      If the device code immediately  follows  the  8  byte  header  on  the
	;; datapack  then  this  address  will be 8.  However it is often desirable to
	;; have other information on the datapack before the device code and  as  such
	;; this word allows the device code to be anywhere on the datapack.

	.WORD $0008

	
	;; ================================================================================
	;; ================================================================================
	
	;; 
	;; Data to write is passed in Accumulator B

	CS3     .EQU    1<<3
	POB_PORT .EQU   $03
	
	PSHB 	;save data	
	LDAB    #3 	;select Top slot
	;; os 	pk$setp 	;and turn on power
	;; OIM 	CS3,POB_PORT6 	;deselect Top slot
	;; OIM 	0E,POB_PORT6 	;set SOE high
	;; OIM 	^xFF,POB_DD2 	;set port 2 to output
	PULB		 	;restore data
	STAB    POB_PORT 	;Output data on port 2
	;; AIM 	^C<CS3>,POB_PORT6 	;take SS3 low
	;; OIM 	CS3,POB_PORT6 	;take SS3 high
	;; AIM 	0,POB_DDR2 	;set port 2 to input
	;; AIM 	^C<0E>,POB_PORT6 	;take SOE low.

	.ORG 41234


	
;; Location 	Mnemonic 	Address
;; Port 6 Data register 	Pob_port6 	$17
;; Port 2 Data register 	Pob_port2 	$03
;; Port 2 Data direction Register 	Pob_DDR2 	$01
