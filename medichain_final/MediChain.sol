// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MediChain
 * @notice Medicine authenticity & cold-chain tracker for Pakistan
 * @dev Deploy on Ethereum Sepolia Testnet — optimizer 200 runs
 */
contract MediChain {

    // ── ENUMS ──────────────────────────────────────────────
    enum Role        { None, Manufacturer, Distributor, Pharmacy, Regulator }
    enum BatchStatus { Active, InTransit, Delivered, Recalled, Expired }
    enum TempStatus  { Normal, Warning, Critical }

    // ── INPUT STRUCTS (prevent stack-too-deep) ─────────────
    struct BatchInput {
        string name;          // Medicine name e.g. "Insulin Glargine"
        string batchNumber;   // e.g. "BN-2025-001"
        string manufacturer;  // Company name
        string composition;   // Active ingredients
        uint256 mfgDate;      // Unix timestamp
        uint256 expDate;      // Unix timestamp
        uint256 quantity;     // Units in batch
        int256  minTemp;      // Min allowed temp (Celsius * 10, e.g. 20 = 2.0°C)
        int256  maxTemp;      // Max allowed temp
        string  ipfsHash;     // Documents hash on IPFS
    }

    // ── STORAGE STRUCTS ────────────────────────────────────
    struct MedicineBatch {
        uint256     id;
        string      name;
        string      batchNumber;
        string      manufacturer;
        string      composition;
        uint256     mfgDate;
        uint256     expDate;
        uint256     quantity;
        int256      minTemp;
        int256      maxTemp;
        string      ipfsHash;
        address     registeredBy;
        BatchStatus status;
        uint256     registeredAt;
        bool        exists;
    }

    struct TransferEvent {
        uint256 batchId;
        address from;
        address to;
        Role    toRole;
        string  location;
        string  notes;
        uint256 timestamp;
        int256  tempAtTransfer; // Temp logged at time of transfer
    }

    struct TempLog {
        uint256 batchId;
        int256  temperature; // Celsius * 10 for decimal precision
        string  location;
        address loggedBy;
        uint256 timestamp;
        TempStatus status;
    }

    struct ActorInfo {
        address wallet;
        string  name;
        string  licenseNumber;
        Role    role;
        bool    isVerified;
        bool    exists;
    }

    struct RecallInfo {
        uint256 batchId;
        string  reason;
        address initiatedBy;
        uint256 timestamp;
    }

    // ── STATE ──────────────────────────────────────────────
    address public immutable owner;
    uint256 private _batchCount;
    uint256 private _transferCount;
    uint256 private _tempLogCount;

    mapping(uint256 => MedicineBatch)   private _batches;
    mapping(uint256 => TransferEvent[]) private _transfers;   // batchId → history
    mapping(uint256 => TempLog[])       private _tempLogs;    // batchId → logs
    mapping(address => ActorInfo)       private _actors;
    mapping(address => bool)            private _admins;
    mapping(uint256 => RecallInfo)      private _recalls;
    mapping(string  => uint256)         private _batchNumberToId; // lookup by batch#

    // Analytics
    uint256 public totalBatches;
    uint256 public totalTransfers;
    uint256 public totalRecalls;
    uint256 public totalTempBreaches;
    uint256 public totalActors;

    // ── EVENTS ─────────────────────────────────────────────
    event ActorRegistered(address indexed wallet, Role role, string name);
    event ActorVerified(address indexed wallet, bool verified);
    event BatchRegistered(uint256 indexed id, string name, string batchNumber, address by);
    event BatchTransferred(uint256 indexed id, address indexed from, address indexed to, uint256 timestamp);
    event TempLogged(uint256 indexed batchId, int256 temp, TempStatus status, uint256 timestamp);
    event BatchRecalled(uint256 indexed id, string reason, address by);
    event BatchExpired(uint256 indexed id);
    event AdminChanged(address indexed admin, bool added);

    // ── MODIFIERS ──────────────────────────────────────────
    modifier onlyOwner()  { require(msg.sender == owner, "Owner only"); _; }
    modifier onlyAdmin()  { require(_admins[msg.sender] || msg.sender == owner, "Admin only"); _; }
    modifier onlyVerified(){ require(_actors[msg.sender].isVerified, "Not verified actor"); _; }
    modifier batchOk(uint256 id){ require(_batches[id].exists, "Batch not found"); _; }

    // ── CONSTRUCTOR ────────────────────────────────────────
    constructor() {
        owner = msg.sender;
        _admins[msg.sender] = true;
        // Register owner as Regulator automatically
        _actors[msg.sender] = ActorInfo({
            wallet: msg.sender,
            name: "MediChain Admin",
            licenseNumber: "ADMIN-001",
            role: Role.Regulator,
            isVerified: true,
            exists: true
        });
        totalActors++;
    }

    // ── ACTOR MANAGEMENT ───────────────────────────────────

    /// @notice Register as a supply chain actor (manufacturer, distributor, pharmacy)
    function registerActor(
        string calldata name,
        string calldata licenseNumber,
        Role role
    ) external {
        require(!_actors[msg.sender].exists, "Already registered");
        require(role != Role.None && role != Role.Regulator, "Invalid role");
        require(bytes(name).length > 0, "Name required");
        require(bytes(licenseNumber).length > 0, "License required");

        _actors[msg.sender] = ActorInfo({
            wallet: msg.sender,
            name: name,
            licenseNumber: licenseNumber,
            role: role,
            isVerified: false, // Admin must verify
            exists: true
        });
        totalActors++;
        emit ActorRegistered(msg.sender, role, name);
    }

    /// @notice Admin verifies an actor
    function verifyActor(address wallet, bool verified) external onlyAdmin {
        require(_actors[wallet].exists, "Actor not found");
        _actors[wallet].isVerified = verified;
        emit ActorVerified(wallet, verified);
    }

    function getActor(address wallet) external view returns (ActorInfo memory) {
        return _actors[wallet];
    }

    function isActorVerified(address wallet) external view returns (bool) {
        return _actors[wallet].isVerified;
    }

    // ── BATCH REGISTRATION ─────────────────────────────────

    /// @notice Manufacturer registers a new medicine batch
    function registerBatch(BatchInput calldata inp) external onlyVerified returns (uint256 id) {
        require(_actors[msg.sender].role == Role.Manufacturer, "Manufacturers only");
        require(bytes(inp.name).length > 0, "Name required");
        require(bytes(inp.batchNumber).length > 0, "Batch# required");
        require(inp.expDate > block.timestamp, "Already expired");
        require(inp.quantity > 0, "Quantity > 0");
        require(_batchNumberToId[inp.batchNumber] == 0, "Batch# already registered");

        _batchCount++;
        id = _batchCount;

        MedicineBatch storage b = _batches[id];
        b.id           = id;
        b.name         = inp.name;
        b.batchNumber  = inp.batchNumber;
        b.manufacturer = inp.manufacturer;
        b.composition  = inp.composition;
        b.mfgDate      = inp.mfgDate;
        b.expDate      = inp.expDate;
        b.quantity     = inp.quantity;
        b.minTemp      = inp.minTemp;
        b.maxTemp      = inp.maxTemp;
        b.ipfsHash     = inp.ipfsHash;
        b.registeredBy = msg.sender;
        b.status       = BatchStatus.Active;
        b.registeredAt = block.timestamp;
        b.exists       = true;

        _batchNumberToId[inp.batchNumber] = id;
        totalBatches++;

        // Log initial transfer (manufacturer → self, i.e. manufactured)
        _logTransfer(id, address(0), msg.sender, Role.Manufacturer, "Manufacturing Plant", "Batch manufactured", 0);

        emit BatchRegistered(id, inp.name, inp.batchNumber, msg.sender);
    }

    // ── SUPPLY CHAIN TRANSFER ──────────────────────────────

    /// @notice Transfer batch to next actor in the supply chain
    function transferBatch(
        uint256        batchId,
        address        toAddress,
        string calldata location,
        string calldata notes,
        int256         currentTemp
    ) external onlyVerified batchOk(batchId) {
        MedicineBatch storage b = _batches[batchId];
        require(
            b.status == BatchStatus.Active || b.status == BatchStatus.InTransit,
            "Batch not transferable"
        );
        require(b.expDate > block.timestamp, "Batch expired");
        require(_actors[toAddress].isVerified, "Recipient not verified");
        require(toAddress != msg.sender, "Cannot transfer to self");

        b.status = BatchStatus.InTransit;

        // Check temp breach
        TempStatus ts = _checkTemp(currentTemp, b.minTemp, b.maxTemp);
        if (ts != TempStatus.Normal) totalTempBreaches++;

        _logTransfer(batchId, msg.sender, toAddress, _actors[toAddress].role, location, notes, currentTemp);

        totalTransfers++;
        emit BatchTransferred(batchId, msg.sender, toAddress, block.timestamp);
        emit TempLogged(batchId, currentTemp, ts, block.timestamp);
    }

    /// @notice Mark batch as delivered (final destination — pharmacy or hospital)
    function markDelivered(uint256 batchId, string calldata location) external onlyVerified batchOk(batchId) {
        require(_actors[msg.sender].role == Role.Pharmacy, "Pharmacy only");
        MedicineBatch storage b = _batches[batchId];
        require(b.status == BatchStatus.InTransit, "Not in transit");
        b.status = BatchStatus.Delivered;

        _logTransfer(batchId, address(0), msg.sender, Role.Pharmacy, location, "Delivered to pharmacy", 0);
    }

    // ── TEMPERATURE LOGGING ────────────────────────────────

    /// @notice Log temperature reading for a batch (IoT device / manual entry)
    function logTemperature(
        uint256        batchId,
        int256         temperature,
        string calldata location
    ) external onlyVerified batchOk(batchId) {
        MedicineBatch storage b = _batches[batchId];
        TempStatus ts = _checkTemp(temperature, b.minTemp, b.maxTemp);

        _tempLogCount++;
        TempLog memory log = TempLog({
            batchId:    batchId,
            temperature: temperature,
            location:   location,
            loggedBy:   msg.sender,
            timestamp:  block.timestamp,
            status:     ts
        });
        _tempLogs[batchId].push(log);

        if (ts != TempStatus.Normal) totalTempBreaches++;

        emit TempLogged(batchId, temperature, ts, block.timestamp);
    }

    // ── RECALL ─────────────────────────────────────────────

    /// @notice Regulator or Admin recalls a batch
    function recallBatch(uint256 batchId, string calldata reason) external batchOk(batchId) {
        require(
            _admins[msg.sender] ||
            _actors[msg.sender].role == Role.Regulator,
            "Not authorized"
        );
        require(bytes(reason).length > 0, "Reason required");

        _batches[batchId].status = BatchStatus.Recalled;
        _recalls[batchId] = RecallInfo({
            batchId: batchId,
            reason: reason,
            initiatedBy: msg.sender,
            timestamp: block.timestamp
        });
        totalRecalls++;
        emit BatchRecalled(batchId, reason, msg.sender);
    }

    // ── VIEW FUNCTIONS ─────────────────────────────────────

    function getBatch(uint256 id) external view batchOk(id) returns (MedicineBatch memory) {
        return _batches[id];
    }

    function getBatchByNumber(string calldata batchNumber) external view returns (MedicineBatch memory) {
        uint256 id = _batchNumberToId[batchNumber];
        require(id != 0, "Batch not found");
        return _batches[id];
    }

    function getBatchIdByNumber(string calldata batchNumber) external view returns (uint256) {
        return _batchNumberToId[batchNumber];
    }

    function getTransferHistory(uint256 batchId) external view returns (TransferEvent[] memory) {
        return _transfers[batchId];
    }

    function getTempLogs(uint256 batchId) external view returns (TempLog[] memory) {
        return _tempLogs[batchId];
    }

    function getRecallInfo(uint256 batchId) external view returns (RecallInfo memory) {
        return _recalls[batchId];
    }

    function getBatchCount() external view returns (uint256) { return _batchCount; }

    function getAnalytics() external view returns (
        uint256 batches, uint256 transfers, uint256 recalls,
        uint256 breaches, uint256 actors
    ) {
        return (totalBatches, totalTransfers, totalRecalls, totalTempBreaches, totalActors);
    }

    // ── ADMIN ──────────────────────────────────────────────

    function addAdmin(address a) external onlyOwner {
        require(!_admins[a], "Already admin");
        _admins[a] = true;
        emit AdminChanged(a, true);
    }

    function removeAdmin(address a) external onlyOwner {
        require(a != owner, "Cannot remove owner");
        _admins[a] = false;
        emit AdminChanged(a, false);
    }

    function isAdmin(address a) external view returns (bool) {
        return _admins[a] || a == owner;
    }

    // ── INTERNAL ───────────────────────────────────────────

    function _logTransfer(
        uint256 batchId,
        address from,
        address to,
        Role    toRole,
        string memory location,
        string memory notes,
        int256  temp
    ) internal {
        _transferCount++;
        _transfers[batchId].push(TransferEvent({
            batchId: batchId,
            from: from,
            to: to,
            toRole: toRole,
            location: location,
            notes: notes,
            timestamp: block.timestamp,
            tempAtTransfer: temp
        }));
    }

    function _checkTemp(int256 temp, int256 minT, int256 maxT) internal pure returns (TempStatus) {
        if (temp < minT || temp > maxT) {
            int256 breach = temp < minT ? minT - temp : temp - maxT;
            if (breach > 50) return TempStatus.Critical; // >5°C breach
            return TempStatus.Warning;
        }
        return TempStatus.Normal;
    }

    receive() external payable {}
}
