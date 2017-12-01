# Makefile

ASM = avra
PROG = avrdude
PROJNAME = IRtranslator
DUMPDIR = eeprom_dumps/
#INCLDIRS = --includedir ../includes

PROGOPTS = -p m8 -E noreset -U $(PROJNAME).hex -U eeprom:w:$(PROJNAME).eep.hex:i
DUMPOPTS = -p m8 -U eeprom:r:$(DUMPDIR)eeprom_dump:d
SOURCES = $(PROJNAME).asm IRreceive.asm IRdecode.asm IRdatabase.asm IRtranslate.asm IRcode.asm IRtransmit.asm
FUNCTIONS = eeprom_write.asm errors.asm registers.asm m8def.inc
LIST = -l $(PROJNAME).list
MAP = -m $(PROJNAME).map

all: program

program: $(PROJNAME).hex
	$(PROG) $(PROGOPTS)

compile: $(PROJNAME).hex

$(PROJNAME).hex: $(SOURCES) $(FUNCTIONS)
	$(ASM) $(INCLDIRS) $(LIST) $(MAP) -o $(PROJNAME) $(PROJNAME).asm

clean:
	rm -f $(PROJNAME).cof $(PROJNAME).eep.hex $(PROJNAME).hex $(PROJNAME).list $(PROJNAME).map $(PROJNAME).obj

dump:
	$(PROG) $(DUMPOPTS)

clean_ee: $(PROJNAME).hex
	$(PROG)	-p m8 -E noreset -U eeprom:w:$(PROJNAME).eep.hex:i
