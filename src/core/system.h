#ifndef SYSTEM_H
#define SYSTEM_H

#include <stdint.h>
#include <libopencm3/cm3/nvic.h>
#include "libopencm3/cm3/systick.h"


uint64_t get_ticks(void);

void systick_setup(void);

void sys_tick_handler(void);

void system_setup(void);

#endif
