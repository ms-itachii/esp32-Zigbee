# Contributing

Contributions are welcome and appreciated! Whether you want to add a new Zigbee app example, fix a bug, improve the Docker setup, or clarify something in the docs. Feel free to jump in.

## How to contribute

1. **Fork** the repository on GitHub
2. Clone your fork and create a branch for your changes
3. Make your changes and make sure the project still builds inside the container
4. Open a **Pull Request** against `main` with a short description of what you did and why

If you're not sure where to start or want to discuss an idea before building it, just open an issue. I would be happy to help.

## Ideas for contributions

- New Zigbee app examples that go beyond the basics (see note below)
- Support for additional ESP32 targets
- Docker or toolchain improvements
- Documentation fixes and clarifications
- CI/CD improvements

## On app examples

Espressif already provides a set of basic Zigbee examples in their official ESP-IDF and esp-zigbee-sdk repositories. Please **don't port those here** — they're already available and well maintained upstream.

What this project is looking for instead are **improved or more advanced examples** that tackle topics not covered by the official ones: real-world device behavior, multi-endpoint setups, interoperability with Home Assistant or other coordinators, low-power configurations, OTA, and so on. If your example does something the official repo doesn't, it belongs here.

## Project structure

```
esp32-zigbee/
├── app/                   
│   └── temp_sensor/       # Reference example — follow this layout
├── esp-zigbee-sdk/        
├── Dockerfile
├── docker-compose.yml
└── README.md
```

New app examples should follow the same layout as `temp_sensor` and include a committed `sdkconfig` so the build is reproducible out of the box.
