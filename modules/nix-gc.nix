_:

{
  launchd.daemons.nix-gc = {
    script = ''
      /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +4
      /nix/var/nix/profiles/default/bin/nix-collect-garbage
    '';
    serviceConfig = {
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 23;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
    };
  };
}
