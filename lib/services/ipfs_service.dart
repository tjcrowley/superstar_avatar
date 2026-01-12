import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';

/// Service for uploading files to IPFS
/// Supports multiple IPFS pinning services (Pinata, NFT.Storage, etc.)
class IPFSService {
  static final IPFSService _instance = IPFSService._internal();
  factory IPFSService() => _instance;
  IPFSService._internal();

  // IPFS Gateway URLs for accessing files
  static const List<String> ipfsGateways = [
    'https://ipfs.io/ipfs/',
    'https://gateway.pinata.cloud/ipfs/',
    'https://cloudflare-ipfs.com/ipfs/',
  ];

  /// Upload image bytes to IPFS using Pinata
  /// Returns the IPFS hash (CID)
  Future<String> uploadImageToPinata(Uint8List imageBytes, String filename) async {
    try {
      // Check if Pinata API keys are configured
      // For production, these should be set in app_constants.dart or environment variables
      const pinataApiKey = 'YOUR_PINATA_API_KEY'; // TODO: Add to app_constants
      const pinataSecretKey = 'YOUR_PINATA_SECRET_KEY'; // TODO: Add to app_constants

      if (pinataApiKey == 'YOUR_PINATA_API_KEY' || pinataSecretKey == 'YOUR_PINATA_SECRET_KEY') {
        throw Exception(
          'Pinata API keys not configured. '
          'Please set PINATA_API_KEY and PINATA_SECRET_KEY in app_constants.dart'
        );
      }

      // Create multipart request
      final uri = Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll({
        'pinata_api_key': pinataApiKey,
        'pinata_secret_api_key': pinataSecretKey,
      });

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      // Add metadata
      final metadata = {
        'name': filename,
        'keyvalues': {
          'app': 'superstar_avatar',
          'type': 'activity_image',
        },
      };
      request.fields['pinataMetadata'] = jsonEncode(metadata);

      // Send request
      debugPrint('Uploading image to Pinata...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final ipfsHash = responseData['IpfsHash'] as String;
        debugPrint('Image uploaded to IPFS: $ipfsHash');
        return ipfsHash;
      } else {
        debugPrint('Pinata upload error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to upload to IPFS: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error uploading to Pinata: $e');
      rethrow;
    }
  }

  /// Upload image bytes to IPFS using NFT.Storage
  /// Returns the IPFS hash (CID)
  Future<String> uploadImageToNFTStorage(Uint8List imageBytes, String filename) async {
    try {
      // Check if NFT.Storage API key is configured
      const nftStorageApiKey = 'YOUR_NFT_STORAGE_API_KEY'; // TODO: Add to app_constants

      if (nftStorageApiKey == 'YOUR_NFT_STORAGE_API_KEY') {
        throw Exception(
          'NFT.Storage API key not configured. '
          'Please set NFT_STORAGE_API_KEY in app_constants.dart'
        );
      }

      // Create multipart request
      final uri = Uri.parse('https://api.nft.storage/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $nftStorageApiKey',
      });

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      // Send request
      debugPrint('Uploading image to NFT.Storage...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final cid = responseData['value']['cid'] as String;
        debugPrint('Image uploaded to IPFS: $cid');
        return cid;
      } else {
        debugPrint('NFT.Storage upload error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to upload to IPFS: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error uploading to NFT.Storage: $e');
      rethrow;
    }
  }

  /// Upload image to IPFS using the configured service
  /// Defaults to Pinata, falls back to NFT.Storage
  Future<String> uploadImage(Uint8List imageBytes, String filename) async {
    try {
      // Try Pinata first
      return await uploadImageToPinata(imageBytes, filename);
    } catch (e) {
      debugPrint('Pinata upload failed, trying NFT.Storage: $e');
      try {
        // Fall back to NFT.Storage
        return await uploadImageToNFTStorage(imageBytes, filename);
      } catch (e2) {
        debugPrint('NFT.Storage upload also failed: $e2');
        // If both fail, throw the original error
        throw Exception('Failed to upload to IPFS. Please check your API keys configuration.');
      }
    }
  }

  /// Get IPFS gateway URL for a hash
  /// Tries multiple gateways for reliability
  String getIPFSUrl(String ipfsHash) {
    // Remove ipfs:// prefix if present
    final hash = ipfsHash.replaceFirst('ipfs://', '');
    // Return first gateway URL (can implement fallback logic if needed)
    return '${ipfsGateways[0]}$hash';
  }

  /// Convert IPFS hash to full IPFS URI
  String getIPFSUri(String ipfsHash) {
    // If it already has ipfs:// prefix, return as is
    if (ipfsHash.startsWith('ipfs://')) {
      return ipfsHash;
    }
    return 'ipfs://$ipfsHash';
  }
}
