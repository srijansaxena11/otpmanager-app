import 'package:otp_manager/repository/interface/base_account_repository.dart';

import '../../models/account.dart';

abstract class AccountRepository extends BaseAccountRepository<Account> {
  bool alreadyExists(String secret);
  Account? getBySecret(String secret);
}
