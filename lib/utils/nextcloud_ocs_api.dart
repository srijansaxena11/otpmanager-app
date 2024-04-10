/// This file contains all the OCS APIs that the app uses to interface with the Nextcloud extension.

class SharedAccountAPI {
  static const unlock = "share/unlock";
  static const updateCounter = "share/update-counter";
}

class AccountAPI {
  static const updateCounter = "accounts/update-counter";
}

class SyncAPI {
  static const sync = "accounts/sync";
}

class PasswordAPI {
  static const check = "password/check";
}
