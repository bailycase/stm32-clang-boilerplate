#include "system.h"

#define CPU_FREQ 100000000
#define SYSTICK_FREQ 1000

volatile uint64_t ticks = 0;

uint64_t get_ticks(void) {
  return ticks;
}

void sys_tick_handler(void) {
  ticks++;
}

void systick_setup(void) {
  systick_set_frequency(SYSTICK_FREQ, CPU_FREQ);
  systick_counter_enable();
  systick_interrupt_enable();
}
