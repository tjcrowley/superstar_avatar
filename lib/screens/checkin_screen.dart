import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/blockchain_service.dart';
import '../services/qr_code_service.dart';
import '../models/ticket.dart';
import '../models/event.dart';
import '../constants/app_constants.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  final String eventId;
  final Event event;

  const CheckInScreen({
    Key? key,
    required this.eventId,
    required this.event,
  }) : super(key: key);

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final BlockchainService _blockchainService = BlockchainService();
  final QRCodeService _qrCodeService = QRCodeService();
  final MobileScannerController _scannerController = MobileScannerController();
  
  bool _isScanning = true;
  bool _isProcessing = false;
  String? _lastScannedData;
  List<CheckInResult> _checkInHistory = [];

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _lastScannedData = qrData;
    });

    try {
      // Parse QR code data
      final qrDataMap = _qrCodeService.parseQRCodeData(qrData);
      
      if (qrDataMap == null || !_qrCodeService.isValidQRCodeData(qrDataMap)) {
        _showError('Invalid QR code format');
        return;
      }

      final ticketId = qrDataMap['ticketId'] as String;
      final eventId = qrDataMap['eventId'] as String;
      final avatarId = qrDataMap['avatarId'] as String;

      // Verify event matches
      if (eventId != widget.eventId) {
        _showError('Ticket is for a different event');
        return;
      }

      // Generate QR code hash for blockchain verification
      final qrHash = _qrCodeService.generateHashFromData(
        ticketId: ticketId,
        eventId: eventId,
        avatarId: avatarId,
        buyerAddress: qrDataMap['buyerAddress'] as String,
        timestamp: DateTime.parse(qrDataMap['purchaseTime'] as String).millisecondsSinceEpoch,
      );

      // Check in ticket on blockchain
      await _blockchainService.checkInTicketWithQRCode(
        qrCodeHash: qrHash,
      );

      // Add to check-in history
      setState(() {
        _checkInHistory.insert(0, CheckInResult(
          ticketId: ticketId,
          avatarId: avatarId,
          timestamp: DateTime.now(),
          success: true,
        ));
      });

      _showSuccess('Ticket checked in successfully!');
      
      // Resume scanning after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isScanning = true;
          });
        }
      });
    } catch (e) {
      _showError('Check-in failed: ${e.toString()}');
      setState(() {
        _isProcessing = false;
        _isScanning = true;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isScanning = !_isScanning;
                if (_isScanning) {
                  _scannerController.start();
                } else {
                  _scannerController.stop();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppConstants.primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.event.venue,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.event.ticketsSold} / ${widget.event.maxTickets} checked in',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Scanner Section
          Expanded(
            flex: 2,
            child: _isScanning && !_isProcessing
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              _processQRCode(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                      // Scanning overlay
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppConstants.primaryColor,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: const EdgeInsets.all(40),
                      ),
                      // Instructions
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Position QR code within the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: _isProcessing
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Processing ticket...',
                                style: TextStyle(
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 64,
                                color: AppConstants.textSecondaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Scanner paused',
                                style: TextStyle(
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                  ),
          ),

          // Check-in History
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Check-ins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _checkInHistory.isEmpty
                        ? Center(
                            child: Text(
                              'No check-ins yet',
                              style: TextStyle(
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _checkInHistory.length,
                            itemBuilder: (context, index) {
                              final result = _checkInHistory[index];
                              return ListTile(
                                leading: Icon(
                                  result.success
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: result.success
                                      ? AppConstants.successColor
                                      : AppConstants.errorColor,
                                ),
                                title: Text('Ticket: ${result.ticketId.substring(0, 8)}...'),
                                subtitle: Text(
                                  'Avatar: ${result.avatarId.substring(0, 8)}...',
                                ),
                                trailing: Text(
                                  '${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: AppConstants.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckInResult {
  final String ticketId;
  final String avatarId;
  final DateTime timestamp;
  final bool success;

  CheckInResult({
    required this.ticketId,
    required this.avatarId,
    required this.timestamp,
    required this.success,
  });
}

