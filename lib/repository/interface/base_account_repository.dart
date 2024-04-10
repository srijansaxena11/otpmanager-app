import '../../main.dart';

abstract class BaseAccountRepository<AccountType> {
  final box = objectBox.store.box<AccountType>();

  void add(AccountType account) {
    box.put(account);
  }

  void update(AccountType account) {
    (account as dynamic).toUpdate = true;
    box.put(account);
  }

  void remove(int id) {
    box.remove(id);
  }

  void removeAll() {
    box.removeAll();
  }

  AccountType? get(int id) {
    return box.get(id);
  }

  List<AccountType> getAll() {
    return box.getAll();
  }

  List<AccountType> getVisible();
  List<AccountType> getVisibleFiltered(String filter);
  void updateNeverSync();
  void deleteOld(List nextcloudAccountIds);
  void addNew(List nextcloudAccounts);
  void updateEdited(List nextcloudAccounts);
  void scalePositionAfter(int position);
  int getLastPosition();
  List<AccountType> getBetweenPositions(int min, int max);
  AccountType? getByPosition(int position);
}
