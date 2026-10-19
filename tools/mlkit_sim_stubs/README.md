# ML Kit stubs (iOS simulator only)

Google ML Kit has no arm64 iOS-simulator build, and current simulators only run arm64 apps.
`tools/run_sim.sh` swaps ML Kit for these empty stubs while running on a simulator, then
restores everything. They never detect faces or text. Never use them for device/release builds.
