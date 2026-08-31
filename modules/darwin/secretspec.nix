{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.secretspec;

  secretType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = name;
          description = "Name of the secret in the SecretSpec profile.";
        };

        profile = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = null;
          description = "SecretSpec profile for this secret. Inherits the global profile when null.";
        };

        path = lib.mkOption {
          type = lib.types.nonEmptyStr;
          description = "Absolute destination at which to materialize the secret.";
        };

        lifetime = lib.mkOption {
          type = lib.types.enum [
            "persistent"
            "runtime"
          ];
          default = "persistent";
          description = ''
            Lifetime of the materialized secret. Runtime secrets are removed
            when the launchd agent exits and before it resolves them at login.
            An explicit runtime path is still disk-backed on macOS.
          '';
        };

        owner = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = config.home.username;
          defaultText = lib.literalExpression "config.home.username";
          description = ''
            Owner of the materialized file. The Home Manager activation user
            must be allowed to set this owner.
          '';
        };

        group = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = null;
          description = ''
            Group of the materialized file. Null retains the activation user's
            default group.
          '';
        };

        mode = lib.mkOption {
          type = lib.types.str;
          default = "0400";
          example = "0600";
          description = "Four-digit octal mode of the materialized file.";
        };

        restartUnits = lib.mkOption {
          type = lib.types.listOf lib.types.nonEmptyStr;
          default = [ ];
          description = ''
            Launchd labels to kickstart after this secret changes. Labels are
            resolved in the current user's GUI domain.
          '';
        };
      };
    }
  );

  effectiveSecrets = lib.mapAttrs (
    _configurationName: secret:
    secret
    // {
      profile = if secret.profile == null then cfg.profile else secret.profile;
    }
  ) cfg.secrets;

  runtimeSecrets = lib.filterAttrs (_: secret: secret.lifetime == "runtime") effectiveSecrets;

  manifest = builtins.fromTOML (builtins.readFile cfg.file);

  collectStrings =
    value:
    if builtins.isString value then
      [ value ]
    else if builtins.isList value then
      lib.concatMap collectStrings value
    else if builtins.isAttrs value then
      lib.concatMap collectStrings (lib.attrValues value)
    else
      [ ];

  usesOnePassword = lib.any (
    value: lib.hasPrefix "onepassword://" value || lib.hasPrefix "onepassword+token://" value
  ) (collectStrings manifest);

  providerPackages = lib.optional usesOnePassword pkgs._1password-cli ++ cfg.extraProviderPackages;

  validatedManifest = pkgs.runCommand "secretspec.toml" { nativeBuildInputs = [ cfg.package ]; } ''
    export HOME="$TMPDIR"
    secretspec schema --file ${lib.escapeShellArg (toString cfg.file)} --output "$TMPDIR/schema.json"
    cp ${lib.escapeShellArg (toString cfg.file)} "$out"
  '';

  mkMaterializer =
    {
      name,
      secrets,
      manifestFile,
    }:
    let
      profileNames = lib.unique (map (secret: secret.profile) (lib.attrValues secrets));
      indexedProfiles = builtins.listToAttrs (
        lib.imap0 (
          index: profile:
          lib.nameValuePair profile {
            inherit profile;
            jsonFile = "profile-${toString index}.json";
          }
        ) profileNames
      );

      resolveProfiles = lib.concatMapStringsSep "\n" (
        profile:
        let
          profileData = indexedProfiles.${profile};
        in
        ''
          echo "resolving SecretSpec profile ${lib.escapeShellArg profile}..." >&2
          if ! secretspec export \
            --file ${lib.escapeShellArg (toString manifestFile)} \
            --profile ${lib.escapeShellArg profile} \
            --reason "Home Manager secret materialization" \
            --format json > "$work_directory/${profileData.jsonFile}"
          then
            echo "SecretSpec failed to resolve profile ${lib.escapeShellArg profile}" >&2
            exit 1
          fi
        ''
      ) profileNames;

      validateSecrets = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          _configurationName: secret:
          let
            jsonFile = indexedProfiles.${secret.profile}.jsonFile;
          in
          ''
            if jq -e --arg key ${lib.escapeShellArg secret.name} 'has($key)' \
              "$work_directory/${jsonFile}" >/dev/null
            then
              if ! jq -e --arg key ${lib.escapeShellArg secret.name} \
                '.[$key] | type == "string"' "$work_directory/${jsonFile}" >/dev/null
              then
                echo "SecretSpec returned a non-string value for ${lib.escapeShellArg secret.name}" >&2
                exit 1
              fi
            fi
          ''
        ) secrets
      );

      installSecrets = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          _configurationName: secret:
          let
            jsonFile = indexedProfiles.${secret.profile}.jsonFile;
            setOwner = lib.optionalString (secret.owner != null && secret.owner != config.home.username) ''
              chown -- ${lib.escapeShellArg secret.owner} "$staged_file"
            '';
            setGroup = lib.optionalString (secret.group != null) ''
              chgrp -- ${lib.escapeShellArg secret.group} "$staged_file"
            '';
            fixExistingOwner =
              lib.optionalString (secret.owner != null && secret.owner != config.home.username)
                ''
                  chown -- ${lib.escapeShellArg secret.owner} "$destination"
                '';
            fixExistingGroup = lib.optionalString (secret.group != null) ''
              chgrp -- ${lib.escapeShellArg secret.group} "$destination"
            '';
            recordRestarts =
              if secret.restartUnits == [ ] then
                ":"
              else
                lib.concatMapStringsSep "\n" (
                  unit: ''printf '%s\n' ${lib.escapeShellArg unit} >> "$restart_file"''
                ) secret.restartUnits;
          in
          ''
            json_file="$work_directory/${jsonFile}"
            if jq -e --arg key ${lib.escapeShellArg secret.name} 'has($key)' "$json_file" >/dev/null; then
              destination=${lib.escapeShellArg secret.path}
              destination_directory="$(dirname -- "$destination")"
              mkdir -p -- "$destination_directory"

              staged_file="$(mktemp "$destination_directory/.secretspec.XXXXXX")"
              pending_files+=("$staged_file")
              jq -j --arg key ${lib.escapeShellArg secret.name} '.[$key]' "$json_file" > "$staged_file"
              chmod ${lib.escapeShellArg secret.mode} "$staged_file"
              ${setOwner}
              ${setGroup}

              changed=1
              if [[ -f "$destination" && ! -L "$destination" ]] \
                && cmp -s -- "$staged_file" "$destination"
              then
                changed=0
                rm -f -- "$staged_file"
                chmod ${lib.escapeShellArg secret.mode} "$destination"
                ${fixExistingOwner}
                ${fixExistingGroup}
              else
                mv -f -- "$staged_file" "$destination"
                echo "materialized ${lib.escapeShellArg secret.name} at $destination" >&2
              fi

              if (( changed )); then
                ${recordRestarts}
              fi
            else
              echo "SecretSpec value ${lib.escapeShellArg secret.name} is unavailable; leaving its destination unchanged" >&2
            fi
          ''
        ) secrets
      );
    in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        cfg.package
        pkgs.coreutils
        pkgs.jq
      ]
      ++ providerPackages;
      text = ''
        umask 077

        work_directory="$(mktemp -d "''${TMPDIR:-/tmp}/secretspec-materialize.XXXXXX")"
        restart_file="$work_directory/restart-units"
        pending_files=()
        cleanup() {
          local pending
          for pending in "''${pending_files[@]}"; do
            rm -f -- "$pending"
          done
          rm -rf -- "$work_directory"
        }
        trap cleanup EXIT

        ${resolveProfiles}
        ${validateSecrets}
        ${installSecrets}

        if [[ -s "$restart_file" ]]; then
          sort -u "$restart_file" | while IFS= read -r unit; do
            echo "restarting launchd unit $unit after a SecretSpec value changed" >&2
            if ! /bin/launchctl kickstart -k "gui/$UID/$unit"; then
              echo "warning: could not restart launchd unit $unit" >&2
            fi
          done
        fi
      '';
    };

  materializeAll = mkMaterializer {
    name = "secretspec-materialize-all";
    secrets = effectiveSecrets;
    manifestFile = validatedManifest;
  };

  materializeRuntime = mkMaterializer {
    name = "secretspec-materialize-runtime";
    secrets = runtimeSecrets;
    manifestFile = validatedManifest;
  };

  cleanupRuntime = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      _configurationName: secret: "rm -f -- ${lib.escapeShellArg secret.path}"
    ) runtimeSecrets
  );

  materializer = pkgs.writeShellApplication {
    name = "secretspec-materialize";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      case "''${1:---all}" in
        --all)
          exec ${lib.getExe materializeAll}
          ;;
        --runtime)
          exec ${lib.getExe materializeRuntime}
          ;;
        --cleanup-runtime)
          ${cleanupRuntime}
          ;;
        *)
          echo "usage: secretspec-materialize [--all|--runtime|--cleanup-runtime]" >&2
          exit 2
          ;;
      esac
    '';
  };

  runtimeAgent = pkgs.writeShellApplication {
    name = "secretspec-runtime-agent";
    runtimeInputs = [
      materializer
      pkgs.coreutils
    ];
    text = ''
      cleanup() {
        secretspec-materialize --cleanup-runtime
      }

      cleanup
      trap cleanup EXIT
      trap 'exit 0' HUP INT TERM

      if ! secretspec-materialize --runtime; then
        echo "SecretSpec runtime materialization failed; use 'secretspec-materialize --runtime' to retry" >&2
      fi

      # Stay alive so launchd gives us an opportunity to clean explicit
      # runtime destinations when the GUI session ends.
      while true; do
        sleep 86400 &
        wait "$!" || true
      done
    '';
  };

  destinations = map (secret: secret.path) (lib.attrValues effectiveSecrets);
  resolutionKeys = map (
    secret:
    builtins.toJSON [
      secret.profile
      secret.name
    ]
  ) (lib.attrValues effectiveSecrets);

  secretAssertions = lib.concatLists (
    lib.mapAttrsToList (configurationName: secret: [
      {
        assertion = builtins.match "^[A-Za-z_][A-Za-z0-9_]*$" secret.name != null;
        message = "secretspec.secrets.${configurationName}.name must be a shell-compatible SecretSpec name";
      }
      {
        assertion = lib.hasPrefix "/" secret.path;
        message = "secretspec.secrets.${configurationName}.path must be absolute";
      }
      {
        assertion = secret.path != "/" && !lib.hasSuffix "/" secret.path;
        message = "secretspec.secrets.${configurationName}.path must name a file, not a directory";
      }
      {
        assertion = builtins.match "^0[0-7][0-7][0-7]$" secret.mode != null;
        message = "secretspec.secrets.${configurationName}.mode must be a four-digit octal mode such as 0600";
      }
      {
        assertion = secret.owner == null || builtins.match "^[A-Za-z0-9_.-]+$" secret.owner != null;
        message = "secretspec.secrets.${configurationName}.owner is not a valid local account name";
      }
      {
        assertion = secret.group == null || builtins.match "^[A-Za-z0-9_.-]+$" secret.group != null;
        message = "secretspec.secrets.${configurationName}.group is not a valid local group name";
      }
      {
        assertion = lib.all (unit: builtins.match "^[A-Za-z0-9_.-]+$" unit != null) secret.restartUnits;
        message = "secretspec.secrets.${configurationName}.restartUnits contains an invalid launchd label";
      }
      {
        assertion = builtins.isAttrs (
          lib.attrByPath [ "profiles" secret.profile secret.name ] null manifest
        );
        message =
          "secretspec.secrets.${configurationName} refers to ${secret.name} in profile "
          + "${secret.profile}, but that declaration is missing from ${toString cfg.file}";
      }
    ]) effectiveSecrets
  );
in
{
  options.secretspec = {
    enable = lib.mkEnableOption "SecretSpec-backed secret materialization";

    package = lib.mkPackageOption pkgs "secretspec" { };

    file = lib.mkOption {
      type = lib.types.path;
      description = ''
        Value-free secretspec.toml containing the project, providers, profiles,
        and secret declarations consumed by the materializer.
      '';
    };

    profile = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "default";
      description = "Default SecretSpec profile inherited by each secret.";
    };

    extraProviderPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Additional provider CLIs to put on the resolver's private PATH.
        The 1Password CLI is added automatically for onepassword:// URIs.
      '';
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf secretType;
      default = { };
      description = "SecretSpec values to materialize as files.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = secretAssertions ++ [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "modules/darwin/secretspec.nix can only be enabled on Darwin";
      }
      {
        assertion = effectiveSecrets != { };
        message = "secretspec.enable requires at least one entry in secretspec.secrets";
      }
      {
        assertion = lib.attrByPath [ "project" "revision" ] null manifest == "1.0";
        message = "secretspec.file must contain [project] with revision = \"1.0\"";
      }
      {
        assertion = lib.length destinations == lib.length (lib.unique destinations);
        message = "secretspec.secrets contains duplicate destination paths";
      }
      {
        assertion = lib.length resolutionKeys == lib.length (lib.unique resolutionKeys);
        message = "secretspec.secrets contains duplicate SecretSpec names within a profile";
      }
    ];

    home.packages = [
      cfg.package
      materializer
    ]
    ++ providerPackages;

    home.activation.materializeSecretSpec =
      lib.hm.dag.entryBetween
        [ "setupLaunchAgents" ]
        [
          "writeBoundary"
        ]
        ''
          run ${lib.getExe materializer} --all
        '';

    launchd.agents.secretspec-runtime = lib.mkIf (runtimeSecrets != { }) {
      enable = true;
      domain = "gui";
      config = {
        ProgramArguments = [ (lib.getExe runtimeAgent) ];
        ProcessType = "Background";
        RunAtLoad = true;
      };
    };
  };
}
