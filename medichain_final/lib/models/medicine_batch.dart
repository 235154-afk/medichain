// lib/models/medicine_batch.dart
enum BatchStatus { active, inTransit, delivered, recalled, expired }
enum TempStatus  { normal, warning, critical }
enum ActorRole   { none, manufacturer, distributor, pharmacy, regulator }

extension BatchStatusX on BatchStatus {
  String get label => ['Active','In Transit','Delivered','Recalled','Expired'][index];
  bool   get isOk  => this == BatchStatus.active || this == BatchStatus.inTransit || this == BatchStatus.delivered;
}

extension ActorRoleX on ActorRole {
  String get label => ['None','Manufacturer','Distributor','Pharmacy','Regulator'][index];
}

class MedicineBatch {
  final BigInt  id;
  final String  name;
  final String  batchNumber;
  final String  manufacturer;
  final String  composition;
  final DateTime mfgDate;
  final DateTime expDate;
  final BigInt  quantity;
  final int     minTemp;   // x10
  final int     maxTemp;   // x10
  final String  ipfsHash;
  final String  registeredBy;
  final BatchStatus status;
  final DateTime registeredAt;

  const MedicineBatch({
    required this.id,
    required this.name,
    required this.batchNumber,
    required this.manufacturer,
    required this.composition,
    required this.mfgDate,
    required this.expDate,
    required this.quantity,
    required this.minTemp,
    required this.maxTemp,
    required this.ipfsHash,
    required this.registeredBy,
    required this.status,
    required this.registeredAt,
  });

  bool get isExpired => DateTime.now().isAfter(expDate);

  String get minTempStr => '${(minTemp / 10).toStringAsFixed(1)}°C';
  String get maxTempStr => '${(maxTemp / 10).toStringAsFixed(1)}°C';
  String get tempRange  => '$minTempStr – $maxTempStr';

  factory MedicineBatch.fromChain(List<dynamic> raw) {
    final statusIdx = (raw[12] as BigInt).toInt();
    return MedicineBatch(
      id:            raw[0]  as BigInt,
      name:          raw[1]  as String,
      batchNumber:   raw[2]  as String,
      manufacturer:  raw[3]  as String,
      composition:   raw[4]  as String,
      mfgDate:       DateTime.fromMillisecondsSinceEpoch((raw[5] as BigInt).toInt() * 1000),
      expDate:       DateTime.fromMillisecondsSinceEpoch((raw[6] as BigInt).toInt() * 1000),
      quantity:      raw[7]  as BigInt,
      minTemp:       (raw[8] as BigInt).toInt(),
      maxTemp:       (raw[9] as BigInt).toInt(),
      ipfsHash:      raw[10] as String,
      registeredBy:  raw[11] as String,
      status:        BatchStatus.values[statusIdx.clamp(0, 4)],
      registeredAt:  DateTime.fromMillisecondsSinceEpoch((raw[13] as BigInt).toInt() * 1000),
    );
  }
}

class TransferEvent {
  final BigInt   batchId;
  final String   from;
  final String   to;
  final ActorRole toRole;
  final String   location;
  final String   notes;
  final DateTime timestamp;
  final int      tempAtTransfer;

  const TransferEvent({
    required this.batchId,
    required this.from,
    required this.to,
    required this.toRole,
    required this.location,
    required this.notes,
    required this.timestamp,
    required this.tempAtTransfer,
  });

  String get tempStr => '${(tempAtTransfer / 10).toStringAsFixed(1)}°C';

  factory TransferEvent.fromChain(List<dynamic> raw) {
    return TransferEvent(
      batchId:        raw[0] as BigInt,
      from:           raw[1] as String,
      to:             raw[2] as String,
      toRole:         ActorRole.values[((raw[3] as BigInt).toInt()).clamp(0,4)],
      location:       raw[4] as String,
      notes:          raw[5] as String,
      timestamp:      DateTime.fromMillisecondsSinceEpoch((raw[6] as BigInt).toInt() * 1000),
      tempAtTransfer: (raw[7] as BigInt).toInt(),
    );
  }
}

class TempLog {
  final BigInt   batchId;
  final int      temperature;
  final String   location;
  final String   loggedBy;
  final DateTime timestamp;
  final TempStatus status;

  const TempLog({
    required this.batchId,
    required this.temperature,
    required this.location,
    required this.loggedBy,
    required this.timestamp,
    required this.status,
  });

  String get tempStr => '${(temperature / 10).toStringAsFixed(1)}°C';

  factory TempLog.fromChain(List<dynamic> raw) {
    return TempLog(
      batchId:     raw[0] as BigInt,
      temperature: (raw[1] as BigInt).toInt(),
      location:    raw[2] as String,
      loggedBy:    raw[3] as String,
      timestamp:   DateTime.fromMillisecondsSinceEpoch((raw[4] as BigInt).toInt() * 1000),
      status:      TempStatus.values[((raw[5] as BigInt).toInt()).clamp(0,2)],
    );
  }
}

class ActorInfo {
  final String   wallet;
  final String   name;
  final String   licenseNumber;
  final ActorRole role;
  final bool     isVerified;
  final bool     exists;

  const ActorInfo({
    required this.wallet,
    required this.name,
    required this.licenseNumber,
    required this.role,
    required this.isVerified,
    required this.exists,
  });

  factory ActorInfo.fromChain(List<dynamic> raw) {
    return ActorInfo(
      wallet:        raw[0] as String,
      name:          raw[1] as String,
      licenseNumber: raw[2] as String,
      role:          ActorRole.values[((raw[3] as BigInt).toInt()).clamp(0,4)],
      isVerified:    raw[4] as bool,
      exists:        raw[5] as bool,
    );
  }

  factory ActorInfo.empty() => const ActorInfo(
    wallet: '', name: '', licenseNumber: '',
    role: ActorRole.none, isVerified: false, exists: false,
  );
}

class Analytics {
  final int batches;
  final int transfers;
  final int recalls;
  final int breaches;
  final int actors;

  const Analytics({
    required this.batches,
    required this.transfers,
    required this.recalls,
    required this.breaches,
    required this.actors,
  });

  factory Analytics.fromChain(List<dynamic> raw) {
    return Analytics(
      batches:   (raw[0] as BigInt).toInt(),
      transfers: (raw[1] as BigInt).toInt(),
      recalls:   (raw[2] as BigInt).toInt(),
      breaches:  (raw[3] as BigInt).toInt(),
      actors:    (raw[4] as BigInt).toInt(),
    );
  }
}
