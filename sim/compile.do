quit -sim
file delete -force work

vlib work

vlog -sv +incdir+../rtl/axi/include +incdir+../rtl/cc/include -f files_axi.f -suppress 2643,2583,13314
vlog -f files_rtl.f -f files_sim.f +incdir+../rtl +incdir+../svas/ +define+INCLUDE_SVAS -suppress 2643,2583,13314

vopt +acc tb -o tbopt -suppress 2643,2583,13314
vsim tbopt -onfinish "stop"

log -r /*
do wave.do
onbreak {wave zoom full}
#run -all
wave zoom full
