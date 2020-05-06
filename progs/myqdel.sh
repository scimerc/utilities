#!/bin/tcsh
foreach jobID ( `qstat -u $USER | gawk '$10 != "C"' | cut -d '.' -f 1 | grep -E "^[0-9]+"` )
	qdel ${jobID}
end
