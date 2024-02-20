#include <stdio.h>
#include <time.h>
#include <string>

#include <lean/lean.h>

extern "C" lean_obj_res formatLocalTime() {
    time_t rawtime;
    struct tm *timeinfo;
    char buffer[80];
    time(&rawtime);
    timeinfo = localtime(&rawtime);
    strftime(buffer, sizeof(buffer), "%c", timeinfo);
    return lean_io_result_mk_ok(lean_mk_string(buffer));
}
