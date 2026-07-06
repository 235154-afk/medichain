// lib/providers/wallet_provider.dart
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/contract_config.dart';
import '../models/medicine_batch.dart';

class WalletProvider extends ChangeNotifier {
  Web3Client? _client;
  DeployedContract? _contract;
  EthPrivateKey? _credentials;
  EthereumAddress? _address;
  EtherAmount? _balance;
  ActorInfo _actorInfo = ActorInfo.empty();

  bool _isConnected = false;
  bool _isLoading   = false;
  String _error     = '';
  String _privateKey = '';

  // Getters
  bool        get isConnected => _isConnected;
  bool        get isLoading   => _isLoading;
  String      get error       => _error;
  String      get walletAddress => _address?.hexEip55 ?? '';
  String      get shortAddress  => walletAddress.isEmpty ? '' : '${walletAddress.substring(0,6)}...${walletAddress.substring(walletAddress.length-4)}';
  EtherAmount? get balance     => _balance;
  String      get balanceStr   => _balance != null ? '${((_balance!.getInWei.toDouble()) / 1e18).toStringAsFixed(4)} ETH' : '0 ETH';
  ActorInfo   get actorInfo    => _actorInfo;
  Web3Client? get client       => _client;
  DeployedContract? get contract => _contract;
  EthPrivateKey?    get credentials => _credentials;

  WalletProvider() {
    _initClient();
    _loadSavedKey();
  }

  void _initClient() {
    _client = Web3Client(ContractConfig.rpcUrl, http.Client());
  }

  Future<void> _loadSavedKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('private_key');
    if (key != null && key.isNotEmpty) {
      await connectWithPrivateKey(key);
    }
  }

  Future<void> connectWithPrivateKey(String privateKey) async {
    _setLoading(true);
    _error = '';
    try {
      final trimmed = privateKey.startsWith('0x') ? privateKey.substring(2) : privateKey;
      _credentials = EthPrivateKey.fromHex(trimmed);
      _address     = _credentials!.address;
      _privateKey  = trimmed;

      await _loadContract();
      await _refreshBalance();
      await _loadActorInfo();

      _isConnected = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('private_key', trimmed);
    } catch (e) {
      _error = 'Invalid private key: ${e.toString()}';
      _isConnected = false;
    }
    _setLoading(false);
  }

  Future<void> _loadContract() async {
    final abi = ContractAbi.fromJson(
      ContractConfig.abi.map((e) => e).toList().toString(),
      'MediChain',
    );
    _contract = DeployedContract(
      abi,
      EthereumAddress.fromHex(ContractConfig.contractAddress),
    );
  }

  Future<void> _refreshBalance() async {
    if (_address == null || _client == null) return;
    _balance = await _client!.getBalance(_address!);
    notifyListeners();
  }

  Future<void> _loadActorInfo() async {
    if (_contract == null || _address == null) return;
    try {
      final fn = _contract!.function('getActor');
      final result = await _client!.call(
        contract: _contract!,
        function: fn,
        params: [_address!],
      );
      if (result.isNotEmpty) {
        _actorInfo = ActorInfo.fromChain(result[0] as List<dynamic>);
      }
    } catch (_) {}
  }

  Future<String> sendTransaction(String functionName, List<dynamic> params) async {
    if (!_isConnected) throw Exception('Wallet not connected');
    final fn = _contract!.function(functionName);
    final txHash = await _client!.sendTransaction(
      _credentials!,
      Transaction.callContract(
        contract: _contract!,
        function: fn,
        parameters: params,
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)),
        maxGas: 500000,
      ),
      chainId: ContractConfig.chainId,
    );
    await _refreshBalance();
    return txHash;
  }

  Future<List<dynamic>> callFunction(String functionName, List<dynamic> params) async {
    if (_contract == null || _client == null) throw Exception('Not connected');
    final fn = _contract!.function(functionName);
    return await _client!.call(
      contract: _contract!,
      function: fn,
      params: params,
    );
  }

  void disconnect() async {
    _isConnected = false;
    _credentials = null;
    _address     = null;
    _balance     = null;
    _actorInfo   = ActorInfo.empty();
    final prefs  = await SharedPreferences.getInstance();
    await prefs.remove('private_key');
    notifyListeners();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
}
