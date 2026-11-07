debImport "-dbdir" "simv.daidir"
debLoadSimResult "dump_spi_adc.fsdb"
wvCreateWindow
wvRestoreSignal -win $_nWave2 "soc_spi_adc_signals.rc" -overWriteAutoAlias on -appendSignals on
wvZoom -win $_nWave2 0 25000000
wvSetCursor -win $_nWave2 5000000
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiSetActWin -win $_nWave2
