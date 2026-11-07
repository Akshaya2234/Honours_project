debImport "-dbdir" "simv.daidir"
debLoadSimResult "dump_uart.fsdb"
wvCreateWindow
wvRestoreSignal -win $_nWave2 "soc_uart_signals.rc" -overWriteAutoAlias on -appendSignals on
wvZoom -win $_nWave2 0 450000000
wvSetCursor -win $_nWave2 82995000
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiSetActWin -win $_nWave2
