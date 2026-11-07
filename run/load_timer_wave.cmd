debImport "-dbdir" "simv.daidir"
debLoadSimResult "dump_timer.fsdb"
wvCreateWindow
wvRestoreSignal -win $_nWave2 "soc_timer_signals.rc" -overWriteAutoAlias on -appendSignals on
wvZoom -win $_nWave2 0 16000000
wvSetCursor -win $_nWave2 3500000
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiSetActWin -win $_nWave2
