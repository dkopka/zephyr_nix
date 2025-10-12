{
  description = "A development environment for Zephyr RTOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # nrf-command-line-tools is unfree
          # segger-jlink is unfree
          config.allowUnfree = true;
          config.segger-jlink.acceptLicense = true;
          config.permittedInsecurePackages = [
            "segger-jlink-qt4-874"
          ];
        };
        # Python packages needed for Zephyr
        pythonEnvBase = pkgs.python3.withPackages (ps: with ps; [
          # BASE requirements (zephyr/scripts/requirements-base.txt)
          west                # >= 0.14.0
          pyelftools          # >= 0.29
          pyyaml              # >= 6.0
          pykwalify
          canopen
          packaging
          progress
          patool              # >= 2.0.0
          psutil              # >= 5.6.6
          pylink-square
          pyserial
          requests            # >= 2.32.0
          semver
          tqdm                # >= 4.67.1
          reuse
          anytree
          intelhex
        ]);

        pythonEnvBuildTest = pkgs.python3.withPackages (ps: with ps; [
          # BUILD-TEST requirements (zephyr/scripts/requirements-build-test.txt)
          colorama
          ply                 # >= 3.10
          # gcovr             # >= 6.0 (not in nixpkgs)
          coverage
          pytest
          mypy
          mock                # >= 4.0.1
          junitparser
        ]);

        pythonEnvRunTest = pkgs.python3.withPackages (ps: with ps; [
          # RUN-TEST requirements (zephyr/scripts/requirements-run-test.txt)
          pyocd               # >= 0.35.0
          tabulate
          natsort
          cbor2               # >= 1.0.0
          psutil              # >= 5.6.6
          python-can          # >= 4.3.0
          spdx-tools
        ]);

        pythonEnvCompliance = pkgs.python3.withPackages (ps: with ps; [
          # COMPLIANCE requirements (zephyr/scripts/requirements-compliance.txt)
          # clang-format      # (separate package)
          # gitlint           # (separate package)
          junitparser         # >= 2
          lxml                # >= 5.3.0
          pykwalify
          pylint              # >= 3
          python-magic        # file type detection (Linux)
          ruff                # >= 0.11.11
          # sphinx-lint       # (not in nixpkgs)
          unidiff
          # vermin            # (separate package)
          yamllint
        ]);

        pythonEnvExtras = pkgs.python3.withPackages (ps: with ps; [
          # EXTRAS requirements (zephyr/scripts/requirements-extras.txt)
          anytree
          gitpython           # >= 3.1.41
          # gitlint           # (separate package)
          junit2html
          lpc_checksum
          spsdk               # == 2.6.0
          pillow              # >= 10.3.0
          pygithub
          graphviz
        ]);

        zephyr-sdk-minimal = pkgs.stdenv.mkDerivation rec {
          pname = "zephyr-sdk";
          version = "0.17.4";

          src = pkgs.fetchurl {
            url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/zephyr-sdk-${version}_linux-aarch64_minimal.tar.xz";
            sha256 = "sha256-R36t/ZKE6l9doQbSAWWSmRTsTrqn5FqvJwKTGh6G54o=";
          };

          nativeBuildInputs = [ pkgs.autoPatchelfHook ];

          installPhase = ''
            mkdir -p $out
            cp -r * $out/
          '';
        };
      in
     {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core development tools
            git
            cmake
            ninja
            gperf
            ccache
            dfu-util
            mcuboot-imgtool

            # ARM Cortex-M embedded toolchain
            gcc-arm-embedded
            # Minimal Zephyr SDK
            zephyr-sdk-minimal

            # Python environment with Zephyr tools
            pythonEnvBase
            # Enable optional packages if needed
            # pythonEnvBuildTest
            # pythonEnvRunTest
            # pythonEnvCompliance
            # pythonEnvExtras

            # Additional tools
            dtc
            openocd
            gdb
            minicom
            screen

            # Nordic tools
            nrf-command-line-tools

            # J-Link tools
            segger-jlink

            # Compliance & code quality tools
            clang-tools     # includes clang-format >= 15.0.0
            ruff            # Python linter/formatter
            graphviz        # for devicetree dependency graphs
            yamllint        # YAML linting
          ];

          shellHook = ''
            # Set up environment variables
            export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
            export GNUARMEMB_TOOLCHAIN_PATH="${pkgs.gcc-arm-embedded}"
            export ZEPHYR_SDK_INSTALL_DIR="${zephyr-sdk-minimal}"

            # Initialize west workspace if not already done
            if [ ! -f ../.west/config ]; then
              echo "Initializing west workspace..."
              west init -l .
              west update
            fi

            # Source Zephyr environment
            if [ -f ../zephyr/zephyr-env.sh ]; then
              source ../zephyr/zephyr-env.sh
              echo "✅ Zephyr environment activated"
            else
              echo "⚠️  Run 'west update' to fetch Zephyr source"
            fi

            echo "Project root:        $(pwd)"
            echo "Zephyr SDK:          ${zephyr-sdk-minimal}"
            echo "Toolchain:           ${pkgs.gcc-arm-embedded}"
            echo "Available commands:"
            echo "     west build -b nrf52840dk/nrf52840 ."
            echo "     west flash"
            echo "     west debug"
          '';
        };
      }
    );
}
