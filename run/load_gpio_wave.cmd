debImport "-dbdir" "simv.daidir"
debLoadSimResult "dump_gpio.fsdb"
wvCreateWindow
wvRestoreSignal -win $_nWave2 "soc_gpio_signals.rc" -overWriteAutoAlias on -appendSignals on
wvZoom -win $_nWave2 0 10000000
wvSetCursor -win $_nWave2 1500000
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiSetActWin -win $_nWave2
