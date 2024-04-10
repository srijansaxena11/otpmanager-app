import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_manager/domain/nextcloud_service.dart';
import 'package:otp_manager/repository/interface/account_repository.dart';
import 'package:otp_manager/repository/interface/shared_account_repository.dart';

import '../../bloc/home/home_bloc.dart';
import '../../bloc/home/home_event.dart';
import '../../bloc/home/home_state.dart';
import '../../bloc/otp_account/otp_account_bloc.dart';
import 'otp_account.dart';

class OtpAccountsList extends StatelessWidget {
  const OtpAccountsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return ReorderableListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: state.accounts.length,
          padding: state.accounts.length <= 1
              ? const EdgeInsets.fromLTRB(0, 0, 0, 150)
              : null,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            var account = state.accounts[index];

            return BlocProvider<OtpAccountBloc>(
              key: ValueKey(account.secret),
              create: (context) => OtpAccountBloc(
                homeBloc: context.read<HomeBloc>(),
                accountRepository: context.read<AccountRepository>(),
                nextcloudService: context.read<NextcloudService>(),
                sharedAccountRepository:
                    context.read<SharedAccountRepository>(),
              ),
              child: OtpAccount(
                account: account,
              ),
            );
          },
          onReorder: (oldIndex, newIndex) => context
              .read<HomeBloc>()
              .add(Reorder(oldIndex: oldIndex, newIndex: newIndex)),
        );
      },
    );
  }
}
