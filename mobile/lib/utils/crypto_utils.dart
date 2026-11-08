import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

class CryptoUtils {
  /// Generate a 2048-bit RSA Key Pair
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRsaKeyPair({int bitLength = 2048}) {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ));

    final pair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  /// Generate a Self-Signed X.509 Certificate DER bytes
  static Uint8List generateSelfSignedCertificate({
    required RSAPublicKey publicKey,
    required RSAPrivateKey privateKey,
    String commonName = 'TCL SMART REMOTE',
    int validityDays = 3650, // 10 years
  }) {
    // TBSCertificate sequence
    final tbs = ASN1Sequence();

    // Version v3 (0x02)
    final versionExplicit = ASN1Sequence(tag: 0xA0);
    versionExplicit.add(ASN1Integer(BigInt.from(2)));
    tbs.add(versionExplicit);

    // Serial Number
    final serial = Random.secure().nextInt(1000000) + 1;
    tbs.add(ASN1Integer(BigInt.from(serial)));

    // Signature Algorithm: SHA256withRSAEncryption (1.2.840.113549.1.1.11)
    final sigAlgSeq = ASN1Sequence();
    sigAlgSeq.add(ASN1ObjectIdentifier.fromComponentString('1.2.840.113549.1.1.11'));
    sigAlgSeq.add(ASN1Null());
    tbs.add(sigAlgSeq);

    // Issuer (CN=commonName)
    final issuerSeq = ASN1Sequence();
    final rdnSet = ASN1Set();
    final rdnSeq = ASN1Sequence();
    rdnSeq.add(ASN1ObjectIdentifier.fromComponentString('2.5.4.3')); // CommonName
    rdnSeq.add(ASN1UTF8String(commonName));
    rdnSet.add(rdnSeq);
    issuerSeq.add(rdnSet);
    tbs.add(issuerSeq);

    // Validity
    final validitySeq = ASN1Sequence();
    final now = DateTime.now().toUtc();
    final notBefore = ASN1UtcTime(now);
    final notAfter = ASN1UtcTime(now.add(Duration(days: validityDays)));
    validitySeq.add(notBefore);
    validitySeq.add(notAfter);
    tbs.add(validitySeq);

    // Subject (same as Issuer for self-signed)
    tbs.add(issuerSeq);

    // SubjectPublicKeyInfo
    final spkiSeq = ASN1Sequence();
    final pkAlgSeq = ASN1Sequence();
    pkAlgSeq.add(ASN1ObjectIdentifier.fromComponentString('1.2.840.113549.1.1.1')); // rsaEncryption
    pkAlgSeq.add(ASN1Null());
    spkiSeq.add(pkAlgSeq);

    final rsaPubSeq = ASN1Sequence();
    rsaPubSeq.add(ASN1Integer(publicKey.modulus!));
    rsaPubSeq.add(ASN1Integer(publicKey.exponent!));
    spkiSeq.add(ASN1BitString(stringValues: rsaPubSeq.encodedBytes));
    tbs.add(spkiSeq);

    // Sign TBSCertificate using SHA256withRSA
    final tbsBytes = tbs.encodedBytes;
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final RSASignature signature = signer.generateSignature(tbsBytes) as RSASignature;

    // Full Certificate Sequence
    final certSeq = ASN1Sequence();
    certSeq.add(tbs);
    certSeq.add(sigAlgSeq);
    certSeq.add(ASN1BitString(stringValues: signature.bytes));

    return certSeq.encodedBytes;
  }

  /// Encode bytes to PEM format
  static String encodeToPem(List<int> bytes, String header) {
    final b64 = base64.encode(bytes);
    final lines = <String>['-----BEGIN $header-----'];
    for (int i = 0; i < b64.length; i += 64) {
      final end = (i + 64 < b64.length) ? i + 64 : b64.length;
      lines.add(b64.substring(i, end));
    }
    lines.add('-----END $header-----');
    return lines.join('\n');
  }

  /// Convert RSA Private Key to PKCS#8 DER bytes
  static Uint8List privateKeyToPkcs8Der(RSAPrivateKey key) {
    final privKeySeq = ASN1Sequence();
    privKeySeq.add(ASN1Integer(BigInt.zero)); // version 0
    privKeySeq.add(ASN1Integer(key.modulus!));
    privKeySeq.add(ASN1Integer(key.publicExponent!));
    privKeySeq.add(ASN1Integer(key.privateExponent!));
    privKeySeq.add(ASN1Integer(key.p!));
    privKeySeq.add(ASN1Integer(key.q!));
    // d mod (p-1)
    privKeySeq.add(ASN1Integer(key.privateExponent! % (key.p! - BigInt.one)));
    // d mod (q-1)
    privKeySeq.add(ASN1Integer(key.privateExponent! % (key.q! - BigInt.one)));
    // q^-1 mod p
    privKeySeq.add(ASN1Integer(key.q!.modInverse(key.p!)));

    return privKeySeq.encodedBytes;
  }

  /// Compute SHA-256 Fingerprint for certificate
  static String computeFingerprint(List<int> certDer) {
    final digest = sha256.convert(certDer);
    return digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }
}
