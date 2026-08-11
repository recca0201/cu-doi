import 'package:cloud_functions/cloud_functions.dart';
import '../state/account_controller.dart';

enum DeletionServerPhase {
  queued,
  deleting,
  providerRecoveryRequired,
  finalSweep,
  completed,
  failed,
}

class DeletionReceipt {
  const DeletionReceipt({required this.receipt, required this.requestId});
  final String receipt;
  final String requestId;
  Map<String, Object> toJson() => {'receipt': receipt, 'requestId': requestId};
}

class DeletionStatus {
  const DeletionStatus(this.phase, {this.errorCode});
  final DeletionServerPhase phase;
  final String? errorCode;
  bool get terminal => phase == DeletionServerPhase.completed;
}

abstract class AccountDeletionRepository {
  Future<DeletionReceipt> begin(
    ReauthenticationProof proof,
    String idempotencyKey,
  );
  Future<DeletionStatus> status(DeletionReceipt receipt);
  Future<void> refreshProviderProof(
    DeletionReceipt receipt,
    ReauthenticationProof proof,
  );
}

class FirebaseAccountDeletionRepository implements AccountDeletionRepository {
  FirebaseAccountDeletionRepository(this.functions);
  final FirebaseFunctions functions;
  @override
  Future<DeletionReceipt> begin(
    ReauthenticationProof proof,
    String idempotencyKey,
  ) async {
    final result = await functions.httpsCallable('beginAccountDeletion').call(
      <String, Object>{
        'provider': proof.provider.name,
        'idempotencyKey': idempotencyKey,
      },
    );
    final data = Map<String, dynamic>.from(result.data as Map);
    return DeletionReceipt(
      receipt: data['receipt'] as String,
      requestId: data['requestId'] as String,
    );
  }

  @override
  Future<DeletionStatus> status(DeletionReceipt receipt) async {
    final result = await functions
        .httpsCallable('getAccountDeletionStatus')
        .call(receipt.toJson());
    final data = Map<String, dynamic>.from(result.data as Map);
    return DeletionStatus(
      DeletionServerPhase.values.byName(data['phase'] as String),
      errorCode: data['errorCode'] as String?,
    );
  }

  @override
  Future<void> refreshProviderProof(
    DeletionReceipt receipt,
    ReauthenticationProof proof,
  ) async => functions.httpsCallable('refreshDeletionProof').call(
    <String, Object>{...receipt.toJson(), 'provider': proof.provider.name},
  );
}
