// lib/providers/medicine_provider.dart
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import '../models/medicine_batch.dart';
import 'wallet_provider.dart';

class MedicineProvider extends ChangeNotifier {
  MedicineBatch?      _currentBatch;
  List<TransferEvent> _transfers = [];
  List<TempLog>       _tempLogs  = [];
  Analytics?          _analytics;
  bool _loading = false;
  String _error = '';

  MedicineBatch?      get currentBatch => _currentBatch;
  List<TransferEvent> get transfers    => _transfers;
  List<TempLog>       get tempLogs     => _tempLogs;
  Analytics?          get analytics    => _analytics;
  bool                get isLoading    => _loading;
  String              get error        => _error;

  // ── VERIFY BATCH BY ID OR BATCH NUMBER ──────────────────
  Future<bool> verifyBatch(WalletProvider wallet, String query) async {
    _loading = true; _error = ''; notifyListeners();
    try {
      List<dynamic> result;
      // Try by batch number string first, then by numeric ID
      if (RegExp(r'^\d+$').hasMatch(query)) {
        result = await wallet.callFunction('getBatch', [BigInt.parse(query)]);
      } else {
        // Search by batch number string
        final idResult = await wallet.callFunction('getBatchIdByNumber', [query]);
        final id = idResult[0] as BigInt;
        if (id == BigInt.zero) {
          _error = 'Batch not found on blockchain.';
          _loading = false; notifyListeners(); return false;
        }
        result = await wallet.callFunction('getBatch', [id]);
      }

      final raw = result[0] as List<dynamic>;
      _currentBatch = MedicineBatch.fromChain(raw);

      // Load transfer history
      final tResult = await wallet.callFunction('getTransferHistory', [_currentBatch!.id]);
      _transfers = (tResult[0] as List<dynamic>)
          .map((e) => TransferEvent.fromChain(e as List<dynamic>))
          .toList();

      // Load temp logs
      final lResult = await wallet.callFunction('getTempLogs', [_currentBatch!.id]);
      _tempLogs = (lResult[0] as List<dynamic>)
          .map((e) => TempLog.fromChain(e as List<dynamic>))
          .toList();

      _loading = false; notifyListeners(); return true;
    } catch (e) {
      _error = 'Verification failed: ${e.toString()}';
      _loading = false; notifyListeners(); return false;
    }
  }

  // ── REGISTER BATCH ──────────────────────────────────────
  Future<String> registerBatch(WalletProvider wallet, {
    required String name,
    required String batchNumber,
    required String manufacturer,
    required String composition,
    required DateTime mfgDate,
    required DateTime expDate,
    required int quantity,
    required int minTemp,
    required int maxTemp,
    String ipfsHash = '',
  }) async {
    _loading = true; notifyListeners();
    try {
      final txHash = await wallet.sendTransaction('registerBatch', [
        [
          name, batchNumber, manufacturer, composition,
          BigInt.from(mfgDate.millisecondsSinceEpoch ~/ 1000),
          BigInt.from(expDate.millisecondsSinceEpoch ~/ 1000),
          BigInt.from(quantity),
          BigInt.from(minTemp),
          BigInt.from(maxTemp),
          ipfsHash,
        ]
      ]);
      _loading = false; notifyListeners();
      return txHash;
    } catch (e) {
      _error = e.toString();
      _loading = false; notifyListeners();
      rethrow;
    }
  }

  // ── TRANSFER BATCH ──────────────────────────────────────
  Future<String> transferBatch(WalletProvider wallet, {
    required BigInt batchId,
    required String toAddress,
    required String location,
    required String notes,
    required int currentTemp,
  }) async {
    _loading = true; notifyListeners();
    try {
      final txHash = await wallet.sendTransaction('transferBatch', [
        batchId,
        EthereumAddress.fromHex(toAddress),
        location,
        notes,
        BigInt.from(currentTemp),
      ]);
      _loading = false; notifyListeners();
      return txHash;
    } catch (e) {
      _error = e.toString();
      _loading = false; notifyListeners();
      rethrow;
    }
  }

  // ── LOG TEMPERATURE ─────────────────────────────────────
  Future<String> logTemperature(WalletProvider wallet, {
    required BigInt batchId,
    required int temperature,
    required String location,
  }) async {
    _loading = true; notifyListeners();
    try {
      final txHash = await wallet.sendTransaction('logTemperature', [
        batchId, BigInt.from(temperature), location,
      ]);
      _loading = false; notifyListeners();
      return txHash;
    } catch (e) {
      _error = e.toString();
      _loading = false; notifyListeners();
      rethrow;
    }
  }

  // ── RECALL BATCH ────────────────────────────────────────
  Future<String> recallBatch(WalletProvider wallet, BigInt batchId, String reason) async {
    _loading = true; notifyListeners();
    try {
      final txHash = await wallet.sendTransaction('recallBatch', [batchId, reason]);
      _loading = false; notifyListeners();
      return txHash;
    } catch (e) {
      _error = e.toString();
      _loading = false; notifyListeners();
      rethrow;
    }
  }

  // ── REGISTER ACTOR ──────────────────────────────────────
  Future<String> registerActor(WalletProvider wallet, {
    required String name,
    required String licenseNumber,
    required int role,
  }) async {
    _loading = true; notifyListeners();
    try {
      final txHash = await wallet.sendTransaction('registerActor', [
        name, licenseNumber, BigInt.from(role),
      ]);
      _loading = false; notifyListeners();
      return txHash;
    } catch (e) {
      _error = e.toString();
      _loading = false; notifyListeners();
      rethrow;
    }
  }

  // ── ANALYTICS ───────────────────────────────────────────
  Future<void> loadAnalytics(WalletProvider wallet) async {
    try {
      final result = await wallet.callFunction('getAnalytics', []);
      _analytics = Analytics.fromChain(result);
      notifyListeners();
    } catch (e) {
      // use cached
    }
  }

  void clear() {
    _currentBatch = null;
    _transfers    = [];
    _tempLogs     = [];
    notifyListeners();
  }
}
