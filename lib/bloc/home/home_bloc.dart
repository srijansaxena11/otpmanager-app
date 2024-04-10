import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_manager/bloc/home/home_event.dart';
import 'package:otp_manager/bloc/home/home_state.dart';
import 'package:otp_manager/domain/nextcloud_service.dart';
import 'package:otp_manager/models/account.dart';
import 'package:otp_manager/repository/interface/account_repository.dart';
import 'package:otp_manager/repository/interface/shared_account_repository.dart';
import 'package:otp_manager/repository/interface/user_repository.dart';
import 'package:otp_manager/routing/constants.dart';

import '../../domain/account_service.dart';
import '../../models/shared_account.dart';
import '../../routing/navigation_service.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserRepository userRepository;
  final AccountRepository accountRepository;
  final AccountService accountService;
  final SharedAccountRepository sharedAccountRepository;
  final NextcloudService nextcloudService;

  final NavigationService _navigationService = NavigationService();

  HomeBloc({
    required this.userRepository,
    required this.accountRepository,
    required this.accountService,
    required this.sharedAccountRepository,
    required this.nextcloudService,
  }) : super(
          HomeState.initial(userRepository.get()!),
        ) {
    on<NextcloudSync>(_onNextcloudSync);
    on<GetAccounts>(_onGetAccounts);
    on<Logout>(_onLogout);
    on<Reorder>(_onReorder);
    on<DeleteAccount>(_onDeleteAccount);
    on<SortByName>(_onSortByName);
    on<SortByIssuer>(_onSortByIssuer);
    on<SortById>(_onSortById);
    on<SearchBarValueChanged>(_onSearchBarValueChanged);
    on<IsAppUpdatedChanged>(_onIsAppUpdatedChanged);
    on<ShowMessage>(_onShowMessage);

    add(GetAccounts());
  }

  void _onIsAppUpdatedChanged(
      IsAppUpdatedChanged event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isAppUpdated: event.value));
  }

  void _onNextcloudSync(NextcloudSync event, Emitter<HomeState> emit) async {
    add(GetAccounts());

    if (!state.isAppUpdated) {
      emit(state.copyWith(
          syncStatus: -1,
          message:
              "Update the app to the latest version to be able to synchronize"));
      emit(state.copyWith(message: ""));
    } else if (!state.isGuest) {
      emit(state.copyWith(syncStatus: 1));

      final Map<String, dynamic> result = await nextcloudService.sync();

      if (result["error"] != null) {
        emit(state.copyWith(syncStatus: -1, message: result["error"]));
        emit(state.copyWith(message: ""));
      } else {
        if (nextcloudService.syncAccountsToAddToEdit(
            result["accounts"], result["sharedAccounts"])) {
          if (accountService.repairPositionError()) {
            await nextcloudService.sync();
          }
          emit(state.copyWith(syncStatus: 0));
        } else {
          emit(state.copyWith(
            syncStatus: -1,
            message: "Password has changed. Insert the new one",
          ));
          emit(state.copyWith(message: ""));
          _navigationService.replaceScreen(authRoute);
        }

        emit(state.copyWith(syncStatus: 0));
      }
    } else {
      emit(state.copyWith(syncStatus: -1));
    }

    add(GetAccounts());
  }

  List mergeResults(
      List<Account> accounts, List<SharedAccount> sharedAccounts) {
    List result = [...accounts, ...sharedAccounts];

    result.sort((a, b) => a.position.compareTo(b.position));

    return result;
  }

  void _onGetAccounts(GetAccounts event, Emitter<HomeState> emit) {
    if (state.searchBarValue == "") {
      emit(state.copyWith(
        accounts: mergeResults(
          accountRepository.getVisible(),
          sharedAccountRepository.getVisible(),
        ),
      ));
    } else {
      emit(state.copyWith(
        accounts: mergeResults(
          accountRepository.getVisibleFiltered(state.searchBarValue),
          sharedAccountRepository.getVisibleFiltered(state.searchBarValue),
        ),
      ));
    }
  }

  void _onLogout(Logout event, Emitter<HomeState> emit) {
    userRepository.removeAll();
    accountRepository.removeAll();
    sharedAccountRepository.removeAll();
    _navigationService.resetToScreen(loginRoute);
  }

  void _onReorder(Reorder event, Emitter<HomeState> emit) {
    emit(state.copyWith(
      sortedByIdDesc: "null",
      sortedByNameDesc: "null",
      sortedByIssuerDesc: "null",
    ));

    final user = userRepository.get()!;
    user.sortedByNameDesc = state.sortedByNameDesc;
    user.sortedByIssuerDesc = state.sortedByIssuerDesc;
    user.sortedByIdDesc = state.sortedByIdDesc;
    userRepository.update(user);

    accountService.reorder(event.oldIndex, event.newIndex);

    add(NextcloudSync());
  }

  void _onDeleteAccount(DeleteAccount event, Emitter<HomeState> emit) {
    if (event.account != null) {
      accountService.setAsDeleted(event.account);

      add(NextcloudSync());

      emit(state.copyWith(
          message: "${event.account.type.toUpperCase()} has been removed"));
    } else {
      emit(state.copyWith(
          message: "There was an error while deleting the account"));
    }

    emit(state.copyWith(message: ""));
    _navigationService.goBack();
  }

  void _onSortById(SortById event, Emitter<HomeState> emit) {
    List<Account> accounts = accountRepository.getVisible();

    if (state.sortedByIdDesc == null || state.sortedByIdDesc == true) {
      accounts.sort((b, a) => a.id.compareTo(b.id));
    } else {
      accounts.sort((a, b) => a.id.compareTo(b.id));
    }

    emit(state.copyWith(
      sortedByIdDesc:
          state.sortedByIdDesc == null ? false : !(state.sortedByIdDesc!),
      sortedByNameDesc: "null",
      sortedByIssuerDesc: "null",
    ));

    _updateSorting(accounts);
  }

  void _onSortByName(SortByName event, Emitter<HomeState> emit) {
    List<Account> accounts = accountRepository.getVisible();

    if (state.sortedByNameDesc == null || state.sortedByNameDesc == true) {
      accounts.sort((a, b) => a.name.compareTo(b.name));
    } else {
      accounts.sort((b, a) => a.name.compareTo(b.name));
    }

    emit(state.copyWith(
      sortedByNameDesc:
          state.sortedByNameDesc == null ? false : !(state.sortedByNameDesc!),
      sortedByIdDesc: "null",
      sortedByIssuerDesc: "null",
    ));

    _updateSorting(accounts);
  }

  void _onSortByIssuer(SortByIssuer event, Emitter<HomeState> emit) {
    List<Account> accounts = accountRepository.getVisible();

    if (state.sortedByIssuerDesc == null || state.sortedByIssuerDesc == true) {
      accounts.sort((a, b) => (a.issuer ?? "").compareTo(b.issuer ?? ""));
    } else {
      accounts.sort((b, a) => (a.issuer ?? "").compareTo(b.issuer ?? ""));
    }

    emit(state.copyWith(
      sortedByIssuerDesc: state.sortedByIssuerDesc == null
          ? false
          : !(state.sortedByIssuerDesc!),
      sortedByIdDesc: "null",
      sortedByNameDesc: "null",
    ));

    _updateSorting(accounts);
  }

  void _updateSorting(List<Account> accounts) {
    final user = userRepository.get()!;
    user.sortedByNameDesc = state.sortedByNameDesc;
    user.sortedByIssuerDesc = state.sortedByIssuerDesc;
    user.sortedByIdDesc = state.sortedByIdDesc;
    userRepository.update(user);

    for (int i = 0; i < accounts.length; i++) {
      accounts[i].position = i;
      accountRepository.update(accounts[i]);
    }

    add(NextcloudSync());
  }

  void _onSearchBarValueChanged(
      SearchBarValueChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(searchBarValue: event.value));
  }

  void _onShowMessage(ShowMessage event, Emitter<HomeState> emit) {
    emit(state.copyWith(message: event.message));
    emit(state.copyWith(message: ""));
  }
}
