cmake_minimum_required(VERSION 3.20.0)

set(BOARD_FLASH_RUNNER nrfjprog)

macro(app_set_runner_args)
  # Default jlink runner uses JLinkGDBServer executable that requires GUI (fails to connect to X).
  board_runner_args(jlink "--speed=4000" --gdbserver=JLinkGDBServerCL)
endmacro()

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(blinky_app)

target_sources(app PRIVATE src/main.c)
