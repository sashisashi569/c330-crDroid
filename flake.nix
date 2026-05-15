{
  description = "crDroid Android 15 build environment for Rakuten Mini (c330ae / SDM439)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Android 15 requires JDK 17
        jdk = pkgs.jdk17;

        # Packages available inside the FHS environment
        fhsPackages = fhsPkgs: with fhsPkgs; [
          # Java
          jdk

          # Python (AOSP requires python3, some scripts need python2 compat)
          python3
          python3Packages.virtualenv

          # Core build tools
          gnumake
          cmake
          ninja
          pkg-config
          autoconf
          automake
          libtool
          m4

          # Version control & repo
          git
          git-lfs
          curl
          wget
          openssh

          # Compilers & linkers
          gcc
          gnumake
          binutils
          lld
          clang

          # Required libraries (FHS paths expected by AOSP)
          zlib
          zlib.dev
          openssl
          openssl.dev
          libxml2
          libxml2.dev
          ncurses
          ncurses.dev
          ncurses5
          readline
          readline.dev
          expat
          libffi

          # AOSP-specific build deps
          bison
          flex
          gperf
          bc
          lzop
          schedtool

          # Image & compression tools
          zip
          unzip
          p7zip
          lz4
          xz
          squashfsTools   # mksquashfs / unsquashfs
          e2fsprogs       # make_ext4fs 相当 (mkfs.ext4)
          dosfstools
          dtc             # Device Tree Compiler

          # Misc utilities
          rsync
          diffutils
          patchutils
          patch
          xxd
          file
          which
          coreutils
          findutils
          procps
          psmisc
          gnugrep
          gnused
          gawk
          ccache

          # Image manipulation (signapk / pngcrush)
          pngcrush
          imagemagick

          # Perl (some AOSP scripts use it)
          perl

          # Networking (for repo sync)
          nettools
        ];

        # FHS environment that mimics Ubuntu — required for AOSP / crDroid
        fhsEnv = pkgs.buildFHSEnv {
          name = "crdroid-build-env";

          targetPkgs = fhsPackages;

          # Extra paths that Android build tools look for
          extraOutputsToInstall = [ "dev" "lib" ];

          profile = ''
            # ── Java ──────────────────────────────────────────────────────────
            export JAVA_HOME="${jdk}"
            export PATH="${jdk}/bin:$PATH"

            # ── ccache ────────────────────────────────────────────────────────
            export USE_CCACHE=1
            export CCACHE_EXEC=$(which ccache)
            export CCACHE_DIR="$HOME/.ccache"
            # Recommended cache size for a full Android build
            ccache -M 50G 2>/dev/null || true

            # ── Python ────────────────────────────────────────────────────────
            export PYTHONDONTWRITEBYTECODE=1

            # ── Android build helpers ─────────────────────────────────────────
            export ALLOW_MISSING_DEPENDENCIES=true

            # ── repo tool (downloaded per-user if not already present) ─────────
            if [ ! -f "$HOME/bin/repo" ]; then
              mkdir -p "$HOME/bin"
              curl -s https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
              chmod +x "$HOME/bin/repo"
              echo "[flake] repo tool installed to ~/bin/repo"
            fi
            export PATH="$HOME/bin:$PATH"

            # ── Prompt hint ────────────────────────────────────────────────────
            export PS1="[crdroid-c330ae] $PS1"

            echo ""
            echo "  crDroid build environment for Rakuten Mini (c330ae / SDM439)"
            echo "  Java:   $(java -version 2>&1 | head -1)"
            echo "  Python: $(python3 --version)"
            echo "  ccache: $(ccache --version | head -1)"
            echo ""
            echo "  Quick-start:"
            echo "    repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --git-lfs"
            echo "    repo sync -c -j\$(nproc) --force-sync --no-clone-bundle --no-tags"
            echo "    source build/envsetup.sh"
            echo "    breakfast c330ae"
            echo "    brunch c330ae"
            echo ""
          '';

          # Run a shell by default
          runScript = "bash";
        };

      in
      {
        devShells.default = fhsEnv.env;
      }
    );
}
