{
  vars,
  ...
}:

{
  system.defaults = {
    screencapture.location = "${vars.homeDirectory}/Pictures/Screenshots";

    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;

      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    finder = {
      ShowPathbar = true;
      FXPreferredViewStyle = "Nlsv";
    };

    controlcenter.BatteryShowPercentage = true;

    CustomUserPreferences = {
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      NSGlobalDomain.NSSmartReplyEnabled = false;
      "com.apple.symbolichotkeys".AppleSymbolicHotKeys."64".enabled = false;
    };
  };
}
