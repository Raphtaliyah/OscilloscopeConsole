SRCDIR=src/
BUILDDIR=build/

ASSEMBLER=as89lp
ASFLAGS=-losxff -i '.include \src/Definitions/CPU/lp51ed2.sfr\'
ASDIR=$(BUILDDIR)Assembler/

LINKER=aslink
LINKERFLAGS=-mxiu -b CODE=0x6B -b VECTOR=0x0 -b XDATA=0xA00 -b BIT=0x08 -b DATA=0x30
LINKERIN:=
LINKERDIR=$(BUILDDIR)Linker/
LINKEROUT=$(LINKERDIR)output

HEXBIN=hexbinw
BINDIR=$(BUILDDIR)Binary/
BINOUT=$(BINDIR)rom.bin

PROGRAMMERPORT=COM3.

SOURCES:=\
System/Application/Loaders/RomLoader.asm\
System/Application/ApplicationManager.asm\
System/Application/ApplicationMessage.asm\
System/Application/RootApplication.asm\
System/Display/Graphics/Graphics.asm\
System/Display/Graphics/ASCII.asm\
System/Display/Graphics/Drawing.asm\
System/Display/Graphics/Render.asm\
System/Display/Display.asm\
System/Display/FrameHandler.asm\
System/Devices/Controller/Controller.asm\
System/Devices/Nixie/Nixie.asm\
System/Devices/StatusLed/StatusLed.asm\
System/Devices/Sound/Sound.asm\
System/Drivers/ADC/MCP3201.asm\
System/Drivers/Clock/SystemClockConfig.asm\
System/Drivers/Clock/TPS.asm\
System/Drivers/DAC/TLC7226.asm\
System/Drivers/GPIO/MCP32S17.asm\
System/Drivers/PCA/PCA.asm\
System/Drivers/Port/PortConfiguration.asm\
System/Drivers/SD/SD.asm\
System/Drivers/SPI/SPI.asm\
System/Drivers/UART/Serial.asm\
System/Drivers/UART/Extensions.asm\
System/Math/Integer/Exponentiation.asm\
System/Math/Integer/Random.asm\
System/Memory/Allocator.asm\
System/Memory/Controller.asm\
System/Memory/MemoryDump.asm\
System/Memory/Memset.asm\
System/Memory/Memcpy.asm\
System/Output/Extensions.asm\
System/Output/StandardOut.asm\
System/Time/Millis.asm\
System/Time/SpinWait.asm\
System/Types/InvocationArray.asm\
System/Utilities/Memory.asm\
System/Utilities/String.asm\
System/Utilities/ToString.asm\
System/Boot.asm\
System/Interrupt.asm\
System/Main.asm\
System/ErrorHandling/Error.asm\
System/ParamStack.asm\
Applications/Terminal/TerminalMain.asm\
Applications/Menu/MenuMain.asm\
Applications/Menu/Render.asm\
Applications/Menu/Resources.asm\
Applications/Pong/PongMain.asm\
Applications/Pong/Graphics.asm\
Applications/Pong/Resources.asm\
Applications/Snake/SnakeMain.asm\
Applications/Snake/Graphics.asm\
Applications/Snake/Resources.asm\
Applications/Options/OptionsMain.asm\


this: $(SOURCES)
	
	-@mkdir $(subst /,\,$(LINKERDIR)) 2> NUL
	$(LINKER) $(LINKERFLAGS) $(LINKEROUT) $(LINKERIN) -e
	
	-@mkdir $(subst /,\,$(BINDIR)) 2> NUL
	$(HEXBIN) $(subst /,\,$(LINKEROUT).ihx $(BINOUT))

	make upload

%.asm:
	-@mkdir $(subst /,\,$(ASDIR)$(@D)) 2> NUL
	$(ASSEMBLER) $(ASFLAGS) $(ASDIR)$* $(SRCDIR)$*
	$(eval LINKERIN := $(LINKERIN) $(ASDIR)$*)

upload:
	8051Programmer -p $(PROGRAMMERPORT) -f $(BINOUT) -ev -t CODE

clean:
	rmdir /s /q $(subst /,\,$(BUILDDIR))