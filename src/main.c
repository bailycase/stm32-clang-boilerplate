#include "core/system.h"
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/rcc.h>

#define LED_PORT GPIOC
#define LED_PIN GPIO13

static void gpio_setup(void) {
  rcc_periph_clock_enable(RCC_GPIOC);
  gpio_mode_setup(LED_PORT, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, LED_PIN);
}

int main(void) {
  systick_setup();
  rcc_clock_setup_pll(&rcc_hsi_configs[RCC_CLOCK_3V3_84MHZ]);
  gpio_setup();

  uint64_t start_time = get_ticks();

  while (1) {
    if(get_ticks() - start_time >= 1000) {
      gpio_toggle(LED_PORT, LED_PIN);
      start_time = get_ticks();
    }
  }

  return 0;
}
