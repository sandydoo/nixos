final: prev: {
  # Use a *much* newer version from GitHub. Includes true color support.
  mosh = prev.mosh.overrideAttrs (_: {
    version = "1.3.2.95rc1";
    src = prev.fetchFromGitHub {
      owner = "mobile-shell";
      repo = "mosh";
      rev = "mosh-1.3.2.95rc1";
      sha256 = "sha256-8/IKcUg2UzrRqm+9B5g7c4IfdyD4optEMwmwzYFs6cA=";
    };
    patches = [
      (prev.path + /pkgs/tools/networking/mosh/ssh_path.patch)
      (prev.path + /pkgs/tools/networking/mosh/mosh-client_path.patch)
      (prev.path + /pkgs/tools/networking/mosh/utempter_path.patch)
      (prev.path + /pkgs/tools/networking/mosh/bash_completion_datadir.patch)
    ];
    postPatch = ''
      substituteInPlace scripts/mosh.pl \
        --subst-var-by ssh "${prev.openssh}/bin/ssh" \
        --subst-var-by mosh-client "$out/bin/mosh-client"
    '';
  });
}
