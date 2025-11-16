import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ticket.dart';

class QRCodeService {
  static final QRCodeService _instance = QRCodeService._internal();
  factory QRCodeService() => _instance;
  QRCodeService._internal();

  /// Generate QR code data string from ticket
  String generateQRCodeData(Ticket ticket) {
    final data = {
      'ticketId': ticket.ticketId,
      'eventId': ticket.eventId,
      'avatarId': ticket.avatarId,
      'buyerAddress': ticket.buyerAddress,
      'purchaseTime': ticket.purchaseTime.toIso8601String(),
    };
    
    return jsonEncode(data);
  }

  /// Generate QR code hash (matches blockchain hash)
  String generateQRCodeHash(Ticket ticket) {
    final data = '${ticket.ticketId}:${ticket.eventId}:${ticket.avatarId}:${ticket.buyerAddress}:${ticket.purchaseTime.millisecondsSinceEpoch}';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Parse QR code data from scanned string
  Map<String, dynamic>? parseQRCodeData(String qrData) {
    try {
      return jsonDecode(qrData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Validate QR code data structure
  bool isValidQRCodeData(Map<String, dynamic> data) {
    return data.containsKey('ticketId') &&
           data.containsKey('eventId') &&
           data.containsKey('avatarId') &&
           data.containsKey('buyerAddress') &&
           data.containsKey('purchaseTime');
  }

  /// Create QR code widget for display
  QrImageView generateQRCodeWidget({
    required String data,
    required double size,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor ?? const Color(0xFFFFFFFF),
      foregroundColor: foregroundColor ?? const Color(0xFF000000),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  /// Generate QR code hash from raw data (for blockchain verification)
  String generateHashFromData({
    required String ticketId,
    required String eventId,
    required String avatarId,
    required String buyerAddress,
    required int timestamp,
  }) {
    final data = '$ticketId:$eventId:$avatarId:$buyerAddress:$timestamp';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Convert hex string to bytes32 format for blockchain
  String hexToBytes32(String hexString) {
    // Remove 0x prefix if present
    if (hexString.startsWith('0x')) {
      hexString = hexString.substring(2);
    }
    
    // Pad to 64 characters (32 bytes)
    while (hexString.length < 64) {
      hexString = '0$hexString';
    }
    
    return '0x$hexString';
  }
}

