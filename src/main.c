#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

#define LED0_LABEL DT_NODELABEL(led0)

#if DT_NODE_HAS_STATUS(LED0_LABEL, okay)
static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(LED0_LABEL, gpios);
#else
#error "led0 devicetree alias is not defined or not enabled"
#endif


int main(void)
{
    int ret;
    bool led_state = false;
    
    LOG_INF("Starting LED test...");

    /* Check if LED GPIO device is ready */
    if (!gpio_is_ready_dt(&led)) {
        LOG_ERR("LED GPIO device not ready");
        return -1;
    }
    
    /* Configure LED pin as output */
    ret = gpio_pin_configure_dt(&led, GPIO_OUTPUT_INACTIVE);
    if (ret < 0) {
        LOG_ERR("Failed to configure LED pin: %d", ret);
        return -1;
    }
    
    while (1) {
        led_state = !led_state;
        ret = gpio_pin_set_dt(&led, led_state);
        if (ret < 0) {
            LOG_ERR("Failed to set LED state: %d", ret);
        } else {
            LOG_INF("LED toggled to %s", led_state ? "ON" : "OFF");
        }
        
        k_sleep(K_MSEC(1000));
    }
    
    return 0;
}
